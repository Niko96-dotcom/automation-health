# Phase 2: Keyboard Navigation - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Add Up and Down arrow navigation across the currently visible sidebar job rows. Keyboard navigation should skip source headers, summary text, empty states, and footer controls while keeping the selected row, detail pane, store selection id, and keyboard-driven scroll position synchronized. This phase does not add new shortcuts, type-ahead navigation, collapsible sections, or any job mutation behavior.

</domain>

<decisions>
## Implementation Decisions

### Selection Start And Boundaries
- **D-01:** When no visible row is currently selected, arrow navigation should enter the visible list: Down selects the first visible job and Up selects the last visible job.
- **D-02:** Boundary presses should keep the current selection. Up on the first visible job and Down on the last visible job should not wrap, clear selection, or move focus away.
- **D-03:** If `selectedJobID` points to a job hidden by the current search filter, keyboard navigation should treat it like no visible selection: Down selects the first visible job and Up selects the last visible job.

### Sidebar Focus Behavior
- **D-04:** The sidebar should handle Up/Down only when the sidebar row/list area is focused, including after a user clicks a sidebar row.
- **D-05:** The sidebar search field should keep normal text-editing arrow behavior; typing in search should not be hijacked by row navigation.
- **D-06:** Clicking a sidebar row should both select the row and make the sidebar/list ready for immediate Up/Down keyboard navigation.
- **D-07:** Phase 2 should rely on subtle/native focus behavior if it appears naturally, but should not add a custom focus ring or new focus visual treatment.

### Search And Refresh Interactions
- **D-08:** When search changes and the current selected job becomes hidden, preserve the existing selection and detail pane until the user explicitly presses Up/Down or chooses another row.
- **D-09:** When search changes and the selected job remains visible, keep that row as the keyboard-navigation anchor inside the filtered visible list.
- **D-10:** After refresh, if the selected job still exists, preserve it and continue keyboard navigation from its updated visible position.
- **D-11:** If refresh removes the selected job, use the existing `JobStore.refresh()` fallback behavior: select the first available refreshed job.

### Scroll Alignment
- **D-12:** Keyboard navigation should scroll only enough to reveal the newly selected row when it is outside the current viewport. It should not center the row on every movement.
- **D-13:** If the newly selected row is already visible, keyboard navigation should not adjust scroll position.
- **D-14:** Phase 2 scroll-to-selection behavior applies to keyboard navigation only. Mouse clicks and refresh selection changes should not introduce extra scroll movement beyond normal user action.

### The Agent's Discretion
- Exact SwiftUI/AppKit focus plumbing may be chosen during planning/implementation as long as it honors the narrow focus scope above.
- Exact helper names and file placement may follow the existing presentation/view pattern, with focused coverage added where navigation behavior is extracted into testable helpers.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Defines Phase 2 goal, requirements, success criteria, and planned waves.
- `.planning/REQUIREMENTS.md` - Defines NAV-01 through NAV-06, SRCH-02, SRCH-04, QUAL-01, and QUAL-02 for this phase.
- `.planning/PROJECT.md` - Defines the product boundary, read-only constraint, and key decision that Up/Down should move through visible jobs while skipping headers.
- `.planning/STATE.md` - Records current phase state, deferred items, and the note that pre-existing source changes may exist.
- `.planning/phases/01-sidebar-grouping-foundation/01-CONTEXT.md` - Locks the grouped sidebar model that Phase 2 navigates through.

### Codebase Guidance
- `.planning/codebase/STRUCTURE.md` - Identifies where presentation models, sidebar views, store state, and self-test coverage belong.
- `.planning/codebase/CONVENTIONS.md` - Captures Swift naming, helper, testing, and formatting conventions.
- `.planning/codebase/STACK.md` - Confirms SwiftPM/macOS 14, SwiftUI/AppKit, no external Swift dependencies, and the existing self-test workflow.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Sources/AutomationHealth/Views/SidebarView.swift` already derives `visibleJobs` by flattening `SidebarJobSection.jobs`; this is the natural visible-order list for keyboard navigation.
- `Sources/AutomationHealth/Models/JobPresentation.swift` provides `SidebarJobSection` and `SidebarJobSummary`, preserving source-grouped visible jobs and row ids without scanner IO.
- `Sources/AutomationHealth/Stores/JobStore.swift` owns `selectedJobID`, `selectedJob`, refresh preservation, and fallback-to-first selection behavior.
- `Sources/AutomationHealth/Views/ContentView.swift` already applies search filtering before grouping, so Phase 2 can navigate the same filtered section data passed to `SidebarView`.

### Established Patterns
- Views remain read-only and consume presentation/store data; scanner IO belongs in `ActiveJobsCore`, not in the sidebar.
- Selection currently flows through a binding to `store.selectedJobID`; keyboard navigation should update the same binding so the detail pane stays synchronized.
- Phase 1 established that source headers are non-selectable structure and rows inside each source preserve the incoming visible order.
- Focused non-UI behavior can be protected through the existing executable self-test style when behavior is extracted into helpers; otherwise `swift build` remains the compile gate for SwiftUI wiring.

### Integration Points
- `SidebarView` is the primary integration point for focus, key handling, row selection, and scroll-to-selected-row behavior.
- `ContentView` may need to pass enough context or bindings for search-filtered visible sections and selection synchronization, while keeping search ownership local.
- `JobPresentation` or a sibling app-target presentation helper is a good place for pure visible-list navigation helpers if the implementation extracts previous/next/boundary logic for coverage.
- `JobStore.refresh()` should remain the source of refresh fallback behavior instead of adding a second policy in the view layer.

</code_context>

<specifics>
## Specific Ideas

- Keyboard behavior should feel like a native macOS sidebar/list: focused rows respond to Up/Down, search editing remains normal, and boundary keys hold position.
- Search should not yank the detail pane around while the user types. Hidden selections stay selected until the user explicitly navigates into the filtered list.
- Long sidebar lists should feel calm: keyboard navigation reveals off-screen rows only when needed and does not recenter on every keypress.

</specifics>

<deferred>
## Deferred Ideas

None from this discussion. Existing project-level deferred items remain out of scope: additional keyboard shortcuts beyond Up/Down, type-ahead navigation, health-based grouping, schedule-based grouping, persisted custom grouping modes, and collapsible groups.

</deferred>

---

*Phase: 02-keyboard-navigation*
*Context gathered: 2026-05-08*
