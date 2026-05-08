# Phase 08: Sidebar Grouping, Collapse, And Focus Polish - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 8 turns the existing source-grouped sidebar into a richer native navigation surface. It adds grouping modes for source, origin/ownership, health, trigger type, and confidence; collapsible sections that do not break detail selection; stable grouped browsing under refresh and search; and a custom focus treatment that matches the app's dark sidebar while staying keyboard-accessible.

This phase does not add scanner sources, read scheduler files from SwiftUI views, mutate real automations, redesign the app shell, add broad preference storage, or introduce third-party dependencies.

</domain>

<decisions>
## Implementation Decisions

### Grouping Controls And Defaults
- **D-01:** Default grouping should remain `Source` on first launch or first load, preserving the shipped v1.0 sidebar behavior while adding richer modes.
- **D-02:** Add a compact sidebar-local grouping control, preferably in or near the sidebar header, rather than a global toolbar control. The grouping choices are exactly `Source`, `Origin`, `Health`, `Trigger`, and `Confidence` for this phase.
- **D-03:** Group ordering must be deterministic and domain-specific, not alphabetical when alphabetical order would bury important records. Source should follow `JobSource.allCases`; origin should be `User-authored`, `Third-party app`, `System`, `Unknown`; confidence should be `Scheduled`, `Registered`, `Candidate`, `Manual`; health should put attention first: `Needs attention`, `Stale`, `Waiting`, `Alive`, `Unknown`.
- **D-04:** Row subtitles should adapt to the active grouping mode so the grouped-by value is not redundantly repeated, while still keeping enough evidence visible for scanning. For example, source grouping can omit source from row subtitles, but origin, health, trigger, and confidence grouping should keep source visible somewhere in the row subtitle.
- **D-05:** Launchd origin separation should happen through the source-independent `JobOrigin` field, not by inventing launchd-specific pseudo-sources. In origin grouping, launchd jobs should split across `User-authored`, `Third-party app`, `System`, or `Unknown` based on the model, while the row subtitle still makes the scheduler source visible.
- **D-06:** To satisfy `SIDE-05` without adding explanatory clutter, the origin grouping control or section headers may provide concise help text explaining that origin is ownership/authorship and source is the scheduler or inventory adapter.
- **D-07:** Do not persist grouping or collapsed-section preferences to disk in Phase 8. Keep grouping and collapse state in app memory, structured so future `PREF-01` work can persist it later.

### Collapse, Search, And Selection
- **D-08:** Section headers may become interactive disclosure rows or contain disclosure buttons, but they must not become selectable jobs. Job selection remains limited to automation records.
- **D-09:** Collapsing a section hides its rows but must not clear or move the selected job. If the selected job is inside a collapsed section, the detail view should continue showing that job until the user selects another visible job.
- **D-10:** Keyboard Up/Down navigation should operate only over visible job rows. When the current selection is hidden by a collapsed section, navigation should start from that hidden record's section boundary when practical, then move to the nearest visible row in the requested direction.
- **D-11:** Search should temporarily reveal matching rows in matching groups without mutating the user's in-memory collapsed state. When the search query is cleared, prior collapsed sections should return to their previous collapsed or expanded state.
- **D-12:** Filtered empty states remain non-selectable and should continue to avoid entering keyboard navigation. Section counts under search should reflect the filtered visible result count.
- **D-13:** Collapse state should be keyed by grouping mode and section identity. Switching grouping modes should preserve in-memory collapsed state for each mode during the session, with all sections expanded the first time a mode is visited.

### Trigger Type Grouping
- **D-14:** Trigger type grouping is a presentation classification over existing `ScheduledJob` fields. It must not add filesystem reads, process calls, script-content analysis, shell history inspection, or new scanner inference.
- **D-15:** Trigger groups should use conservative evidence labels: `Time-based`, `Login / Keep Alive`, `File / Queue Trigger`, `Registered Only`, `Candidate Scripts`, and `Manual / Unspecified`.
- **D-16:** Trigger classification should prefer explicit schedule text and source/confidence boundaries. Candidate scripts remain candidates, manual records remain app-owned manual records, and registered Shortcuts/Automator records should not be described as scheduled unless a scanner has direct schedule evidence.
- **D-17:** Trigger group ordering should keep proven scheduled behavior ahead of weaker evidence: `Time-based`, `Login / Keep Alive`, `File / Queue Trigger`, `Registered Only`, `Candidate Scripts`, `Manual / Unspecified`.

### Focus Treatment
- **D-18:** Replace the oversized default blue focus rectangle with an app-matched custom focus cue on the dark sidebar. The cue should feel like a native navigation focus state, not a form-field error or bright overlay.
- **D-19:** Keep selection and focus visually distinct. Selection can continue using the existing compact selected-row fill; keyboard focus should add a thin outline, inset stroke, or similarly restrained shape cue that remains visible on the dark material sidebar.
- **D-20:** The focus cue must remain accessible to keyboard users and visible in active/inactive window states and high-contrast conditions. Do not rely on color alone if shape or stroke can carry the state.
- **D-21:** Prefer SwiftUI focus and overlay styling around the existing `SidebarView` and row components. Use AppKit interop only if SwiftUI cannot suppress or replace the default focus rectangle cleanly.
- **D-22:** Keep the sidebar compact. Do not use this phase to introduce large cards, decorative redesign, oversized headers, or marketing-style layout.

