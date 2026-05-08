# Phase 1: Sidebar Grouping Foundation - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Represent and render the visible sidebar jobs grouped by scheduler source. The grouping must work for the full job list and for search-filtered results, while preserving the app's read-only behavior and keeping scanner IO out of views.

</domain>

<decisions>
## Implementation Decisions

### Source Section Ordering
- **D-01:** Source sections should use the known source order: Launchd first, Hermes cron second.
- **D-02:** Jobs within each source section should preserve the existing inventory order instead of introducing a new per-section sort. This keeps the current next-run-then-name behavior intact.
- **D-03:** Sources with zero visible jobs should not render section headers or placeholder rows.

### Section Header Content
- **D-04:** Each source header should show the human-readable source name plus the count of visible jobs in that section.
- **D-05:** Job row subtitles should remove the duplicated source name once rows are grouped under source headers. The subtitle should focus on timing or schedule text.

### Filtered Count Behavior
- **D-06:** When search is active, section header counts should reflect only visible filtered jobs.
- **D-07:** The top sidebar summary count should also reflect only visible filtered jobs, keeping the sidebar count language consistent under search.

### The Agent's Discretion
- Exact source header typography, spacing, and count separator may be chosen during planning/implementation as long as the result stays compact, native-feeling, and clearly shows source name plus visible count.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Defines Phase 1 goal, requirements, success criteria, and plan breakdown.
- `.planning/REQUIREMENTS.md` - Defines ORG-01, ORG-02, ORG-03, ORG-05, SRCH-01, and QUAL-03 for this phase.
- `.planning/PROJECT.md` - Defines the product boundary, read-only constraint, and v1 decision to group sidebar jobs by source.
- `.planning/STATE.md` - Records current phase state and deferred items, including custom grouping and collapsible groups being out of scope.

### Codebase Guidance
- `.planning/codebase/STRUCTURE.md` - Identifies where presentation models, sidebar views, and self-test coverage belong.
- `.planning/codebase/CONVENTIONS.md` - Captures Swift naming, helper, testing, and formatting conventions.
- `.planning/codebase/STACK.md` - Confirms SwiftPM/macOS 14, SwiftUI, no external Swift dependencies, and the existing self-test workflow.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Sources/AutomationHealth/Models/JobPresentation.swift` already adapts `ScheduledJob` values into UI-ready display fields, source names, health values, and searchable text.
- `SidebarJobSummary` is the right presentation-level row summary to extend so grouped sidebar data stays out of scanner IO and views remain simple.
- `HealthDot` and the current `SidebarJobRow` in `Sources/AutomationHealth/Views/SidebarView.swift` should be reused so Phase 1 does not alter health visuals or row selection styling beyond removing source text duplication.

### Established Patterns
- `Sources/AutomationHealth/Views/ContentView.swift` owns search filtering today, then maps visible jobs into sidebar rows. Grouping should happen after filtering so groups and counts reflect visible results.
- `JobInventory` already sorts jobs by next run then name before presentation. Phase 1 should preserve that order within each source group.
- Non-UI behavior that moves into presentation helpers should receive focused validation through `Sources/ActiveJobsCoreSelfTest/main.swift` or equivalent compile-time coverage, matching the current project testing style.

### Integration Points
- `ContentView` should pass grouped sidebar presentation data into `SidebarView`.
- `SidebarView` should render source headers as non-selectable structure and continue binding selection only to job rows.
- `JobPresentation` or a sibling presentation helper is the natural place for source-grouped sidebar data, because the app target can use `ActiveJobsCore.JobSource` without adding scanner IO to views.

</code_context>

<specifics>
## Specific Ideas

- Grouping is source-based only for v1.
- Header counts and top summary counts both mean "currently visible" when search is active.
- Row subtitles should become less repetitive by dropping the source name inside grouped sections.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 1 scope. Existing project-level deferred items remain out of scope: health-based grouping, schedule-based grouping, persisted custom grouping modes, and collapsible groups.

</deferred>

---

*Phase: 01-sidebar-grouping-foundation*
*Context gathered: 2026-05-08*
