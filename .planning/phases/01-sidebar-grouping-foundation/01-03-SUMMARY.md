---
phase: 01-sidebar-grouping-foundation
plan: 01-03
subsystem: testing
tags: [swiftpm, self-test, source-order]
requires:
  - phase: 01-01
    provides: Source-ordered sidebar section data
  - phase: 01-02
    provides: Grouped sidebar rendering
provides:
  - JobSource source-order regression check
  - Build validation evidence for grouped sidebar changes
affects: [sidebar, testing, phase-03-sidebar-polish]
tech-stack:
  added: []
  patterns: [executable self-test coverage]
key-files:
  created: []
  modified:
    - Sources/ActiveJobsCoreSelfTest/main.swift
key-decisions:
  - "Validate source order in ActiveJobsCoreSelfTest instead of importing app-target presentation helpers."
patterns-established:
  - "Use the existing executable self-test target for stable core contracts that app presentation relies on."
requirements-completed: [ORG-05, QUAL-03]
duration: 6 min
completed: 2026-05-08
---

# Phase 01 Plan 03: Grouping Validation Summary

**Source-order self-test plus build validation for grouped sidebar behavior.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-08T09:21:00Z
- **Completed:** 2026-05-08T09:23:09Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added `testJobSourceOrderMatchesSidebarGroupingContract()` to assert `JobSource.allCases == [.launchd, .hermesCron]`.
- Checked source display names used by source headers: `["launchd", "Hermes cron"]`.
- Ran `swift build` successfully after the grouping changes.

## Task Commits

1. **Task 1: Add source order self-test** - `5965413` (test)
2. **Task 2: Run app compile validation** - `5965413` (test)
3. **Task 3: Run the existing local CI gate** - documented below

## Files Created/Modified

- `Sources/ActiveJobsCoreSelfTest/main.swift` - Adds source-order and display-name regression coverage.

## Decisions Made

- Kept validation in `ActiveJobsCoreSelfTest` because it already depends on `ActiveJobsCore`, where `JobSource` lives.
- Did not broaden scope into fixing unrelated date-relative humanizer behavior during this phase.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `swift run ActiveJobsCoreSelfTest` failed with an unrelated pre-existing date-sensitive assertion: `ActiveJobsCoreSelfTest/main.swift:225: Fatal error: Expectation failed: tomorrow next run`.
- `./script/ci.sh` exited 133 for the same failure after `swift build` passed. The failing command was `swift run ActiveJobsCoreSelfTest` via `./script/test.sh`.
- The failure is not caused by the new source-order assertion; it occurs later in `testHumanizesSchedulesAndRunTimes()`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The grouping contract is protected by a source-order self-test, and the app target compiles. The existing date-sensitive self-test failure should be addressed before relying on the full local CI gate as a release signal.

## Self-Check: PASSED

- `swift build` passed.
- `Package.swift` still has no package dependencies.
- `ContentView.swift` and `SidebarView.swift` contain no scanner IO APIs.
- The local CI failure was recorded with the exact command and failure line as required by the plan.

---
*Phase: 01-sidebar-grouping-foundation*
*Completed: 2026-05-08*
