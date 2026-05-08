---
phase: 07
slug: candidate-discovery-and-manual-records
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
---

# Phase 07 - Validation Strategy

Per-phase validation contract for bounded candidate discovery, app-only manual records, and search/detail integration.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | SwiftPM executable self-test |
| Config file | none |
| Quick run command | `./script/test.sh` |
| Full suite command | `./script/ci.sh` |
| Estimated runtime | ~20 seconds quick, ~60 seconds full |

## Sampling Rate

- After every task commit: Run `./script/test.sh`.
- After every plan wave: Run `./script/ci.sh`.
- Before `$gsd-verify-work`: Full suite must be green.
- Max feedback latency: 60 seconds for Phase 07 validation.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | DISC-06, QUAL-03 | T-07-02 | Candidate scanner stays inside injected bounded roots and caps depth/results/visited files | self-test | `./script/test.sh` | yes | pending |
| 07-01-02 | 01 | 1 | DISC-06, QUAL-03 | T-07-02 / T-07-03 | Candidate scanner ignores hidden/build/dependency/cache/oversized files and reports scan notes | self-test | `./script/test.sh` | yes | pending |
| 07-01-03 | 01 | 1 | DISC-06 | T-07-01 | Candidate records use `.candidate` confidence and explicit no-schedule-evidence schedule text | self-test | `./script/test.sh` | yes | pending |
| 07-02-01 | 02 | 2 | MAN-01, MAN-03 | T-07-04 | Manual record store creates and reads only app-owned JSON records from injected paths | self-test | `./script/test.sh` | yes | pending |
| 07-02-02 | 02 | 2 | MAN-02, MAN-03 | T-07-01 / T-07-04 | Manual edit/remove updates only app-owned records and never writes scheduler/script paths | self-test/grep | `./script/ci.sh` | yes | pending |
| 07-02-03 | 02 | 2 | MAN-01, MAN-02 | T-07-05 | SwiftUI mutation controls are scoped to manual records through `JobStore` methods | build/manual | `./script/ci.sh` | yes | pending |
| 07-03-01 | 03 | 3 | DISC-08, MAN-03 | T-07-05 | Candidate and manual records appear in search/detail through `JobPresentation` without view-layer scanner IO | self-test/grep | `./script/ci.sh` | yes | pending |
| 07-03-02 | 03 | 3 | DISC-08 | T-07-05 | Existing launchd, Hermes cron, cron, Shortcuts, and Automator records still render through the shared presentation path | self-test | `./script/test.sh` | yes | pending |
| 07-03-03 | 03 | 3 | QUAL-03 | T-07-02 / T-07-03 | Docs name candidate locations, scan limits, ignore rules, and failure behavior | docs/grep | `./script/ci.sh` | yes | pending |

## Requirement Coverage

| Requirement | Validation Evidence |
|-------------|---------------------|
| DISC-06 | Candidate scanner fixture tests verify bounded locations, `.candidate` confidence, and no schedule evidence. |
| DISC-08 | Search/detail tests verify candidate/manual text flows through existing presentation state and selected records remain accessible. |
| MAN-01 | Manual record store and UI/store tests verify creation of app-owned records. |
| MAN-02 | Manual record store and grep checks verify edit/remove only touches app-owned storage and exposes no real scheduler mutation path. |
| MAN-03 | Persistence tests verify manual records survive reload and convert to `ScheduledJob` with `.manual` confidence. |
| QUAL-03 | Candidate scanner tests and docs grep verify performance bounds, ignore rules, scan notes, and failure behavior. |

## Wave 0 Requirements

- [x] Existing `ActiveJobsCoreSelfTest` infrastructure covers Phase 07 core and presentation helper tests.
- [x] Existing `./script/ci.sh` covers build and self-test execution.
- [x] No new test framework or external Swift dependency required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Add/edit/remove manual record UI | MAN-01, MAN-02, MAN-03 | The project has no XCTest/UI automation target. | Launch the app, add a synthetic manual record, verify it appears in sidebar/detail/search, edit it, then remove it. |
| Candidate/manual visual labeling | DISC-06, DISC-08, MAN-03 | The project has no screenshot assertion workflow. | Launch the app with fixture-like local records and verify Candidate and Manual confidence are visible in detail and not confused with Scheduled. |

## Validation Sign-Off

- [x] All tasks have automated verification commands or explicit manual verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is under 60 seconds for the full Phase 07 suite.
- [x] `nyquist_compliant: true` is set in frontmatter.

Approval: pending
