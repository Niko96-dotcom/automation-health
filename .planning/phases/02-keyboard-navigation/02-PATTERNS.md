# Phase 2: Keyboard Navigation - Pattern Map

**Mapped:** 2026-05-08
**Phase:** 02 - Keyboard Navigation

## Summary

Phase 2 should reuse the Phase 1 grouped sidebar pipeline. The canonical navigation list is the already-filtered, already-grouped visible row list exposed by `SidebarView.visibleJobs = sections.flatMap(\.jobs)`. Keyboard behavior should move through that flattened row list, write to the existing `selectedJobID` binding, and leave search, refresh, scanner IO, and row styling in their current ownership layers.

## Files In Scope

| Planned file | Role | Closest existing analog | Pattern to preserve |
|--------------|------|-------------------------|---------------------|
| `Sources/AutomationHealth/Models/JobPresentation.swift` | Presentation helper location for pure visible-row navigation behavior if extracted | `SidebarJobSection.sections(for:)` and `SidebarJobSummary` | Keep helper inputs UI-ready and in-memory. Do not read scheduler files, store state, or raw scanner sources. |
| `Sources/AutomationHealth/Views/SidebarView.swift` | Focus, key handling, row selection, and scroll reveal | Current `ScrollView` + `LazyVStack` + `SidebarJobRow` button structure | Keep source headers and summary text non-selectable. Only job rows and keyboard navigation write `selectedJobID`. |
| `Sources/AutomationHealth/Views/ContentView.swift` | Search ownership and grouped visible data handoff | `filteredJobs` then `SidebarJobSection.sections(for: filteredJobs)` | Search filtering stays in `ContentView`; `SidebarView` receives sections and does not re-filter or inspect the query. |
| `Sources/AutomationHealth/Stores/JobStore.swift` | Selection lookup and refresh fallback behavior | `selectedJob`, `refresh()`, and selected-id preservation | Do not duplicate refresh policy in views. Refresh keeps selected job when present and falls back to the first refreshed job. |
| `Sources/ActiveJobsCoreSelfTest/main.swift` | Existing self-test workflow | Top-level `try test...()` calls and `expect(...)` helper | Use for core contracts only. It cannot import the `AutomationHealth` executable target without package restructuring. |

## Visible Navigation Pattern

Use the existing sidebar-visible row list as the only traversal source:

```swift
private var visibleJobs: [SidebarJobSummary] {
    sections.flatMap(\.jobs)
}
```

This list already excludes the summary header, source section headers, empty-state copy, and footer controls. It also reflects the active search query because `ContentView` computes `SidebarJobSection.sections(for: filteredJobs)` before rendering `SidebarView`.

Navigation should be defined over visible row ids, not over `store.jobs`, raw `ScheduledJob` values, source sections, or source headers.

## Selection Binding Pattern

`SidebarJobRow` currently selects by writing the shared binding:

```swift
selectedJobID = job.id
```

Keyboard navigation should use the same binding. That keeps the selected row, `JobStore.selectedJobID`, `JobStore.selectedJob`, and `DetailView` synchronized without adding a second selection model.

## Focus Pattern

Keep Up/Down handling scoped to the sidebar row/list area. The search field is owned by `.searchable(text: $searchText, placement: .sidebar)` in `ContentView`, so key handling should not be attached to `NavigationSplitView` or other broad ancestors where text-editing arrows can be intercepted.

Recommended shape:

- Add a focused list/container state in `SidebarView`.
- Make the row/list area focusable.
- On row click, select the row and focus the row/list area.
- Handle `.upArrow` and `.downArrow` only from that focused row/list surface.
- Do not add a custom focus ring or visible keyboard instruction text.

## Scroll Reveal Pattern

Use `ScrollViewReader` around the existing scroll content and stable row ids on job rows. Track keyboard-originated navigation separately, for example with a pending keyboard target id. Only that keyboard path should call `scrollTo(targetID, anchor: nil)`.

Do not call `scrollTo` for every `selectedJobID` change, because mouse clicks, search changes, and refresh fallback should not add extra scroll movement.

## Testing And Verification Pattern

The current package has no test target for `AutomationHealth`; `ActiveJobsCoreSelfTest` depends only on `ActiveJobsCore`. Keep Phase 2 within the existing workflow:

- Use `swift build` after helper and SwiftUI wiring changes.
- Use grep-verifiable criteria for extracted helper signatures, key handlers, focus scoping, and scroll reveal code.
- Use `./script/ci.sh` at the end, while recording the known pre-existing `testHumanizesSchedulesAndRunTimes()` failure if it still appears.
- Add manual verification notes for focus behavior and scroll reveal, because the current repository has no UI automation harness.

## Pitfalls To Avoid

- Do not navigate `store.jobs`; navigate only `sections.flatMap(\.jobs)`.
- Do not clear or wrap selection at first/last visible row boundaries.
- Do not change selection merely because search hides the selected job; wait for explicit keyboard navigation or row click.
- Do not attach arrow-key handling globally where the search field loses native arrow behavior.
- Do not scroll on mouse click, search update, or refresh preservation.
- Do not add filesystem reads, scanner calls, scheduler writes, new shortcuts, type-ahead navigation, collapsible sections, or third-party dependencies.
