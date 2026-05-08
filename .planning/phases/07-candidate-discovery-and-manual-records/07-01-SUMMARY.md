---
phase: 07-candidate-discovery-and-manual-records
plan: 01
subsystem: core
tags: [candidate-discovery, scanner, read-only, scan-notes]
requires:
  - phase: 06-inventory-model-and-deterministic-sources
    provides: JobScanResult, JobConfidence, JobOrigin, and deterministic source ordering
provides:
  - Bounded Candidate scripts inventory source
  - Candidate confidence records with no schedule evidence
  - Fixture coverage for candidate roots, depth, ignore rules, caps, and scan notes
affects: [active-jobs-core, scanner-docs, readme]
tech-stack:
  added: []
  patterns: [bounded metadata-only filesystem traversal, candidate confidence scanner]
key-files:
  created:
    - Sources/ActiveJobsCore/Services/CandidateScriptScanner.swift
  modified:
    - Sources/ActiveJobsCore/Models/ScheduledJob.swift
    - Sources/ActiveJobsCore/Services/JobScanning.swift
    - Sources/ActiveJobsCoreSelfTest/main.swift
    - docs/scheduled-job-sources.md
    - README.md
key-decisions:
  - "Candidate scripts use Candidate confidence and explicit no-schedule-evidence schedule text."
  - "Candidate discovery is capped by default roots, depth, visited-file count, result count, and file size."
patterns-established:
  - "Possible automations are represented below the view layer as scanner records, not inferred scheduled jobs."
  - "Candidate traversal reports missing roots, ignored paths, oversized files, and caps as ScanNote values."
requirements-completed: [DISC-06, QUAL-03]
duration: 16 min
completed: 2026-05-08
---

# Phase 07 Plan 01: Candidate Discovery Summary

**Bounded candidate script discovery with Candidate confidence and no schedule claims**

## Performance

- **Duration:** 16 min
- **Started:** 2026-05-08T17:53:00Z
- **Completed:** 2026-05-08T18:09:08Z
- **Tasks:** 4
- **Files modified:** 6

## Accomplishments

- Added `JobSource.candidateScripts` with display name `Candidate scripts`.
- Added `CandidateScriptScanner` for bounded read-only metadata traversal of documented script folders.
- Added scan notes for missing roots, unreadable roots, ignored paths, oversized files, and traversal/result caps.
- Added self-tests for bounded script inclusion, hidden/ignored/oversized skips, missing roots, caps, Candidate confidence, and no run evidence.
- Documented candidate roots, caps, ignore rules, Candidate confidence, and the no-run/no-schedule boundary.

## Task Commits

Task-level commits were not created in this run because the repository started with pre-existing uncommitted Phase 6 changes that overlap Phase 7 files. The working tree was kept intact and verified with `./script/test.sh`, `./script/ci.sh`, and `./script/build_and_run.sh --verify`.

## Files Created/Modified

- `Sources/ActiveJobsCore/Services/CandidateScriptScanner.swift` - Bounded candidate script scanner with injected roots and metadata-only traversal.
- `Sources/ActiveJobsCore/Models/ScheduledJob.swift` - Added the Candidate scripts source.
- `Sources/ActiveJobsCore/Services/JobScanning.swift` - Added Candidate scanner composition in live inventory.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Added candidate fixture tests for inclusion, skips, caps, and confidence.
- `docs/scheduled-job-sources.md` - Added Candidate Scripts source documentation.
- `README.md` - Added high-level bounded candidate script support and limitations.

## Decisions Made

Candidate records use `state = "candidate"` and `Script candidate (no schedule evidence)` even when a script is executable, because file presence is not scheduling evidence.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

macOS temporary paths can appear with `/var` or `/private/var`; candidate path tests assert suffixes to avoid false failures from path normalization.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Manual records can compose after candidate scripts through the same `JobInventory` result path.

---
*Phase: 07-candidate-discovery-and-manual-records*
*Completed: 2026-05-08*
