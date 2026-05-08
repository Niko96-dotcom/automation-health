---
phase: 08
slug: sidebar-grouping-collapse-and-focus-polish
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
---

# Phase 08 - Validation Strategy

Per-phase validation contract for sidebar grouping, collapsible sections, visible-row keyboard navigation, and custom focus polish.

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
- Max feedback latency: 60 seconds for Phase 08 validation.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | SIDE-03, SIDE-04, SIDE-05 | T-08-03 | Grouping helpers use existing `ScheduledJob` presentation fields and deterministic source/origin/health/trigger/confidence order | self-test | `./script/test.sh` | yes | pending |
| 08-01-02 | 01 | 1 | SIDE-01, SIDE-02 | T-08-04 / T-08-05 | Collapse state hides rows from visible navigation without clearing selected job IDs | self-test | `./script/test.sh` | yes | pending |
| 08-01-03 | 01 | 1 | SIDE-02 | T-08-05 | Keyboard navigation skips collapsed and search-hidden rows and handles hidden selected IDs predictably | self-test | `./script/test.sh` | yes | pending |
| 08-02-01 | 02 | 2 | SIDE-03, SIDE-04 | T-08-02 / T-08-03 | SwiftUI sidebar uses presentation sections and in-memory grouping state without scanner/file IO | build/grep | `./script/ci.sh` | yes | pending |
| 08-02-02 | 02 | 2 | SIDE-01, SIDE-05 | T-08-04 | Section headers toggle collapse, show filtered counts, and provide concise source/origin help without becoming selectable jobs | build/manual | `./script/ci.sh` | yes | pending |
| 08-02-03 | 02 | 2 | SIDE-01, SIDE-02 | T-08-04 / T-08-06 | Search temporarily reveals matching rows and clearing search restores in-memory collapsed state without persisted preferences | self-test/manual | `./script/ci.sh` | yes | pending |
| 08-03-01 | 03 | 3 | SIDE-06, SIDE-07 | T-08-05 | Custom focus cue replaces the oversized default blue rectangle while remaining visible to keyboard users | build/manual | `./script/ci.sh` | yes | pending |
| 08-03-02 | 03 | 3 | SIDE-06, SIDE-07 | T-08-05 | Selection and focus remain visually distinct in active/inactive and dark/light sidebar states | manual | `./script/build_and_run.sh --verify` | yes | pending |
| 08-03-03 | 03 | 3 | SIDE-01, SIDE-02, SIDE-03, SIDE-04, SIDE-05, SIDE-06, SIDE-07 | T-08-01 / T-08-02 | Final CI and grep confirm read-only behavior and no view-layer scanner IO regressions | ci/grep | `./script/ci.sh` | yes | pending |

## Requirement Coverage

| Requirement | Validation Evidence |
|-------------|---------------------|
| SIDE-01 | Self-tests and manual checks verify collapsing/expanding sections leaves `selectedJobID` and detail display coherent. |
| SIDE-02 | Self-tests verify visible-row navigation excludes collapsed/search-hidden rows and handles hidden selected records. |
| SIDE-03 | Self-tests verify grouping modes and labels exactly `Source`, `Origin`, `Health`, `Trigger`, and `Confidence`. |
| SIDE-04 | Self-tests verify deterministic group ordering and stable section identities. |
| SIDE-05 | Origin grouping tests verify `launchd` records split by `JobOrigin` while row subtitles still show scheduler source. |
| SIDE-06 | Manual visual verification confirms the oversized default blue focus rectangle is replaced in the sidebar. |
| SIDE-07 | Manual keyboard/high-contrast verification confirms a visible custom focus cue remains available. |

## Wave 0 Requirements

- [x] Existing `ActiveJobsCoreSelfTest` infrastructure covers Phase 08 non-UI grouping/navigation helper tests.
- [x] Existing `./script/ci.sh` covers build and self-test execution.
- [x] Existing `script/build_and_run.sh --verify` covers local app bundle verification.
- [x] No new test framework or external Swift dependency required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Grouping control placement and section disclosure affordance | SIDE-01, SIDE-03, SIDE-04, SIDE-05 | The project has no XCTest/UI automation target. | Launch the app, switch through all grouping modes, collapse/expand sections, and confirm counts/order/labels match the UI-SPEC and context. |
| Search with collapsed sections | SIDE-01, SIDE-02 | Requires interactive sidebar state and search field behavior. | Collapse a section, search for a row in that section, confirm the row appears, clear search, and confirm prior collapse state returns. |
| Keyboard navigation through hidden rows | SIDE-02, SIDE-07 | Current coverage can test helper logic, but end-to-end key handling is manual. | Focus the sidebar, collapse/filter rows, use Up/Down, and confirm selection moves only to visible rows. |
| Custom focus styling | SIDE-06, SIDE-07 | The project has no screenshot assertion workflow. | Verify the default blue rectangle is gone and a restrained visible focus cue remains in dark mode, light mode, inactive window state, and high-contrast mode where practical. |

## Validation Sign-Off

- [x] All tasks have automated verification commands or explicit manual verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is under 60 seconds for the full Phase 08 suite.
- [x] `nyquist_compliant: true` is set in frontmatter.

Approval: pending
