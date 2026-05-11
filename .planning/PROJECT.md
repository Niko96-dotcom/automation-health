# Automation Health

## What This Is

Automation Health is a local macOS SwiftUI app for inspecting scheduled jobs on this Mac. It scans supported scheduler sources, presents a searchable sidebar of automations grouped by source, origin, health, trigger, confidence, or schedule, and shows detail needed to understand job health, timing, configuration, and recent output.

v1.2 shipped persisted user preferences (grouping mode, collapse state, scan config), keyboard navigation (8 shortcuts + type-to-select), and schedule-based grouping. v1.3 targets the remaining distribution work: codesigning, notarization, DMG, GitHub Release, and Sparkle auto-update.

## Core Value

Users can quickly understand and navigate the health of their local scheduled automations without the app modifying those jobs.

## Current Milestone: v1.3 Shippable Distribution

**Goal:** Ship a signed, notarized, auto-updating downloadable release of Automation Health.

**Target features:**
- Codesigning with Developer ID and hardened runtime entitlements
- Notarization recipe (notarytool + stapler) with CI automation
- Signed + notarized DMG produced by the release pipeline
- GitHub Release with downloadable artifact
- Release process documentation with placeholder identifiers
- Sparkle auto-update integration against GitHub Releases

## Current State

**Shipped version:** v1.2 Preferences, Polish, and Shippable Distribution on 2026-05-11

v1.0 (3 phases, 8 plans) shipped sidebar grouping foundation, keyboard navigation, and polish. v1.1 (6 phases, 16 plans) shipped open source readiness, visual identity, inventory model, candidate discovery, sidebar grouping/collapse, and publication verification.

v1.2 completed 3 phases and 8 plans:
- **Phase 10:** PreferencesStore with UserDefaults-backed @Published properties (grouping mode, collapse state, scan config), native macOS Settings scene (Cmd+,), Codable sidebar types, LICENSE with correct copyright, 3 self-tests
- **Phase 11:** 8 keyboard shortcuts (Cmd+Shift+F/E/W, Cmd+1-6), Finder-style type-to-select with 300ms buffer and wrap-around cycling, expand/collapse override with manual reset, AppKit search field focus, Escape handler, 3 self-tests
- **Phase 12:** SidebarScheduleKind (9 cases), SidebarScheduleClassifier (confidence-gated, time-of-day + frequency detection), .schedule grouping mode, Cmd+6 shortcut, evidence boundary preservation, 5 self-tests

41/41 self-tests passing. 5,795 lines of Swift.

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
- [x] Visual identity assets are generated and integrated, starting with a polished macOS app icon - shipped in Phase 5.
- [x] Source-independent confidence and origin model fields exist below the view layer - shipped in Phase 6.
- [x] Cron, Shortcuts, and Automator inventory sources are covered by injected fixtures and scan notes - shipped in Phase 6.
- [x] Scanner additions remain read-only and report source limitations without view-layer IO - shipped in Phase 6.
- [x] Candidate script discovery and app-only manual records are available through bounded, read-only flows - shipped in Phase 7.
- [x] Candidate and Manual records participate in shared inventory, search, sidebar, selection, and detail presentation - shipped in Phase 7.
- [x] Sidebar sections are collapsible and can be grouped/sorted by source, origin, health, trigger, and confidence - shipped in Phase 8.
- [x] The sidebar focus treatment matches the app's dark navigation surface while preserving keyboard accessibility - shipped in Phase 8.
- [x] Publication privacy scrub, sanitized visual guidance, local CI, app bundle verification, smoke evidence, and traceability are complete - shipped in Phase 9.
- [x] Sidebar grouping mode persists across app launches via UserDefaults — shipped in Phase 10.
- [x] Sidebar collapse state persists per group key via UserDefaults — shipped in Phase 10.
- [x] Candidate scan configuration persists via UserDefaults — shipped in Phase 10.
- [x] Default values used when no preferences exist — shipped in Phase 10.
- [x] Settings scene (Cmd+,) exposes persistent scan configuration preferences — shipped in Phase 10.
- [x] LICENSE file (MIT) committed to repository root — shipped in Phase 10.
- [x] Keyboard shortcut focuses search field (Cmd+Shift+F) — shipped in Phase 11.
- [x] Keyboard shortcut expands all sidebar groups (Cmd+Shift+E) — shipped in Phase 11.
- [x] Keyboard shortcut collapses all sidebar groups (Cmd+Shift+W) — shipped in Phase 11.
- [x] Keyboard shortcuts switch grouping mode (Cmd+1 through Cmd+6) — shipped in Phase 11/12.
- [x] Type-to-select letter navigation in sidebar — shipped in Phase 11.
- [x] Schedule-based grouping mode available in grouping mode selector — shipped in Phase 12.
- [x] Schedule-based grouping classifies jobs into time-of-day or frequency buckets — shipped in Phase 12.
- [x] Non-scheduled records appear in "No schedule evidence" bucket — shipped in Phase 12.
- [x] Evidence boundaries preserved — non-scheduled records never claim schedule they don't have — shipped in Phase 12.

