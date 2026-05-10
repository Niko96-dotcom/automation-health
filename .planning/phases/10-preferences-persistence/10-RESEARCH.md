# Phase 10: Preferences Persistence - Research

**Researched:** 2026-05-10
**Domain:** macOS SwiftUI app — UserDefaults/@AppStorage persistence, SwiftUI Settings scene, MIT LICENSE
**Confidence:** HIGH

## Summary

Phase 10 introduces a `PreferencesStore` (a new `@MainActor ObservableObject`) that bridges `UserDefaults` to `@Published` properties for grouping mode, sidebar collapse state, and candidate scan configuration. It also adds a native macOS Settings scene (Cmd+,) and updates the existing MIT LICENSE copyright line.

The phase is well-constrained by CONTEXT.md decisions. The existing codebase has clean extension points: `SidebarGroupingMode` is already `String`-raw-representable (directly `@AppStorage`-compatible), `SidebarView` already takes `@Binding` for both grouping mode and collapse state (only the source of the binding changes), and `CandidateScriptScanner.Configuration` has a `.default` static that can be replaced with a PreferencesStore-derived instance at scan time.

**Primary recommendation:** Build `PreferencesStore` following the `JobStore` pattern (`@MainActor final class: ObservableObject`, `@Published` properties with `didSet` writing to `UserDefaults`), migrate `ContentView`'s two `@State` vars to `@ObservedObject`, and wire scan config values into `CandidateScriptScanner` initializer via a `JobInventory.live()` overload accepting a `Configuration`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|-------------|-------------|----------------|-----------|
| PreferencesStore (grouping mode, collapse state, scan config) | Store/ObservableObject layer (`Sources/AutomationHealth/Stores/`) | Foundation layer (`UserDefaults`) | Single source of truth for UI state with persistent backing; owned at app level |
| Grouping mode persistence | PreferencesStore (`@Published` + `UserDefaults.set`) | SwiftUI views (`@ObservedObject` / `@Binding`) | Store writes on `didSet`; views read via published properties |
| Collapse state persistence | PreferencesStore (`@Published` + `JSONEncoder`) | Foundation layer (`UserDefaults Data`) | Complex `Set<SidebarSectionID>` needs JSON encoding; store handles serialization |
| Scan config persistence | PreferencesStore (`@Published` + `UserDefaults`) | Core layer (`CandidateScriptScanner.Configuration`) | Config values flow from store into scanner at construction time |
| Settings scene (Cmd+,) | SwiftUI `Settings` scene (`Sources/AutomationHealth/Views/`) | PreferencesStore (`@ObservedObject`) | Pure UI presentation; all state lives in the store |
| LICENSE file | Repository root (static file) | — | Static artifact; no runtime component |

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a separate `PreferencesStore` (@MainActor ObservableObject) — not merged into `JobStore`. JobStore stays focused on scanner state, selection, and manual record CRUD. Two @StateObjects in AutomationHealthApp.
- **D-02:** `PreferencesStore` owns `@Published groupingMode: SidebarGroupingMode`, `@Published collapseState: SidebarCollapseState`, `@Published scanOnLaunch: Bool`, `@Published scanMaxDepth: Int`, `@Published scanMaxResults: Int`. Each writes to UserDefaults on change. Reads defaults on init.
- **D-03:** Settings exposes three knobs: maxDepth (slider 0–5, default 2), maxResults (slider 10–500, default 200), "Scan candidate scripts on launch" toggle (default: on). Script extensions and ignored directories stay at compile-time defaults from `CandidateScriptScanner.Configuration.default`.
- **D-04:** Scan config values feed into `CandidateScriptScanner` via its `Configuration` struct at inventory construction time — not through global mutable state.
- **D-05:** Settings scene (Cmd+,) exposes: default grouping mode picker, candidate scan knobs (depth slider, results slider, on/off toggle). No keyboard shortcut reference table.
- **D-06:** MIT license in repository root. Copyright line: `Copyright (c) 2026 Niko`.

