---
status: resolved
phase: 09-publication-verification-and-docs-polish
source: [09-02-PLAN.md, 09-01-SUMMARY.md, 07-VERIFICATION.md, 08-VERIFICATION.md, 08-HUMAN-UAT.md]
started: 2026-05-10T19:21:42Z
updated: 2026-05-10T19:21:42Z
---

# Phase 09 Human UAT

## Current Test

Publication smoke verification recorded from privacy-safe evidence on 2026-05-10. The app bundle was launched with `./script/build_and_run.sh --verify`; broad inventory, manual-record, grouping, collapse/search, navigation, and read-only behavior were verified through synthetic self-test fixtures and prior human-approved Phase 7/8 evidence without publishing live local scheduler data.

## Tests

### 1. Privacy scrub

expected: Publication scrub commands produce no unexpected public-surface findings.

result: passed - `09-01-SUMMARY.md` records no `.DS_Store` output, no unexpected `niko|com\.niko|/Users/niko` findings, and expected guidance-only sensitive-category matches.

### 2. Public visuals

expected: Public visuals use abstract Pulse Grid assets or explicitly synthetic screenshots only.

result: passed - README and `Assets/AppIcon/README.md` require abstract/synthetic visuals, `automation-health-icon-source.png` is the committed source art, and `./script/test_app_icon.sh` passed.

### 3. Launchd and Hermes cron

expected: Launchd and Hermes cron records still parse and render through normalized inventory where privacy-safe fixtures are available.

result: passed - `ActiveJobsCoreSelfTest` covers launchd plist parsing, Hermes cron metadata/output parsing, health summaries, and shared inventory composition using synthetic fixture data.

### 4. Broad inventory

expected: Cron, Shortcuts, Automator, candidate script, and manual record sources remain searchable/selectable where fixtures or safe local records exist.

result: passed - `ActiveJobsCoreSelfTest` covers cron, Shortcuts, Automator, candidate script, manual record, source ordering, search-facing presentation, and sidebar grouping behavior with synthetic data.

### 5. Manual records

expected: Manual records can be added, edited, and removed as app-owned metadata only.

result: passed - `ActiveJobsCoreSelfTest` covers create/update/delete in `ManualRecordStore`, scanner conversion to manual jobs, malformed JSON preservation, and presentation ID behavior. Phase 07 manual verification previously exercised the app UI with a synthetic manual record.

### 6. Sidebar grouping

expected: Source, Origin, Health, Trigger, and Confidence grouping modes remain stable.

result: passed - `ActiveJobsCoreSelfTest` covers grouping labels, ordering, launchd origin splitting, trigger classification, and confidence grouping.

### 7. Collapse/search

expected: Collapsed groups preserve selection context, and search reveals matching rows inside collapsed sections without mutating collapse state.

result: passed - `ActiveJobsCoreSelfTest` covers collapsed sections, retained IDs, search reveal, and hidden-selection navigation.

### 8. Focus styling

expected: Phase 8 custom focus cue remains visible and the oversized default blue rectangle remains absent.

result: passed - Phase 08 human UAT approved the visual/accessibility focus checklist on 2026-05-09; Phase 09 did not change the focus implementation.

### 9. Refresh

expected: Refresh preserves selection where possible, reports scan notes, and does not crash.

result: passed - `./script/ci.sh` and `./script/build_and_run.sh --verify` passed after the Phase 9 cleanup. Store/inventory self-tests cover scan notes and inventory refresh behavior with synthetic fixtures.

### 10. Read-only posture

expected: Smoke verification confirms no real scheduler files, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata were modified.

result: passed - verification used repository scripts, synthetic self-test fixtures, and app-owned manual-record coverage. No real scheduler files, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata were modified by this phase.

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
