# Phase 3: Sidebar Polish And Verification - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine the existing source-grouped sidebar so it feels clean, compact, and native at the current split-view width; add a clear non-selectable empty state for filtered searches with no visible jobs; and verify the final behavior through the local CI gate plus a focused manual sidebar check. This phase does not change source grouping, add new grouping modes, add collapsible sections, add new keyboard shortcuts, or introduce job mutation behavior.

</domain>

<decisions>
## Implementation Decisions

### Rows And Section Headers
- **D-01:** Section headers should use a compact label-plus-count treatment with a subtle divider, rather than the current parenthetical count style or a count badge.
- **D-02:** Header styling should stay quiet and native-feeling. Phase 1 decisions still apply: source order is launchd first then Hermes cron, and counts represent only currently visible jobs.
- **D-03:** Job rows should receive light polish only: keep the current row structure and preserve display name, subtitle, health dot, and selected-row behavior.
- **D-04:** Preserve the current soft accent selected-row fill. Implementation may tune opacity, spacing, or corner radius if needed, but should not switch to a much stronger native-list selection treatment.
- **D-05:** Add a quiet hover background if straightforward in the existing SwiftUI view structure. Do not add custom focus rings or a new explicit focus visual treatment.

### Filtered Empty State
- **D-06:** When a non-empty search query produces no visible jobs, show a small inline sidebar empty state.
- **D-07:** The new empty state is only for filtered searches. If the scan finds no jobs at all, keep that broader app/detail empty behavior out of this phase.
- **D-08:** The empty state must not be a selectable placeholder row. Up/Down keyboard navigation should do nothing when there are no visible jobs.
- **D-09:** Empty-state copy should be plain and functional: `No matching automations` and `Try a different search.`

### Verification
- **D-10:** The required automated gate is `./script/ci.sh`.
- **D-11:** The manual sidebar behavior check should verify that rows still show display name, subtitle, health dot, and selection styling; search no-results shows the inline empty state; and clearing search restores grouped Up/Down keyboard navigation.
- **D-12:** Document the manual check in the phase plan only. Do not add a separate checklist document or a new script for this phase.
- **D-13:** If CI fails because of pre-existing unrelated modified files or unrelated self-test failures, report and isolate the failure. Only fix issues caused by Phase 3, and record whether unrelated failures block phase acceptance.

### The Agent's Discretion
- Exact font sizes, padding values, divider opacity, and row/header spacing may be chosen during implementation as long as the sidebar remains compact and native-feeling.
- The implementation may choose the simplest SwiftUI hover mechanism that works cleanly with the existing `SidebarJobRow`; if hover support becomes awkward or destabilizes row behavior, preserve the core row polish and note the tradeoff.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Defines Phase 3 goal, requirements, success criteria, and the two planned work items.
- `.planning/REQUIREMENTS.md` - Defines ORG-04, SRCH-03, and QUAL-04 for this phase, plus v2/out-of-scope items that must remain deferred.
- `.planning/PROJECT.md` - Defines the product boundary, read-only constraint, current sidebar focus, and key decisions already validated in earlier phases.
- `.planning/STATE.md` - Records current phase state, deferred items, and the note about pre-existing source changes.
- `.planning/phases/01-sidebar-grouping-foundation/01-CONTEXT.md` - Locks source grouping, visible counts, row subtitle behavior, and non-selectable section headers.
- `.planning/phases/02-keyboard-navigation/02-CONTEXT.md` - Locks Up/Down behavior, focus scope, scroll alignment, and search/refresh navigation behavior.

### Codebase Guidance
- `.planning/codebase/STRUCTURE.md` - Identifies where sidebar views, presentation models, and self-test coverage belong.
- `.planning/codebase/CONVENTIONS.md` - Captures Swift naming, formatting, helper, and file organization conventions.
- `.planning/codebase/TESTING.md` - Defines the existing self-test runner and local CI workflow for verification.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Sources/AutomationHealth/Views/SidebarView.swift` already owns `SidebarHeader`, `SourceSectionHeader`, `SidebarJobRow`, `HealthDot`, selection binding, keyboard navigation, and scroll-to-selection behavior.
- `Sources/AutomationHealth/Models/JobPresentation.swift` already provides `SidebarJobSection`, `SidebarJobSummary`, and `SidebarNavigation`, which keep grouping and visible-list navigation outside scanner IO.
- `Sources/AutomationHealth/Views/ContentView.swift` owns `searchText` and computes `filteredJobs` before deriving `sidebarSections`, making it the likely integration point for telling `SidebarView` whether the current empty result is caused by search.
- `script/ci.sh` is the repository gate for `swift build` plus `./script/test.sh`.

### Established Patterns
- Views consume presentation/store data and do not read scheduler files directly.
- Existing `SidebarJobRow` already preserves the required display name, subtitle, health dot, and selected styling surface that Phase 3 must keep.
- Phase 1 and Phase 2 already extracted source order and navigation behavior into presentation helpers where focused validation can compile through the self-test target.
- UI view behavior is not currently covered by XCTest or UI automation, so manual verification is expected for sidebar polish.

### Integration Points
- `SidebarView` is the main implementation point for header styling, row hover/spacing polish, selected-row preservation, and inline empty-state rendering.
- `ContentView` may need to pass search-empty context, such as whether the trimmed query is non-empty and `sidebarSections` is empty.
- `JobPresentation` should remain unchanged unless planning identifies a small presentation helper needed for empty-state logic; scanner-layer models should not change for this phase.

</code_context>

<specifics>
## Specific Ideas

- Section headers should read like compact navigation structure: source label plus visible count, with subtle separation between groups.
- The sidebar should feel polished by refinement, not redesign: light typography/spacing cleanup, same row structure, same health dot, same soft selected fill.
- Empty search results should be calm and plain: `No matching automations` followed by `Try a different search.`
- Verification should include a human pass through search, no-results, clearing search, and Up/Down navigation to catch the pieces automated tests do not cover.

</specifics>

<deferred>
## Deferred Ideas

None from this discussion. Existing project-level deferred items remain out of scope: health-based grouping, schedule-based grouping, persisted custom grouping modes, collapsible groups, additional keyboard shortcuts beyond Up/Down, and type-ahead navigation.

</deferred>

---

*Phase: 03-sidebar-polish-and-verification*
*Context gathered: 2026-05-08*
