# Roadmap: Automation Health

## Milestones

- ✅ **v1.0 Sidebar Navigation** — Phases 1-3 shipped 2026-05-08; 8 plans, 23 tasks. Archives: [roadmap](milestones/v1.0-ROADMAP.md), [requirements](milestones/v1.0-REQUIREMENTS.md), [audit](milestones/v1.0-MILESTONE-AUDIT.md).
- ✅ **v1.1 Open Source Readiness and Broad Inventory** — Phases 4-9 shipped 2026-05-10; 16 plans, 63 tasks. Archives: [roadmap](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md).
- ◆ **v1.2 Preferences, Polish, and Shippable Distribution** — Phases 10-13 in progress.

## Phases

<details>
<summary>✅ v1.0 Sidebar Navigation (Phases 1-3) — shipped 2026-05-08</summary>

- [x] Phase 1: Sidebar Grouping Foundation (3/3 plans)
- [x] Phase 2: Keyboard Navigation (3/3 plans)
- [x] Phase 3: Polish And Verification (2/2 plans)

</details>

<details>
<summary>✅ v1.1 Open Source Readiness and Broad Inventory (Phases 4-9) — shipped 2026-05-10</summary>

- [x] Phase 4: Open Source Foundation And Privacy Scrub (3/3 plans) — public repo health files, privacy scrub checklist, scanner extension guide.
- [x] Phase 5: Visual Identity And Icon Pipeline (2/2 plans) — Pulse Grid app icon source art and deterministic local iconset/ICNS pipeline.
- [x] Phase 6: Inventory Model And Deterministic Sources (3/3 plans) — confidence/origin/scan-note contract, plus CronScanner, ShortcutsScanner, AutomatorScanner.
- [x] Phase 7: Candidate Discovery And Manual Records (3/3 plans) — bounded candidate scripts, app-owned manual records, shared inventory presentation.
- [x] Phase 8: Sidebar Grouping, Collapse, And Focus Polish (3/3 plans) — AutomationHealthCore module split, five grouping modes, disclosure sections, restrained focus cue.
- [x] Phase 9: Publication Verification And Docs Polish (2/2 plans) — privacy scrub, sanitized public visuals, CI/bundle verification, traceability closure.

</details>

<details open>
<summary>◆ v1.2 Preferences, Polish, and Shippable Distribution — in progress</summary>

- [ ] **Phase 10: Preferences Persistence** (foundation) — PreferencesStore, @AppStorage/@UserDefaults for grouping mode, collapse state, and scan config. Native Settings scene. LICENSE file.
  - **Plans:** 3 plans
  - Requirements: PREFS-01, PREFS-02, PREFS-03, PREFS-04, PREFS-05, DIST-01
  - Plans:
    - [x] 10-01-PLAN.md — Preferences store foundation: Codable types, PreferencesStore, scan config wiring
    - [x] 10-02-PLAN.md — Settings scene and app integration: SettingsView, AutomationHealthApp, ContentView migration
    - [x] 10-03-PLAN.md — LICENSE copyright and self-test verification
  - Canonical refs: `.planning/research/STACK.md`, `.planning/research/ARCHITECTURE.md`

- [ ] **Phase 11: Keyboard Navigation** (depends on Phase 10) — Focus search, expand/collapse all, switch grouping mode shortcuts, jump-to-letter navigation.
  - **Plans:** 3 plans
  - Requirements: NAV-01, NAV-02, NAV-03, NAV-04, NAV-05
  - Plans:
    - [x] 11-01-PLAN.md — PreferencesStore expand override + global shortcuts (View CommandMenu, Cmd+Shift+F/E/W, Cmd+1..5) + ContentView search focus and Escape
    - [x] 11-02-PLAN.md — Type-to-select matching logic (SidebarNavigation) + sidebar buffer/cycling + expand override rendering and manual reset
    - [ ] 11-03-PLAN.md — Self-test coverage for type-to-select, expand override lifecycle, and shortcut key mappings
  - Canonical refs: `.planning/research/STACK.md`, `.planning/research/FEATURES.md`

- [ ] **Phase 12: Schedule-Based Grouping** (depends on Phase 10) — New schedule-based grouping mode with confidence-gated classifier. Evidence boundary preservation for Registered, Candidate, and Manual records.
  - Requirements: GROUP-01, GROUP-02, GROUP-03, GROUP-04
  - Canonical refs: `.planning/research/ARCHITECTURE.md`, `.planning/research/PITFALLS.md`

- [ ] **Phase 13: Shippable Distribution** (independent of UI phases) — Codesigning, hardened runtime entitlements, notarization, DMG packaging, GitHub Release, release process documentation.
  - Requirements: DIST-02, DIST-03, DIST-04, DIST-05, DIST-06, DIST-07
  - Canonical refs: `.planning/research/STACK.md`, `.planning/research/PITFALLS.md`

</details>

## Success Criteria

### Phase 10: Preferences Persistence
1. Grouping mode selection survives app quit and relaunch
2. Sidebar section collapse state is restored on relaunch per grouping mode and group key
3. Candidate scan configuration (roots, depth, caps) persists across launches
4. First launch with no preferences uses the documented v1.1 defaults
5. Settings scene (Cmd+,) exposes scannable configuration fields with persistent values
6. LICENSE file (MIT) is present in the repository root

### Phase 11: Keyboard Navigation
1. Cmd+Shift+F focuses the sidebar search field from anywhere in the app
2. Single shortcut expands all sidebar sections; companion shortcut collapses all
3. Cmd+1 through Cmd+N switch between available grouping modes
4. Typing one or more letters in the sidebar selects the first matching job row
5. All keyboard shortcuts coexist with existing Up/Down arrow navigation
6. Shortcuts work regardless of current grouping mode or collapse state

### Phase 12: Schedule-Based Grouping
1. "Schedule" appears as a selectable grouping mode alongside existing five modes
2. Jobs with schedule evidence are classified into time-of-day or frequency buckets
3. Registered, Candidate, and Manual records appear in a "No schedule evidence" section
4. Non-scheduled confidence records never display fabricated run times or next-run dates
5. Existing grouping modes (Source, Origin, Health, Trigger, Confidence) are unaffected

### Phase 13: Shippable Distribution
1. A single script command produces a Developer ID-signed, hardened-runtime `.app` bundle
2. Notarization succeeds via `notarytool --wait` and staple attaches the ticket
3. Signed and notarized `.app.zip` or `.dmg` is ready for distribution
4. GitHub Release page for v1.2 contains the downloadable artifact
5. `docs/release-process.md` documents the full pipeline with placeholder identifiers
6. No real Developer ID, team ID, or credentials appear in committed files

## Progress

| Milestone | Phases | Plans | Status      | Shipped    |
| --------- | ------ | ----- | ----------- | ---------- |
| v1.0      | 3      | 8/8   | Complete    | 2026-05-08 |
| v1.1      | 6      | 16/16 | Complete    | 2026-05-10 |
| v1.2      | 4      | 0/3   | In progress | —          |
