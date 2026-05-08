# Automation Health

## What This Is

Automation Health is a local macOS SwiftUI app for inspecting scheduled jobs on this Mac. It scans supported scheduler sources, presents a searchable sidebar of automations, and shows detail needed to understand job health, timing, configuration, and recent output.

The shipped v1.0 sidebar now behaves like a more polished navigation surface: visible jobs are grouped by source, grouped search results stay stable, Up and Down move through visible jobs, and filtered no-result states avoid selectable placeholder rows.

## Core Value

Users can quickly understand and navigate the health of their local scheduled automations without the app modifying those jobs.

## Current State

**Shipped version:** v1.0 Sidebar Navigation on 2026-05-08

v1.0 completed 3 phases, 8 plans, and 19/19 scoped requirements. The milestone archive lives in `.planning/milestones/`, and the living roadmap is collapsed to the shipped milestone summary.

The repository CI gate passes after the milestone audit fix to `JobHumanizer.relativeRunDescription(for:relativeTo:)`, which now computes today/tomorrow/yesterday labels relative to the supplied reference date.

## Requirements

### Validated

- [x] The app scans supported launchd and Hermes cron sources read-only - existing.
- [x] The scanner layer normalizes source-specific jobs into shared scheduled job models - existing.
- [x] The UI shows a searchable sidebar connected to a detail view for health, schedule, configuration, and latest output - existing.
- [x] Refresh behavior preserves the selected job when possible and selects an available job after refresh - existing.
- [x] Local build and self-test workflows exist through SwiftPM scripts and Makefile shortcuts - existing.
- [x] The sidebar groups visible jobs by source with clear section headers and counts - shipped in v1.0.
- [x] Search filtering preserves the same grouping model - shipped in v1.0.
- [x] The sidebar supports Up and Down arrow navigation across visible jobs - shipped in v1.0.
- [x] Keyboard navigation skips non-job UI such as headers and footer controls - shipped in v1.0.
- [x] Keyboard navigation keeps the selected row, detail view, and scroll position synchronized - shipped in v1.0.
- [x] Search filtering only navigates through visible filtered jobs - shipped in v1.0.
- [x] The visual sidebar treatment remains compact, native-feeling, and consistent with the existing macOS SwiftUI app - shipped in v1.0.
- [x] Filtered no-result searches show a non-selectable inline sidebar empty state - shipped in v1.0.
- [x] The full local CI gate passes for the shipped milestone - shipped in v1.0.

### Active

No active requirements remain. The next milestone should start with `$gsd-new-milestone` so requirements are defined fresh before new roadmap work begins.

### Out of Scope

- Editing, enabling, disabling, deleting, or creating scheduled jobs - the app remains read-only.
- Adding new scheduler sources - v1.0 improved navigation and organization over existing scanned jobs.
- Persisted custom grouping preferences - source-based grouping was sufficient for v1.0 sidebar cleanup.
- A full design-system rewrite - v1.0 stayed localized to the existing sidebar and presentation boundary.

## Next Milestone Goals

Candidate directions for the next milestone, to be confirmed through fresh requirements:

- Alternate grouping modes such as health state or schedule type.
- Collapsible sidebar sections or persisted sidebar preferences.
- Broader keyboard shortcuts for refresh, reveal output, and focus movement.
- Additional scheduler/source coverage if the product focus shifts beyond navigation.

## Context

Automation Health is a brownfield SwiftPM macOS application with an existing codebase map in `.planning/codebase/`. The app is organized into `ActiveJobsCore` for scanner models and source adapters, `JobStore` and `JobPresentation` for UI state and display adaptation, and SwiftUI views for the app shell.

The relevant current ownership boundaries are:

- `Sources/AutomationHealth/Views/ContentView.swift` owns search filtering and passes sidebar sections into `SidebarView`.
- `Sources/AutomationHealth/Views/SidebarView.swift` renders the sidebar header, grouped source sections, job rows, selection visuals, keyboard navigation, scroll view, filtered empty state, and scan footer.
- `Sources/AutomationHealth/Models/JobPresentation.swift` adapts scanner models into display names, source names, health values, grouped sidebar sections, and navigation targets.
- `Sources/AutomationHealth/Stores/JobStore.swift` owns the selected job id and selected job lookup used by the detail view.

## Constraints

- **Platform**: macOS 14 or newer through SwiftPM - the app uses SwiftUI/AppKit APIs and should stay native.
- **Architecture**: Keep scanner IO out of views - sidebar work should use presentation/store data, not direct filesystem reads.
- **Scope**: Preserve read-only behavior - this project is about navigation and organization, not job management.
- **Dependencies**: Avoid new third-party packages unless a later phase proves one is necessary - the current package has no external Swift dependencies.
- **Testing**: Use the existing `ActiveJobsCoreSelfTest` and `script/ci.sh` workflow; add focused coverage where non-UI behavior moves into presentation helpers.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Group sidebar jobs by source for v1 | Source is already available on every job, maps cleanly to current scanners, and keeps categories stable under search. | Shipped in v1.0 |
| Make Up/Down move selection through visible jobs | This matches common macOS sidebar/list behavior and keeps the detail pane aligned with keyboard navigation. | Shipped in v1.0 |
| Keep section headers non-selectable | Headers should organize the list but not enter the job selection model. | Shipped in v1.0 |
| Use compact source headers with trailing counts | This keeps categories scannable without adding badges, collapse controls, or new grouping modes. | Shipped in v1.0 |
| Keep the app read-only | The product value is safe inspection of local automations, not administration. | Preserved in v1.0 |
| Compute relative run labels from the supplied reference date | Tests and UI adapters can pass deterministic dates, so humanized labels should not depend on the wall-clock day when `relativeTo` is provided. | Fixed during v1.0 audit |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition**:
1. Requirements invalidated? -> Move to Out of Scope with reason.
2. Requirements validated? -> Move to Validated with phase reference.
3. New requirements emerged? -> Add to Active.
4. Decisions to log? -> Add to Key Decisions.
5. "What This Is" still accurate? -> Update if drifted.

**After each milestone**:
1. Full review of all sections.
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state.

---
*Last updated: 2026-05-08 after v1.0 milestone completion*
