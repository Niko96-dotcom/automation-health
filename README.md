# Automation Health

Automation Health is a local macOS SwiftUI app for inspecting scheduled jobs that run on this Mac. It collects jobs from supported scheduler sources, summarizes schedule and recent status, and shows detail needed to understand what each automation is configured to do.

The app is intentionally read-only and local. It scans scheduler definitions and readable output on this Mac, keeps scan data on this Mac, and does not create, edit, enable, disable, or delete jobs.

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

Automation Health reads local scheduler definitions and, when configured paths are readable, recent job output. The app does not send scan results to a service, and the current repository contains no analytics, login, database, or cloud sync layer.

Because scheduler definitions and output can reveal private workflows, public issues and pull requests should use sanitized summaries instead of raw logs, screenshots, scheduler output, paths, hostnames, job names, tokens, or secrets. See [docs/privacy-scrub-checklist.md](docs/privacy-scrub-checklist.md) before publishing docs, fixtures, screenshots, or sample output.

## What It Scans

Automation Health uses the `ActiveJobsCore` library to scan:

- launchd property lists in the current user's `~/Library/LaunchAgents`, plus `/Library/LaunchAgents` and `/Library/LaunchDaemons` when readable.
- Hermes cron jobs in `~/.hermes/cron/jobs.json`.
- Recent job output where the source exposes a readable output path.

The scanner normalizes each source into a shared `ScheduledJob` model with source, command, schedule, state, last run, next run, and detail text. The UI presents those jobs in a searchable sidebar with a detail view for health, timing, configuration, and latest output.

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

## Current Distribution Status

Automation Health is currently distributed as source and built locally through `script/build_and_run.sh`. The generated `.app` is unsigned, unsandboxed, and not notarized.

Signed and notarized release artifacts are out of scope for this milestone.

## Known Limitations

- Discovery is best-effort and not a guarantee that every automation on every Mac has been found.
- Root-only or protected job definitions may be invisible unless the current user can read them.
- Shortcuts automations, Calendar alarms, user/root crontabs outside Hermes, `at` jobs, and third-party scheduler databases are not supported yet.
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
