---
phase: 06-inventory-model-and-deterministic-sources
plan: 03
subsystem: core
tags: [shortcuts, automator, registered-inventory, fixtures]
requires:
  - phase: 06-inventory-model-and-deterministic-sources
    provides: Cron source ordering and shared inventory contract
provides:
  - Registered Shortcuts inventory through list-only command runner
  - Bounded Automator workflow inventory from user workflow locations
  - Documentation for registered inventory evidence limits
affects: [active-jobs-core, scanner-docs, readme]
tech-stack:
  added: []
  patterns: [registered confidence scanners, bounded directory enumeration]
key-files:
  created:
    - Sources/ActiveJobsCore/Services/ShortcutsScanner.swift
    - Sources/ActiveJobsCore/Services/AutomatorScanner.swift
  modified:
    - Sources/ActiveJobsCore/Models/ScheduledJob.swift
    - Sources/ActiveJobsCore/Services/JobScanning.swift
    - Sources/ActiveJobsCoreSelfTest/main.swift
    - docs/scheduled-job-sources.md
    - README.md
key-decisions:
  - "Shortcuts and Automator records are registered inventory, not proof of scheduling."
  - "Automator scanning is bounded to configured workflow directories and direct children."
patterns-established:
  - "Registered sources use explicit no-schedule-evidence schedule text."
  - "Workflow metadata parse failures are scan notes rather than fatal scanner failures."
requirements-completed: [DISC-04, DISC-05, DISC-07, QUAL-01, QUAL-02]
duration: 8 min
completed: 2026-05-08
---

# Phase 06 Plan 03: Registered Inventory Summary

**Shortcuts and Automator registered inventory with conservative confidence and bounded reads**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-08T16:36:30Z
- **Completed:** 2026-05-08T16:43:50Z
- **Tasks:** 4
- **Files modified:** 7

## Accomplishments

- Added `ShortcutsScanner` using `/usr/bin/shortcuts list --show-identifiers` through an injected command runner.
- Added `AutomatorScanner` for bounded direct-child workflow enumeration in `~/Library/Services` and `~/Library/Workflows`.
- Added `JobSource.shortcuts` and `JobSource.automator` after cron in deterministic source order.
- Covered successful and failing Shortcuts scans plus Automator workflow and missing-directory fixtures.
- Documented registered confidence and no-schedule-evidence limits in source docs and README.

## Task Commits

Task-level commits were not created in this run because the repository had pre-existing uncommitted changes. The working tree was kept intact and verified with `./script/ci.sh`.

## Files Created/Modified

- `Sources/ActiveJobsCore/Services/ShortcutsScanner.swift` - List-only registered Shortcuts scanner.
- `Sources/ActiveJobsCore/Services/AutomatorScanner.swift` - Bounded Automator workflow scanner.
- `Sources/ActiveJobsCore/Models/ScheduledJob.swift` - Added `shortcuts` and `automator` sources.
- `Sources/ActiveJobsCore/Services/JobScanning.swift` - Added registered scanners to live inventory.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Added Shortcuts and Automator fixture tests.
- `docs/scheduled-job-sources.md` - Documented Shortcuts and Automator limits.
- `README.md` - Added registered inventory support and limitation wording.

## Decisions Made

Registered sources use `.registered` confidence and explicit "no schedule evidence" schedule text so the UI never overclaims that listed Shortcuts or workflows are scheduled jobs.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 6 scanner coverage is implemented and ready for phase-level verification.

---
*Phase: 06-inventory-model-and-deterministic-sources*
*Completed: 2026-05-08*
