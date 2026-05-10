# Requirements: Automation Health

**Defined:** 2026-05-10
**Core Value:** Users can quickly understand and navigate the health of their local scheduled automations without the app modifying those jobs.

## v1.2 Requirements

Requirements for v1.2 Preferences, Polish, and Shippable Distribution. Each maps to roadmap phases.

### Preferences

- [ ] **PREFS-01**: Sidebar grouping mode persists across app launches via @AppStorage
- [ ] **PREFS-02**: Sidebar collapse state persists per group key via UserDefaults
- [ ] **PREFS-03**: Candidate scan configuration (roots, depth, file count cap, result cap, file size cap) persists via UserDefaults
- [ ] **PREFS-04**: Default values are used when no preferences exist (no migration required)
- [ ] **PREFS-05**: Settings scene (Cmd+,) exposes persistent scan configuration preferences

### Grouping

- [ ] **GROUP-01**: Schedule-based grouping mode is available in the grouping mode selector
- [ ] **GROUP-02**: Schedule-based grouping classifies jobs into time-of-day or frequency buckets
- [ ] **GROUP-03**: Non-scheduled records (Registered, Candidate, Manual) appear in a "No schedule evidence" bucket
- [ ] **GROUP-04**: Evidence boundaries are preserved — non-scheduled records never claim schedule they don't have

### Keyboard Navigation

- [ ] **NAV-01**: Keyboard shortcut focuses the search field (Cmd+Shift+F)
- [ ] **NAV-02**: Keyboard shortcut expands all sidebar groups at once
- [ ] **NAV-03**: Keyboard shortcut collapses all sidebar groups at once
- [ ] **NAV-04**: Keyboard shortcuts switch grouping mode (Cmd+1 through Cmd+N)
- [ ] **NAV-05**: Jump-to-letter navigation in sidebar — typing first letters of a job name selects the matching row

### Distribution

- [ ] **DIST-01**: Permissive LICENSE file (MIT) is committed to the repository root
- [ ] **DIST-02**: The `.app` bundle is codesigned with a Developer ID Application certificate via the build pipeline
- [ ] **DIST-03**: Hardened runtime entitlements are configured for the signed app
- [ ] **DIST-04**: Notarization recipe (notarytool + stapler) is documented and reproducible with placeholder identifiers
- [ ] **DIST-05**: A signed and notarized `.app.zip` or `.dmg` is produced by the release pipeline
- [ ] **DIST-06**: A GitHub Release is created for v1.2 with the downloadable artifact
- [ ] **DIST-07**: Release process documentation (`docs/release-process.md`) covers signing, notarization, and packaging with placeholder identifiers — no real Developer ID or team ID in committed artifacts

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Grouping

- **GROUP-05**: Custom ordering grouping mode with user-defined section ordering
- **GROUP-06**: Health-based grouping mode reconciled with existing health stub as a first-class mode

### Distribution

- **DIST-08**: Automated CI-based notarization via GitHub Actions

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Mutation of real automations | Read-only product boundary — the app inspects, never modifies |
| Cloud sync, accounts, telemetry, analytics | All preferences persist locally only |
| iOS port or Mac Catalyst | macOS native only |
| In-app auto-update | Rely on the GitHub Releases page |
| Settings scene redesign | Use the native macOS Settings scene SwiftUI provides |
| Custom ordering grouping mode | Deferred to future milestone — drag-to-reorder is non-trivial in current LazyVStack layout |
| CI-based notarization (GitHub Actions) | Stretch goal — local notarization recipe is the v1.2 requirement |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PREFS-01 | Phase 10 | Pending |
| PREFS-02 | Phase 10 | Pending |
| PREFS-03 | Phase 10 | Pending |
| PREFS-04 | Phase 10 | Pending |
| PREFS-05 | Phase 10 | Pending |
| DIST-01 | Phase 10 | Pending |
| NAV-01 | Phase 11 | Pending |
| NAV-02 | Phase 11 | Pending |
| NAV-03 | Phase 11 | Pending |
| NAV-04 | Phase 11 | Pending |
| NAV-05 | Phase 11 | Pending |
| GROUP-01 | Phase 12 | Pending |
| GROUP-02 | Phase 12 | Pending |
| GROUP-03 | Phase 12 | Pending |
| GROUP-04 | Phase 12 | Pending |
| DIST-02 | Phase 13 | Pending |
| DIST-03 | Phase 13 | Pending |
| DIST-04 | Phase 13 | Pending |
| DIST-05 | Phase 13 | Pending |
| DIST-06 | Phase 13 | Pending |
| DIST-07 | Phase 13 | Pending |

**Coverage:**
- v1.2 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-10*
*Last updated: 2026-05-10 after roadmap creation*
