---
phase: 07-candidate-discovery-and-manual-records
plan: 02
subsystem: core-ui
tags: [manual-records, persistence, swiftui, app-owned-data]
requires:
  - phase: 07-candidate-discovery-and-manual-records
    provides: Candidate scripts source and inventory extension point
provides:
  - App-owned manual record JSON persistence
  - Manual inventory scanner and Manual confidence records
  - Store-level add, edit, remove facade with selection behavior
  - Native SwiftUI manual record sheet and manual-only detail actions
affects: [active-jobs-core, automation-health-ui, scanner-docs, readme]
tech-stack:
  added: []
  patterns: [app-owned JSON store, store-owned mutation facade, manual-only UI actions]
key-files:
  created:
    - Sources/ActiveJobsCore/Services/ManualRecordStore.swift
  modified:
    - Sources/ActiveJobsCore/Models/ScheduledJob.swift
    - Sources/ActiveJobsCore/Services/JobScanning.swift
    - Sources/AutomationHealth/Stores/JobStore.swift
    - Sources/AutomationHealth/Views/ContentView.swift
    - Sources/AutomationHealth/Views/DetailView.swift
    - Sources/ActiveJobsCoreSelfTest/main.swift
    - docs/scheduled-job-sources.md
    - README.md
key-decisions:
  - "Manual records persist only in app-owned Application Support JSON."
  - "SwiftUI views call JobStore manual methods and never read or write manual JSON directly."
patterns-established:
  - "Manual scanner failures become warning ScanNote values without deleting malformed user data."
  - "Manual edit/remove controls are gated to JobSource.manualRecords."
requirements-completed: [MAN-01, MAN-02, MAN-03]
duration: 16 min
completed: 2026-05-08
---

# Phase 07 Plan 02: Manual Records Summary

**App-owned Manual records with JSON persistence, store facade, and manual-only SwiftUI mutation controls**

## Performance

- **Duration:** 16 min
- **Started:** 2026-05-08T17:53:00Z
- **Completed:** 2026-05-08T18:09:08Z
- **Tasks:** 5
- **Files modified:** 9

## Accomplishments

- Added `JobSource.manualRecords` with display name `Manual records`.
- Added `ManualAutomationRecord`, `ManualRecordDraft`, `ManualRecordStore`, and `ManualRecordScanner`.
- Persisted manual records at `~/Library/Application Support/AutomationHealth/manual-records.json`.
- Added `JobStore.addManualRecord`, `updateManualRecord`, and `removeManualRecord` with create/edit/remove selection behavior.
- Added a native SwiftUI create/edit sheet and manual-only edit/remove controls in detail.
- Added self-tests for create/update/delete, manual conversion, and malformed JSON preservation.

## Task Commits

Task-level commits were not created in this run because the repository started with pre-existing uncommitted Phase 6 changes that overlap Phase 7 files. The working tree was kept intact and verified with `./script/test.sh`, `./script/ci.sh`, and `./script/build_and_run.sh --verify`.

## Files Created/Modified

- `Sources/ActiveJobsCore/Services/ManualRecordStore.swift` - Codable manual record persistence, scanner, and ScheduledJob conversion.
- `Sources/ActiveJobsCore/Models/ScheduledJob.swift` - Added Manual records source.
- `Sources/ActiveJobsCore/Services/JobScanning.swift` - Added Manual scanner composition with shared store injection.
- `Sources/AutomationHealth/Stores/JobStore.swift` - Added manual create/edit/remove facade and preferred selection refresh behavior.
- `Sources/AutomationHealth/Views/ContentView.swift` - Added Add Manual Record toolbar action and shared create/edit sheet.
- `Sources/AutomationHealth/Views/DetailView.swift` - Added manual-only edit/remove actions and destructive confirmation.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Added manual store, scanner, malformed JSON, and inventory tests.
- `docs/scheduled-job-sources.md` - Added Manual Records source documentation.
- `README.md` - Added manual-record privacy and limitation wording.

## Decisions Made

Manual records convert to `.manualRecords` jobs with `.manual` confidence and never receive last-run, next-run, or scheduler state beyond the explicit `manual` state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Queued manual refresh while a scan is already running**
- **Found during:** Manual UI verification after Task 4
- **Issue:** `JobStore.refresh(preferredSelectionID:)` returned early during an active scan, so a manual remove could leave stale presentation rows until the next rescan.
- **Fix:** Added a single pending refresh slot that preserves the preferred selection and runs immediately after the active scan completes.
- **Files modified:** `Sources/AutomationHealth/Stores/JobStore.swift`
- **Verification:** `./script/ci.sh`
- **Committed in:** Not committed; see Task Commits note.

---

**Total deviations:** 1 auto-fixed blocking issue.
**Impact on plan:** The fix is required to satisfy the manual selection/refresh contract and does not expand scope.

## Issues Encountered

Swift required explicit `try` markers around manual draft name validation, and the non-throwing self-test assertion helper required precomputing throwing load/read results.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Candidate and Manual records are available for shared presentation, search, sidebar, and detail integration.

---
*Phase: 07-candidate-discovery-and-manual-records*
*Completed: 2026-05-08*
