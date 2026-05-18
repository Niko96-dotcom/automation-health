# Automation Health

Automation Health is a local macOS SwiftUI app for inspecting automation records on this Mac. It collects records from supported scheduler sources, bounded candidate script folders, and app-owned manual metadata, then shows detail needed to understand what each automation is configured to do.

The app is intentionally read-only and local for real automations. It scans scheduler definitions and readable output on this Mac, keeps scan data on this Mac, and does not create, edit, enable, disable, or delete real jobs. Manual records are app-owned metadata only.

## Quick Start

Run the full local workflow gate:

```sh
./script/ci.sh
```

Build a local `.app` bundle in `dist/` and open it:

```sh
./script/build_and_run.sh
```

Build, open, and verify the app process starts:

```sh
./script/build_and_run.sh --verify
```

Developer shortcuts are also available through `make`:

```sh
make test
make run
```

## Privacy And Local Data

Automation Health reads local scheduler definitions and, when configured paths are readable, recent job output. Manual notes remain local in Application Support. The app does not send scan results to a service, and the current repository contains no analytics, login, database, or cloud sync layer.

Because scheduler definitions and output can reveal private workflows, public issues and pull requests should use sanitized summaries instead of raw logs, screenshots, scheduler output, paths, hostnames, job names, tokens, or secrets. See [docs/privacy-scrub-checklist.md](docs/privacy-scrub-checklist.md) before publishing docs, fixtures, screenshots, or sample output.

Public visuals use the abstract Pulse Grid app icon assets or explicitly synthetic screenshots only. Do not publish screenshots that expose real local automation names, paths, hostnames, scheduler output, private commands, tokens, or secrets.

## What It Scans

Automation Health uses the `ActiveJobsCore` library to scan:

- launchd property lists in the current user's `~/Library/LaunchAgents`, plus `/Library/LaunchAgents` and `/Library/LaunchDaemons` when readable.
- Hermes cron jobs in `~/.hermes/cron/jobs.json`.
- Local cron jobs through `crontab -l` and readable system cron files.
- registered Shortcuts and Automator workflows.
- bounded candidate scripts from common user script folders.
- app-owned manual records for automations the scanner cannot prove.
- Recent job output where the source exposes a readable output path.

The scanner normalizes each source into a shared `ScheduledJob` model with source, confidence, origin, command, schedule, state, last run, next run, and detail text. The UI presents those automation records in a searchable sidebar with a detail view for health, timing, configuration, confidence, origin, and latest output.

Source coverage is best-effort. Read [docs/scheduled-job-sources.md](docs/scheduled-job-sources.md) for exactly what each scanner reads, what it cannot see, and what the available evidence means.

## Build And Run

Build all package products:

```sh
swift build
```

Run the self-test executable:

```sh
./script/test.sh
```

Build the local app bundle:

```sh
./script/build_and_run.sh
```

The generated bundle is written to `dist/AutomationHealth.app`.

App icon assets are generated locally from committed source art; see docs/development.md for regeneration steps.
The committed source art lives at `Assets/AppIcon/automation-health-icon-source.png`.

## Current Distribution Status

Automation Health ships as a signed and notarized DMG from [GitHub Releases](https://github.com/Niko96-dotcom/automation-health/releases). Download the latest `AutomationHealth-*.dmg`, open it, and drag to your Applications folder.

The DMG is codesigned with a Developer ID, includes hardened runtime, and is notarized by Apple. macOS Gatekeeper allows it to run without security warnings.

To produce a signed and notarized release from source (requires Apple Developer Program membership), see [docs/release-process.md](docs/release-process.md).

You can also build and run locally without code signing:

```sh
./script/build_and_run.sh
```

## Known Limitations

- Discovery is best-effort and not a guarantee that every automation on every Mac has been found.
- Root-only or protected job definitions may be invisible unless the current user can read them.
- Calendar alarms, `at` jobs, and third-party scheduler databases are not supported yet.
- Some protected root-only cron locations may remain invisible.
- Registered Shortcuts and Automator workflows are registered inventory, not proof of scheduling.
- Bounded candidate scripts are possible automation records, not proof of scheduling.
- Configurable candidate folders are not supported yet.
- launchd next-run times are not calculated; the app shows configured schedules and launchctl/log-derived state where available.
- Health summaries are heuristic and based on available last-run, next-run, and status fields.

## Products

- `AutomationHealth`: SwiftUI macOS app executable.
- `ActiveJobsCore`: scanner and domain model library.
- `ActiveJobsCoreSelfTest`: lightweight executable self-test for the scanner layer.

## Contributing

Start with [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/development.md](docs/development.md) for the local workflow, pull request checklist, and CI details.

Scanner contributors should also read [docs/architecture.md](docs/architecture.md), [docs/scheduled-job-sources.md](docs/scheduled-job-sources.md), and [docs/scanner-extension-guide.md](docs/scanner-extension-guide.md).

For security or privacy concerns, see [SECURITY.md](SECURITY.md). For support boundaries and issue routing, see [SUPPORT.md](SUPPORT.md).
