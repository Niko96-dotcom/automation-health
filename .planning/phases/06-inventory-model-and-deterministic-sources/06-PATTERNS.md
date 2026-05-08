# Phase 6: Inventory Model And Deterministic Sources - Pattern Map

**Mapped:** 2026-05-08
**Inputs:** `06-RESEARCH.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`

## Summary

Phase 6 should extend the existing adapter pattern:

`ActiveJobsCore scanner IO -> ScheduledJob/JobScanResult -> JobInventory -> JobStore -> JobPresentation -> SwiftUI views`

New source support should live under `Sources/ActiveJobsCore/Services`. SwiftUI views should receive already-normalized presentation values and must not read cron, Shortcuts, Automator, plist, SQLite, or filesystem source data directly.

## Planned Files And Closest Analogs

| Planned File | Role | Closest Existing Analog | Reuse Pattern |
|--------------|------|-------------------------|---------------|
| `Sources/ActiveJobsCore/Models/ScheduledJob.swift` | Core source-neutral model and enums | Existing `JobSource` and `ScheduledJob` definitions | Add small immutable `Sendable` value types/enums with public initializers and defaults. |
| `Sources/ActiveJobsCore/Services/JobScanning.swift` | Scanner protocol and inventory aggregation | Existing `JobScanning` and `JobInventory.refresh()` | Keep scanner composition in one place, dedupe by `source:id`, sort by next run/name, and avoid view-layer dependencies. |
| `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` | Existing scanner upgraded for confidence/origin/result notes | Current `LaunchAgentScanner.parsePlist` | Keep plist parsing private, return normalized model values, and treat optional enrichment as best effort. |
| `Sources/ActiveJobsCore/Services/HermesCronScanner.swift` | Existing scanner upgraded for confidence/origin/result notes | Current `HermesCronScanner.scan()` and `latestOutput(for:)` | Keep metadata parsing and output lookup private, filter disabled/paused jobs, and return synthetic-safe values. |
| `Sources/ActiveJobsCore/Services/CronScanner.swift` | New deterministic cron scanner | `HermesCronScanner` for metadata parsing, `LaunchctlStatusReader` for process wrapper style | Inject command runner and file paths, parse text into `ScheduledJob`, report non-fatal limitations as notes. |
| `Sources/ActiveJobsCore/Services/ShortcutsScanner.swift` | New registered Shortcuts scanner | `LaunchctlStatusReader.runLaunchctl` and `HermesCronScanner` private decode helpers | Wrap `/usr/bin/shortcuts list --show-identifiers` behind a runner; never call run/view/sign. |
| `Sources/ActiveJobsCore/Services/AutomatorScanner.swift` | New bounded workflow-file scanner | `LaunchAgentScanner.scanDirectory(_:)` | Enumerate injected directories, filter extensions, read optional Info.plist, and return empty/notes for missing or unreadable paths. |
| `Sources/AutomationHealth/Stores/JobStore.swift` | Main-actor bridge from inventory results to UI state | Current `refresh()` detached task | Keep scanner work off the main actor, publish presentation data and scan notes only after result is available. |
| `Sources/AutomationHealth/Models/JobPresentation.swift` | UI-ready confidence/origin/note display text | Existing `JobPresentation` and `SidebarJobSummary` | Derive display strings once in presentation helpers, include new fields in search text. |
| `Sources/AutomationHealth/Views/SidebarView.swift` | Optional scan-note count in existing footer | Current last-scan footer | Keep UI minimal and driven by store data; no source-specific branches or filesystem reads. |
| `Sources/ActiveJobsCoreSelfTest/main.swift` | Fixture-driven coverage | Existing `TemporaryFixture`, `StaticJobScanner`, `expect` helpers | Add focused functions and synthetic runners/fixtures; do not use live local machine state. |
| `docs/scheduled-job-sources.md` | Public source notes | Current launchd/Hermes sections and Phase 4 doc language | Explain reads, limits, evidence strength, and scan-note meanings for cron, Shortcuts, and Automator. |
| `docs/scanner-extension-guide.md` | Contributor adapter recipe updates if needed | Current guide from Phase 4 | Mention `JobScanResult`, confidence/origin fields, and scan notes in the scanner contract. |

## Concrete Code Patterns

### Model Shape

