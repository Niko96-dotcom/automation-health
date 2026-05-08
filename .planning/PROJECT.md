# Automation Health

## What This Is

Automation Health is a local macOS SwiftUI app for inspecting scheduled jobs on this Mac. It scans supported scheduler sources, presents a searchable sidebar of automations, and shows detail needed to understand job health, timing, configuration, and recent output.

The shipped v1.0 sidebar now behaves like a more polished navigation surface: visible jobs are grouped by source, grouped search results stay stable, Up and Down move through visible jobs, and filtered no-result states avoid selectable placeholder rows.

## Core Value

Users can quickly understand and navigate the health of their local scheduled automations without the app modifying those jobs.

## Current Milestone: v1.1 Open Source Readiness and Broad Inventory

**Goal:** Make Automation Health ready to publish as a clean open-source GitHub project while expanding discovery beyond the current machine-specific scheduler slice and polishing the sidebar experience.

**Target features:**
- Public GitHub readiness: license, security/support/community files, README/docs/workflows, and privacy scrub so personal local details are not leaked.
- Image-generated visual identity: Codex should produce copy-paste-ready ChatGPT image prompts for app/public assets, with at least a polished app icon and a deterministic packaging path from chosen source art.
- Broad automation inventory: add deterministic scanner coverage, confidence-labeled candidate discoveries, and manual app-only records for automations the scanner cannot prove.
- Sidebar organization polish: app-matched focus styling, collapsible categories, and grouping/sorting options that separate source from ownership, health, trigger type, and confidence.

## Current State

**Shipped version:** v1.0 Sidebar Navigation on 2026-05-08

v1.0 completed 3 phases, 8 plans, and 19/19 scoped requirements. The milestone archive lives in `.planning/milestones/`, and the living roadmap is collapsed to the shipped milestone summary.

The repository CI gate passes after Phase 4's open-source readiness work. Phase 4 added public repository health files, privacy-safe templates, public scanner docs, a rerunnable privacy scrub checklist, a neutral bundle identifier, and synthetic scanner fixtures.

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
- [x] Publishable open-source repository materials and workflows exist without personal local data leaks - shipped in Phase 4.

### Active

- [ ] Visual identity assets are generated and integrated, starting with a polished macOS app icon.
- [ ] Automation discovery distinguishes proven scheduled jobs, registered automations, candidate scripts, and manual records.
- [ ] Sidebar sections are collapsible and can be grouped/sorted by more useful categories than raw scheduler source.
- [ ] The sidebar focus treatment matches the app's dark navigation surface while preserving keyboard accessibility.

### Out of Scope

- Editing, enabling, disabling, deleting, or creating scheduled jobs - the app remains read-only.
- Claiming perfect discovery of every possible automation on every Mac - v1.1 should label confidence and limitations honestly.
- Broad unbounded filesystem indexing - candidate discovery must be bounded, transparent, and performance-conscious.
- Uploading or sharing local scan data - publishing work must avoid leaking personal paths, hostnames, outputs, or job details.
- A full design-system rewrite - v1.1 should polish the existing native SwiftUI app rather than replace the app shell.

## Next Milestone Goals

This section is superseded by the active v1.1 milestone above.

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
| Use confidence labels for broad discovery | A script or registered tool can be automation-like without being a proven scheduled job, so the UI should distinguish scheduled, registered, candidate, and manual records. | Planned for v1.1 |
| Separate scheduler source from ownership/origin | launchd can contain Apple jobs, third-party app updaters, and user-authored scripts, so grouping by source alone is not enough for v1.1. | Planned for v1.1 |
| Require a privacy scrub before GitHub publication | Public repo materials must not expose local usernames, hostnames, real job output, personal bundle identifiers, or private paths. | Shipped in Phase 4 |

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
*Last updated: 2026-05-08 after Phase 4 completion*
