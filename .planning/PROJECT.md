# Automation Health

## What This Is

Automation Health is a local macOS SwiftUI app for inspecting scheduled jobs on this Mac. It scans supported scheduler sources, presents a searchable sidebar of automations, and shows detail needed to understand job health, timing, configuration, and recent output.

The current project focus is to make the left sidebar feel more like a polished navigation surface: keyboard-friendly, easier to scan, and visually organized into clear job categories.

## Core Value

Users can quickly understand and navigate the health of their local scheduled automations without the app modifying those jobs.

## Requirements

### Validated

- [x] The app scans supported launchd and Hermes cron sources read-only - existing.
- [x] The scanner layer normalizes source-specific jobs into shared scheduled job models - existing.
- [x] The UI shows a searchable sidebar connected to a detail view for health, schedule, configuration, and latest output - existing.
- [x] Refresh behavior preserves the selected job when possible and selects an available job after refresh - existing.
- [x] Local build and self-test workflows exist through SwiftPM scripts and Makefile shortcuts - existing.
- [x] The sidebar groups visible jobs by source with clear section headers and counts - validated in Phase 1.
- [x] Search filtering preserves the same grouping model - validated in Phase 1.
- [x] The sidebar supports Up and Down arrow navigation across visible jobs - validated in Phase 2.
- [x] Keyboard navigation skips non-job UI such as headers and footer controls - validated in Phase 2.
- [x] Keyboard navigation keeps the selected row, detail view, and scroll position synchronized - validated in Phase 2.
- [x] Search filtering only navigates through visible filtered jobs - validated in Phase 2.
- [x] The visual sidebar treatment remains compact, native-feeling, and consistent with the existing macOS SwiftUI app - validated in Phase 3.
- [x] Filtered no-result searches show a non-selectable inline sidebar empty state - validated in Phase 3.
- [x] Local Phase 3 verification evidence covers source checks and a manual sidebar behavior pass - validated in Phase 3.

### Active

No active v1 sidebar requirements remain in this milestone.

### Out of Scope

- Editing, enabling, disabling, deleting, or creating scheduled jobs - the app remains read-only.
- Adding new scheduler sources - this milestone improves navigation and organization over existing scanned jobs.
- Persisted custom grouping preferences - source-based grouping is sufficient for the requested v1 sidebar cleanup.
- A full design-system rewrite - the change should stay localized to the existing sidebar and presentation boundary.

## Context

Automation Health is a brownfield SwiftPM macOS application with an existing codebase map in `.planning/codebase/`. The app is organized into `ActiveJobsCore` for scanner models and source adapters, `JobStore` and `JobPresentation` for UI state and display adaptation, and SwiftUI views for the app shell.

The relevant current ownership boundaries are:

- `Sources/AutomationHealth/Views/ContentView.swift` owns search filtering and passes sidebar rows into `SidebarView`.
- `Sources/AutomationHealth/Views/SidebarView.swift` renders the sidebar header, job rows, selection visuals, scroll view, and scan footer.
- `Sources/AutomationHealth/Models/JobPresentation.swift` adapts scanner models into display names, source names, health values, and sidebar row summaries.
- `Sources/AutomationHealth/Stores/JobStore.swift` owns the selected job id and selected job lookup used by the detail view.

The user specifically asked to improve the left sidebar by supporting Up/Down arrow scrolling through items and visually organizing jobs into cleaner categories with clear section headers.

## Constraints

- **Platform**: macOS 14 or newer through SwiftPM - the app uses SwiftUI/AppKit APIs and should stay native.
- **Architecture**: Keep scanner IO out of views - sidebar work should use presentation/store data, not direct filesystem reads.
- **Scope**: Preserve read-only behavior - this project is about navigation and organization, not job management.
- **Dependencies**: Avoid new third-party packages unless a later phase proves one is necessary - the current package has no external Swift dependencies.
- **Testing**: Use the existing `ActiveJobsCoreSelfTest` and `script/ci.sh` workflow; add focused coverage where non-UI behavior moves into presentation helpers.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Group sidebar jobs by source for v1 | Source is already available on every job, maps cleanly to current scanners, and keeps categories stable under search. | Validated in Phase 1 |
| Make Up/Down move selection through visible jobs | This matches common macOS sidebar/list behavior and keeps the detail pane aligned with keyboard navigation. | Validated in Phase 2 |
| Keep section headers non-selectable | Headers should organize the list but not enter the job selection model. | Validated in Phase 2 |
| Use compact source headers with trailing counts | This keeps categories scannable without adding badges, collapse controls, or new grouping modes. | Validated in Phase 3 |
| Keep the app read-only | The product value is safe inspection of local automations, not administration. | Validated through Phase 3 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason.
2. Requirements validated? -> Move to Validated with phase reference.
3. New requirements emerged? -> Add to Active.
4. Decisions to log? -> Add to Key Decisions.
5. "What This Is" still accurate? -> Update if drifted.

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections.
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state.

---
*Last updated: 2026-05-08 after Phase 3 completion*
