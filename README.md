# Automation Health

Automation Health is a local macOS SwiftUI app for inspecting scheduled jobs that run on this Mac. It collects jobs from supported scheduler sources, summarizes their schedule and recent status, and shows enough detail to understand what each automation is configured to do.

The app currently focuses on personal automation health rather than full system administration. It is intentionally read-only: it scans job definitions and related output, but does not create, edit, enable, disable, or delete jobs.

## What It Scans

Automation Health uses the `ActiveJobsCore` library to scan:

- launchd property lists in the current user's `~/Library/LaunchAgents`, plus `/Library/LaunchAgents` and `/Library/LaunchDaemons` when readable.
- Hermes cron jobs in `~/.hermes/cron/jobs.json`.
- Recent job output where the source exposes a readable output path.

The scanner normalizes each source into a shared `ScheduledJob` model with source, command, schedule, state, last run, next run, and detail text. The UI then presents those jobs as a searchable sidebar with a detail view for health, timing, configuration, and latest output.

## Build And Run

From the repo root:

Run the full local workflow gate:

```sh
./script/ci.sh
```

Build all package products:

```sh
swift build
```

Run the self-test executable:

```sh
./script/test.sh
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

## Products

- `AutomationHealth`: SwiftUI macOS app executable.
- `ActiveJobsCore`: scanner and domain model library.
- `ActiveJobsCoreSelfTest`: lightweight executable self-test for the scanner layer.

## Known Limitations

- Root-only or protected job definitions may be invisible unless the current user can read them.
- Shortcuts automations, Calendar alarms, `at` jobs, and third-party scheduler databases are not scanned yet.
- launchd next-run times are not calculated; the app shows configured schedules and launchctl/log-derived state where available.
- Health summaries are heuristic and based on available last-run, next-run, and status fields.

See [docs/scheduled-job-sources.md](docs/scheduled-job-sources.md) for source-specific details.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/development.md](docs/development.md) for the local workflow, pull request checklist, and CI details.