### Active

- [ ] **DIST-01**: The `.app` bundle is codesigned with a Developer ID from the build pipeline.
- [ ] **DIST-02**: Hardened runtime entitlements are configured for the signed app.
- [ ] **DIST-03**: A notarization recipe (notarytool + stapler) is documented and reproducible.
- [ ] **DIST-04**: A signed and notarized DMG is produced by the release pipeline.
- [ ] **DIST-05**: A GitHub Release delivers a downloadable artifact.
- [ ] **DIST-06**: Release process documentation covers signing and notarization with placeholder identifiers.
- [ ] **DIST-07**: CI-based notarization runs in GitHub Actions as part of the release pipeline.
- [ ] **DIST-08**: Sparkle auto-update checks GitHub Releases and presents update UI to the user.

### Out of Scope

- Editing, enabling, disabling, deleting, or creating scheduled jobs - the app remains read-only.
- Claiming perfect discovery of every possible automation on every Mac - the app labels confidence and limitations honestly.
- Broad unbounded filesystem indexing - candidate discovery must be bounded, transparent, and performance-conscious.
- Uploading or sharing local scan data - publishing work must avoid leaking personal paths, hostnames, outputs, or job details.
- A full design-system rewrite - polish the existing native SwiftUI app rather than replace the app shell.
- Cloud sync, accounts, telemetry, or analytics — all preferences persist locally only.
- iOS port or Mac Catalyst — macOS native only.
- A separate preferences app or Settings scene redesign — use the native macOS Settings scene.
- Custom ordering grouping mode — deferred to future milestone, drag-to-reorder is non-trivial in current LazyVStack layout.
- In-app auto-update beyond Sparkle's standard GitHub Releases integration (custom update channels, delta updates).

## Context

Automation Health is a brownfield SwiftPM macOS application with an existing codebase map in `.planning/codebase/`. The app is organized into `ActiveJobsCore` for scanner models and source adapters, `JobStore` and `JobPresentation` for UI state and display adaptation, and SwiftUI views for the app shell.

The relevant current ownership boundaries are:

- `Sources/AutomationHealth/Views/ContentView.swift` owns search filtering and passes sidebar sections into `SidebarView`.
- `Sources/AutomationHealth/Views/SidebarView.swift` renders the sidebar header, grouped source sections, job rows, selection visuals, keyboard navigation, scroll view, filtered empty state, and scan footer.
- `Sources/AutomationHealth/Models/JobPresentation.swift` adapts scanner models into display names, source names, health values, grouped sidebar sections, and navigation targets.
- `Sources/AutomationHealth/Stores/JobStore.swift` owns the selected job id and selected job lookup used by the detail view.
- `Sources/AutomationHealth/Stores/PreferencesStore.swift` owns persisted preferences (grouping mode, collapse state, scan config) and transient bridge flags for keyboard shortcuts.

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
| Keep the app read-only | The product value is safe inspection of local automations, not administration. | Preserved |
| Compute relative run labels from the supplied reference date | Tests and UI adapters can pass deterministic dates, so humanized labels should not depend on the wall-clock day when `relativeTo` is provided. | Fixed during v1.0 audit |
| Use confidence labels for broad discovery | A script or registered tool can be automation-like without being a proven scheduled job, so the UI should distinguish scheduled, registered, candidate, and manual records. | Shipped in v1.1 |
| Separate scheduler source from ownership/origin | launchd can contain Apple jobs, third-party app updaters, and user-authored scripts. | Shipped in v1.1 |
| Require a privacy scrub before GitHub publication | Public repo materials must not expose local usernames, hostnames, real job output, personal bundle identifiers, or private paths. | Shipped in Phase 4 |
| Use Pulse Calendar for the app icon | A graphite calendar tile with one green pulse communicates scheduled automations and health without text, screenshots, or private scheduler detail. | Shipped in Phase 5 |
| Generate icon assets locally from committed source art | Built-in macOS `sips` and `iconutil` keep the app icon pipeline deterministic. | Shipped in Phase 5 |
| Return scanner jobs with source notes | Missing tools, unreadable locations, and evidence limitations need to be visible even when a scanner returns no jobs. | Shipped in Phase 6 |
| Treat Shortcuts and Automator as registered inventory | Listing registered automations is not schedule evidence, so these sources use Registered confidence and no next-run claims. | Shipped in Phase 6 |
| Treat script discoveries as Candidate records | File presence is possible automation evidence, not schedule evidence, so Candidate scripts use Candidate confidence and no run/next-run claims. | Shipped in Phase 7 |
| Keep Manual records app-owned | Users can track automations the scanner cannot prove, but only through Automation Health's own Application Support JSON. | Shipped in Phase 7 |
| Use abstract or synthetic public visuals only | Public docs and release materials must not expose real local automations, paths, hostnames, scheduler output, private commands, tokens, or secrets. | Shipped in Phase 9 |
| Treat publication evidence as command names plus outcomes | Final summaries and verification records should avoid raw terminal logs while preserving rerunnable command evidence. | Shipped in Phase 9 |
| Two @StateObjects with explicit init() sharing one PreferencesStore | Single source of truth for preferences, both stores receive identical reference. | Shipped in Phase 10 |
| Settings scene as sibling to WindowGroup | SwiftUI auto-registers Cmd+, without manual menu wiring. | Shipped in Phase 10 |
| Int-to-Double Binding wrappers for Slider controls | Avoids SwiftUI compile error (Slider expects Binding<Double>, not Binding<Int>). | Shipped in Phase 10 |
| Transient @Published bridge flags for keyboard shortcuts | Focus and expand/collapse requests use non-persisted flags, reset immediately after consumption. | Shipped in Phase 11 |
| NSSearchField located via NSToolbar.visibleItems iteration | Standard AppKit approach for .searchable-placed fields, no environment injection needed. | Shipped in Phase 11 |
| Type-to-select via .onKeyPress(characters: .alphanumerics) | Arrow keys, Escape, and modifiers pass through unmodified. | Shipped in Phase 11 |
| 300ms buffer timeout via Date comparison | Simpler than Timer/DispatchQueue, no lifecycle management or retain cycle risk. | Shipped in Phase 11 |
| effectiveSections computed property for expand override | Avoids mutating persistent collapseState — override is view-level transformation. | Shipped in Phase 11 |
| Schedule classifier as file-private enum with static kind(for:) | Follows existing SidebarTriggerClassifier pattern, tested indirectly through sections() API. | Shipped in Phase 12 |
| Time-of-day classification ranges: Morning (4-11), Afternoon (12-17), Evening (18-21), Night (0-3,22-23) | Standard macOS day-part intervals. | Shipped in Phase 12 |
| Only .scheduled confidence jobs eligible for schedule classification | Evidence boundary: registered/candidate/manual always → No schedule evidence. | Shipped in Phase 12 |

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
*Last updated: 2026-05-12 — v1.3 milestone started*
