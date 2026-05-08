# Scheduled Job Sources

Automation Health supports a focused set of local scheduler sources. All scanning is read-only, local, and best-effort.

## Best-Effort Inventory

Automation Health can only show sources it knows how to scan and can read from the current user context. Unsupported sources are not currently scanned, and protected files may be skipped by macOS permissions.

Source inclusion is evidence that Automation Health found a supported scheduler definition or metadata record. It is not proof that every automation on this Mac has been found.

Future confidence and origin inventory work is planned, not shipped. Current docs and UI should not be read as promising confidence fields, origin badges, or complete automation discovery.

## launchd LaunchAgents And LaunchDaemons

Scanner: `LaunchAgentScanner`

Supported locations:

- `~/Library/LaunchAgents`
- `/Library/LaunchAgents`
- `/Library/LaunchDaemons`

The scanner reads `.plist` files and extracts:

- `Label`
- `Program` or `ProgramArguments`
- `StartCalendarInterval`
- `StartInterval`
- `WatchPaths`
- `QueueDirectories`
- `RunAtLoad`
- `KeepAlive`
- `StandardOutPath` or `StandardErrorPath`

Runtime state and last exit code are best-effort values from `launchctl print`, invoked through `/bin/launchctl`.

Jobs are included when they have a schedule-like trigger, or when a `RunAtLoad` or `KeepAlive` job looks relevant to personal automation scripts. That inclusion is evidence of configured triggers or relevant login/keepalive definitions, not proof that launchd will run the job next or that every local automation exists.

Limitations and error meanings:

- System or root-owned plists may be skipped if the current user cannot read them.
- Malformed or unreadable plists are ignored rather than blocking the full scan.
- `launchctl` failures leave runtime state unknown; they do not prove the job is inactive.
- launchd does not expose a simple universal next-run value here, so next run is usually unknown.
- Only stdout or stderr snippets are shown when the plist points to a readable log file.

## Hermes Cron Jobs

Scanner: `HermesCronScanner`

Supported locations:

- `~/.hermes/cron/jobs.json`
- `~/.hermes/cron/output/<job-id>/*.md`

The scanner reads enabled, non-paused jobs from the Hermes cron metadata file and extracts:

- job id and name
- prompt or script
- schedule display or cron expression
- state
- last status
- last run timestamp
- next run timestamp

For latest output, it looks for the most recently modified markdown file under `~/.hermes/cron/output/<job-id>`. Readable output is bounded so large files do not dominate the UI.

Limitations and error meanings:

- Jobs without `~/.hermes/cron/jobs.json` are not discovered.
- Disabled or paused jobs are filtered out.
- Output is shown only when markdown output files are present and readable.
- Prompt-to-command extraction is heuristic when Hermes does not provide an explicit script.
- Missing output does not prove a job has never run; it only means Automation Health did not find readable markdown output.

## Not Supported Yet

These sources are not currently scanned:

- Shortcuts personal automations.
- Calendar alarms and reminders.
- User or root crontabs outside Hermes.
- `at` jobs, especially root-only queues.
- Homebrew services metadata beyond any launchd plist it installs.
- Third-party scheduler databases or cloud schedulers.

Future scanners should implement `JobScanning` and return `ScheduledJob` values so the UI can consume them without source-specific logic. See [docs/scanner-extension-guide.md](scanner-extension-guide.md) for the scanner adapter recipe.
