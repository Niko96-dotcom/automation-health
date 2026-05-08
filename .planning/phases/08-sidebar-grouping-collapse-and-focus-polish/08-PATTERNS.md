# Phase 08 - Pattern Map

**Phase:** 08 - Sidebar Grouping, Collapse, And Focus Polish
**Mapped:** 2026-05-08
**Inputs:** `08-CONTEXT.md`, `08-RESEARCH.md`, `08-UI-SPEC.md`, current source tree

## Summary

Phase 8 should keep the existing data flow:

`ActiveJobsCore scanner IO -> JobInventory -> JobStore -> JobPresentation/sidebar presentation helpers -> SwiftUI views`

The new grouping, collapse, trigger classification, row-subtitle, and visible-row navigation behavior should be presentation logic, not scanner IO. SwiftUI views should render prepared sections and mutate only in-memory grouping/collapse state.

Because `ActiveJobsCoreSelfTest` currently imports `ActiveJobsCore` only and the Phase 8 validation contract requires automated non-UI coverage for sidebar helpers, the cleanest implementation path is to introduce a small internal `AutomationHealthCore` library target that depends on `ActiveJobsCore`. Move `JobPresentation` and sidebar presentation helpers there, then let both the app executable and the self-test executable import it.

## Implementation Targets

| Target File | Role | Closest Existing Analog | Pattern To Reuse |
|-------------|------|-------------------------|------------------|
| `Package.swift` | Internal presentation library target wiring | Existing `ActiveJobsCore` library and executable target dependencies | Add a local library product/target only; no third-party packages. Make `AutomationHealth` and `ActiveJobsCoreSelfTest` depend on it. |
| `Sources/AutomationHealthCore/JobPresentation.swift` | UI-ready presentation, grouping, trigger, collapse, and navigation helpers | Existing `Sources/AutomationHealth/Models/JobPresentation.swift` | Preserve current display/search helpers, then add pure `Sendable` value types that self-tests can import. |
| `Sources/AutomationHealth/Models/JobPresentation.swift` | Old app-local presentation file | One-primary-type-per-file convention and SwiftPM target directories | Remove after moving content to `AutomationHealthCore`, or leave only app-specific extensions if needed. Avoid duplicate type definitions. |
| `Sources/AutomationHealth/Views/ContentView.swift` | Search, grouping mode state, collapse state owner | Existing `searchText`, `filteredJobs`, and `sidebarSections` derivation | Keep view IO-free. Add `@State` for `SidebarGroupingMode` and `SidebarCollapseState`; derive effective sections from filtered jobs and search state. |
| `Sources/AutomationHealth/Views/SidebarView.swift` | Grouping control, disclosure headers, visible rows, keyboard handling, focus cue | Existing `SidebarView`, `SourceSectionHeader`, `SidebarJobRow`, `SidebarNavigation.targetJobID` | Render prepared sections, section headers as plain buttons, rows as only selectable items, and Up/Down over `visibleJobs` only. |
| `Sources/AutomationHealth/Stores/JobStore.swift` | Selection owner and refresh behavior | Existing `selectedJob` and refresh selection preservation | Do not change selection for collapse/search. Store selection remains independent from visible sidebar rows. |
| `Sources/ActiveJobsCoreSelfTest/main.swift` | Fixture-driven coverage | Existing top-level executable self-test style | Import `AutomationHealthCore`; add tests for labels, deterministic orders, origin grouping, trigger classification, collapse/search visibility, and hidden-selection navigation. |

## Concrete Code Patterns

### Internal Presentation Target

Use a local target so the executable self-test can validate Phase 8 logic without importing SwiftUI views:

```swift
.library(
    name: "AutomationHealthCore",
    targets: ["AutomationHealthCore"]
)

.target(
    name: "AutomationHealthCore",
    dependencies: ["ActiveJobsCore"]
)
```

Then update target dependencies:

```swift
.executableTarget(
    name: "AutomationHealth",
    dependencies: ["ActiveJobsCore", "AutomationHealthCore"]
)

.executableTarget(
    name: "ActiveJobsCoreSelfTest",
    dependencies: ["ActiveJobsCore", "AutomationHealthCore"]
)
```

