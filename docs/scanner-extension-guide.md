# Scanner Extension Guide

Automation Health keeps scheduler IO and inventory reads in `ActiveJobsCore` so scanners are testable, read-only, and separate from SwiftUI views.

Use this guide when adding a new scheduler source, candidate inventory source, manual inventory source, or extending an existing scanner.

## Scanner Adapter Recipe

1. Add or update a scanner type under `Sources/ActiveJobsCore/Services`.
2. Return a `JobScanResult` containing normalized `ScheduledJob` values and any non-fatal `ScanNote` values from the scanner.
3. Update `JobSource` in `Sources/ActiveJobsCore/Models/ScheduledJob.swift` with the new source case and display name.
4. Compose the scanner in `JobInventory.live(homeDirectory:)` in `Sources/ActiveJobsCore/Services/JobScanning.swift`.
5. Add fixture-driven coverage in `Sources/ActiveJobsCoreSelfTest/main.swift`.
6. Update `docs/scheduled-job-sources.md` with what the source reads, what it cannot see, and what evidence proves scheduling.

## Core Contracts

- `JobScanning` is the adapter protocol. Each scanner returns `JobScanResult(jobs:notes:)`.
- `ScheduledJob` is the source-neutral model used by presentation code.
- `JobSource` identifies the scheduler source and controls display ordering.
- `JobConfidence` describes evidence strength: use `.scheduled` only for direct schedule evidence, `.registered` for known automations without schedule evidence, `.candidate` for possible automations from `CandidateScriptScanner`, and `.manual` only for app-authored manual records from `ManualRecordScanner`.
- `JobOrigin` describes ownership separately from scheduler source.
- `ScanNote` reports non-fatal source limitations, missing inputs, unreadable locations, or unavailable tools without failing the whole inventory.
- `JobInventory.live(homeDirectory:)` is the live composition point for scanner sources.

Scanners should accept injected paths, file managers, or command runners where practical. That keeps tests deterministic and avoids hard-coded reads from a contributor's machine.

SwiftUI views must not read scheduler files, script files, or manual JSON directly, and they must not execute scanner commands. Views should consume store and presentation values that were already produced below the view layer.

## Testing A Scanner

Add focused self-test coverage in `Sources/ActiveJobsCoreSelfTest/main.swift`.

Good scanner tests use temporary fixtures with synthetic job ids, names, paths, prompts, commands, and output. Avoid real local paths, hostnames, job names, scheduler output, tokens, or secrets.

Run the full local gate before opening a pull request:

```sh
./script/ci.sh
```

## Documentation Updates

When a scanner changes, update:

- `README.md` for high-level source support and limitations.
- `docs/scheduled-job-sources.md` for source-specific read paths, shell-outs, error meanings, evidence limits, and unsupported cases.
- `docs/architecture.md` if the scanner introduces a new reusable pattern.

Use `docs/privacy-scrub-checklist.md` before adding public examples, fixtures, screenshots, or sample output.

## What Not To Put In Views

Do not add direct filesystem reads, shell-outs, source-specific parsing, manual JSON directly, or scheduler-specific branching to SwiftUI views.

Views should consume `JobStore`, `JobPresentation`, and `ScheduledJob` fields that were already produced by `ActiveJobsCore`. If a UI needs new source detail, add that detail at the scanner or presentation boundary first. Manual records may be added, edited, or removed through app-owned metadata, but real scheduler files, script files, Shortcuts, Automator workflows, cron entries, launchd plists, and Hermes metadata remain read-only.
