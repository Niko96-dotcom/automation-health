# Scheduled Job Sources

Automation Health supports a focused set of local automation inventory sources. All scanning is read-only, local, and best-effort, except Manual Records, which are app-owned metadata stored by Automation Health.

## Best-Effort Inventory

Automation Health can only show sources it knows how to scan and can read from the current user context. Unsupported sources are not currently scanned, and protected files may be skipped by macOS permissions.

Source inclusion is evidence that Automation Health found a supported scheduler definition, registered automation, candidate script, or app-owned manual record. It is not proof that every automation on this Mac has been found.

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

## Cron Jobs

Scanner: `CronScanner`

Supported locations and commands:

- `/usr/bin/crontab -l` for the current user's crontab.
- Readable system cron files such as `/etc/crontab`.

The scanner parses standard five-field cron lines and special strings such as `@hourly`. Cron records are labeled with Scheduled confidence because each parsed entry is direct schedule evidence.

Missing or unreadable cron locations are reported as scan notes. Root-only or protected cron tab files may be skipped when the current user cannot read them.

Automation Health does not edit, install, remove, or execute cron jobs.

## Shortcuts

Scanner: `ShortcutsScanner`

Supported command:

- `/usr/bin/shortcuts list --show-identifiers`

The scanner records listed shortcuts as Registered confidence. It does not claim schedule evidence for those records, and it does not call `shortcuts run`, `shortcuts view`, or `shortcuts sign`.

Missing command access, permission failures, or non-zero command results are reported as scan notes.

## Automator Workflows

Scanner: `AutomatorScanner`

Supported locations:

- `~/Library/Services`
- `~/Library/Workflows`

The scanner reads bounded user workflow locations and records readable workflows as Registered confidence. It does not claim schedule evidence, does not execute workflows, and reports missing or unreadable locations as scan notes.

## Candidate Scripts

Scanner: `CandidateScriptScanner`

Supported default locations:

- `~/Scripts`
- `~/bin`
- `~/.local/bin`
- `~/Library/Scripts`
- `~/Documents/Scripts`

The scanner treats files in these bounded folders as possible automation records, not proof of scheduling. It traverses at most two levels below each configured root and applies these hard limits:

- `maxVisitedFiles = 2_000`
- `maxResults = 200`
- `maximumCandidateBytes = 1_000_000`

Candidate discovery includes script extensions such as `.sh`, `.zsh`, `.bash`, `.command`, `.py`, `.rb`, `.js`, `.swift`, `.scpt`, `.applescript`, and `.pl`. Extensionless executable files are included only in `~/bin`, `~/.local/bin`, or equivalent injected test roots.

The scanner skips hidden files and directories, plus build, dependency, cache, and virtual-environment directories including `.git`, `.build`, `build`, `dist`, `DerivedData`, `node_modules`, `vendor`, `.venv`, `venv`, `__pycache__`, and `.swiftpm`.

Candidate records are labeled with Candidate confidence and use `Script candidate (no schedule evidence)`. Missing directories, unreadable roots, skipped oversized files, ignored paths, and traversal/result caps are reported as scan notes.

Automation Health never runs, validates, edits, rewrites, or infers schedules from candidate scripts.

## Manual Records

Scanner: `ManualRecordScanner`

Storage location:

- `~/Library/Application Support/AutomationHealth/manual-records.json`

Manual records are app-owned JSON metadata for automations the scanner cannot prove. They are labeled with Manual confidence, can be added/edited/removed by Automation Health, and do not modify scheduler files, script files, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata.

Malformed manual JSON is reported as an app-storage scan note/error and is not silently deleted or overwritten.

## Not Supported Yet

These sources are not currently scanned:

- Calendar alarms and reminders.
- `at` jobs, especially root-only queues.
- Homebrew services metadata beyond any launchd plist it installs.
- Third-party scheduler databases or cloud schedulers.

Future scanners should implement `JobScanning` and return `ScheduledJob` values so the UI can consume them without source-specific logic. See [docs/scanner-extension-guide.md](scanner-extension-guide.md) for the scanner adapter recipe.