### Grouping Helpers

Recommended type shape:

```swift
public enum SidebarGroupingMode: String, CaseIterable, Identifiable, Sendable {
    case source
    case origin
    case health
    case trigger
    case confidence
}
```

Labels must be exactly `Source`, `Origin`, `Health`, `Trigger`, and `Confidence`.

Generalize sections from source-only:

```swift
public struct SidebarJobSection: Identifiable, Hashable, Sendable {
    public let id: SidebarSectionID
    public let title: String
    public let visibleCount: Int
    public let totalCount: Int
    public let isCollapsed: Bool
    public let jobs: [SidebarJobSummary]
    public let allJobIDs: [String]
}
```

Keep deterministic order arrays:

- Source: `JobSource.allCases`
- Origin: `.userAuthored`, `.thirdPartyApp`, `.system`, `.unknown`
- Health: `.failed`, `.stale`, `.waiting`, `.alive`, `.unknown` displayed as `Needs attention`, `Stale`, `Waiting`, `Alive`, `Unknown`
- Trigger: `Time-based`, `Login / Keep Alive`, `File / Queue Trigger`, `Registered Only`, `Candidate Scripts`, `Manual / Unspecified`
- Confidence: `.scheduled`, `.registered`, `.candidate`, `.manual`

### Subtitle Patterns

`SidebarJobSummary` should accept the active grouping mode and produce exact patterns:

- Source: `{Confidence} - {schedule or next run}`
- Origin: `{Source} - {Confidence} - {schedule or next run}`
- Health: `{Source} - {Confidence} - {schedule or next run}`
- Trigger: `{Source} - {Confidence} - {schedule or next run}`
- Confidence: `{Source} - {schedule or next run}`

### Collapse And Search

Collapse state should be a pure value keyed by grouping mode and section identity:

```swift
public struct SidebarCollapseState: Hashable, Sendable {
    public private(set) var collapsedSectionIDs: Set<SidebarSectionID>
}
```

Search expansion is derived:

- `hasSearchQuery == true` makes matching groups display matching rows even when stored collapse state says collapsed.
- Clearing search restores the stored collapsed/expanded state.
- Collapse toggles do not clear `selectedJobID`.

### Navigation

Keep the existing helper pattern but pass section context so hidden selected records can move predictably:

```swift
public enum SidebarNavigation {
    public static func targetJobID(
        in sections: [SidebarJobSection],
        selectedJobID: String?,
        direction: SidebarNavigationDirection
    ) -> String?
}
```

The helper should:

- Return nil for no visible jobs.
- Move previous/next when the selected job is visible.
- If selected is hidden in a collapsed section, use `allJobIDs` position to choose the nearest visible row before/after the hidden record.
- Fall back to first/last visible row when no positional context exists.

### Focus Cue

Keep the scroll/list area focusable for `.onKeyPress`. Add a custom 1-2 px rounded inset stroke or equivalent shape cue when `focusedTarget == .jobList`. Do not remove keyboard focus visibility. Use AppKit interop only if the SwiftUI focus ring cannot be suppressed.

## Validation Hooks

Automated:

- `./script/test.sh`
- `./script/ci.sh`
- `! rg -n "Data\\(contentsOf:|FileManager\\.default|contentsOfDirectory|JSONEncoder|JSONDecoder|crontab|shortcuts list|launchctl" Sources/AutomationHealth/Views`

Manual:

- Switch all grouping modes and verify order/counts/subtitles.
- Collapse selected and unselected groups; verify detail stays coherent.
- Search inside a collapsed group; verify rows appear and clearing search restores collapse state.
- Use Up/Down with collapsed and filtered rows; verify hidden rows are skipped.
- Verify the oversized default blue focus rectangle is gone and a visible custom focus cue remains in dark, light, inactive, and high-contrast states where practical.

## Guardrails

- Do not persist grouping or collapse state in Phase 8.
- Do not add third-party dependencies.
- Do not introduce scanner/file/process IO into SwiftUI views.
- Do not classify registered, candidate, or manual records as scheduled without direct schedule evidence.
- Do not make section headers selectable jobs.
- Do not clear or move selection merely because a row becomes hidden by collapse or search.
