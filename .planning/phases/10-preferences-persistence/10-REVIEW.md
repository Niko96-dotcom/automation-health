---
phase: 10-preferences-persistence
reviewed: 2026-05-11T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - LICENSE
  - Sources/ActiveJobsCore/Services/JobScanning.swift
  - Sources/ActiveJobsCoreSelfTest/main.swift
  - Sources/AutomationHealth/App/AutomationHealthApp.swift
  - Sources/AutomationHealth/Stores/JobStore.swift
  - Sources/AutomationHealth/Stores/PreferencesStore.swift
  - Sources/AutomationHealth/Views/ContentView.swift
  - Sources/AutomationHealth/Views/SettingsView.swift
  - Sources/AutomationHealthCore/JobPresentation.swift
findings:
  critical: 1
  warning: 4
  info: 4
  total: 9
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-05-11
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the preferences persistence implementation across 8 source files. The phase introduces a new `AutomationHealthCore` library target containing `JobPresentation` and sidebar grouping logic extracted from the app target. A `PreferencesStore` manages user preferences via `UserDefaults` and `@Published` properties. A `SettingsView` exposes scan configuration controls.

**Key concern:** The `scanOnLaunch` preference is displayed in the Settings UI but has no effect on application behavior — `AutomationHealthApp` always triggers a scan on launch regardless. Additionally, there are several code quality issues around dead code, brittle string comparisons, and inconsistent use of injected dependencies.

## Critical Issues

### CR-01: `scanOnLaunch` Preference Has No Functional Effect

**File:** `Sources/AutomationHealth/App/AutomationHealthApp.swift:28-30` and `Sources/AutomationHealth/Stores/PreferencesStore.swift:22-23`

**Issue:** The `PreferencesStore.scanOnLaunch` property is persisted to `UserDefaults`, exposed in `SettingsView` as a toggle labeled "Scan for candidate scripts on launch", but no code ever reads it to influence behavior. The `AutomationHealthApp.task` modifier unconditionally calls `store.refresh()` on every appear. The `candidateScannerConfiguration` computed property in `PreferencesStore` does not reference `scanOnLaunch` at all. This makes the preference entirely non-functional — toggling it in Settings has zero impact.

**Fix:** Either wire `scanOnLaunch` into the app launch flow or remove it. To fix:

```swift
// AutomationHealthApp.swift, line 28-30
.task {
    if preferences.scanOnLaunch {
        store.refresh()
    }
}
```

Additionally, the `candidateScannerConfiguration` computed property could incorporate `scanOnLaunch` to conditionally disable candidate scanning entirely, or the preference should gate whether `CandidateScriptScanner` is included in the scanner list in `JobInventory.live()`.

## Warnings

### WR-01: `PreferencesStore` `didSet` Observers Bypass Injected `UserDefaults`

**File:** `Sources/AutomationHealth/Stores/PreferencesStore.swift:10,17,23,27,31`

**Issue:** The `init(userDefaults:)` parameter allows injecting a custom `UserDefaults` instance (e.g., a test suite), and the initializer correctly reads from it. However, every `didSet` observer writes to `UserDefaults.standard` directly instead of the injected instance:

```swift
didSet {
    UserDefaults.standard.set(groupingMode.rawValue, forKey: "sidebarGroupingMode")
}
```

This creates a split-brain: initial reads come from the injected suite, but all subsequent writes go to `.standard`. In production with the default argument this works by coincidence (the injected instance IS `.standard`), but it silently breaks testability and is a latent correctness issue.

**Fix:** Store the injected `UserDefaults` instance and use it in all `didSet` observers:

```swift
@MainActor
final class PreferencesStore: ObservableObject {
    private let userDefaults: UserDefaults

    @Published var groupingMode: SidebarGroupingMode {
        didSet {
            userDefaults.set(groupingMode.rawValue, forKey: "sidebarGroupingMode")
        }
    }
    // ... apply same pattern to all didSet observers
}
```

### WR-02: `JobInventory.init` Accepts Unused `homeDirectory` Parameter

**File:** `Sources/ActiveJobsCore/Services/JobScanning.swift:20-22`

**Issue:** The `JobInventory` initializer accepts a `homeDirectory` parameter but never stores or uses it:

```swift
public init(scanners: [JobScanning], homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
    self.scanners = scanners
}
```

The `homeDirectory` is only used in the `.live()` factory method where it's passed to individual scanner constructors. The bare `init` ignores it, making the parameter dead code that could mislead callers into thinking it has an effect.

**Fix:** Remove the `homeDirectory` parameter from `init(scanners:)` since `JobInventory` does not own directory configuration — that responsibility belongs to individual scanners:

```swift
public init(scanners: [JobScanning]) {
    self.scanners = scanners
}
```

Update callers in self-test (`main.swift:208`) to omit the parameter.

### WR-03: Brittle String Comparison for Manual Record Schedule Detection

**File:** `Sources/AutomationHealth/Views/ContentView.swift:148`

**Issue:** The edit sheet factory method uses a hardcoded string comparison to detect whether a manual record has the default schedule:

