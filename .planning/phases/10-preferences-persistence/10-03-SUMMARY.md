---
phase: 10-preferences-persistence
plan: 03
subsystem: preferences
tags: [license, self-test, codable, configuration, swiftpm]

# Dependency graph
requires:
  - 10-01
provides:
  - MIT LICENSE with correct copyright holder (Niko) per D-06
  - Self-test coverage for SidebarCollapseState Codable round-trip
  - Self-test coverage for SidebarGroupingMode Codable round-trip
  - Self-test coverage for CandidateScriptScanner.Configuration.default v1.1 values
affects: [10-preferences-persistence-plan-04, distribution-requirements, ci-pipeline]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Self-test Codable round-trip pattern: JSONEncoder → JSONDecoder → assert equality (reusable for future Codable types)
    - Self-test enum round-trip pattern: iterate allCases, encode/decode each, verify nil for invalid raw values
    - Self-test config defaults pattern: compare static .default against expected constants

key-files:
  modified:
    - LICENSE
    - Sources/ActiveJobsCoreSelfTest/main.swift

key-decisions:
  - "LICENSE copyright changed from 'Automation Health contributors' to 'Niko' per D-06 decision — personal copyright, MIT terms preserved"
  - "Self-tests added for SidebarCollapseState, SidebarGroupingMode Codable, and CandidateScriptScanner.Configuration.default — automated regression guard for Plan 01 types"
  - "No new imports needed — ActiveJobsCoreSelfTest already imports ActiveJobsCore and AutomationHealthCore"

requirements-completed: [DIST-01]

# Metrics
duration: 4min
completed: 2026-05-11
---

# Phase 10 Plan 3: LICENSE Update and Self-Test Coverage Summary

**Updated MIT LICENSE copyright line per D-06, and added 3 self-test functions verifying Codable round-trips and scan configuration defaults created in Plan 01.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-11T00:50:00+02:00
- **Completed:** 2026-05-11T00:54:00+02:00
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `LICENSE` line 3 now reads `Copyright (c) 2026 Niko` — replaced "Automation Health contributors" per D-06. MIT license text and warranty disclaimer preserved unchanged.
- `testCollapseStateCodableRoundTrip` added — verifies JSON encode/decode round-trip for `SidebarCollapseState` with both populated (2 collapsed sections) and empty states. Asserts `collapsedSectionIDs` equality, `isCollapsed()` correctness, and non-collapsed section preservation.
- `testGroupingModeCodableRoundTrip` added — iterates all 5 `SidebarGroupingMode` cases (source, origin, health, trigger, confidence), encodes each to JSON, decodes back, and asserts equality. Also verifies that an invalid raw value (`"nonexistent_mode"`) decodes to `nil` for safe `rawValue:` initialization fallback.
- `testScanConfigDefaults` added — verifies `CandidateScriptScanner.Configuration.default` matches documented v1.1 values: `maxDepth=2`, `maxVisitedFiles=2000`, `maxResults=200`, `maximumCandidateBytes=1_000_000`. Checks presence of key `scriptExtensions` (sh, py, swift) and `ignoredDirectoryNames` (.git, node_modules, .swiftpm). Also verifies custom `Configuration` initializer respects provided values.

## Task Commits

Each task was committed atomically:

1. **Task 1: Update LICENSE copyright line** - `f45872c` (docs)
2. **Task 2: Add self-tests for Codable types and scan config defaults** - `30774dd` (test)

## Files Created/Modified

- `LICENSE` — Changed line 3 from `Copyright (c) 2026 Automation Health contributors` to `Copyright (c) 2026 Niko`
- `Sources/ActiveJobsCoreSelfTest/main.swift` — Added 3 test invocations (lines 37-39) and 3 test function definitions (`testCollapseStateCodableRoundTrip`, `testGroupingModeCodableRoundTrip`, `testScanConfigDefaults`), totaling 104 lines of new test code

## Decisions Made

None — plan executed exactly as written. Both tasks matched their specifications precisely. No divergences.

## Deviations from Plan

None — plan executed exactly as written. All three test functions implemented verbatim from plan specifications. No auto-fixes were required.

## Issues Encountered

None. Both tasks completed on first attempt. `swift run ActiveJobsCoreSelfTest` passed with all 33 tests (30 existing + 3 new).

## Threat Model Compliance

Both threats from the plan's STRIDE register are accepted:

| Threat | Disposition | Rationale |
|--------|-----------|-----------|
| T-10-08: LICENSE file information disclosure | accept | MIT license text is public by design — no secrets, credentials, or identifiers beyond the copyright holder's name |
| T-10-09: Self-test fixture tampering | accept | Self-tests are developer-only and never included in the shipped `.app` bundle |

## Verification

- `grep -n "Copyright (c) 2026 Niko" LICENSE` — returned line 3 ✓
- `grep -c "Automation Health contributors" LICENSE` — returned 0 ✓
- `grep -c "Permission is hereby granted" LICENSE` — returned 1 ✓
- `grep -c "THE SOFTWARE IS PROVIDED" LICENSE` — returned 1 ✓
- All 6 acceptance criteria grep checks for Task 2 passed (2+ occurrences each) ✓
- `swift run ActiveJobsCoreSelfTest` — exited 0, all 33 tests passed ✓

## Requirement Completion

- **DIST-01** (Permissive LICENSE file committed to repository root): ✅ Complete — LICENSE now has correct copyright holder and was already present at repository root

---

*Phase: 10-preferences-persistence*
*Completed: 2026-05-11*
