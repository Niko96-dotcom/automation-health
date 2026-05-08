---
phase: 06-inventory-model-and-deterministic-sources
plan: 02
subsystem: core
tags: [cron, scanner, read-only, fixtures]
requires:
  - phase: 06-inventory-model-and-deterministic-sources
    provides: JobScanResult, JobConfidence, JobOrigin, and ScanNote
provides:
  - Read-only cron scanner for current-user and readable system cron entries
  - Cron source composition in live inventory
  - Fixture-driven cron parser and scan-note coverage
affects: [active-jobs-core, scanner-docs, readme]
tech-stack:
  added: []
  patterns: [injected command runner, deterministic text parser, source notes]
key-files:
  created:
    - Sources/ActiveJobsCore/Services/CronScanner.swift
  modified:
    - Sources/ActiveJobsCore/Models/ScheduledJob.swift
    - Sources/ActiveJobsCore/Services/JobScanning.swift
    - Sources/ActiveJobsCoreSelfTest/main.swift
    - docs/scheduled-job-sources.md
    - README.md
key-decisions:
  - "Production cron scanning invokes only /usr/bin/crontab -l for current-user crontab data."
  - "Missing or unreadable cron locations are scan notes, not fatal inventory failures."
patterns-established:
  - "Command-backed scanners expose small injected runner protocols for deterministic tests."
  - "System cron files and directories are parsed best-effort without requiring elevated access."
requirements-completed: [DISC-03, DISC-07, QUAL-01, QUAL-02]
duration: 7 min
completed: 2026-05-08
---

# Phase 06 Plan 02: Cron Scanner Summary

**Read-only cron inventory through injected crontab output and readable system cron fixtures**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-08T16:36:00Z
- **Completed:** 2026-05-08T16:43:50Z
- **Tasks:** 4
- **Files modified:** 6

## Accomplishments

- Added `JobSource.cron` and a `CronScanner` with injected `CronCommandRunning`.
- Parsed user and system cron lines, including comments, environment assignments, five-field schedules, and special schedules like `@hourly`.
- Added scan notes for unavailable `crontab -l`, missing files, unreadable files, and missing cron directories.
- Documented cron support and updated README limitations.

## Task Commits

Task-level commits were not created in this run because the repository had pre-existing uncommitted changes. The working tree was kept intact and verified with `./script/ci.sh`.

## Files Created/Modified

- `Sources/ActiveJobsCore/Services/CronScanner.swift` - Read-only cron parser, command runner, and source notes.
- `Sources/ActiveJobsCore/Models/ScheduledJob.swift` - Added `JobSource.cron`.
- `Sources/ActiveJobsCore/Services/JobScanning.swift` - Added `CronScanner()` to live inventory.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Added cron fixture tests and stub runner.
- `docs/scheduled-job-sources.md` - Added `Cron Jobs` source documentation.
- `README.md` - Added high-level cron support and updated limitations.

## Decisions Made

Cron entries are `Scheduled` confidence because parsed crontab lines are direct schedule evidence; current-user entries are user-authored and readable system files are system origin.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Swift required the `split(maxSplits:whereSeparator:)` argument order for parser tokenization.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Registered inventory scanners can now compose after launchd, Hermes cron, and cron in deterministic sidebar source order.

---
*Phase: 06-inventory-model-and-deterministic-sources*
*Completed: 2026-05-08*