```swift
let scheduleDescription = job.job.schedule == "Manual record (no schedule evidence)" ? "" : job.job.schedule
```

This string is defined in `ManualRecordStore.swift:40` as a fallback. If that fallback string is ever changed, this comparison silently breaks — the edit sheet would pre-populate the schedule field with the fallback text instead of leaving it empty for the user.

**Fix:** Define a constant in a shared location accessible to both `ManualRecordStore` and `ContentView`:

```swift
// In ActiveJobsCore or AutomationHealthCore
extension ScheduledJob {
    public static let manualDefaultSchedule = "Manual record (no schedule evidence)"
}
```

Or, alternatively, check whether the `ManualAutomationRecord.scheduleDescription` is `nil` rather than comparing the rendered string:

```swift
// Since scheduleDescription is nil when no description was provided,
// compare against the default schedule string via a shared constant
let scheduleDescription = job.job.schedule == ScheduledJob.manualDefaultSchedule ? "" : job.job.schedule
```

### WR-04: Recursive `refresh()` Pattern in `JobStore`

**File:** `Sources/AutomationHealth/Stores/JobStore.swift:153-155`

**Issue:** After a scan completes, if a `pendingRefresh` was queued, `refresh(preferredSelectionID:)` calls itself recursively:

```swift
if let queuedRefresh {
    refresh(preferredSelectionID: queuedRefresh.preferredSelectionID)
}
```

While the current logic limits recursion to depth 2 (since `pendingRefresh` is set to `nil` first and only one pending refresh is stored), this recursive pattern is fragile. If the pending refresh logic is ever extended to support multiple queued refreshes, this could lead to unbounded recursion.

**Fix:** Replace recursion with a loop or guard against re-entry more explicitly:

```swift
isScanning = false

if let queuedRefresh = pendingRefresh {
    pendingRefresh = nil
    // Use Task to break potential recursion
    Task { @MainActor in
        refresh(preferredSelectionID: queuedRefresh.preferredSelectionID)
    }
}
```

## Info

### IN-01: Missing Default Registration for `sidebarCollapseState`

**File:** `Sources/AutomationHealth/Stores/PreferencesStore.swift:35-39`

**Issue:** The `init` registers defaults for `sidebarGroupingMode`, `scanOnLaunch`, `scanMaxDepth`, and `scanMaxResults`, but not for `sidebarCollapseState`. All other persisted keys have explicit defaults. This inconsistency is minor since the code handles nil data gracefully with `collapseState = SidebarCollapseState()`, but omitting the default registration means there's no single place documenting all default values.

**Fix:** Consider adding an explicit default for `sidebarCollapseState`, even though `UserDefaults` doesn't directly support `Data` default registration well. At minimum, add a comment noting the intentional omission.

### IN-02: Error `ScanNote` Uses Hardcoded `.launchd` Source

**File:** `Sources/AutomationHealth/Stores/JobStore.swift:138-144`

**Issue:** When the scan fails, the error `ScanNote` always reports `source: .launchd`:

```swift
ScanNote(
    source: .launchd,
    severity: .error,
    message: "Scan failed",
    detail: error.localizedDescription
)
```

The failure could originate from any scanner or the inventory aggregation itself, but the note unconditionally attributes it to `launchd`.

**Fix:** Use a source-agnostic approach, or capture the actual failing source if possible:

```swift
// Option A: Use a more generic source (if one exists)
ScanNote(
    source: .launchd, // Currently the only source with severity .error; consider adding a generic source
    ...
)

// Option B: Propagate source from the underlying error
```

### IN-03: Hardcoded Numeric Defaults Mirror `CandidateScriptScanner.Configuration`

**File:** `Sources/AutomationHealth/Stores/PreferencesStore.swift:38-39`

**Issue:** The default values `scanMaxDepth: 2` and `scanMaxResults: 200` are hardcoded in `PreferencesStore.init` and also defined in `CandidateScriptScanner.Configuration.default`. If the scanner defaults change, the preference defaults would silently diverge.

**Fix:** Reference the scanner configuration defaults directly:

```swift
let scannerDefaults = CandidateScriptScanner.Configuration.default
userDefaults.register(defaults: [
    ...
    "scanMaxDepth": scannerDefaults.maxDepth,
    "scanMaxResults": scannerDefaults.maxResults
])
```

### IN-04: `ManualRecordSheetView` Embedded in `ContentView.swift`

**File:** `Sources/AutomationHealth/Views/ContentView.swift:165-260`

**Issue:** The `ManualRecordSheetView` (~95 lines) and `ManualRecordSheetState` (~50 lines) are defined as file-private types within `ContentView.swift`. The project convention is one primary type per file. While file-private helper types are acceptable, these are substantial view and state types that could benefit from separate files for readability and testability.

**Fix:** Consider extracting `ManualRecordSheetState` and `ManualRecordSheetView` into dedicated files, e.g., `Sources/AutomationHealth/Views/ManualRecordSheetView.swift`.

---

_Reviewed: 2026-05-11T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
