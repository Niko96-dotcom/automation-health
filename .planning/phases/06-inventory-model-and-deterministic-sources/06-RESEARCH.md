# Phase 6: Inventory Model And Deterministic Sources - Research

**Researched:** 2026-05-08
**Domain:** Source-independent inventory modeling, deterministic local scanner adapters, cron, Shortcuts, Automator
**Confidence:** HIGH

## Context Status

No `06-CONTEXT.md` exists for this phase. Planning used the locked roadmap scope, requirements, current codebase contracts, Phase 4 scanner-extension guidance, and local macOS command/man-page evidence.

The roadmap marks Phase 6 with `UI hint: no`. The phrase "below the view layer" in the success criteria is architectural, not a frontend/UI design request, so a UI-SPEC is not required for planning.

## Phase Scope

Phase 6 broadens inventory without adding job mutation or broad candidate discovery. It should:

- Add source-independent confidence states: Scheduled, Registered, Candidate, Manual.
- Add origin classifications independent from scheduler source: user-authored, third-party app, system, unknown.
- Add source-specific scan notes for missing tools, unreadable locations, permission limits, and confidence limitations.
- Add cron scanner coverage for the current user's crontab and supported readable system cron files.
- Add registered Shortcuts inventory through the `shortcuts` CLI when available.
- Add best-effort Automator workflow inventory from bounded readable workflow locations.
- Keep candidate script discovery and manual record CRUD out of scope for Phase 6; those belong to Phase 7.

## Requirements Mapping

| Requirement | Planning Implication |
|-------------|----------------------|
| DISC-01 | Add a model-level `JobConfidence` enum and carry it through inventory and presentation data. |
| DISC-02 | Add a model-level `JobOrigin` enum and derive origin separately from `JobSource`. |
| DISC-03 | Add a cron scanner with fixture-driven parsing for current-user and readable system entries. |
| DISC-04 | Add a Shortcuts inventory scanner that lists registered shortcuts but never labels them as scheduled. |
| DISC-05 | Add an Automator scanner that lists readable workflow files with registered confidence unless stronger evidence exists. |
| DISC-07 | Return source-specific scan notes from scanner/inventory results instead of throwing for best-effort gaps. |
| QUAL-01 | All scanners remain read-only; no edit/remove/install/run subcommands and no writes to scheduler locations. |
| QUAL-02 | Scanner additions use injected paths or command runners and synthetic self-test fixtures. |

## Current Architecture Findings

`ScheduledJob` is the normalized core model consumed by `JobPresentation` and SwiftUI views. `JobSource` currently contains only `launchd` and `hermesCron`. `JobInventory.refresh()` currently returns `[ScheduledJob]`, deduplices by `source:id`, and sorts by `nextRun` then name.

`LaunchAgentScanner` and `HermesCronScanner` already follow the adapter pattern: source-specific IO is isolated in `Sources/ActiveJobsCore/Services`, and the UI consumes normalized presentation data. Phase 6 should extend this pattern rather than introducing source-specific view logic.

The existing executable self-test in `Sources/ActiveJobsCoreSelfTest/main.swift` is the right test surface. It already creates temporary fixtures, uses synthetic data, and verifies scanner parsing, inventory aggregation, humanization, and presentation-adjacent behavior without live machine state.

## Recommended Implementation Split

1. **Core model/result contract:** Add `JobConfidence`, `JobOrigin`, `ScanNote`, and `JobScanResult`; update scanners, `JobInventory`, `JobStore`, presentation adapters, and self-tests to carry confidence, origin, and scan notes.
2. **Cron scanner:** Add `CronScanner` with injected command runner and fixture paths; parse crontab syntax read-only; include scan notes for missing/unreadable or permission-limited sources.
3. **Shortcuts and Automator scanners:** Add registered inventory scanners with injected command/file providers; label records as Registered, never Scheduled, unless scanner evidence proves scheduling.

This split keeps Phase 6 aligned with the existing three-plan roadmap and prevents the new scanner work from duplicating model changes.

## Cron Research

Local evidence:

- `/usr/bin/crontab` exists.
- `crontab -l` is the supported read-only way to display the current user's crontab.
- `crontab(1)` says user crontabs are not intended to be edited directly.
- `cron(8)` says macOS cron loads `/etc/crontab` and files in `/usr/lib/cron/tabs`.
- `crontab(5)` defines five time/date fields followed by command for user crontabs, and an extra username field for system crontab entries.
- `crontab(5)` supports special strings such as `@reboot`, `@yearly`, `@monthly`, `@weekly`, `@daily`, `@midnight`, and `@hourly`.

Recommended scanner behavior:

- Use an injected command runner for `crontab -l`; production runner invokes `/usr/bin/crontab` with only `-l`.
- Treat `crontab -l` exit codes that mean "no crontab", permission denied, or command unavailable as scan notes, not full inventory failures.
- Parse readable system files from an injected list with `/etc/crontab` as the default supported system file.
- Optionally inspect readable files under injected cron tab directories in tests, but do not require root-only spools to be readable in production.
- Ignore comments, blank lines, and environment assignment lines.
- Parse user crontab entries as five schedule fields plus command; parse system entries as five fields plus username plus command.
- Parse special schedule strings with either command or username plus command depending on source type.
- Set `confidence` to `.scheduled`, because cron entries are direct scheduling definitions.
- Set `origin` to `.userAuthored` for the current user crontab, `.system` for `/etc/crontab` or root/system cron sources, and `.unknown` when owner/source evidence is unclear.

## Shortcuts Research

Local evidence:

- `/usr/bin/shortcuts` exists.
- `shortcuts help` describes the command-line utility as "for running shortcuts."
- `shortcuts help list` supports `shortcuts list`, `--folder-name`, `--folders`, and `--show-identifiers`.

