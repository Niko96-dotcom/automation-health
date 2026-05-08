---
phase: 05
slug: visual-identity-and-icon-pipeline
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
updated: 2026-05-08
---

# Phase 05 - Validation Strategy

Per-phase validation contract for feedback sampling during execution and retroactive Nyquist coverage.

Note: Phase 05 originally planned the source-art metaphor as Pulse Calendar. The later quick task `260508-o6e` replaced the committed source art and README contract with the current Pulse Grid direction while preserving the VIS-01 through VIS-03 requirements. This validation file tests the current committed artifact contract and deterministic icon pipeline.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Bash smoke/integration tests plus SwiftPM executable self-test |
| Config file | none |
| Quick run command | `./script/test.sh` |
| Full suite command | `./script/ci.sh && ./script/test_app_icon.sh --bundle` |
| Estimated runtime | ~20 seconds quick, ~60 seconds full |

## Sampling Rate

- After every task commit: Run `./script/test.sh`.
- After every plan wave: Run `./script/ci.sh && ./script/test_app_icon.sh --bundle`.
- Before `$gsd-verify-work`: Full suite must be green.
- Max feedback latency: 60 seconds for Phase 05 validation.

## Generated Tests

| File | Type | Command | Coverage |
|------|------|---------|----------|
| `script/test_app_icon.sh` | smoke/integration | `./script/test_app_icon.sh` | Source-art README contract, source PNG dimensions, generated iconset dimensions, `.icns` existence, static bundle wiring, docs, privacy string checks |
| `script/test_app_icon.sh` | integration | `./script/test_app_icon.sh --bundle` | Local app bundle icon resource copy and `CFBundleIconFile` plist value |

`script/test.sh` runs `script/test_app_icon.sh` after `ActiveJobsCoreSelfTest`, so the standard local and CI test path covers the non-launching icon contract.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | VIS-01 | T-05-01-01 / T-05-01-04 | Prompt and docs reject private data, terminal output, and required API/CLI generation | smoke | `./script/test_app_icon.sh` | yes | green |
| 05-01-02 | 01 | 1 | VIS-01 | T-05-01-01 / T-05-01-02 | Source PNG exists, is square, is at least 1024px, and has no private-looking embedded strings | smoke | `./script/test_app_icon.sh` | yes | green |
| 05-01-03 | 01 | 1 | VIS-01 | T-05-01-03 | Selection notes are complete, have no `TBD`, and include the required privacy statement | smoke | `./script/test_app_icon.sh` | yes | green |
| 05-02-01 | 02 | 2 | VIS-03 | T-05-02-01 / T-05-02-05 | Generator is executable, local-only, source-art driven, and wired to the expected `.icns` output | integration | `./script/test_app_icon.sh` | yes | green |
| 05-02-02 | 02 | 2 | VIS-03 | T-05-02-01 / T-05-02-03 | Generator creates the full macOS iconset matrix and non-empty `AutomationHealth.icns` from committed source art | integration | `./script/test_app_icon.sh` | yes | green |
| 05-02-03 | 02 | 2 | VIS-02 | T-05-02-02 / T-05-02-04 | Bundle builder copies `AutomationHealth.icns` into `Contents/Resources` and declares `CFBundleIconFile` | integration | `./script/test_app_icon.sh --bundle` | yes | green |
| 05-02-04 | 02 | 2 | VIS-02, VIS-03 | T-05-02-03 / T-05-02-05 | Docs describe local regeneration and verification with no API key, secret, network access, signing, or notarization requirement | smoke | `./script/test_app_icon.sh` | yes | green |

## Requirement Coverage

| Requirement | Status | Automated Evidence |
|-------------|--------|--------------------|
| VIS-01 | COVERED | `script/test_app_icon.sh` verifies the copy-paste prompt, current Pulse Grid source-art contract, negative constraints, source path, complete selection notes, source PNG dimensions, and privacy string checks. |
| VIS-02 | COVERED | `script/test_app_icon.sh --bundle` runs the existing bundle builder, verifies `dist/AutomationHealth.app/Contents/Resources/AutomationHealth.icns`, and confirms `CFBundleIconFile` is `AutomationHealth.icns`. |
| VIS-03 | COVERED | `script/test_app_icon.sh` runs `script/generate_app_icon.sh`, checks all 10 expected iconset PNG dimensions, and verifies the generated `.icns` is non-empty. |

## Wave 0 Requirements

- [x] `script/test_app_icon.sh` - focused Phase 05 icon validation.
- [x] `script/test.sh` - standard test runner invokes the Phase 05 icon validation.
- [x] No framework install required.

## Manual-Only Verifications

All Phase 05 requirement behaviors have automated verification.

## Validation Audit 2026-05-08

| Metric | Count |
|--------|-------|
| Gaps found | 3 |
| Resolved | 3 |
| Escalated | 0 |
| Manual-only | 0 |

## Validation Sign-Off

- [x] All tasks have automated verification commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is under 60 seconds for the full Phase 05 suite.
- [x] `nyquist_compliant: true` is set in frontmatter.

Approval: approved 2026-05-08
