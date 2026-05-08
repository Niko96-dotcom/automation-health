# Phase 07 - Pattern Map

**Phase:** 07 - Candidate Discovery And Manual Records
**Mapped:** 2026-05-08
**Inputs:** `07-CONTEXT.md`, `07-RESEARCH.md`, `07-UI-SPEC.md`, current source tree

## Implementation Targets

| Target File | Role | Closest Existing Analog | Pattern To Reuse |
|-------------|------|-------------------------|------------------|
| `Sources/ActiveJobsCore/Models/ScheduledJob.swift` | Add `candidateScripts` and `manualRecords` sources | Existing `JobSource.cron`, `JobSource.shortcuts`, `JobSource.automator` | Add enum cases in display/grouping order, then extend `displayName` with human-facing source titles. |
| `Sources/ActiveJobsCore/Services/CandidateScriptScanner.swift` | Bounded script-candidate discovery | `AutomatorScanner.swift` plus `CronScanner.swift` | Inject roots/file manager, return `JobScanResult`, add `ScanNote` for missing/unreadable/skipped inputs, never mutate or execute discovered files. |
| `Sources/ActiveJobsCore/Services/ManualRecordStore.swift` | App-owned manual JSON persistence | `HermesCronScanner.swift` JSON decoding shape plus `TextSnippetReader.swift` bounded IO discipline | Keep JSON model Codable and testable with injected file URL; create parent directory as needed; use atomic writes; convert records to `ScheduledJob`. |
| `Sources/ActiveJobsCore/Services/JobScanning.swift` | Compose candidate/manual sources | Existing `JobInventory.live(homeDirectory:)` scanner list | Add scanners at the end of the deterministic source list and preserve `JobScanResult` aggregation/dedupe/sort behavior. |
| `Sources/AutomationHealth/Stores/JobStore.swift` | Manual create/edit/remove facade and selection policy | Existing `refresh()` selection preservation | Keep IO behind store methods, refresh after app-owned writes, select created/edited manual records, and choose a nearby visible row after removal. |
| `Sources/AutomationHealth/Models/JobPresentation.swift` | Search/sidebar/detail display fields | Existing `confidenceName`, `originName`, `searchText`, `SidebarJobSummary` | Extend search and subtitle copy with confidence/origin/candidate paths/manual notes without source-specific file IO. |
| `Sources/AutomationHealth/Views/ContentView.swift` | Toolbar and manual sheet entry | Existing primary action toolbar group | Add `Add Manual Record` with `plus`, rename rescan copy to inventory language, and pass store actions into detail/sheet views. |
| `Sources/AutomationHealth/Views/SidebarView.swift` | Source-sectioned rows and empty states | Current `SidebarJobSection.sections(for:)` and Up/Down navigation | Keep source sections; change secondary line to `{confidenceName} - {schedule or next run}`; retain visible-row keyboard navigation. |
| `Sources/AutomationHealth/Views/DetailView.swift` | Confidence/origin cards, source icons, manual actions | Existing `StatusOverview`, `TechnicalDetails`, `TextSection`, AppKit reveal | Add source icon mapping, Confidence/Origin cards, Candidate/Manual fallback text, reveal-script label, and manual-only edit/remove actions. |
| `Sources/ActiveJobsCoreSelfTest/main.swift` | Fixture-driven core coverage | Existing cron/Shortcuts/Automator scanner fixtures | Add candidate scanner and manual store fixtures with synthetic paths, injected roots, and no live machine state. |
| `docs/scheduled-job-sources.md` and `README.md` | Public evidence/limits docs | Existing Cron, Shortcuts, Automator sections | Document exact read paths, bounds, confidence labels, manual app-owned storage, and read-only limitations. |

## Concrete Code Patterns

### Scanner Shape

Use the current scanner contract:

```swift
public struct SomeScanner: JobScanning, @unchecked Sendable {
    private let fileManager: FileManager

    public func scan() throws -> JobScanResult {
        var jobs: [ScheduledJob] = []
        var notes: [ScanNote] = []
        return JobScanResult(jobs: jobs, notes: notes)
    }
}
```

Candidate discovery should follow `AutomatorScanner`'s missing-directory note pattern, but with stricter traversal bounds from `07-CONTEXT.md`:

- default roots: `~/Scripts`, `~/bin`, `~/.local/bin`, `~/Library/Scripts`, `~/Documents/Scripts`
- max depth: `2`
- max visited files: `2_000`
- max results: `200`
- max candidate bytes: `1_000_000`
- skipped directory names: `.git`, `.build`, `build`, `dist`, `DerivedData`, `node_modules`, `vendor`, `.venv`, `venv`, `__pycache__`, `.swiftpm`

### ScheduledJob Conversion

Candidate records must use:

```swift
ScheduledJob(
    id: "candidate-\(slug(from: url.path))",
    name: candidateName,
    source: .candidateScripts,
    confidence: .candidate,
    origin: .userAuthored,
    schedule: "Script candidate (no schedule evidence)",
    command: url.path,
    state: "candidate",
    lastStatus: nil,
    lastRun: nil,
    nextRun: nil,
    definition: "Candidate script discovered at \(url.path).",
    lastRunDetails: nil,
    detailPath: url.path
)
```

Manual records must convert to:

```swift
ScheduledJob(
    id: "manual-\(record.id.uuidString)",
    name: record.name,
    source: .manualRecords,
    confidence: .manual,
    origin: record.origin,
    schedule: record.scheduleDescription ?? "Manual record (no schedule evidence)",
    command: record.command,
    state: "manual",
    lastStatus: nil,
    lastRun: nil,
    nextRun: nil,
    definition: record.notes.isEmpty ? "Manual app record: \(record.name)" : record.notes,
    lastRunDetails: nil,
    detailPath: nil
)
```

### Store Boundary

`JobStore` is the view-facing mutation facade. SwiftUI views should call methods such as `addManualRecord`, `updateManualRecord`, and `removeManualRecord`; they should not reference `ManualRecordStore`, `FileManager`, `Data(contentsOf:)`, `JSONEncoder`, or `JSONDecoder`.

The store should extend the existing refresh pattern rather than adding separate view-owned state machines:

- write through the app-owned manual store
- refresh the shared `JobInventory`
- select `manualRecords:manual-{uuid}` after create/edit when present
- after remove, select the next visible record from the pre-remove ordering, otherwise the first visible record

### Detail And Sidebar Presentation

Reuse source-independent presentation values:

- `job.sourceName`
- `job.confidenceName`
- `job.originName`
- `job.scheduleText`
- `job.nextRunText`
- `job.job.definition`
- `job.job.command`

Do not branch in views to read files. Source-specific view branching is acceptable only for display choices already present on `ScheduledJob`, such as source icon, reveal label, fallback copy, and manual-only actions.

## Validation Hooks

Required automated gates:

- `./script/test.sh`
- `./script/ci.sh`
- grep for no view IO:
  `! rg -n "Data\\(contentsOf:|FileManager\\.default|contentsOfDirectory|JSONEncoder|JSONDecoder|crontab|shortcuts list" Sources/AutomationHealth/Views`

Required fixture coverage:

- Candidate scanner includes script-like extensions and extensionless executable files only in `~/bin`/`~/.local/bin` roots.
- Candidate scanner skips hidden/build/dependency/cache directories and oversized files.
- Candidate scanner emits scan notes for missing/unreadable roots and cap/skip behavior.
- Manual store creates, reads, updates, deletes, and surfaces malformed JSON without deleting user records.
- Inventory composes candidate and manual records without breaking existing source order.

