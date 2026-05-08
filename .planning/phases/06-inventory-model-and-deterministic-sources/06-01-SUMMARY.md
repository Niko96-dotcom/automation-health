---
phase: 06-inventory-model-and-deterministic-sources
plan: 01
subsystem: core
tags: [inventory, scanners, presentation, scan-notes]
requires:
  - phase: 05-visual-identity-and-icon-pipeline
    provides: Polished app shell and existing scanner UI surface
provides:
  - Source-independent job confidence and origin model fields
  - JobScanResult aggregation with source scan notes
  - Store and presentation propagation for scan notes, confidence, and origin
affects: [active-jobs-core, automation-health-ui, scanner-docs]
tech-stack:
  added: []
  patterns: [source-neutral scanner result, scan-note aggregation]
key-files:
  created: []
  modified:
    - Sources/ActiveJobsCore/Models/ScheduledJob.swift
    - Sources/ActiveJobsCore/Services/JobScanning.swift
    - Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift
    - Sources/ActiveJobsCore/Services/HermesCronScanner.swift
    - Sources/AutomationHealth/Stores/JobStore.swift
    - Sources/AutomationHealth/Models/JobPresentation.swift
    - Sources/AutomationHealth/Views/ContentView.swift
    - Sources/AutomationHealth/Views/SidebarView.swift
    - Sources/ActiveJobsCoreSelfTest/main.swift
    - docs/scanner-extension-guide.md
key-decisions:
  - "Scan limitations are carried as source-specific ScanNote values rather than view-layer scanner branches."
  - "Existing launchd and Hermes cron records keep scheduled confidence after the model migration."
patterns-established:
  - "Scanners return JobScanResult so jobs and non-fatal source notes travel together."
  - "Presentation helpers expose confidence and origin display names without source-specific SwiftUI IO."
requirements-completed: [DISC-01, DISC-02, DISC-07, QUAL-01, QUAL-02]
duration: 12 min
completed: 2026-05-08
---

# Phase 06 Plan 01: Inventory Contract Summary

**Source-neutral confidence, origin, and scan-note contract for all scanner results**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-08T16:31:00Z
- **Completed:** 2026-05-08T16:43:50Z
- **Tasks:** 4
- **Files modified:** 10

## Accomplishments

- Added `JobConfidence`, `JobOrigin`, `ScanNoteSeverity`, `ScanNote`, and `JobScanResult` below the view layer.
- Migrated launchd and Hermes scanners plus inventory aggregation to return `JobScanResult`.
- Published `scanNotes` through `JobStore` and surfaced note counts in the sidebar footer.
- Added fixture coverage for confidence/origin cases, note aggregation, and migrated scanner defaults.

## Task Commits

Task-level commits were not created in this run because the repository had pre-existing uncommitted changes overlapping `Sources/ActiveJobsCoreSelfTest/main.swift`. The working tree was kept intact and verified with `./script/ci.sh`.

## Files Created/Modified

- `Sources/ActiveJobsCore/Models/ScheduledJob.swift` - Added confidence, origin, and scan-note model types.
- `Sources/ActiveJobsCore/Services/JobScanning.swift` - Added result aggregation and note preservation.
- `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` - Returned scheduled confidence and derived launchd origin.
- `Sources/ActiveJobsCore/Services/HermesCronScanner.swift` - Returned scheduled user-authored Hermes jobs.
- `Sources/AutomationHealth/Stores/JobStore.swift` - Published scan notes beside presentation rows.
- `Sources/AutomationHealth/Models/JobPresentation.swift` - Added confidence and origin display/search fields.
- `Sources/AutomationHealth/Views/ContentView.swift` - Passed scan notes into the sidebar.
- `Sources/AutomationHealth/Views/SidebarView.swift` - Displayed scan-note counts and help text in the footer.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Added model and aggregation coverage.
- `docs/scanner-extension-guide.md` - Documented the expanded scanner contract.

## Decisions Made

Scan failures that prevent the whole inventory refresh are represented as an error scan note in `JobStore`; source-specific limitations continue to live in `JobScanResult.notes`.

## Deviations from Plan

Path normalization was added to launchd origin detection so temporary fixture paths under `/var` and `/private/var` classify consistently as user-authored.

**Total deviations:** 1 auto-fixed compatibility issue.
**Impact on plan:** No scope expansion; the fix makes the planned origin heuristic deterministic on macOS temp paths.

## Issues Encountered

Swift needed an explicit `[ScheduledJob]` annotation in the Hermes compact-map migration, and a fixture helper recursion was corrected before the self-test passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Cron, Shortcuts, and Automator scanners can build on the `JobScanResult`, confidence, origin, and scan-note contract.

---
*Phase: 06-inventory-model-and-deterministic-sources*
*Completed: 2026-05-08*
