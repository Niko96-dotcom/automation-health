---
phase: 07-candidate-discovery-and-manual-records
plan: 03
subsystem: ui
tags: [presentation, search, sidebar, detail, manual-verification]
requires:
  - phase: 07-candidate-discovery-and-manual-records
    provides: Candidate and Manual inventory records
provides:
  - Candidate and Manual presentation helpers for icons, fallback copy, reveal labels, and search
  - Source-sectioned sidebar rows with confidence subtitles and inventory copy
  - Detail confidence/origin cards plus Candidate/Manual fallback output and actions
  - Updated scanner extension and public inventory documentation
affects: [automation-health-ui, scanner-docs, readme]
tech-stack:
  added: []
  patterns: [presentation-owned source display helpers, source-independent search text, manual-only detail actions]
key-files:
  created: []
  modified:
    - Sources/AutomationHealth/Models/JobPresentation.swift
    - Sources/AutomationHealth/Stores/JobStore.swift
    - Sources/AutomationHealth/Views/ContentView.swift
    - Sources/AutomationHealth/Views/SidebarView.swift
    - Sources/AutomationHealth/Views/DetailView.swift
    - Sources/ActiveJobsCoreSelfTest/main.swift
    - docs/scheduled-job-sources.md
    - docs/scanner-extension-guide.md
    - README.md
key-decisions:
  - "Phase 7 keeps source-sectioned sidebar organization and leaves grouping/collapse/focus polish to Phase 8."
  - "Detail icons, definition fallbacks, output fallbacks, and reveal labels live in presentation helpers."
patterns-established:
  - "SwiftUI views consume JobPresentation display helpers rather than scanner-specific file IO."
  - "Manual UI verification can be exercised with a synthetic app-owned record and restored afterward."
requirements-completed: [DISC-08, MAN-03, QUAL-03]
duration: 16 min
completed: 2026-05-08
---

# Phase 07 Plan 03: Presentation Integration Summary

**Candidate and Manual records integrated into shared search, source-sectioned sidebar rows, and detail evidence labels**

## Performance

- **Duration:** 16 min
- **Started:** 2026-05-08T17:53:00Z
- **Completed:** 2026-05-08T18:09:08Z
- **Tasks:** 6
- **Files modified:** 9

## Accomplishments

- Added `sourceIconName`, `definitionText`, `lastOutputText`, and `revealActionLabel` to `JobPresentation`.
- Expanded search indexing to include source, confidence, origin, schedule, command/path, definition fallback, and detail path.
- Updated sidebar rows to show `{confidenceName} - {schedule or next run}` inside source sections.
- Updated toolbar, sidebar, and empty-state copy to use `inventory` and `automation records`.
- Added visible Confidence and Origin cards in detail, plus Candidate/Manual fallback output text.
- Updated docs to describe broad automation inventory while preserving the read-only real-automation boundary.
- Verified add/edit/remove Manual UI with a synthetic record through macOS UI automation and restored the manual-record file to its original missing state.

## Task Commits

Task-level commits were not created in this run because the repository started with pre-existing uncommitted Phase 6 changes that overlap Phase 7 files. The working tree was kept intact and verified with `./script/test.sh`, `./script/ci.sh`, and `./script/build_and_run.sh --verify`.

## Files Created/Modified

- `Sources/AutomationHealth/Models/JobPresentation.swift` - Added source icons, fallback copy, reveal labels, expanded search, and confidence subtitle text.
- `Sources/AutomationHealth/Stores/JobStore.swift` - Supports preferred-selection refresh for manual create/edit/remove.
- `Sources/AutomationHealth/Views/ContentView.swift` - Added manual sheet and inventory toolbar copy.
- `Sources/AutomationHealth/Views/SidebarView.swift` - Updated inventory copy and retained visible-row Up/Down navigation.
- `Sources/AutomationHealth/Views/DetailView.swift` - Added source icons, Confidence/Origin cards, manual-only actions, Candidate/Manual fallbacks, and inventory empty/error copy.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Added inventory integration coverage for existing, candidate, and manual sources.
- `docs/scheduled-job-sources.md` - Documented Candidate and Manual inventory sources.
- `docs/scanner-extension-guide.md` - Documented candidate/manual scanner guidance and view IO boundary.
- `README.md` - Updated public wording for automation records, manual notes, app-owned metadata, and candidate limitations.

## Decisions Made

Presentation owns source-specific display labels and icons so SwiftUI views stay source-independent and scanner IO remains below the view layer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Queued manual refresh while a scan is already running**
- **Found during:** Task 5 manual UI verification
- **Issue:** Rapid manual edit/remove interactions can overlap scanner refresh work; without a queued refresh, the app could temporarily keep a removed manual row selected.
- **Fix:** `JobStore` now remembers one pending refresh with the desired selection and runs it after the current scan finishes.
- **Files modified:** `Sources/AutomationHealth/Stores/JobStore.swift`
- **Verification:** `./script/ci.sh`
- **Committed in:** Not committed; see Task Commits note.

---

**Total deviations:** 1 auto-fixed blocking issue.
**Impact on plan:** The fix preserves the promised manual selection behavior without adding mutation paths for real automation sources.

## Issues Encountered

The macOS UI automation path can inspect and operate SwiftUI controls even when button accessibility names are sparse; the verification used stable toolbar/detail positions and visible confirmation text.

## User Setup Required

None - no external service configuration required.

## Manual UI Checklist

- `./script/build_and_run.sh --verify` exited 0.
- Added a synthetic Manual record named `Quarterly archive reminder`.
- Verified the detail view showed Confidence `Manual`, Origin `Unknown`, Manual source, manual schedule fallback, and manual notes.
- Edited the record name to `Quarterly archive reminder updated` and verified selection stayed on that record.
- Opened the remove confirmation and verified the body states scheduler files, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, and Hermes metadata are not changed.
- Removed the synthetic record and restored `~/Library/Application Support/AutomationHealth/manual-records.json` to its original missing state.

## Next Phase Readiness

Phase 8 can add grouping, collapse, and focus polish on top of the source-sectioned Candidate/Manual inventory surface without changing scanner IO boundaries.

---
*Phase: 07-candidate-discovery-and-manual-records*
*Completed: 2026-05-08*
