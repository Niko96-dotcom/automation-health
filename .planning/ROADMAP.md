# Roadmap: Automation Health

## Milestones

- ✅ **v1.0 Sidebar Navigation** — Phases 1-3 shipped 2026-05-08; 8 plans, 23 tasks. Archives: [roadmap](milestones/v1.0-ROADMAP.md), [requirements](milestones/v1.0-REQUIREMENTS.md), [audit](milestones/v1.0-MILESTONE-AUDIT.md).
- ✅ **v1.1 Open Source Readiness and Broad Inventory** — Phases 4-9 shipped 2026-05-10; 16 plans, 63 tasks. Archives: [roadmap](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md).
- ✅ **v1.2 Preferences, Polish, and Shippable Distribution** — Phases 10-12 shipped 2026-05-11; 8 plans, 19 tasks. Archives: [roadmap](milestones/v1.2-ROADMAP.md), [requirements](milestones/v1.2-REQUIREMENTS.md).

## Phases

<details>
<summary>✅ v1.0 Sidebar Navigation (Phases 1-3) — shipped 2026-05-08</summary>

- [x] Phase 1: Sidebar Grouping Foundation (3/3 plans)
- [x] Phase 2: Keyboard Navigation (3/3 plans)
- [x] Phase 3: Polish And Verification (2/2 plans)

</details>

<details>
<summary>✅ v1.1 Open Source Readiness and Broad Inventory (Phases 4-9) — shipped 2026-05-10</summary>

- [x] Phase 4: Open Source Foundation And Privacy Scrub (3/3 plans)
- [x] Phase 5: Visual Identity And Icon Pipeline (2/2 plans)
- [x] Phase 6: Inventory Model And Deterministic Sources (3/3 plans)
- [x] Phase 7: Candidate Discovery And Manual Records (3/3 plans)
- [x] Phase 8: Sidebar Grouping, Collapse, And Focus Polish (3/3 plans)
- [x] Phase 9: Publication Verification And Docs Polish (2/2 plans)

</details>

<details>
<summary>✅ v1.2 Preferences, Polish, and Shippable Distribution (Phases 10-12) — shipped 2026-05-11</summary>

- [x] Phase 10: Preferences Persistence (3/3 plans) — PreferencesStore, UserDefaults persistence, native Settings scene, LICENSE file.
- [x] Phase 11: Keyboard Navigation (3/3 plans) — 8 keyboard shortcuts, type-to-select letter navigation, expand/collapse override.
- [x] Phase 12: Schedule-Based Grouping (2/2 plans) — SidebarScheduleKind, SidebarScheduleClassifier, .schedule grouping mode, Cmd+6 shortcut.

</details>

## Next Milestone: v1.3 Shippable Distribution

- [x] **Phase 13: Signed and Notarized DMG with CI Pipeline** — Static linking, entitlements, codesigning, DMG packaging, notarization, GitHub Release, release process docs, and CI automation. (completed 2026-05-12)
- [ ] **Phase 14: Sparkle Auto-Update Integration** — Sparkle 2 framework integration, auto-update UI, EdDSA signing, and end-to-end update flow against GitHub Releases.

## Phase Details

### Phase 13: Signed and Notarized DMG with CI Pipeline
**Goal**: Users can download a Gatekeeper-compatible, signed and notarized DMG of Automation Health from GitHub Releases, built entirely by CI with no manual steps.
**Depends on**: Nothing (first phase of v1.3)
**Requirements**: DIST-01, DIST-02, DIST-03, DIST-04, DIST-05, DIST-06, DIST-07
**Success Criteria** (what must be TRUE):
  1. The `.app` bundle built from the release pipeline passes `spctl --assess --verbose` without Gatekeeper rejection on a non-development Mac.
  2. The hardened runtime entitlement allows the app's `launchctl`-based scanner to execute without crashes or permission denials.
  3. A `.dmg` file is produced by the release pipeline that, when opened, shows the Automation Health icon and an Applications folder alias for drag-to-install.
  4. Running `stapler validate` against the DMG confirms a stapled notarization ticket.
  5. A tagged GitHub Release contains the signed and notarized DMG as a downloadable asset.
  6. A developer following the documented release process can produce a signed and notarized release using their own Developer ID credentials.
**Plans**: 3 plans

Plans:
**Wave 1**
- [x] 13-01-PLAN.md — Entitlements file, release script with codesign+DMG+notarize+staple, and Makefile targets

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 13-02-PLAN.md — GitHub Actions release workflow with certificate import, notarization, and GitHub Release creation
- [x] 13-03-PLAN.md — Release process documentation, .gitignore update, and README distribution status update
**UI hint**: yes

### Phase 14: Sparkle Auto-Update Integration
**Goal**: Users with a running Automation Health app receive in-app update notifications and can install new versions published to GitHub Releases.
**Depends on**: Phase 13
**Requirements**: DIST-08
**Success Criteria** (what must be TRUE):
  1. The app displays its current version in an Updates section within the native macOS Settings window.
  2. The app checks for updates against the GitHub Releases appcast feed and shows an update alert when a newer version is available.
  3. A user can download and install an update entirely from within the app, with the app relaunching to the new version.
  4. The EdDSA public key is embedded in the app bundle, and update signatures are verified before installation is offered.
**Plans**: 4 plans

Plans:
**Wave 1** *(independent)*
- [ ] 14-01-PLAN.md — Sparkle 2 SPM dependency, UpdateStore ObservableObject, and EdDSA key generation script

**Wave 2** *(depends on 14-01)*
- [ ] 14-02-PLAN.md — Sparkle updater lifecycle in AutomationHealthApp, Check for Updates menu item, and Updates section in SettingsView
- [ ] 14-03-PLAN.md — Appcast generation in release.sh and Sparkle setup in release documentation

**Wave 3** *(depends on 14-03)*
- [ ] 14-04-PLAN.md **(gap closure)** — Embed SUPublicEDKey in build script Info.plist templates, wire SPARKLE_EDDSA_PRIVATE_KEY injection and appcast.xml upload into CI release workflow
**UI hint**: yes

## Progress

| Milestone | Phases | Plans | Status      | Shipped    |
| --------- | ------ | ----- | ----------- | ---------- |
| v1.0      | 3      | 8/8   | Complete    | 2026-05-08 |
| v1.1      | 6      | 16/16 | Complete    | 2026-05-10 |
| v1.2      | 3      | 8/8   | Complete    | 2026-05-11 |
| v1.3      | 2      | 3/7   | In Progress | —          |
