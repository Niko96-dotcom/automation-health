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
| 06-01-01 | 01 | 1 | DISC-01, DISC-02, DISC-07 | T-06-01-01 | Model carries confidence, origin, and scan notes without source-specific view IO | self-test | `./script/test.sh` | yes | COVERED |
| 06-01-02 | 01 | 1 | DISC-01, DISC-02, DISC-07, QUAL-01 | T-06-01-02 | Existing scanners return scheduled confidence, conservative origins, and non-fatal notes | self-test | `./script/test.sh` | yes | COVERED |
| 06-01-03 | 01 | 1 | DISC-01, DISC-02, DISC-07 | T-06-01-03 | Store/presentation data exposes scan notes without direct scheduler reads in views | self-test/build | `./script/ci.sh` | yes | COVERED |
| 06-02-01 | 02 | 2 | DISC-03, DISC-07, QUAL-01, QUAL-02 | T-06-02-01 | Cron command runner uses only `crontab -l` and fixture runners in tests | self-test | `./script/test.sh` | yes | COVERED |
| 06-02-02 | 02 | 2 | DISC-03, QUAL-02 | T-06-02-02 | Cron parser handles user/system forms, special schedules, comments, and env lines from synthetic fixtures | self-test | `./script/test.sh` | yes | COVERED |
| 06-02-03 | 02 | 2 | DISC-03, DISC-07 | T-06-02-03 | Inventory includes cron scanner and reports source notes for missing/unreadable cron inputs | self-test/build | `./script/ci.sh` | yes | COVERED |
| 06-03-01 | 03 | 3 | DISC-04, DISC-07, QUAL-01, QUAL-02 | T-06-03-01 | Shortcuts scanner lists records with injected `shortcuts list --show-identifiers` and never runs shortcuts | self-test | `./script/test.sh` | yes | COVERED |
| 06-03-02 | 03 | 3 | DISC-05, DISC-07, QUAL-01, QUAL-02 | T-06-03-02 | Automator scanner reads bounded fixture directories and never executes workflows | self-test | `./script/test.sh` | yes | COVERED |
| 06-03-03 | 03 | 3 | DISC-04, DISC-05, DISC-07 | T-06-03-03 | Docs describe registered confidence and no schedule evidence for Shortcuts and Automator | smoke/self-test | `./script/ci.sh` | yes | COVERED |

## Requirement Coverage

| Requirement | Status | Automated Evidence |
|-------------|--------|--------------------|
| DISC-01 | COVERED | `testJobConfidenceAndOriginCases()` verifies `JobConfidence` cases; `./script/ci.sh` verifies model/presentation propagation compiles. |
| DISC-02 | COVERED | `testJobConfidenceAndOriginCases()` and `testExistingScannersPopulateScheduledConfidenceAndOrigins()` verify `JobOrigin` cases and conservative scanner derivation. |
| DISC-03 | COVERED | `testParsesUserCrontabEntriesWithInjectedRunner()`, `testParsesSystemCrontabEntriesFromFixtureFile()`, and `testCronScannerReportsSourceNotesForUnavailableInputs()` verify cron parsing and scan notes. |
| DISC-04 | COVERED | `testShortcutsScannerListsRegisteredShortcutsWithoutSchedulingEvidence()` and `testShortcutsScannerReportsCommandFailureAsScanNote()` verify registered Shortcuts inventory and failure notes. |
| DISC-05 | COVERED | `testAutomatorScannerListsWorkflowFixturesAsRegistered()` and `testAutomatorScannerReportsMissingWorkflowDirectoriesAsNotes()` verify bounded Automator inventory and missing-location notes. |
| DISC-07 | COVERED | `testInventoryAggregatesJobsAndScanNotes()`, cron, Shortcuts, and Automator failure/missing-input tests verify source-specific scan notes. |
| QUAL-01 | COVERED | `./script/ci.sh` passes; audit grep checks verified no cron edit/remove forms, no Shortcuts run/view/sign forms, and no scheduler IO in SwiftUI views. |
| QUAL-02 | COVERED | `./script/test.sh` uses injected paths and command runners, not live machine state. |

## Validation Audit 2026-05-08

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit evidence:
- `./script/ci.sh` passed.
- `! rg -n "crontab.*-e|crontab.*-r|Process.*crontab.*[^-]-[^l]" Sources/ActiveJobsCore/Services/CronScanner.swift` passed.
- `! rg -n 'shortcuts.*run|shortcuts.*view|shortcuts.*sign|\["run"|\["view"|\["sign"' Sources/ActiveJobsCore/Services/ShortcutsScanner.swift` passed.
- `! rg -n "crontab|shortcuts list|\\.workflow|Data\\(contentsOf:|FileManager\\.default\\.contentsOfDirectory|Process\\(" Sources/AutomationHealth/Views` passed.

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
