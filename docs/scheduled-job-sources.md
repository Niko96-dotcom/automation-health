# Scheduled Job Sources

Automation Health supports a focused set of local scheduler sources. All scanning is read-only.

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

Jobs are included when they have a schedule-like trigger, or when a `RunAtLoad` or `KeepAlive` job looks relevant to personal automation scripts. Runtime state and last exit code are best-effort values from `launchctl print`.

Limitations:

- System or root-owned plists may be skipped if the current user cannot read them.
- launchd does not expose a simple universal next-run value here, so next run is usually unknown.
- Only stdout or stderr snippets are shown when the plist points to a readable log file.

## Hermes Cron Jobs

Scanner: `HermesCronScanner`

Supported location:

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

For latest output, it looks for the most recently modified markdown file in the job's Hermes output directory.

Limitations:

- Jobs without `~/.hermes/cron/jobs.json` are not discovered.
- Output is shown only when markdown output files are present and readable.
- Prompt-to-command extraction is heuristic when Hermes does not provide an explicit script.

## Not Supported Yet

These sources are not scanned yet:

- Shortcuts personal automations.
- Calendar alarms and reminders.
- User or root crontabs outside Hermes.
- `at` jobs, especially root-only queues.
- Homebrew services metadata beyond any launchd plist it installs.
- Third-party scheduler databases or cloud schedulers.

Future scanners should implement `JobScanning` and return `ScheduledJob` values so the UI can consume them without source-specific logic.
