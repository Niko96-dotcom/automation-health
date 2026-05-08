---
phase: 06
slug: inventory-model-and-deterministic-sources
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-08
---

# Phase 06 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Scanner source data -> normalized model | Source-specific evidence is converted into confidence, origin, jobs, and notes. | Scheduler metadata, command output, file metadata. |
| Core scanner result -> SwiftUI store | Scanner IO completes below the view layer before view state is published. | `JobScanResult`, `ScheduledJob`, `ScanNote`. |
| Missing or unreadable source -> user-facing note | Best-effort limitations are represented without throwing away all inventory data. | Source limitation messages. |
| `/usr/bin/crontab -l` -> scanner parser | Production command output is treated as untrusted text and parsed read-only. | Current-user crontab text. |
| System cron files -> scanner parser | Readable file contents are parsed without writing back to cron locations. | System crontab text. |
| Cron limitations -> scan notes | Missing, protected, or unavailable sources become user-visible notes instead of fatal failures. | Cron source limitation messages. |
| `/usr/bin/shortcuts list --show-identifiers` -> scanner parser | Command output is parsed as untrusted text and never executed. | Shortcut names and identifiers. |
| Workflow bundle metadata -> scanner model | Readable Info.plist metadata is used only for display names and details. | Workflow bundle metadata. |
| Registered records -> user understanding | Listed Shortcuts and workflow files are registered inventory, not scheduling proof. | Confidence, origin, schedule evidence labels. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-06-01-01 | Spoofing | Confidence/origin labels | mitigate | Use explicit enums and conservative derivation; default to `.unknown` origin rather than overclaiming ownership. | closed |
| T-06-01-02 | Tampering | Scanner result contract | mitigate | Preserve read-only scanner behavior and keep mutation commands out of model/store/view code. | closed |
| T-06-01-03 | Information Disclosure | Scan-note display | mitigate | Display only scanner limitation messages, not raw private scheduler output, paths beyond existing detail paths, or command stdout. | closed |
| T-06-01-04 | Denial of Service | Inventory aggregation | mitigate | Preserve existing dedupe/sort behavior and aggregate notes without changing scanner execution order or adding live recursive scans. | closed |
| T-06-01-05 | Elevation of Privilege | View-layer scanner IO | avoid | Do not add filesystem reads, process execution, or scheduler-specific branches to SwiftUI views. | closed |
| T-06-02-01 | Tampering | Cron command runner | avoid | Production runner invokes only `/usr/bin/crontab -l`; grep verifies no `-e` or `-r` usage. | closed |
| T-06-02-02 | Information Disclosure | Cron fixtures/docs | mitigate | Use synthetic commands and paths under `/Users/example`; do not commit real crontab output. | closed |
| T-06-02-03 | Denial of Service | Cron parser | mitigate | Parse bounded strings/files from injected sources and skip comments/env lines without recursive filesystem traversal. | closed |
| T-06-02-04 | Spoofing | Cron origin classification | mitigate | Use `.userAuthored` only for current-user crontab and `.system` only for explicit system files; otherwise prefer `.unknown`. | closed |
| T-06-02-05 | Elevation of Privilege | Protected cron files | avoid | Do not require root access; unreadable/protected files produce scan notes. | closed |
| T-06-03-01 | Tampering | Shortcuts scanner | avoid | Production runner invokes only `shortcuts list --show-identifiers`; grep verifies no run/view/sign subcommands. | closed |
| T-06-03-02 | Elevation of Privilege | Automator scanner | avoid | Scanner reads bounded user workflow locations and never executes workflows or opens apps. | closed |
| T-06-03-03 | Spoofing | Registered confidence | mitigate | Use `.registered` and explicit no-schedule-evidence schedule text for Shortcuts and Automator records. | closed |
| T-06-03-04 | Information Disclosure | Fixtures and docs | mitigate | Use synthetic names such as `Morning Routine` and `Resize Images`; do not commit live shortcut or workflow details. | closed |
| T-06-03-05 | Denial of Service | Workflow enumeration | mitigate | Enumerate only injected bounded directories and direct children, not arbitrary recursive home scans. | closed |

---

## Evidence Notes

