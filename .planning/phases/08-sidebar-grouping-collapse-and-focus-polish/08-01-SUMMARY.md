---
phase: 08-sidebar-grouping-collapse-and-focus-polish
plan: 01
subsystem: ui
tags: [swiftui, swiftpm, sidebar, presentation, testing]
requires:
  - phase: 07-candidate-discovery-and-manual-records
    provides: Candidate and manual inventory records consumed by sidebar presentation logic
provides:
  - Importable AutomationHealthCore presentation target
  - Deterministic sidebar grouping, trigger classification, collapse state, and navigation helpers
  - Self-test coverage for non-UI sidebar behavior
affects: [sidebar, navigation, activejobscore-selftest]
tech-stack:
  added: []
  patterns: [shared presentation target, pure sidebar helper types, executable self-test coverage]
key-files:
  created:
    - Sources/AutomationHealthCore/JobPresentation.swift
  modified:
    - Package.swift
    - Sources/AutomationHealth/Views/ContentView.swift
    - Sources/AutomationHealth/Views/SidebarView.swift
    - Sources/AutomationHealth/Views/DetailView.swift
    - Sources/AutomationHealth/Stores/JobStore.swift
    - Sources/ActiveJobsCoreSelfTest/main.swift
key-decisions:
  - "Moved sidebar presentation helpers into AutomationHealthCore so app and self-test share one implementation."
  - "Kept trigger classification presentation-only and conservative for registered/candidate/manual records."
patterns-established:
  - "Sidebar sections are built from pure presentation data with stable SidebarSectionID values."
  - "Collapse state is an in-memory value keyed by grouping mode plus group key."
requirements-completed: [SIDE-02, SIDE-03, SIDE-04, SIDE-05]
duration: 10min
completed: 2026-05-08
---

# Phase 08 Plan 01 Summary

**Shared sidebar presentation core with deterministic grouping, conservative trigger labels, collapse state, and hidden-row navigation tests**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-08T18:49:06Z
- **Completed:** 2026-05-08T18:55:36Z
- **Tasks:** 4
- **Files modified:** 6

## Accomplishments

- Added the internal `AutomationHealthCore` SwiftPM target and library product.
- Moved `JobPresentation`, sidebar summaries, sectioning, navigation, and new Phase 8 helper types into the shared target.
- Added deterministic grouping by Source, Origin, Health, Trigger, and Confidence.
- Added fixture-driven self-tests for labels/order, origin grouping, trigger evidence boundaries, collapse/search reveal, and hidden-selection navigation.

## Task Commits

Atomic task commits were not created in this execution because the working tree already contained overlapping uncommitted Phase 6/7 source changes in the same files. The implementation preserved that dirty state and left all changes uncommitted for user review.

## Files Created/Modified

- `Package.swift` - Adds `AutomationHealthCore` and updates executable dependencies.
- `Sources/AutomationHealthCore/JobPresentation.swift` - Shared presentation, grouping, trigger, collapse, and navigation helpers.
- `Sources/AutomationHealth/Views/ContentView.swift` - Imports the shared presentation target.
- `Sources/AutomationHealth/Views/SidebarView.swift` - Imports the shared presentation target.
- `Sources/AutomationHealth/Views/DetailView.swift` - Imports the shared presentation target.
- `Sources/AutomationHealth/Stores/JobStore.swift` - Imports the shared presentation target.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Adds Phase 8 presentation helper tests.

## Decisions Made

- Used `AutomationHealthCore` rather than keeping app-local presentation code so the existing self-test executable can cover sidebar behavior.
- Tightened cron evidence detection so arbitrary five-word "no schedule evidence" text does not look like a cron expression.

## Deviations from Plan

- Atomic commits were skipped due to the pre-existing overlapping dirty working tree.

## Issues Encountered

- The first trigger classifier treated generic five-word strings as cron-like evidence. The self-test caught this, and the detector now validates cron characters before classifying a string as a five-field cron expression.

## User Setup Required

None.

## Self-Check: PASSED

- `swift build` passed.
- `./script/test.sh` passed.
- Presentation-core IO grep passed.

