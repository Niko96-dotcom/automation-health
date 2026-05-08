# Phase 1: Sidebar Grouping Foundation - Pattern Map

**Mapped:** 2026-05-08
**Phase:** 01 - Sidebar Grouping Foundation

## Summary

Phase 1 should reuse the existing presentation and sidebar structure instead of introducing scanner-layer grouping. The closest local pattern is the current flow from `ContentView.filteredJobs` to `SidebarJobSummary` to `SidebarView`. The new source sections should be render-ready presentation data built from already-visible `JobPresentation` values.

## Files In Scope

| Planned file | Role | Closest existing analog | Pattern to preserve |
|--------------|------|-------------------------|---------------------|
| `Sources/AutomationHealth/Models/JobPresentation.swift` | Presentation data and sidebar row text | `JobPresentation` and `SidebarJobSummary` | Keep UI-ready fields in the app target, derived from `ScheduledJob`; do not read files or scanner state. |
| `Sources/AutomationHealth/Views/ContentView.swift` | Search/filter integration point | `filteredJobs` and `sidebarJobs` computed properties | Apply search first, then derive sidebar render data from the visible job list. |
| `Sources/AutomationHealth/Views/SidebarView.swift` | Sidebar rendering | `SidebarHeader`, `SidebarJobRow`, `HealthDot` | Keep job rows as buttons, headers as non-selectable structure, and preserve health/selection styling. |
| `Sources/ActiveJobsCoreSelfTest/main.swift` | Focused validation | Existing `test...` functions and `expect` helper | Add small deterministic checks through the executable self-test where the current target structure permits it. |

## Source Order Pattern

Use `JobSource.allCases` as the canonical source order. The enum currently declares `launchd` first and `hermesCron` second in `Sources/ActiveJobsCore/Models/ScheduledJob.swift`.

```swift
public enum JobSource: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case launchd
    case hermesCron
}
```

Do not sort sources by display name or raw value. The implementation should iterate `JobSource.allCases` and drop sections whose visible job list is empty.

## Filter Then Group Pattern

`ContentView` already owns the visible job calculation:

```swift
private var filteredJobs: [JobPresentation] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !query.isEmpty else {
        return store.jobs
    }

    return store.jobs.filter { $0.searchText.contains(query) }
}
```

The section builder should consume `filteredJobs`, not `store.jobs` and not a search query. This makes section counts, omitted empty sections, and the top sidebar summary all describe the same visible set.

## Row Text Pattern

`SidebarJobSummary` currently decides row subtitle text:

```swift
if job.job.nextRun != nil {
    subtitle = "\(job.sourceName) • \(job.nextRunText)"
} else {
    subtitle = "\(job.sourceName) • \(job.scheduleText)"
}
```

The grouped sidebar should keep subtitle construction in `SidebarJobSummary` or a nearby presentation helper, but allow grouped rows to omit the source prefix. The target subtitle rules are:

- If `job.job.nextRun != nil`, use `job.nextRunText`.
- Otherwise, use `job.scheduleText`.
- Do not include `job.sourceName` inside grouped rows.

## Sidebar Rendering Pattern

`SidebarView` currently renders a `ScrollView` with a `LazyVStack`, a non-selectable header, and selectable `SidebarJobRow` buttons. Keep that structure. Add non-selectable source headers between the top summary and row buttons.

Concrete rendering rules:

- `SidebarView` should receive `[SidebarJobSection]`.
- `SidebarHeader(jobCount:)` should count all visible rows across sections.
- Source headers should display `"{source name} ({visible count})"`.
- Source headers should be `Text`/layout only, with no button, click handler, selection background, or focus state.
- `SidebarJobRow` should remain the only element that writes to `selectedJobID`.

## Validation Pattern

The app target is an executable target, while `ActiveJobsCoreSelfTest` currently depends only on `ActiveJobsCore`. Do not force the self-test to import app-target internals. Use:

- A focused self-test for core source ordering and display names, which are the stable source order contract for grouping.
- `swift build` / `./script/ci.sh` as compile and integration validation for the app-target presentation helper and sidebar rendering.

## Pitfalls To Avoid

- Do not group before search filtering.
- Do not render empty source headers.
- Do not sort jobs inside a source group.
- Do not keep source names in grouped row subtitles.
- Do not add grouping preferences, collapsible headers, job editing controls, new scanner IO, or third-party dependencies.