| Threat ID | Evidence |
|-----------|----------|
| T-06-01-01 | `Sources/ActiveJobsCore/Models/ScheduledJob.swift:28` defines `JobConfidence`; `Sources/ActiveJobsCore/Models/ScheduledJob.swift:63` defines `JobOrigin`; `Sources/ActiveJobsCore/Models/ScheduledJob.swift:151` defaults `ScheduledJob` confidence to `.scheduled` and origin to `.unknown`. Conservative derivation is implemented in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift:187`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift:32`, `Sources/ActiveJobsCore/Services/CronScanner.swift:212`, `Sources/ActiveJobsCore/Services/ShortcutsScanner.swift:84`, and `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:92`. |
| T-06-01-02 | `Sources/ActiveJobsCore/Services/JobScanning.swift:3` defines `JobScanResult`; `Sources/ActiveJobsCore/Services/JobScanning.swift:13` keeps scanners on the read-only `scan()` contract. Production command-backed scanners only list/read: `Sources/ActiveJobsCore/Services/CronScanner.swift:22` uses `/usr/bin/crontab` with `["-l"]`, and `Sources/ActiveJobsCore/Services/ShortcutsScanner.swift:22` uses `/usr/bin/shortcuts` with `["list", "--show-identifiers"]`. |
| T-06-01-03 | `Sources/AutomationHealth/Views/SidebarView.swift:34` appends only a scan-note count to the footer; `Sources/AutomationHealth/Views/SidebarView.swift:43` maps help text from `ScanNote.message` only, excluding `detail`, raw command stdout, and private paths. |
| T-06-01-04 | `Sources/ActiveJobsCore/Services/JobScanning.swift:24` preserves deterministic live scanner order; `Sources/ActiveJobsCore/Services/JobScanning.swift:37` deduplicates by source/id and sorts by next run/name; `Sources/ActiveJobsCore/Services/JobScanning.swift:59` aggregates notes with `results.flatMap(\.notes)`. |
| T-06-01-05 | Grep over `Sources/AutomationHealth/Views/*.swift` found no `Data(contentsOf:)`, `FileManager.default`, `contentsOfDirectory`, `Process(`, `crontab`, `shortcuts`, or `.workflow` scanner IO. Views consume `scanNotes` from `JobStore`, as shown in `Sources/AutomationHealth/Views/ContentView.swift:36` and `Sources/AutomationHealth/Views/SidebarView.swift:13`. |
| T-06-02-01 | `Sources/ActiveJobsCore/Services/CronScanner.swift:22` creates the production process, `Sources/ActiveJobsCore/Services/CronScanner.swift:24` pins `/usr/bin/crontab`, and `Sources/ActiveJobsCore/Services/CronScanner.swift:25` passes only `["-l"]`. Grep found no `crontab.*-e` or `crontab.*-r` in `CronScanner.swift`. |
| T-06-02-02 | Cron tests use synthetic paths and commands: `Sources/ActiveJobsCoreSelfTest/main.swift:293` uses `/Users/example/Scripts/weekday-report.sh`, `Sources/ActiveJobsCoreSelfTest/main.swift:294` uses `/Users/example/Scripts/hourly-check.sh`, and `Sources/ActiveJobsCoreSelfTest/main.swift:321` uses `/usr/libexec/example-maintenance`. Docs also require sanitized fixture data in `docs/scanner-extension-guide.md:34`. |
| T-06-02-03 | `Sources/ActiveJobsCore/Services/CronScanner.swift:65` builds jobs/notes from injected command/file sources; `Sources/ActiveJobsCore/Services/CronScanner.swift:115` enumerates configured cron tab directories only one level deep; `Sources/ActiveJobsCore/Services/CronScanner.swift:196` skips blank/comment/environment lines via `isEnvironmentAssignment`; `Sources/ActiveJobsCore/Services/CronScanner.swift:230` and `Sources/ActiveJobsCore/Services/CronScanner.swift:240` parse special and five-field forms without recursive traversal. |
| T-06-02-04 | `Sources/ActiveJobsCore/Services/CronScanner.swift:71` classifies current-user crontab jobs as `.userAuthored`; `Sources/ActiveJobsCore/Services/CronScanner.swift:97` and `Sources/ActiveJobsCore/Services/CronScanner.swift:139` classify configured system cron files as `.system`; `Sources/ActiveJobsCore/Models/ScheduledJob.swift:151` keeps the model default origin `.unknown` for callers without ownership evidence. |
| T-06-02-05 | `Sources/ActiveJobsCore/Services/CronScanner.swift:86` and `Sources/ActiveJobsCore/Services/CronScanner.swift:115` handle missing cron files/directories as scan notes; `Sources/ActiveJobsCore/Services/CronScanner.swift:105`, `Sources/ActiveJobsCore/Services/CronScanner.swift:147`, and `Sources/ActiveJobsCore/Services/CronScanner.swift:156` convert unreadable files/directories to warning notes. No root escalation path is present. |
| T-06-03-01 | `Sources/ActiveJobsCore/Services/ShortcutsScanner.swift:22` creates the production process, `Sources/ActiveJobsCore/Services/ShortcutsScanner.swift:24` pins `/usr/bin/shortcuts`, and `Sources/ActiveJobsCore/Services/ShortcutsScanner.swift:25` passes only `["list", "--show-identifiers"]`. Grep found no `shortcuts.*run`, `shortcuts.*view`, or `shortcuts.*sign` in `ShortcutsScanner.swift`. |
| T-06-03-02 | `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:18` derives the bounded default locations `~/Library/Services` and `~/Library/Workflows`; `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:37` enumerates only direct children; `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:62` parses workflow metadata only. The file contains no `Process`, `NSWorkspace`, app launch, or workflow execution path. |
| T-06-03-03 | `Sources/ActiveJobsCore/Services/ShortcutsScanner.swift:84` creates Shortcuts jobs with `.registered` confidence and `Registered shortcut (no schedule evidence)`; `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:92` creates Automator jobs with `.registered` confidence and `Automator workflow (no schedule evidence)`. |
| T-06-03-04 | Shortcuts and Automator tests use synthetic fixture names: `Sources/ActiveJobsCoreSelfTest/main.swift:364` uses `Morning Routine (ABC-123)`, and `Sources/ActiveJobsCoreSelfTest/main.swift:398` creates `Resize Images.workflow`. `docs/scanner-extension-guide.md:34` directs scanner tests to use synthetic values and avoid real local paths, hostnames, scheduler output, tokens, or secrets. |
| T-06-03-05 | `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:18` limits default directories; `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:37` uses `contentsOfDirectory` on each configured directory and iterates direct children only; no recursive enumerator is present. Missing and unreadable locations become notes at `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:26` and `Sources/ActiveJobsCore/Services/AutomatorScanner.swift:49`. |

No `## Threat Flags` sections were present in `06-01-SUMMARY.md`, `06-02-SUMMARY.md`, or `06-03-SUMMARY.md`.

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-08 | 15 | 15 | 0 | Codex |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-08
