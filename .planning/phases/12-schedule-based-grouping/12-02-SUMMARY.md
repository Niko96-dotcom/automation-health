---
phase: 12-schedule-based-grouping
plan: 02
subsystem: ui
tags: [swift, swiftui, testing, self-test, scheduling, classification]

# Dependency graph
requires:
  - phase: 12-schedule-based-grouping
    plan: 01
    provides: SidebarScheduleKind, SidebarScheduleClassifier, SidebarGroupingMode.schedule
provides:
  - "Comprehensive self-test coverage for schedule classifier (time-of-day, frequency, evidence boundaries)"
  - "testGroupingModeShortcutKeys updated for 6 grouping modes"
  - "testSidebarGroupingModeLabelsAndOrders updated for 6 labels"
affects: [12-schedule-based-grouping, testing, self-test]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Schedule classifier tests follow existing SidebarTriggerClassifier test pattern: indirect via SidebarJobSection.sections() API"
    - "Set-based comparison for no-evidence sections to avoid ordering dependence"
    - "Calendar(identifier: .gregorian) with DateComponents for deterministic fixture dates"

key-files:
  created: []
  modified:
    - Sources/ActiveJobsCoreSelfTest/main.swift

key-decisions:
  - "Evidence boundary tests use Set comparison for no-evidence section flexibility"
  - "Integration test verifies 3-section output (morning, daily, no-evidence) with 6 empty sections excluded"
  - "Clock-time fallback test verifies earliest matched hour for multi-clock schedules"

requirements-completed: [GROUP-02, GROUP-03, GROUP-04]

# Metrics
duration: 5min
completed: 2026-05-11
---

# Phase 12 Plan 02: Schedule Classifier Self-Test Coverage Summary

**Four new self-test functions for schedule classification + updated grouping mode shortcut/label tests**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-11T09:18:00Z
- **Completed:** 2026-05-11T09:23:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- testGroupingModeShortcutKeys updated to expect 6 grouping modes with Cmd+6 mapped to Schedule
- testSidebarGroupingModeLabelsAndOrders updated to include "Schedule" in the label list (Rule 1 auto-fix)
- testScheduleClassifierTimeOfDay: verifies nextRun hour classification (Morning 8, Afternoon 14, Evening 20, Night 22/2) and clock-time regex fallback (12:00 → Afternoon, earliest of 01:00/04:00 → Night)
- testScheduleClassifierFrequency: verifies keyword detection from humanized schedule text (Every hour → Hourly, 0 10 * * * → Daily, Every week → Weekly, 0 10 15 * * → Monthly)
- testScheduleClassifierEvidenceBoundaries: verifies .registered/.candidate/.manual always → No schedule evidence; .scheduled with empty schedule → No schedule evidence; proves Pitfall 3 is solved (candidate with cron does not leak into Daily)
- testScheduleGroupingIntegration: verifies correct section ordering (time-of-day → frequency → no-evidence), correct job-to-section mapping, empty section exclusion, no-evidence section last

## Task Commits

Each task was committed atomically:

1. **Task 1: Update testGroupingModeShortcutKeys for 6 grouping modes** — `58f2c4d` (fix)
2. **Task 2: Add schedule classifier tests and grouping integration tests** — `93f043e` (test)

## Files Created/Modified
- `Sources/ActiveJobsCoreSelfTest/main.swift` — 127 lines added: updated testGroupingModeShortcutKeys (10 lines changed, 6 new 6th-mode assertions), updated testSidebarGroupingModeLabelsAndOrders (1 line), added 4 test function invocations + implementations (121 lines)

## Decisions Made
- Evidence boundary tests use Set-based comparison for "No schedule evidence" section to avoid ordering dependence across job fixtures
- Integration test explicitly verifies exactly 3 sections are produced (6 empty sections correctly excluded by sections() API)
- Clock-time fallback test includes multi-clock schedule ("01:00, 04:00") to verify earliest hour behavior

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed testSidebarGroupingModeLabelsAndOrders expecting 5 labels instead of 6**
- **Found during:** Task 1 execution
- **Issue:** Plan 01 added `.schedule` as 6th grouping mode but testSidebarGroupingModeLabelsAndOrders (line 480) still expected `["Source", "Origin", "Health", "Trigger", "Confidence"]` without "Schedule"
- **Fix:** Updated expected labels array to `["Source", "Origin", "Health", "Trigger", "Confidence", "Schedule"]`
- **Files modified:** `Sources/ActiveJobsCoreSelfTest/main.swift`
- **Commit:** `58f2c4d` — included in Task 1 commit

## Issues Encountered
- Pre-existing testSidebarGroupingModeLabelsAndOrders (line 480) also failed due to 6th mode — auto-fixed alongside testGroupingModeShortcutKeys per Rule 1. The plan only mentioned testGroupingModeShortcutKeys but both tests hardcoded 5 modes.
- Pre-existing compiler warnings (unused `root` in two fixture tests) are out of scope and not addressed.

## Known Stubs
None — all test fixtures exercise real classification logic through the public SidebarJobSection.sections() API; no hardcoded values or placeholders.

## Threat Flags
None — self-tests run in-process with no external dependencies; no new trust boundaries introduced.

## User Setup Required
None — no external service configuration required.

---
*Phase: 12-schedule-based-grouping*
*Completed: 2026-05-11*

## Self-Check: PASSED
- SUMMARY.md exists: ✓
- Commit 58f2c4d (Task 1): ✓
- Commit 93f043e (Task 2): ✓
- `swift build` passes with exit code 0: ✓
- `swift run ActiveJobsCoreSelfTest` outputs "ActiveJobsCoreSelfTest passed": ✓
- All acceptance criteria verified via grep: ✓
