---
phase: 10
slug: preferences-persistence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-10
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ActiveJobsCoreSelfTest` (SwiftPM executable target) + `swift build` compile gate |
| **Config file** | None — custom self-test runner in `Sources/ActiveJobsCoreSelfTest/main.swift` |
| **Quick run command** | `swift run ActiveJobsCoreSelfTest` |
| **Full suite command** | `./script/ci.sh` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift build`
- **After every plan wave:** Run `./script/ci.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | PREFS-02 | T-10-01 / — | JSON decode fallback to empty collapse state on malformed data | self-test | `swift run ActiveJobsCoreSelfTest` | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | PREFS-04 | — | N/A | self-test | `swift run ActiveJobsCoreSelfTest` | ❌ W0 | ⬜ pending |
| 10-01-03 | 01 | 1 | PREFS-03 | — | N/A | self-test | `swift run ActiveJobsCoreSelfTest` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 1 | PREFS-01, PREFS-02 | — | N/A | compile | `swift build` | ❌ W0 | ⬜ pending |
| 10-02-02 | 02 | 1 | PREFS-01, PREFS-02, PREFS-05 | T-10-01 / — | Enum rawValue init with fallback on invalid data | compile | `swift build` | ❌ W0 | ⬜ pending |
| 10-02-03 | 02 | 1 | PREFS-03, PREFS-04 | — | Slider bounds prevent out-of-range input | compile | `swift build` | ❌ W0 | ⬜ pending |
| 10-03-01 | 03 | 1 | DIST-01 | — | N/A | file-exists | `grep "Copyright (c) 2026 Niko" LICENSE` | ❌ W0 | ⬜ pending |
| 10-03-02 | 03 | 1 | PREFS-03, PREFS-05 | — | N/A | compile | `swift build` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Sources/ActiveJobsCoreSelfTest/main.swift` — add `testCollapseStateCodableRoundTrip()` (verify JSON encode/decode for SidebarCollapseState)
- [ ] `Sources/ActiveJobsCoreSelfTest/main.swift` — add `testPreferencesStoreDefaults()` (verify register(defaults:) seeds correct values)
- [ ] `Sources/ActiveJobsCoreSelfTest/main.swift` — add `testScanConfigFromPreferences()` (verify Configuration derivation from PreferencesStore values)
- [ ] `Sources/ActiveJobsCoreSelfTest/main.swift` — add `testSidebarSectionIDCodable()` (verify SidebarSectionID+SidebarGroupingMode Codable round-trip)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Settings scene Cmd+, shortcut opens window | PREFS-05 | SwiftUI Settings scene cannot be tested programmatically in self-test | Build and run, press Cmd+, verify Settings window opens |
| Grouping mode survives app quit and relaunch | PREFS-01 | Requires full app lifecycle (UserDefaults persistence across launches) | Change grouping mode, quit app, relaunch, verify mode persisted |
| Slider visual behavior at boundaries | PREFS-05 | Visual-only concern; behavior is functionally correct | Drag sliders to boundaries (0, 5, 10, 500), verify no visual glitches |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
