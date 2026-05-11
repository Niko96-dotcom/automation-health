---
phase: 12-schedule-based-grouping
plan: 01
subsystem: ui
tags: [swift, swiftui, sidebar, grouping, scheduling, classification]

# Dependency graph
requires:
  - phase: 08-grouped-sidebar-sections
    provides: SidebarGroupingMode infrastructure, groupDefinitions pattern, SidebarTriggerClassifier pattern
provides:
  - SidebarScheduleKind public enum with 9 cases (morning-night, hourly-monthly, noScheduleEvidence)
  - SidebarScheduleClassifier private enum with confidence gate, time-of-day, clock-time fallback, frequency detection
  - SidebarGroupingMode.schedule case with label "Schedule"
  - Cmd+6 keyboard shortcut for schedule grouping mode
affects: [12-schedule-based-grouping, sidebar, navigation, keyboard-shortcuts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Schedule classifier follows SidebarTriggerClassifier pattern: private enum with static kind(for:) method"
    - "Time-of-day classification via Calendar.current.component(.hour) with switch on hour ranges"
    - "Clock-time regex fallback using NSRegularExpression pattern \b(\d{1,2}):(\d{2})\b"
    - "Frequency keyword detection via lowercased scheduleText contains checks"

key-files:
  created: []
  modified:
    - Sources/AutomationHealthCore/JobPresentation.swift
    - Sources/AutomationHealth/App/AutomationHealthApp.swift
    - Sources/ActiveJobsCoreSelfTest/main.swift

key-decisions:
  - "Time-of-day ranges: Morning (4-11), Afternoon (12-17), Evening (18-21), Night (0-3,22-23) per D-01"
  - "Only .scheduled confidence jobs eligible for time-of-day/frequency classification per D-08"
  - "Time-of-day classification takes priority over frequency classification per D-09"
  - "'No schedule evidence' section always appears last per D-04"
  - "Schedule grouping mode added as 6th case after Confidence, preserving Cmd+1..5 shortcuts per D-12"
  - "Classifier tested indirectly through SidebarJobSection.sections() API, following existing SidebarTriggerClassifier pattern"

patterns-established:
  - "Private enum classifier pattern: confidence gate → time-of-day → clock-time regex → frequency keywords → fallthrough"
  - "Schedule grouping sections use SidebarScheduleKind.allCases to generate group definitions"

requirements-completed: [GROUP-01, GROUP-02, GROUP-03, GROUP-04]

# Metrics
duration: 17min
completed: 2026-05-11
---

# Phase 12 Plan 01: Schedule-Based Grouping Summary

**Schedule grouping mode with time-of-day and frequency classification, gated on .scheduled confidence, accessible via Cmd+6**

## Performance

- **Duration:** 17 min
- **Started:** 2026-05-11T08:52:05Z
- **Completed:** 2026-05-11T09:09:30Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- SidebarScheduleKind public enum with 9 classification cases (Morning/Night time-of-day, Hourly-Monthly frequency, No schedule evidence)
- SidebarScheduleClassifier private enum with confidence gate, nextRun hour extraction, clock-time regex fallback, and frequency keyword detection
- SidebarGroupingMode.schedule case wired into groupDefinitions, SidebarJobSummary, and sidebar picker (auto-inherited via allCases)
- Cmd+6 keyboard shortcut registered in CommandMenu for schedule grouping mode
- Self-test integration verifying time-of-day, frequency, and noScheduleEvidence section classification

## Task Commits

Each task was committed atomically:

1. **Task 1: Add SidebarScheduleKind enum and SidebarScheduleClassifier** — `c65edd6` (test/RED), `97aa443` (feat/GREEN)
2. **Task 2: Wire .schedule into SidebarGroupingMode, groupDefinitions, and SidebarJobSummary** — `4e8730b` (test/RED), `6f6ba0b` (feat/GREEN)
3. **Task 3: Add Cmd+6 keyboard shortcut for Schedule grouping mode** — `efc5338` (feat)

## Files Created/Modified
- `Sources/AutomationHealthCore/JobPresentation.swift` — Added SidebarScheduleKind enum (9 cases with titles), SidebarScheduleClassifier private enum (confidence gate, time-of-day, clock-time regex, frequency detection), .schedule case in SidebarGroupingMode, .schedule branch in groupDefinitions, .schedule in SidebarJobSummary subtitle switch
- `Sources/AutomationHealth/App/AutomationHealthApp.swift` — Added "Group by Schedule" button with .keyboardShortcut("6") in CommandMenu View section
- `Sources/ActiveJobsCoreSelfTest/main.swift` — Added testSidebarScheduleGroupingModeAndSections integration test

## Decisions Made
- Classifier tested indirectly through `SidebarJobSection.sections()` API rather than direct calls, consistent with existing `SidebarTriggerClassifier` pattern (file-private enum, tested via public sections API)
- `testSidebarGroupingModeLabelsAndOrders` and `testGroupingModeShortcutKeys` now fail because they hardcode 5 modes — acknowledged as expected breakage deferred to Plan 02 per plan documentation
- Clock-time regex fallback uses first match only (not all matches) from raw schedule string — matches plan spec for "earliest matched time"

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- Initial TDD test code attempted direct `SidebarScheduleClassifier.kind(for:)` calls, but classifier is file-private (following SidebarTriggerClassifier pattern). Reverted and restructured tests to use `SidebarJobSection.sections()` integration approach. This matches how SidebarTriggerClassifier is tested.
- Pre-existing tests (`testSidebarGroupingModeLabelsAndOrders`, `testGroupingModeShortcutKeys`) fail because they expect exactly 5 grouping modes. These are documented in the plan as deferred to Plan 02.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Plan 02 can update the pre-existing tests (`testSidebarGroupingModeLabelsAndOrders`, `testGroupingModeShortcutKeys`) to expect 6 modes
- Schedule grouping mode is fully functional — classification logic, UI integration, and keyboard shortcut are all wired
- No blockers or concerns for continuation

---
*Phase: 12-schedule-based-grouping*
*Completed: 2026-05-11*

## Self-Check: PASSED
- SUMMARY.md exists: ✓
- All 5 commits verified: c65edd6, 97aa443, 4e8730b, 6f6ba0b, efc5338 ✓
- `swift build` passes with exit code 0 ✓