### the agent's Discretion
Downstream agents may choose exact helper type names, whether grouping state lives in `JobPresentation`, a new sidebar presentation helper, or `ContentView` state, and the precise SwiftUI control style for the grouping menu/disclosure affordance. They should preserve the decisions above, the read-only boundary, the no-view-IO rule, and the compact native macOS feel.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Defines Phase 8 goal, success criteria, planned waves, dependency on Phase 7, and fixed scope.
- `.planning/REQUIREMENTS.md` - Defines `SIDE-01` through `SIDE-07`, `QUAL-04`, and the future `PREF-01` persistence boundary.
- `.planning/PROJECT.md` - Captures current milestone context, read-only posture, sidebar ownership boundaries, and prior sidebar decisions.
- `.planning/STATE.md` - Current GSD state, deferred sidebar ideas, and warning about preserving unrelated working-tree changes.

### Prior Phase Contracts
- `.planning/phases/07-candidate-discovery-and-manual-records/07-CONTEXT.md` - Locks Candidate/Manual inventory presentation and explicitly leaves grouping modes, collapsible sections, and custom focus treatment to Phase 8.
- `.planning/phases/07-candidate-discovery-and-manual-records/07-UI-SPEC.md` - Approved Phase 7 UI contract whose sidebar/search/detail language and Candidate/Manual boundaries must remain intact.

### Existing Source Files
- `Sources/AutomationHealth/Views/ContentView.swift` - Owns search text, filtered jobs, sidebar section derivation, toolbar actions, and the right place to hold sidebar-local grouping state if kept in view state.
- `Sources/AutomationHealth/Views/SidebarView.swift` - Renders section headers, rows, focus state, scroll behavior, filtered empty state, and keyboard navigation.
- `Sources/AutomationHealth/Models/JobPresentation.swift` - Existing presentation adapter for search text, display fields, `SidebarJobSummary`, `SidebarNavigation`, and `SidebarJobSection`.
- `Sources/AutomationHealth/Stores/JobStore.swift` - Selection owner and refresh preservation behavior; useful for keeping selected details coherent when rows are hidden.
- `Sources/ActiveJobsCore/Models/ScheduledJob.swift` - Source, confidence, origin, and normalized job fields used by grouping modes.
- `Sources/ActiveJobsCore/Support/JobHumanizer.swift` - Health classification and human schedule descriptions that can feed health and trigger grouping.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Existing executable self-test target; add focused non-UI tests for grouping, trigger classification, and navigation helpers.

### Product Documentation
- `docs/scanner-extension-guide.md` - Reinforces that SwiftUI views must consume scanner/presentation data and avoid direct filesystem reads.
- `docs/scheduled-job-sources.md` - Defines evidence boundaries for Scheduled, Registered, Candidate, and Manual records.
- `README.md` - Public wording around local read-only inventory and supported evidence levels that sidebar copy should not contradict.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `JobSource`, `JobConfidence`, and `JobOrigin` already provide source-independent categories and display names for grouping.
- `JobHealthKind` and `ScheduledJob.health(relativeTo:)` already produce health categories for grouping and row dot colors.
- `JobPresentation` already centralizes display names, source/confidence/origin labels, schedule text, search text, and row summaries.
- `SidebarJobSection.sections(for:)` already creates deterministic source sections and is the natural seam to generalize into grouping modes.
- `SidebarNavigation.targetJobID(in:selectedJobID:direction:)` already isolates keyboard navigation over visible rows and should be extended with focused coverage for collapsed/search-hidden rows.
- `JobStore.selectedJobID` and `selectedJob` already preserve selected detail independently from the current filtered sidebar rows.

### Established Patterns
- Scanner IO belongs in `ActiveJobsCore`; SwiftUI views should use `JobStore`, `JobPresentation`, and normalized `ScheduledJob` data only.
- Sidebar presentation helpers live in `Sources/AutomationHealth/Models/JobPresentation.swift` today, with UI rendering in `SidebarView`.
- The app favors compact native SwiftUI controls, small private view helpers, and no third-party dependencies.
- Executable self-tests in `Sources/ActiveJobsCoreSelfTest/main.swift` are the current regression path for non-UI behavior.

### Integration Points
- Add grouping-mode state and collapse state around `ContentView`/`SidebarView`, keeping search filtering in `ContentView`.
- Generalize `SidebarJobSection` so it can group by source, origin, health, trigger type, or confidence and produce stable section IDs.
- Update `SidebarJobSummary` subtitle composition to avoid redundant labels per grouping mode while preserving source/evidence context.
- Update `SidebarView` section headers to support disclosure, counts, help text, and accessible labels without adding selectable placeholder rows.
- Update navigation helpers to derive the visible row list from expanded sections and search state, with tests for collapsed and filtered rows.
- Replace or suppress the default focus rectangle through SwiftUI focus/overlay styling and verify the result in the local macOS app.

</code_context>

<specifics>
## Specific Ideas

- Preferred default grouping label: `Source`.
- Preferred grouping control shape: compact sidebar-local `Group` menu or picker, with checkmark state and short labels.
- Preferred trigger group labels: `Time-based`, `Login / Keep Alive`, `File / Queue Trigger`, `Registered Only`, `Candidate Scripts`, and `Manual / Unspecified`.
- Origin grouping should visibly separate user-authored, third-party app, system, and unknown records even when several rows share `launchd` as their scheduler source.
- Prompt UI was unavailable in this Codex mode, so this context uses the GSD workflow fallback: all key gray areas were selected and recommended defaults were captured explicitly.

</specifics>

<deferred>
## Deferred Ideas

- Persisted grouping and collapsed-section preferences remain future `PREF-01` work; Phase 8 should keep state in memory only.
- Additional keyboard shortcuts beyond predictable Up/Down row navigation and normal focus/disclosure behavior remain future polish.
- Full design-system redesign, settings screens, signed distribution, and new automation source scanners remain outside Phase 8.

</deferred>

---

*Phase: 08-sidebar-grouping-collapse-and-focus-polish*
*Context gathered: 2026-05-08*