Recommended scanner behavior:

- Use an injected command runner for `/usr/bin/shortcuts list --show-identifiers`.
- Do not use `shortcuts run`, `shortcuts view`, or `shortcuts sign` in scanner code.
- Treat command missing, non-zero output, permissions/TCC failures, and unparsable output as scan notes.
- Return registered shortcut records with `confidence` `.registered`, `origin` `.userAuthored`, schedule text like `Registered shortcut (no schedule evidence)`, and no next-run claim.
- Include shortcut name and identifier in `definition`, but avoid reading private Shortcuts SQLite databases directly.

## Automator Research

Local evidence:

- Automator workflows are file/bundle artifacts with `.workflow` extension and may appear in user-visible workflow locations such as `~/Library/Services`.
- The current machine has no readable workflow files in `~/Library/Services`, so missing directories or empty results must be normal, non-fatal states.

Recommended scanner behavior:

- Use injected search directories with defaults limited to user-readable locations such as `~/Library/Services` and `~/Library/Workflows`.
- Find `.workflow` bundles and Automator app/workflow artifacts only within those bounded directories.
- Read `Contents/Info.plist` when present to derive display name or bundle metadata, but fall back to file names.
- Return registered records with `confidence` `.registered`, no scheduling evidence, no next-run claim, and source notes when directories are missing/unreadable.
- Do not execute workflows, open Automator apps, modify bundles, or index arbitrary home-directory paths.

## Origin Heuristics

Origin must be derived separately from `JobSource`. Recommended initial rules:

- User-authored: records under the current user's home directory, user crontab entries, Hermes cron jobs, Shortcuts records, and Automator workflows under user Library paths.
- System: Apple/system labels such as `com.apple.*`, `/System` paths, `/usr/libexec` system commands, root/system cron files, and `/Library/LaunchDaemons` records with clear system ownership.
- Third-party app: launchd plists in `/Library/LaunchAgents` or `/Library/LaunchDaemons` with non-Apple labels or commands under `/Applications`, `/Library/Application Support`, or app bundle paths.
- Unknown: records where path, label, owner, or command evidence is insufficient.

The initial heuristic should be deterministic and conservative. Unknown is preferable to overclaiming ownership.

## Scan Note Model

Scan notes should be source-specific and non-fatal. Recommended fields:

- `source: JobSource`
- `severity: ScanNoteSeverity` with `.info`, `.warning`, `.error`
- `message: String`
- `detail: String?`

The inventory result should carry both jobs and notes so a scanner can report "Shortcuts command unavailable" even when it finds no jobs. Existing scanner parse failures that currently return empty arrays can continue doing so where appropriate, but known best-effort limitations should become notes when practical.

## Validation Architecture

Phase 6 can be validated with the existing SwiftPM and executable self-test flow:

- Quick command: `./script/test.sh`
- Full command: `./script/ci.sh`
- Core fixture target: `Sources/ActiveJobsCoreSelfTest/main.swift`

Tests should cover:

- New `ScheduledJob` defaults and explicit confidence/origin values.
- `JobInventory.refresh()` deduping/sorting jobs while preserving scan notes.
- Launchd and Hermes scanners populate scheduled confidence and derived origins.
- Cron parser handles comments, environment lines, five-field schedules, special schedules, user/system forms, no-crontab output, and unreadable/missing system files.
- Shortcuts scanner uses an injected command runner, parses synthetic `--show-identifiers` output, and produces registered records without schedule evidence.
- Automator scanner uses injected directories and synthetic `.workflow` fixtures, handles missing directories, and never scans unbounded home paths.

## Security Domain

Security enforcement is applicable. The main risks are information disclosure from local scheduler definitions and unsafe scanner behavior that mutates scheduler state or executes automations.

Mitigations:

- Invoke only read/list commands: `crontab -l` and `shortcuts list --show-identifiers`.
- Never call `crontab -e`, `crontab -r`, `shortcuts run`, `shortcuts sign`, Automator execution APIs, or file writes in scheduler locations.
- Use bounded fixture directories and injected command runners in tests.
- Treat unavailable tools and unreadable locations as scan notes.
- Keep docs and fixtures synthetic, with no real local job names, hostnames, paths, scheduler output, tokens, or secrets.

## Common Pitfalls

| Pitfall | Why It Matters | Plan Guardrail |
|---------|----------------|----------------|
| Treating Shortcuts or Automator inventory as scheduled jobs | Listing registered automations is not proof they are scheduled. | Set confidence to Registered and schedule text to "no schedule evidence". |
| Returning only jobs from inventory | Missing tools and unreadable sources have no job to attach failure detail to. | Add `JobScanResult` with `jobs` and `notes`. |
| Reading root cron spools directly as a requirement | macOS protects cron tab files and `crontab(1)` says users should not edit them directly. | Use `crontab -l` for current user and best-effort readable system files with notes. |
| Adding scanner IO to SwiftUI views | Violates the project architecture boundary. | All source reads and command calls stay in `ActiveJobsCore`; views consume store/presentation values. |
| Overconfident origin classification | Source and ownership are different concepts. | Derive origin through conservative helper rules and default to Unknown. |
| Live-machine tests | CI and contributors will have different local automations. | Use injected paths/command runners and synthetic fixtures only. |

## Sources

- Repository files verified locally: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `docs/scanner-extension-guide.md`, `docs/scheduled-job-sources.md`, `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Local command evidence: `which crontab`, `which shortcuts`, `shortcuts help`, `shortcuts help list`.
- Local man pages: `crontab(1)`, `cron(8)`, `crontab(5)`.