### Agent's Discretion
- Collapse state serialization: JSON-encode `Set<SidebarSectionID>` to `Data` for UserDefaults. Requires adding `Codable` conformance to `SidebarSectionID` and `SidebarCollapseState`.
- PreferencesStore UserDefaults key naming (e.g., `"sidebarGroupingMode"`, `"sidebarCollapseState"`, `"scanOnLaunch"`, `"scanMaxDepth"`, `"scanMaxResults"`).
- Settings view layout — standard SwiftUI Form with grouped sections, `Picker` for grouping mode, `Slider` for depth/results, `Toggle` for scan-on-launch.
- `PreferencesStore` should use `UserDefaults.standard.register(defaults:)` for initial defaults on first launch.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PREFS-01 | Sidebar grouping mode persists across app launches via @AppStorage | D-01, D-02: `PreferencesStore.groupingMode` writes to `UserDefaults` on `didSet`; `SidebarGroupingMode` is String-raw-representable → directly `@AppStorage`-compatible [VERIFIED: codebase analysis] |
| PREFS-02 | Sidebar collapse state persists per group key via UserDefaults | D-02: `SidebarCollapseState` stores `Set<SidebarSectionID>` which includes `groupingMode` in its `groupKey`; JSON encode to `Data` for UserDefaults; `SidebarSectionID` and `SidebarCollapseState` need `Codable` conformance [VERIFIED: codebase analysis] |
| PREFS-03 | Candidate scan configuration (roots, depth, file count cap, result cap, file size cap) persists via UserDefaults | D-03, D-04: Only `maxDepth` and `maxResults` exposed in Settings (others stay at `.default` values). `PreferencesStore` publishes these values; `CandidateScriptScanner` receives them via `Configuration` struct at construction time [VERIFIED: codebase analysis — `Configuration` struct has all 6 fields] |
| PREFS-04 | Default values are used when no preferences exist | D-02: `PreferencesStore.init()` calls `UserDefaults.standard.register(defaults:)` with documented v1.1 defaults: grouping mode `.source`, collapse state empty (all expanded), scan-on-launch `true`, max depth `2`, max results `200` [ASSUMED: standard Apple pattern; confirmed by CONTEXT.md agent's discretion] |
| PREFS-05 | Settings scene (Cmd+,) exposes persistent scan configuration preferences | D-03, D-05: SwiftUI `Settings` scene with `Form` and `.formStyle(.grouped)`, two sections: "Default View" (grouping mode Picker) and "Candidate Scanning" (Toggle + two Sliders) [VERIFIED: UI-SPEC layout contract] |
| DIST-01 | Permissive LICENSE file (MIT) is committed to the repository root | D-06: LICENSE already exists with MIT text; requires copyright line update from "Automation Health contributors" to "Copyright (c) 2026 Niko" [VERIFIED: codebase analysis — file exists at repo root] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `UserDefaults` | Foundation (macOS 14+) | Persist preferences (grouping mode, collapse state, scan config) | Built-in; no external dependency; supports String, Int, Bool, Data, URL; synchronous writes; `register(defaults:)` for first-launch values |
| `@AppStorage` | SwiftUI (macOS 14+) | Read/write simple preferences in SwiftUI views | Native property wrapper; auto-invalidates views on change; supports String, Int, Bool, Data, URL, RawRepresentable enums |
| `JSONEncoder` / `JSONDecoder` | Foundation (built-in) | Serialize `SidebarCollapseState` to/from `Data` for UserDefaults | Built-in, zero-dependency; used only for `Set<SidebarSectionID>` which `@AppStorage` can't handle directly |
| SwiftUI `Settings` scene | SwiftUI (macOS 13+) | Native macOS Settings window (Cmd+,) | Automatically adds Settings menu item; no manual menu wiring; `.formStyle(.grouped)` for native look |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Combine` | Foundation (macOS 14+) | `ObservableObject` / `@Published` for `PreferencesStore` | Already imported in JobStore — same pattern |
| `SwiftUI` `Form` / `Picker` / `Toggle` / `Slider` | SwiftUI (macOS 14+) | Settings view controls | All standard SwiftUI controls; no custom components needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@AppStorage` for view-only prefs | `@AppStorage` everywhere (including store) | `@AppStorage` is view-only; store needs direct `UserDefaults` access. Keep single source of truth in `PreferencesStore` via `UserDefaults` reads/writes |
| `UserDefaults` directly in views | `@AppStorage` for views, `UserDefaults` for store | Separates concerns: views read from `@Published` properties on `PreferencesStore`, never touch UserDefaults directly |
| Separate stores for scan vs UI prefs | Single `PreferencesStore` | Unnecessary complexity for ~5 keys; single store is the CONTEXT.md lock |

**Installation:** No new packages required. All technologies are built into macOS 14+ / SwiftUI / Foundation.

**Version verification:** These are all built-in Apple SDK modules — no npm/pip packages to verify. The project targets macOS 14 (`Package.swift: .macOS(.v14)`) which guarantees availability of all listed APIs. [VERIFIED: Package.swift platform constraint]

## Architecture Patterns

### System Architecture Diagram

```
App Launch
    │
    ▼
AutomationHealthApp
    │  @StateObject private var store = JobStore()
    │  @StateObject private var preferences = PreferencesStore()   ← NEW
    │
    ├─ WindowGroup ── ContentView(store:store, preferences:preferences)
    │                    │
    │                    ├─ @ObservedObject store
    │                    ├─ @ObservedObject preferences              ← CHANGED (was @State)
    │                    │
    │                    ├─ SidebarView(groupingMode: $preferences.groupingMode,    ← BINDING SOURCE CHANGED
    │                    │              collapseState: $preferences.collapseState)   ← (was $state, now $published)
    │                    │
    │                    └─ DetailView(job: store.selectedJob, ...)
    │
    └─ Settings ── SettingsView(preferences: preferences)           ← NEW
                     │
                     ├─ Picker("Default Grouping", selection: $preferences.groupingMode)
                     ├─ Toggle("Scan on launch", isOn: $preferences.scanOnLaunch)
                     ├─ Slider(value: intBinding($preferences.scanMaxDepth), in: 0...5)
                     └─ Slider(value: intBinding($preferences.scanMaxResults), in: 10...500)

PreferencesStore (@MainActor ObservableObject)                      ← NEW FILE
    │
    ├─ init():
    │   1. UserDefaults.standard.register(defaults:)   ← sets first-launch defaults
    │   2. Read UserDefaults into @Published properties
    │
    ├─ @Published groupingMode: SidebarGroupingMode {
    │     didSet { UserDefaults.standard.set(rawValue, forKey: "sidebarGroupingMode") }
    │   }
    ├─ @Published collapseState: SidebarCollapseState {
    │     didSet { encode to JSON Data, set forKey: "sidebarCollapseState" }
    │   }
    ├─ @Published scanOnLaunch: Bool {
    │     didSet { UserDefaults.standard.set(value, forKey: "scanOnLaunch") }
    │   }
    ├─ @Published scanMaxDepth: Int {
    │     didSet { UserDefaults.standard.set(value, forKey: "scanMaxDepth") }
    │   }
    └─ @Published scanMaxResults: Int {
          didSet { UserDefaults.standard.set(value, forKey: "scanMaxResults") }
        }


JobStore.init() constructor                                         ← MODIFIED
    │
    └─ JobInventory.live(homeDirectory:, manualRecordStore:, candidateConfig:)   ← NEW PARAMETER
         │
         └─ CandidateScriptScanner(homeDirectory:, configuration: candidateConfig)
              │  candidateConfig derived from PreferencesStore values:
              │    maxDepth = preferences.scanMaxDepth
              │    maxResults = preferences.scanMaxResults
              │    maxVisitedFiles = Configuration.default.maxVisitedFiles         ← unchanged
              │    maximumCandidateBytes = Configuration.default.maximumCandidateBytes  ← unchanged
              │    scriptExtensions = Configuration.default.scriptExtensions       ← unchanged
              │    ignoredDirectoryNames = Configuration.default.ignoredDirectoryNames  ← unchanged


LICENSE (root)                                                       ← MODIFIED
    └─ Copyright line: "Copyright (c) 2026 Niko" (was "Automation Health contributors")
```

### Recommended Project Structure
```
Sources/
├── ActiveJobsCore/
│   └── Services/
│       ├── CandidateScriptScanner.swift   # MODIFIED: Configuration already exists; no changes needed
│       └── JobScanning.swift              # MODIFIED: JobInventory.live() needs optional Configuration param
├── AutomationHealthCore/
│   └── JobPresentation.swift              # MODIFIED: add Codable to SidebarSectionID + SidebarCollapseState
└── AutomationHealth/
    ├── App/
    │   └── AutomationHealthApp.swift      # MODIFIED: +@StateObject preferences, +Settings scene, pass to ContentView
    ├── Stores/
    │   ├── JobStore.swift                 # MODIFIED: JobStore.init() accept optional CandidateScriptScanner.Configuration
    │   └── PreferencesStore.swift         # NEW: @MainActor ObservableObject with @Published + UserDefaults
    └── Views/
        ├── ContentView.swift              # MODIFIED: @State → @ObservedObject preferences; pass to Sidebar/JobStore
        ├── SidebarView.swift              # UNCHANGED: already takes @Binding for groupingMode + collapseState
        └── SettingsView.swift             # NEW: SwiftUI Form with Picker/Toggle/Slider bound to PreferencesStore
```

### Pattern 1: PreferencesStore (Follows JobStore Pattern)
**What:** `@MainActor final class: ObservableObject` with `@Published` properties and `didSet` UserDefaults writes
**When to use:** For all persisted user preferences; keeps single source of truth
**Example:**
```swift
// Source: CONTEXT.md D-02 + JobStore.swift pattern [VERIFIED: codebase analysis]
import Combine
import Foundation
import AutomationHealthCore

@MainActor
final class PreferencesStore: ObservableObject {
    @Published var groupingMode: SidebarGroupingMode {
        didSet {
            UserDefaults.standard.set(groupingMode.rawValue, forKey: "sidebarGroupingMode")
        }
    }

    @Published var collapseState: SidebarCollapseState {
        didSet {
            if let data = try? JSONEncoder().encode(collapseState) {
                UserDefaults.standard.set(data, forKey: "sidebarCollapseState")
            }
        }
    }

    @Published var scanOnLaunch: Bool {
        didSet { UserDefaults.standard.set(scanOnLaunch, forKey: "scanOnLaunch") }
    }

    @Published var scanMaxDepth: Int {
        didSet { UserDefaults.standard.set(scanMaxDepth, forKey: "scanMaxDepth") }
    }

    @Published var scanMaxResults: Int {
        didSet { UserDefaults.standard.set(scanMaxResults, forKey: "scanMaxResults") }
    }

    init(userDefaults: UserDefaults = .standard) {
        userDefaults.register(defaults: [
            "sidebarGroupingMode": SidebarGroupingMode.defaultMode.rawValue,
            "scanOnLaunch": true,
            "scanMaxDepth": 2,
            "scanMaxResults": 200
        ])

        groupingMode = SidebarGroupingMode(
            rawValue: userDefaults.string(forKey: "sidebarGroupingMode") ?? ""
        ) ?? .defaultMode

        if let collapseData = userDefaults.data(forKey: "sidebarCollapseState"),
           let decoded = try? JSONDecoder().decode(SidebarCollapseState.self, from: collapseData) {
            collapseState = decoded
        } else {
            collapseState = SidebarCollapseState()
        }

        scanOnLaunch = userDefaults.bool(forKey: "scanOnLaunch")
        scanMaxDepth = userDefaults.integer(forKey: "scanMaxDepth")
        scanMaxResults = userDefaults.integer(forKey: "scanMaxResults")
    }
}
```

### Pattern 2: Codable Conformance for SidebarSectionID + SidebarCollapseState
**What:** Add `Codable` to `SidebarSectionID` and `SidebarCollapseState` for JSON persistence
**When to use:** Required for PREFS-02 — collapse state must survive app quit
**Example:**
```swift
// Source: CONTEXT.md agent's discretion [ASSUMED: standard Codable pattern]
// In AutomationHealthCore/JobPresentation.swift:

// SidebarSectionID needs Codable added to its conformance list:
public struct SidebarSectionID: Hashable, Sendable, Codable {
    // ... existing properties and init unchanged
}

// SidebarCollapseState needs Codable added:
public struct SidebarCollapseState: Hashable, Sendable, Codable {
    // collapsedSectionIDs stored as Set<SidebarSectionID>
    // JSONEncoder automatically encodes Set as array
    // ... existing properties and methods unchanged
}
```

**Note:** `SidebarGroupingMode` is `RawRepresentable` as `String` and `CaseIterable` — `Codable` synthesis requires the enum to be `Codable`. Since `SidebarGroupingMode` already conforms to `String`-raw-representable and `CaseIterable`, adding `Codable` to the enum conformance list enables automatic synthesis. [ASSUMED: Swift Codable synthesis for String-backed enums]

### Pattern 3: Settings Scene Integration
**What:** Add `Settings { SettingsView(preferences: preferences) }` as sibling to `WindowGroup`
**When to use:** PREFS-05 — expose scan configuration and grouping mode defaults
**Example:**
```swift
// Source: research/STACK.md + UI-SPEC.md [VERIFIED: Apple SwiftUI docs via research]
// In AutomationHealthApp.swift:
@main
struct AutomationHealthApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = JobStore()
    @StateObject private var preferences = PreferencesStore()   // NEW

    var body: some Scene {
        WindowGroup("Automation Health", id: "main") {
            ContentView(store: store, preferences: preferences)  // MODIFIED: pass preferences
                .frame(minWidth: 980, minHeight: 620)
                .task { store.refresh() }
        }
        .commands {
            CommandMenu("Automations") {
                Button("Rescan Automations") { store.refresh() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }

        Settings {                                              // NEW
            SettingsView(preferences: preferences)
        }
    }
}
```

### Pattern 4: Scan Config → CandidateScriptScanner Wiring
**What:** `JobInventory.live()` accepts optional `CandidateScriptScanner.Configuration` parameter; `JobStore` passes it through
**When to use:** PREFS-03 — scan config must reach `CandidateScriptScanner` at construction time
**Example:**
```swift
// Source: CONTEXT.md D-04 + JobScanning.swift [VERIFIED: codebase analysis]
// In JobScanning.swift, add optional Configuration parameter:
public static func live(
    homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
    manualRecordStore: ManualRecordStore? = nil,
    candidateConfiguration: CandidateScriptScanner.Configuration? = nil   // NEW
) -> JobInventory {
    let manualRecordStore = manualRecordStore ?? ManualRecordStore.live(homeDirectory: homeDirectory)
    let config = candidateConfiguration ?? .default

    return JobInventory(
        scanners: [
            LaunchAgentScanner(homeDirectory: homeDirectory),
            HermesCronScanner(homeDirectory: homeDirectory),
            CronScanner(),
            ShortcutsScanner(),
            AutomatorScanner(homeDirectory: homeDirectory),
            CandidateScriptScanner(homeDirectory: homeDirectory, configuration: config),  // MODIFIED
            ManualRecordScanner(store: manualRecordStore)
        ],
        homeDirectory: homeDirectory
    )
}
```

### Anti-Patterns to Avoid
- **Merging preferences into JobStore:** JobStore handles scan state, selection, manual record CRUD. Adding grouping/collapse/scan-config state violates single responsibility. CONTEXT.md D-01 explicitly forbids this.
- **@AppStorage in views while also using UserDefaults in store:** Creates duplicate keys, conflicting defaults, and two sources of truth. Views should bind to `PreferencesStore.@Published` properties only.
- **Writing to UserDefaults in `init()` before calling `register(defaults:)`:** Must call `register(defaults:)` first so that fallback values are defined before reads. [ASSUMED: standard Apple UserDefaults pattern]
- **Using `@SceneStorage` for app-wide preferences:** `@SceneStorage` is per-window/per-scene and won't survive window close/reopen. Grouping mode and collapse state must be app-wide via `UserDefaults`.
- **Modifying `SidebarView` to read UserDefaults directly:** `SidebarView` already accepts `@Binding` — no changes needed. Views should not depend on Foundation's UserDefaults directly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Preferences serialization | Custom file-based config reader/writer | `UserDefaults` + `@AppStorage` | Built-in, synchronous, sandbox-compatible, no file handling, automatic app-group containment |
| Collapse state serialization | Custom binary format or plist XML | `JSONEncoder`/`JSONDecoder` to `Data` | `Set<SidebarSectionID>` maps naturally to JSON array; `Codable` synthesis handles all encoding/decoding logic |
| Settings window | Custom `Window` or `NSWindow` subclass | SwiftUI `Settings` scene | Automatically registers Cmd+, shortcut; inherits native macOS Settings window behavior; no manual menu wiring |
| Preferences migration | Custom migration logic | `UserDefaults.register(defaults:)` + fallback on read failure | First-launch defaults are registered before reads; decode failures fall back to empty/default state — no migration needed for v1.2 |
| LICENSE file creation | Custom license text | Standard MIT license template | Already exists at repo root; only copyright line needs update |

**Key insight:** All needed infrastructure is built into macOS 14+ / SwiftUI / Foundation. No third-party packages are needed, which aligns with the project constraint of avoiding external Swift dependencies.

## Runtime State Inventory

> Phase 10 is a greenfield preferences persistence phase — no runtime state migration is needed. The app currently stores no preferences. On first launch with the new code, `UserDefaults.register(defaults:)` seeds the v1.1 documented defaults.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — app has no preference storage today. `UserDefaults` keys `"sidebarGroupingMode"`, `"sidebarCollapseState"`, `"scanOnLaunch"`, `"scanMaxDepth"`, `"scanMaxResults"` are all new. | No migration. `register(defaults:)` seeds defaults on first launch. |
| Live service config | None — preferences are local UserDefaults only. No external services configured. | None. |
| OS-registered state | None — no OS-level registrations (Task Scheduler, pm2, launchd plists) reference preference keys. | None. |
| Secrets/env vars | None — no secrets or env vars reference preference keys. | None. |
| Build artifacts | None — no stale artifacts reference old preference storage (none existed). | None — verified by absence of any `UserDefaults` writes in the pre-Phase 10 codebase. |

## Common Pitfalls

### Pitfall 1: UserDefaults Did-Change Timing on First Launch
**What goes wrong:** `UserDefaults.register(defaults:)` sets default values but does not trigger `didSet` on `@Published` properties if the initial read already matches. The first write only happens on explicit user change.
**Why it happens:** `register(defaults:)` sets fallback values; initial property reads return those fallbacks. `didSet` only fires on subsequent assignments.
**How to avoid:** In `PreferencesStore.init()`, directly read UserDefaults values *after* `register(defaults:)` and assign to properties in the init body (not as property initializers). This ensures properties reflect persisted or default values correctly.
**Warning signs:** Settings scene shows empty/default values that don't match `register(defaults:)` — means properties were assigned before `register(defaults:)` completed.

### Pitfall 2: `SidebarCollapseState` Codable Conformance with `Set`
**What goes wrong:** `JSONEncoder` encodes `Set<SidebarSectionID>` as JSON array. `JSONDecoder` decodes it back as array but needs to reconstruct the Set. If `SidebarSectionID` Codable synthesis fails (e.g., because `SidebarGroupingMode` lacks explicit `Codable` conformance), the entire collapse state silently falls back to empty.
**Why it happens:** `SidebarGroupingMode` is `RawRepresentable` as `String` but does not explicitly conform to `Codable`. Swift can synthesize `Codable` for `String`-backed enums, but only if the enum explicitly declares conformance.
**How to avoid:** Add `Codable` to `SidebarGroupingMode` enum conformance list (`public enum SidebarGroupingMode: String, CaseIterable, Identifiable, Sendable, Codable`). Verify round-trip with unit test: encode → decode → compare.
**Warning signs:** Collapse state resets to all-expanded on every launch — decode failed silently.

### Pitfall 3: `Int` Sliders with `@Published` `Int` Properties
**What goes wrong:** SwiftUI `Slider` expects a `Binding<Double>` (or `Binding<Float>` on newer OS), not `Binding<Int>`. Direct binding of `$preferences.scanMaxDepth` (an `Int`) will not compile.
**Why it happens:** `Slider` value parameter is typed as `Double`; `Int` bindings require explicit conversion.
**How to avoid:** Create a computed `Binding<Double>` in `SettingsView` that wraps the `Int` preference:
```swift
private var maxDepthBinding: Binding<Double> {
    Binding(
        get: { Double(preferences.scanMaxDepth) },
        set: { preferences.scanMaxDepth = Int($0) }
    )
}
```
Alternative: Use a `Stepper` instead of `Slider` for integer-stepped values (cleaner for `Int`). The UI-SPEC specifies `Slider` with step `1` (for depth) and step `10` (for results) — use the `Double` binding wrapper pattern.
**Warning signs:** Compiler error: "Cannot convert value of type 'Binding<Int>' to expected argument type 'Binding<Double>'".

### Pitfall 4: `scanOnLaunch` Boolean Semantics
**What goes wrong:** `UserDefaults.bool(forKey:)` returns `false` for both "key doesn't exist" and "key exists and is `false`". On first launch, `register(defaults:)` sets it to `true`, but if the key is somehow absent without registration, it reads as `false` (meaning "don't scan on launch").
**Why it happens:** `UserDefaults.bool(forKey:)` default is `false` when key is absent.
**How to avoid:** Always call `register(defaults:)` before reading `bool(forKey:)`. This ensures the first-launch default of `true` is honored. The `PreferencesStore.init()` pattern above does this correctly.
**Warning signs:** Candidate scripts don't appear after first launch — `scanOnLaunch` is `false` unexpectedly.

## Code Examples

Verified patterns from official sources:

### PreferencesStore Initialization with register(defaults:)
```swift
// Source: Apple UserDefaults documentation + CONTEXT.md D-02 [ASSUMED: standard pattern, verified by Apple docs]
init(userDefaults: UserDefaults = .standard) {
    // 1. Register fallback defaults FIRST
    userDefaults.register(defaults: [
        "sidebarGroupingMode": SidebarGroupingMode.defaultMode.rawValue,
        "scanOnLaunch": true,
        "scanMaxDepth": 2,
        "scanMaxResults": 200
    ])

    // 2. Read existing values (will use registered defaults if keys absent)
    groupingMode = SidebarGroupingMode(
        rawValue: userDefaults.string(forKey: "sidebarGroupingMode") ?? ""
    ) ?? .defaultMode

    if let collapseData = userDefaults.data(forKey: "sidebarCollapseState"),
       let decoded = try? JSONDecoder().decode(SidebarCollapseState.self, from: collapseData) {
        collapseState = decoded
    } else {
        collapseState = SidebarCollapseState()
    }

    scanOnLaunch = userDefaults.bool(forKey: "scanOnLaunch")
    scanMaxDepth = userDefaults.integer(forKey: "scanMaxDepth")
    scanMaxResults = userDefaults.integer(forKey: "scanMaxResults")
}
```

### SettingsView with Int-to-Double Binding Wrapper
```swift
// Source: Apple SwiftUI Slider documentation + UI-SPEC layout contract [ASSUMED: standard SwiftUI pattern]
struct SettingsView: View {
    @ObservedObject var preferences: PreferencesStore

    private var maxDepthBinding: Binding<Double> {
        Binding(
            get: { Double(preferences.scanMaxDepth) },
            set: { preferences.scanMaxDepth = Int($0) }
        )
    }

    private var maxResultsBinding: Binding<Double> {
        Binding(
            get: { Double(preferences.scanMaxResults) },
            set: { preferences.scanMaxResults = Int($0) }
        )
    }

    var body: some View {
        Form {
            Section("Default View") {
                Picker("Default Grouping", selection: $preferences.groupingMode) {
                    ForEach(SidebarGroupingMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
            }

            Section("Candidate Scanning") {
                Toggle("Scan for candidate scripts on launch", isOn: $preferences.scanOnLaunch)
                Text("When enabled, Automation Health searches supported script directories for automations that may not be registered in a known scheduler.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: maxDepthBinding, in: 0...5, step: 1) {
                    Text("Maximum Scan Depth")
                }
                Text("Limits how many subdirectory levels the candidate scanner traverses. Depth 0 scans only the top-level script directories.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: maxResultsBinding, in: 10...500, step: 10) {
                    Text("Maximum Results Per Scan")
                }
                Text("Limits the total number of candidate records produced by a single scan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
    }
}
```

### ContentView Migration from @State to @ObservedObject
```swift
// Source: CONTEXT.md integration points + codebase analysis [VERIFIED: codebase analysis]
// BEFORE (current code):
// @State private var sidebarGroupingMode: SidebarGroupingMode = .defaultMode
// @State private var sidebarCollapseState = SidebarCollapseState()

// AFTER:
struct ContentView: View {
    @ObservedObject var store: JobStore
    @ObservedObject var preferences: PreferencesStore     // NEW: replaces both @State vars
    @State private var searchText = ""
    @State private var manualRecordSheet: ManualRecordSheetState?

    private var sidebarSections: [SidebarJobSection] {
        SidebarJobSection.sections(
            for: filteredJobs,
            groupingMode: preferences.groupingMode,         // CHANGED: was sidebarGroupingMode
            collapseState: preferences.collapseState,       // CHANGED: was sidebarCollapseState
            hasSearchQuery: hasSearchQuery
        )
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                sections: sidebarSections,
                showsFilteredEmptyState: showsFilteredEmptyState,
                groupingMode: $preferences.groupingMode,    // CHANGED: $binding source
                collapseState: $preferences.collapseState,  // CHANGED: $binding source
                hasSearchQuery: hasSearchQuery,
                selectedJobID: $store.selectedJobID,
                lastScannedDescription: store.lastScannedDescription,
                scanNotes: store.scanNotes,
                isScanning: store.isScanning
            )
            // ... rest unchanged
        }
        // ... rest unchanged
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No preferences persistence — grouping mode and collapse state lost on app quit | `PreferencesStore` with `UserDefaults` persistence | Phase 10 (now) | User preferences survive app relaunch |
| `@State` in ContentView for grouping/collapse state | `@ObservedObject preferences` from `PreferencesStore` | Phase 10 (now) | State is shared across views and Settings scene |
| `SidebarCollapseState` not Codable | `Codable` conformance with JSON round-trip to `Data` | Phase 10 (now) | Collapse state persists to UserDefaults |
| `CandidateScriptScanner` always uses `.default` Configuration | Accepts Configuration from `PreferencesStore` values at construction | Phase 10 (now) | User-configurable scan depth and result cap |

**Deprecated/outdated:**
- `@State private var sidebarGroupingMode` in `ContentView` (line 8) — replaced by `@ObservedObject preferences.groupingMode`
- `@State private var sidebarCollapseState` in `ContentView` (line 9) — replaced by `@ObservedObject preferences.collapseState`
- `CandidateScriptScanner.Configuration.default` used unconditionally in `JobInventory.live()` — replaced by config derived from `PreferencesStore`
- Copyright line "Automation Health contributors" — replaced by "Copyright (c) 2026 Niko" per D-06

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `UserDefaults.register(defaults:)` followed by direct reads in `init()` correctly seeds first-launch defaults | Code Examples | LOW — standard Apple pattern documented in UserDefaults docs; fallback: inline defaults in each read path |
| A2 | `Codable` synthesis works for `SidebarGroupingMode` when `Codable` is added to its conformance list (it's already `String`-raw-representable with `CaseIterable`) | Common Pitfalls | LOW — Swift synthesizes Codable for enums that are RawRepresentable as String/Int; testable via compile check |
| A3 | `JSONEncoder().encode(Set<SidebarSectionID>)` produces a JSON array, and `JSONDecoder().decode(Set<SidebarSectionID>.self, from:)` reconstructs the Set correctly | Code Examples | LOW — standard Swift behavior for Codable Set; testable via round-trip unit test |
| A4 | `Slider` with `Binding<Double>` wrapping `Int` property works correctly — `Int($0)` truncation does not cause off-by-one at boundaries | Code Examples | MEDIUM — at step boundaries (e.g., step 10), rounding errors could cause the slider to snap incorrectly; verify in testing |
| A5 | No existing `UserDefaults` keys conflict with the proposed key names (`"sidebarGroupingMode"`, etc.) | Standard Stack | LOW — app currently writes nothing to UserDefaults; verified by codebase search for `UserDefaults.standard.set` and `@AppStorage` |
| A6 | `PreferencesStore` does not need `Sendable` conformance because it's `@MainActor`-isolated and never passed across actor boundaries | Architecture Patterns | LOW — `@MainActor` classes are implicitly `@MainActor`-isolated; same pattern as `JobStore` (148 lines, no `Sendable` conformance) |

## Open Questions

1. **Slider step behavior at boundaries**
   - What we know: SwiftUI `Slider` with `step: 10` and `in: 10...500` snaps to multiples of 10. The `Int(Double)` conversion truncates.
   - What's unclear: Whether `Double(Int($0))` round-trips cleanly — e.g., slider value 199.7 → `Int` = 199 → `Double` = 199.0 → slider would snap to 200 (next step). This might cause visual snapping but should be correct functionally.
   - Recommendation: Test with boundary values (0, 10, 500) to verify stable behavior. If snapping is jarring, use `Stepper` instead of `Slider` for integer values.

2. **LICENSE file — whether to regenerate or edit in place**
   - What we know: `LICENSE` exists at repo root with MIT text and "Copyright (c) 2026 Automation Health contributors". D-06 says copyright line should be "Copyright (c) 2026 Niko".
   - What's unclear: Whether to replace the entire file (in case the template differs from standard MIT) or just edit the copyright line.
   - Recommendation: Edit the copyright line in place — the existing text is standard MIT template. Only line 3 needs changing.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift toolchain | Build & compile | ✓ | Apple Swift 6.3 (swiftlang-6.3.0.123.5) | — |
| macOS 14+ SDK | SwiftUI Settings, @AppStorage, UserDefaults | ✓ | macOS 26.0 (Sequoia) — well above minimum | — |
| Command Line Tools | `swift build` | ✓ | Installed (no Xcode.app, CLT only) | — |

**Missing dependencies with no fallback:** None — all required technologies are built into the Swift toolchain and macOS SDK.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `ActiveJobsCoreSelfTest` (SwiftPM executable target) + `swift build` compile gate |
| Config file | None — custom self-test runner in `Sources/ActiveJobsCoreSelfTest/main.swift` |
| Quick run command | `swift run ActiveJobsCoreSelfTest` |
| Full suite command | `./script/ci.sh` (runs `swift build` + `swift run ActiveJobsCoreSelfTest`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PREFS-01 | Grouping mode survives app relaunch (UserDefaults read/write) | Smoke / self-test | ~~Cannot test in self-test (requires app lifecycle)~~ → Verified by compile check + manual smoke | ❌ Wave 0 (manual validation recommended) |
| PREFS-02 | Collapse state survives app relaunch (JSON encode/decode round-trip) | Self-test | `swift run ActiveJobsCoreSelfTest` (add `testCollapseStateCodableRoundTrip`) | ❌ Wave 0 |
| PREFS-03 | Scan config persists via UserDefaults | Self-test | `swift run ActiveJobsCoreSelfTest` (add `testScanConfigDefaults`) | ❌ Wave 0 |
| PREFS-04 | Default values used when no preferences exist | Self-test | `swift run ActiveJobsCoreSelfTest` (add `testPreferencesStoreDefaults`) | ❌ Wave 0 |
| PREFS-05 | Settings scene compiles and integrates | Compile gate | `swift build` | ❌ Wave 0 |
| DIST-01 | LICENSE file present with correct copyright | File existence check | `grep "Copyright (c) 2026 Niko" LICENSE` | ❌ Wave 0 (one-liner) |

### Sampling Rate
- **Per task commit:** `swift build` (compile check — catches all binding/type errors)
- **Per wave merge:** `./script/ci.sh` (full build + self-test suite)
- **Phase gate:** `./script/ci.sh` green + manual smoke verification of persisted preferences

### Wave 0 Gaps
- [ ] `Sources/ActiveJobsCoreSelfTest/main.swift` — add `testCollapseStateCodableRoundTrip()` (verify JSON encode/decode for `SidebarCollapseState`)
- [ ] `Sources/ActiveJobsCoreSelfTest/main.swift` — add `testPreferencesStoreDefaults()` (verify `register(defaults:)` seeds correct values)
- [ ] `Sources/ActiveJobsCoreSelfTest/main.swift` — add `testScanConfigFromPreferences()` (verify Configuration derivation from PreferencesStore values)
- [ ] `SettingsView.swift` — not testable in self-test (SwiftUI view); compile check + manual smoke covers PREFS-05

## Security Domain

> `security_enforcement` is not explicitly set to `false` in `.planning/config.json`. Including security domain per default behavior.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No user authentication — single-user local app |
| V3 Session Management | No | No sessions — app runs locally |
| V4 Access Control | No | No multi-user isolation needed |
| V5 Input Validation | Yes (minimal) | `Sliders` have bounded ranges (0-5, 10-500); `Picker` limited to enum cases; `Toggle` is boolean. No free-form text input in Settings scene. No validation beyond native control constraints needed. |
| V6 Cryptography | No | No cryptographic operations in preferences persistence |

### Known Threat Patterns for macOS SwiftUI / UserDefaults

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| UserDefaults tampering via `defaults write` | Tampering | UserDefaults is not a security boundary — sandboxing prevents other apps from writing. Preference values are validated at read time (enum rawValue → init, JSON decode with fallback to default) |
| JSON injection via malformed UserDefaults data | Tampering | `try? JSONDecoder().decode()` with fallback to empty `SidebarCollapseState` — malformed data is silently reset to defaults |
| Integer overflow in scan config values | Tampering | `Slider` bounds prevent out-of-range input; `Int`-typed properties have implicit bounds from slider ranges |

## Sources

### Primary (HIGH confidence)
- Direct file reads of all source files in `Sources/AutomationHealth/`, `Sources/AutomationHealthCore/`, `Sources/ActiveJobsCore/Services/` — verified current codebase state [VERIFIED: codebase analysis]
- `.planning/CONTEXT.md` (Phase 10) — locked decisions D-01 through D-06 [VERIFIED: user decisions from discuss-phase]
- `.planning/research/STACK.md` — preferences technology stack, Settings scene pattern, @AppStorage vs UserDefaults guidance [VERIFIED: prior research, HIGH confidence]
- `.planning/research/ARCHITECTURE.md` — integration points, anti-patterns, build order, data flow diagrams [VERIFIED: prior research, HIGH confidence]
- `.planning/phases/10-preferences-persistence/10-UI-SPEC.md` — Settings view layout contract, copywriting, interaction behavior [VERIFIED: approved UI-SPEC]
- `.planning/REQUIREMENTS.md` — PREFS-01 through PREFS-05, DIST-01 traceability [VERIFIED: requirements document]
- `Package.swift` — target declarations, platform constraint (macOS .v14) [VERIFIED: project configuration]

### Secondary (MEDIUM confidence)
- `.planning/codebase/CONVENTIONS.md` — naming patterns, code style, import organization [VERIFIED: codebase analysis]
- `.planning/codebase/ARCHITECTURE.md` — component responsibilities [VERIFIED: codebase analysis]

### Tertiary (LOW confidence)
- None — all research is based on direct codebase analysis and existing verified planning artifacts.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all technologies are built-in macOS/SwiftUI/Foundation APIs; verified against `Package.swift` platform constraint; no external dependencies
- Architecture: HIGH — integration points verified against actual source code; CONTEXT.md provides locked decisions; existing patterns (JobStore, @Binding) are clear extension points
- Pitfalls: MEDIUM — Slider/Int binding wrapping is an assumed pattern (not directly verified with Apple docs); Codable synthesis for SidebarGroupingMode is assumed but easily testable

**Research date:** 2026-05-10
**Valid until:** 2026-05-24 (30 days — this is a stable domain; Apple SDK APIs for UserDefaults, @AppStorage, and Settings scene have been stable since macOS 13/14)

## RESEARCH COMPLETE
