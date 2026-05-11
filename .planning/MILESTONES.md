# Milestones

## v1.2 Preferences, Polish, and Shippable Distribution (Shipped: 2026-05-11)

**Phases completed:** 3 phases, 8 plans, 19 tasks

**Key accomplishments:**

- Codable sidebar types, PreferencesStore with UserDefaults-backed @Published properties, and scan configuration wired through JobInventory → CandidateScriptScanner
- Native macOS Settings window wired to PreferencesStore, ContentView migrated to @ObservedObject
- Updated MIT LICENSE copyright line per D-06, and added 3 self-test functions verifying Codable round-trips and scan configuration defaults created in Plan 01.
- PreferencesStore transient bridge properties, View CommandMenu with 8 shortcuts, and AppKit search field focus wiring — the app-level infrastructure for keyboard navigation
- Type-to-select letter navigation with Finder-style cycling, expand/collapse override rendering, and focus bridge wiring — the view-level keyboard interaction layer
- Automated regression tests for type-to-select matching logic, expand/collapse override lifecycle, and grouping mode shortcut key mappings — 160 lines of pure logic verification added to ActiveJobsCoreSelfTest
- Schedule grouping mode with time-of-day and frequency classification, gated on .scheduled confidence, accessible via Cmd+6
- Four new self-test functions for schedule classification + updated grouping mode shortcut/label tests

---

## v1.1 Open Source Readiness and Broad Inventory (Shipped: 2026-05-10)

**Phases completed:** 6 phases, 16 plans, 63 tasks

**Key accomplishments:**

- Standard public repository health files with privacy-safe issue/PR intake and a clearly named local CI workflow
- Public docs now explain Automation Health's local read-only value, best-effort scanner boundaries, unsigned local bundle status, and scanner extension path
- Rerunnable privacy checklist plus neutral bundle identifier, synthetic scanner fixtures, and cleaned launchd heuristic terms
- Pulse Calendar source-art prompt and selected graphite calendar PNG with one green health pulse
- Deterministic macOS iconset and ICNS pipeline wired into the local app bundle
- Source-neutral confidence, origin, and scan-note contract for all scanner results
- Read-only cron inventory through injected crontab output and readable system cron fixtures
- Shortcuts and Automator registered inventory with conservative confidence and bounded reads
- Bounded candidate script discovery with Candidate confidence and no schedule claims
- App-owned Manual records with JSON persistence, store facade, and manual-only SwiftUI mutation controls
- Candidate and Manual records integrated into shared search, source-sectioned sidebar rows, and detail evidence labels
- Shared sidebar presentation core with deterministic grouping, conservative trigger labels, collapse state, and hidden-row navigation tests
- Native sidebar grouping menu and disclosure sections wired to in-memory collapse state and visible-row navigation
- Restrained sidebar keyboard focus cue with full automated Phase 8 build, self-test, CI, IO-boundary, and app-bundle verification
- Publication privacy scrub evidence with cleaned macOS metadata, private-neutral display-name normalization, and abstract/synthetic public visual guidance
- Final publication verification with passing CI, app bundle launch, privacy-safe smoke evidence, and completed requirement traceability

---

## v1.0 Sidebar Navigation (Shipped: 2026-05-08)

**Phases completed:** 3 phases, 8 plans, 23 tasks

**Audit:** passed, 19/19 requirements satisfied

**Archives:**

- [Roadmap](milestones/v1.0-ROADMAP.md)
- [Requirements](milestones/v1.0-REQUIREMENTS.md)
- [Audit](milestones/v1.0-MILESTONE-AUDIT.md)

**Key accomplishments:**

- Source-ordered sidebar section data built from visible JobPresentation values.
- Filter-then-group sidebar rendering with compact source headers and row-only selection.
- Source-order self-test plus build validation for grouped sidebar behavior.
- Pure sidebar navigation helper that computes previous and next selection targets from visible job rows
- Focus-scoped Up and Down navigation that updates the existing sidebar selection binding
- Keyboard-originated sidebar scroll reveal that keeps selected visible rows in view without affecting search, refresh, or mouse clicks
- Compact grouped sidebar polish with a non-selectable filtered empty state and quiet row hover feedback
- Phase 3 sidebar verification evidence for CI, source contracts, and focused manual behavior checks

---
