---
phase: 06
slug: inventory-model-and-deterministic-sources
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
updated: 2026-05-08
---

# Phase 06 - Validation Strategy

Per-phase validation contract for feedback sampling during execution and retroactive Nyquist coverage.

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
- Max feedback latency: 60 seconds for Phase 06 validation.

## Generated Tests

| File | Type | Command | Coverage |
|------|------|---------|----------|
| `Sources/ActiveJobsCoreSelfTest/main.swift` | executable self-test | `./script/test.sh` | Inventory confidence/origin/scan-note model, scanner result aggregation, cron parser/runner fixtures, Shortcuts command fixtures, Automator directory fixtures |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | DISC-01, DISC-02, DISC-07 | T-06-01-01 | Model carries confidence, origin, and scan notes without source-specific view IO | self-test | `./script/test.sh` | yes | pending |
| 06-01-02 | 01 | 1 | DISC-01, DISC-02, DISC-07, QUAL-01 | T-06-01-02 | Existing scanners return scheduled confidence, conservative origins, and non-fatal notes | self-test | `./script/test.sh` | yes | pending |
| 06-01-03 | 01 | 1 | DISC-01, DISC-02, DISC-07 | T-06-01-03 | Store/presentation data exposes scan notes without direct scheduler reads in views | self-test/build | `./script/ci.sh` | yes | pending |
| 06-02-01 | 02 | 2 | DISC-03, DISC-07, QUAL-01, QUAL-02 | T-06-02-01 | Cron command runner uses only `crontab -l` and fixture runners in tests | self-test | `./script/test.sh` | yes | pending |
| 06-02-02 | 02 | 2 | DISC-03, QUAL-02 | T-06-02-02 | Cron parser handles user/system forms, special schedules, comments, and env lines from synthetic fixtures | self-test | `./script/test.sh` | yes | pending |
| 06-02-03 | 02 | 2 | DISC-03, DISC-07 | T-06-02-03 | Inventory includes cron scanner and reports source notes for missing/unreadable cron inputs | self-test/build | `./script/ci.sh` | yes | pending |
| 06-03-01 | 03 | 3 | DISC-04, DISC-07, QUAL-01, QUAL-02 | T-06-03-01 | Shortcuts scanner lists records with injected `shortcuts list --show-identifiers` and never runs shortcuts | self-test | `./script/test.sh` | yes | pending |
| 06-03-02 | 03 | 3 | DISC-05, DISC-07, QUAL-01, QUAL-02 | T-06-03-02 | Automator scanner reads bounded fixture directories and never executes workflows | self-test | `./script/test.sh` | yes | pending |
| 06-03-03 | 03 | 3 | DISC-04, DISC-05, DISC-07 | T-06-03-03 | Docs describe registered confidence and no schedule evidence for Shortcuts and Automator | smoke/self-test | `./script/ci.sh` | yes | pending |

## Requirement Coverage

| Requirement | Status | Automated Evidence |
|-------------|--------|--------------------|
| DISC-01 | PLANNED | `./script/test.sh` verifies `JobConfidence` cases and model/presentation propagation. |
| DISC-02 | PLANNED | `./script/test.sh` verifies `JobOrigin` cases and conservative derivation for scanner fixtures. |
| DISC-03 | PLANNED | `./script/test.sh` verifies cron scanner parsing and scan notes with injected fixtures. |
| DISC-04 | PLANNED | `./script/test.sh` verifies Shortcuts scanner registered records from injected command output. |
| DISC-05 | PLANNED | `./script/test.sh` verifies Automator workflow records from injected fixture directories. |
| DISC-07 | PLANNED | `./script/test.sh` verifies source-specific scan notes on inventory results. |
| QUAL-01 | PLANNED | `./script/ci.sh` plus grep checks verify only read/list commands are present. |
| QUAL-02 | PLANNED | `./script/test.sh` uses injected paths and command runners, not live machine state. |

## Wave 0 Requirements

- [x] Existing `ActiveJobsCoreSelfTest` infrastructure covers all Phase 06 requirements.
- [x] No new test framework or external Swift dependency required.

## Manual-Only Verifications

All Phase 06 requirement behaviors have automated verification through the SwiftPM self-test and CI gate.

## Validation Sign-Off

- [x] All tasks have automated verification commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is under 60 seconds for the full Phase 06 suite.
- [x] `nyquist_compliant: true` is set in frontmatter.

Approval: approved 2026-05-08