Existing pattern in `ScheduledJob.swift`:

```swift
public enum JobSource: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case launchd
    case hermesCron
}

public struct ScheduledJob: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let source: JobSource
}
```

Phase 6 should mirror this style for:

- `JobConfidence`
- `JobOrigin`
- `ScanNoteSeverity`
- `ScanNote`
- `JobScanResult`

Use explicit public initializers where downstream targets need construction. Prefer default parameters on `ScheduledJob.init` for new fields so existing fixture call sites can be migrated gradually in one plan.

### Scanner Protocol And Inventory Result

Current inventory aggregation:

```swift
let jobs = try scanners.flatMap { try $0.scan() }
var seen = Set<String>()
let uniqueJobs = jobs.filter { job in
    let inserted = seen.insert("\(job.source.rawValue):\(job.id)").inserted
    return inserted
}
```

Phase 6 should preserve the dedupe/sort logic but aggregate result notes:

```swift
let results = try scanners.map { try $0.scan() }
let jobs = results.flatMap(\.jobs)
let notes = results.flatMap(\.notes)
return JobScanResult(jobs: sortedUniqueJobs, notes: notes)
```

### Process Wrapper Style

Current `LaunchctlStatusReader` pattern:

```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
process.arguments = arguments
```

New command-backed scanners should follow the same private wrapper style, but expose an injected protocol or closure for tests. Production cron must only call `/usr/bin/crontab` with `["-l"]`. Production Shortcuts must only call `/usr/bin/shortcuts` with `["list", "--show-identifiers"]`.

### File Enumeration Style

Current `LaunchAgentScanner.scanDirectory(_:)` pattern:

```swift
guard fileManager.fileExists(atPath: directory.path) else {
    return []
}

let files = try fileManager.contentsOfDirectory(
    at: directory,
    includingPropertiesForKeys: nil,
    options: [.skipsHiddenFiles]
)
```

Automator should reuse this style with injected directories and bounded `maxDepth`/direct child scanning. Missing directories should not fail the full scan.

### Store Refresh Style

Current `JobStore.refresh()` runs scanner work in a detached task and then updates `@Published` state on the main actor. Keep that structure:

```swift
Task {
    let result = await Task.detached(priority: .userInitiated) {
        Result { try inventory.refresh() }
    }.value
}
```

Convert `JobScanResult.jobs` into `[JobPresentation]` after the scan, and publish `scanNotes` beside `jobs`.

## Testing Patterns

Use the existing self-test style:

```swift
try testParsesEnabledHermesCronJobsWithLatestOutput()
try testAggregatesAndSortsJobsByNextRunThenName()

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError("Expectation failed: \(message)")
    }
}
```

Recommended new tests:

- `testInventoryAggregatesJobsAndScanNotes()`
- `testExistingScannersPopulateScheduledConfidenceAndOrigins()`
- `testParsesUserCrontabEntriesWithInjectedRunner()`
- `testParsesSystemCrontabEntriesFromFixtureFile()`
- `testCronScannerReportsNoCrontabAsScanNote()`
- `testShortcutsScannerListsRegisteredShortcutsWithoutSchedulingEvidence()`
- `testShortcutsScannerReportsMissingCommandAsScanNote()`
- `testAutomatorScannerListsWorkflowFixturesAsRegistered()`
- `testAutomatorScannerReportsMissingWorkflowDirectoriesAsNotes()`
- `testJobSourceOrderMatchesExpandedSidebarGroupingContract()`

## File Ownership And Sequencing

Plan 06-01 owns the shared model/protocol changes. Plans 06-02 and 06-03 depend on those fields and should not rework the base contract.

Plan 06-02 owns cron source additions and should update `JobSource.allCases` before Plan 06-03 adds Shortcuts and Automator. Plan 06-03 therefore runs after Plan 06-02 even though both ultimately depend on the model foundation.

## Guardrails

- Do not add third-party Swift packages.
- Do not create an XCTest target in this phase.
- Do not read Shortcuts SQLite databases directly.
- Do not execute cron, Shortcuts, or Automator jobs.
- Do not write scheduler files or app workflow bundles.
- Do not move scanner IO into SwiftUI views.
- Do not label Shortcuts or Automator records as Scheduled unless a scanner has direct scheduling evidence.
