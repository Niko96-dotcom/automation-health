# Phase 7: Candidate Discovery And Manual Records - Research

**Researched:** 2026-05-08
**Domain:** Bounded local candidate discovery, app-only manual records, search/detail integration
**Confidence:** HIGH

## Context Status

No `07-CONTEXT.md` exists for this phase. Planning should use the locked roadmap scope, Phase 6 summaries, current source contracts, and the v1.1 milestone audit. Because Phase 7 has `UI hint: yes`, the UI design contract gate is applicable before `PLAN.md` files are generated.

Phase 7 depends on Phase 6. The current working tree already contains the Phase 6 inventory contract:

- `JobConfidence` includes `.candidate` and `.manual`.
- `JobOrigin` is source-independent.
- `JobScanResult` carries jobs plus source-specific `ScanNote` values.
- `JobInventory.live(homeDirectory:)` composes deterministic scanners.
- `JobPresentation` indexes source, confidence, origin, schedule, command, and definition for search.
- Sidebar sections currently group by `JobSource.allCases`; detail cards do not visibly expose confidence/origin yet.

## Phase Scope

Phase 7 should let users account for automations that are not proven scheduled jobs:

- Add bounded script candidate discovery from documented user locations only.
- Label script discoveries with `JobConfidence.candidate`, not Scheduled or Registered.
- Document candidate scan bounds, ignore rules, permission behavior, and failure notes.
- Add app-only manual records with create, edit, delete, local persistence, and Manual confidence.
- Include candidate and manual records in the same inventory, search, selection, and detail path as existing records.
- Preserve read-only behavior for real scheduler files and discovered scripts.

Out of scope:

- Running scripts, validating scripts, or inferring schedules from script contents.
- Editing discovered scripts or real scheduler definitions.
- User-configurable candidate scan folders; `PREF-02` defers that to a future release.
- Sidebar grouping/collapse modes; Phase 8 owns richer grouping controls.

## Requirements Mapping

| Requirement | Planning Implication |
|-------------|----------------------|
| DISC-06 | Add a bounded candidate scanner below the view layer with documented default locations, ignore rules, result caps, and `JobConfidence.candidate`. |
| DISC-08 | Ensure candidate and manual records flow through `JobInventory`, `JobStore`, `JobPresentation`, sidebar search, selection, and detail without source-specific view IO. |
| MAN-01 | Add a manual record creation path in app UI that writes only app-owned local data. |
| MAN-02 | Add edit and remove flows for manual records, with no mutation APIs for real scheduled jobs or scripts. |
| MAN-03 | Persist manual records locally and label them with `JobConfidence.manual` and an app-owned source/display path. |
| QUAL-03 | Add tests and docs proving candidate scan bounds, ignore rules, skipped files, cap notes, and failure behavior. |

## Current Architecture Findings

`ActiveJobsCore` is still the right home for scanner and inventory contracts. Candidate discovery should be another `JobScanning` implementation under `Sources/ActiveJobsCore/Services` with injected directories and `FileManager` for tests.

Manual records need both read and write behavior, but only for app-owned data. The safest shape is a small local store type with injected file URL and JSON encoding. `JobInventory.live` can include a read-only manual-record scanner/view over that store, while `JobStore` exposes create/edit/remove methods that call the app-owned store and then refresh. SwiftUI views should call `JobStore` methods, not touch files directly.

The current UI already has a searchable sidebar and detail view, but copy and icons still assume scheduler-backed records in several places:

- `ContentView` refresh help says "Scan launchd and Hermes cron jobs again".
- `EmptySelectionView` says "Refresh to scan launchd and Hermes cron jobs."
- `DetailView` chooses a Hermes icon or generic gear only; candidate/manual need explicit source-neutral icon mapping.
- `StatusOverview` has Source, Health, Next Run, Last Run cards but not visible Confidence or Origin.
- `SidebarJobSummary.subtitle` shows source plus schedule/next-run, but not confidence.

Those are integration targets for Phase 7, while Phase 8 can later reorganize grouping and focus behavior.

## Recommended Implementation Split

1. **Candidate scanner and docs:** Add `JobSource.candidateScripts` plus `CandidateScriptScanner` with bounded defaults, ignore rules, scan notes, fixture tests, and source docs.
2. **Manual record storage and mutation flow:** Add `JobSource.manualRecords`, `ManualAutomationRecord`, and `ManualRecordStore`; expose `JobStore.addManualRecord`, `updateManualRecord`, and `removeManualRecord`; add SwiftUI create/edit/remove surfaces that write only app-owned JSON.
3. **Presentation integration:** Update search/detail/sidebar copy and visible labels so candidate and manual records are clearly marked and existing launchd/Hermes/cron/Shortcuts/Automator records still render through the same presentation path.

This follows the roadmap's three planned waves and keeps manual mutation separate from scanner-source mutation.

## Candidate Discovery Research

Recommended default locations should be explicit and bounded:

- `~/Scripts`
- `~/bin`
- `~/.local/bin`
- `~/Library/Scripts`
- `~/Documents/Scripts`

Recommended bounds:

- Traverse only the configured roots and at most two directory levels below each root.
- Skip hidden files and hidden directories.
- Skip known dependency/build/cache directories: `.git`, `.build`, `build`, `dist`, `DerivedData`, `node_modules`, `vendor`, `.venv`, `venv`, `__pycache__`, `.swiftpm`.
- Consider script-like files by extension: `.sh`, `.zsh`, `.bash`, `.command`, `.py`, `.rb`, `.js`, `.swift`, `.scpt`, `.applescript`, `.pl`.
- Also include executable regular files with no extension only inside explicitly script-like directories such as `~/bin` and `~/.local/bin`.
- Avoid reading full file contents. Use file metadata, path, executable bit, size, and optionally a tiny first-line/shebang read if needed.
- Cap candidate results, for example `maxResults = 200`, and cap visited files, for example `maxVisitedFiles = 2_000`.
- Skip files larger than a small threshold, for example `maximumCandidateBytes = 1_000_000`, and report skipped/capped behavior through `ScanNote`.

Recommended `ScheduledJob` values:

- `source`: `.candidateScripts`
- `confidence`: `.candidate`
- `origin`: `.userAuthored`
- `schedule`: `Script candidate (no schedule evidence)`
- `state`: `candidate`
- `command`: script path
- `definition`: `Candidate script: <path>`
- `lastRun`, `nextRun`, `lastStatus`, `lastRunDetails`: nil unless metadata gives safe evidence; do not infer execution.
- `detailPath`: script path, for Finder reveal only if the UI exposes it.

Important guardrails:

- Do not execute scripts.
- Do not parse private shell history, editor history, terminal history, or broad home-directory content.
- Do not crawl arbitrary `~/Documents` beyond the documented `Scripts` folder.
- Do not label candidates as Scheduled or Registered unless a deterministic scanner provides stronger evidence.

## Manual Records Research

Manual records should be app-owned metadata. A simple JSON store is enough and avoids new dependencies.

Recommended storage path:

- `~/Library/Application Support/AutomationHealth/manual-records.json`

Recommended record fields:

- `id: UUID`
- `name: String`
- `notes: String`
- `command: String?`
- `scheduleDescription: String?`
- `origin: JobOrigin`
- `createdAt: Date`
- `updatedAt: Date`

Recommended conversion to `ScheduledJob`:

- `source`: `.manualRecords`
- `confidence`: `.manual`
- `origin`: record origin, default `.unknown`
- `schedule`: record schedule text or `Manual record (no schedule evidence)`
- `state`: `manual`
- `definition`: notes or `Manual app record: <name>`
- `detailPath`: nil unless the user explicitly stores a path in a future phase.

Mutation safety rules:

- Add, edit, and remove only the app-owned JSON file.
- Never write to launchd plists, crontabs, script files, Shortcuts, Automator bundles, or Hermes metadata.
- Keep scanner refresh read-only for real scheduler sources.
- Use atomic JSON writes where available and create the Application Support directory as needed.
- Treat malformed JSON as a recoverable app-storage note or surfaced error, not as permission to delete the file.

UI planning notes:

- Phase 7 needs a UI-SPEC before planning because create/edit/remove flows affect layout, copy, validation, and destructive-action affordances.
- The first implementation can use a toolbar add button and a sheet/form for manual record fields.
- Edit/remove controls should appear only for `.manualRecords`; discovered scanner records should not show mutation controls.
- Manual records should be visibly labeled Manual in detail and searchable by name, notes, command, origin, and confidence.

## Search And Detail Integration

Current search can already index confidence and origin through `JobPresentation.searchText`. Phase 7 should extend this by adding manual notes and candidate paths through `definition` and `command`, then verifying search hits for:

- Candidate script file name.
- Candidate script parent path text.
- Manual record name.
- Manual record notes.
- Manual confidence text.
- Existing launchd/Hermes/cron records after the new sources are added.

Detail integration should make evidence strength visible. Recommended additions:

- Add a Confidence card or detail line using `job.confidenceName` and `job.job.confidence.description`.
- Add an Origin card or detail line using `job.originName`.
- Add source-icon mapping for launchd, Hermes cron, cron, Shortcuts, Automator, candidate scripts, and manual records.
- Update empty-state and toolbar copy to refer to supported automation inventory, not only launchd and Hermes cron.

## Validation Architecture

Phase 7 can be validated with the existing SwiftPM and executable self-test flow:

- Quick command: `./script/test.sh`
- Full command: `./script/ci.sh`
- Core fixture target: `Sources/ActiveJobsCoreSelfTest/main.swift`

Tests should cover:

- `CandidateScriptScanner` only scans injected bounded directories.
- Candidate scanner ignores hidden, build, dependency, cache, and oversized files.
- Candidate scanner caps traversal/results and emits `ScanNote` values for bounds and unreadable inputs.
- Candidate records use `.candidate` confidence and no schedule evidence.
- `ManualRecordStore` creates, reads, updates, deletes, and preserves records through synthetic JSON fixtures.
- Manual records convert to `ScheduledJob` with `.manual` confidence and app-owned source.
- `JobInventory` includes candidate/manual records while preserving existing source sort/dedupe behavior.
- `JobStore` manual add/edit/remove methods refresh presentation state without mutating scheduler files.
- `JobPresentation.searchText` and sidebar/detail integration include candidate/manual text.
- View-boundary grep proves candidate/manual file IO remains out of SwiftUI views except through store actions.

Manual verification should cover the sheet/form workflow because SwiftUI UI interactions are not currently under XCTest:

- Add a manual record, verify it appears in sidebar and detail.
- Edit the record, verify the updated text appears in search/detail.
- Remove the record, verify it disappears and no scheduler files or discovered scripts changed.
- Search for candidate and manual terms and verify selection remains stable.

## Security Domain

Security enforcement is applicable. The main risks are accidental mutation of real automations, excessive filesystem traversal, and disclosure of private script paths or notes.

Threat model topics for every plan:

- **T-07-01 real automation mutation:** Candidate and scanner records must never expose edit/remove behavior that writes scheduler files or scripts.
- **T-07-02 unbounded traversal:** Candidate discovery must stay inside documented roots with depth, result, visited-file, and size caps.
- **T-07-03 data disclosure:** Docs/tests must use synthetic paths and records; public examples must not include real local automation names or script contents.
- **T-07-04 manual store corruption:** Manual record writes must be app-owned, atomic where practical, and tolerant of malformed input.
- **T-07-05 UI affordance confusion:** Manual edit/remove controls must be scoped to manual records so users do not think Automation Health can edit real jobs.

## Common Pitfalls

| Pitfall | Why It Matters | Plan Guardrail |
|---------|----------------|----------------|
| Crawling the whole home directory | Violates performance and privacy scope. | Use only documented roots, max depth, file count, result count, and size caps. |
| Treating script files as scheduled jobs | A script on disk is not proof of automation. | Use `.candidate` confidence and explicit no-schedule-evidence schedule text. |
| Putting manual JSON writes in SwiftUI views | Breaks the scanner/view boundary and makes behavior harder to test. | Expose store methods; keep persistence in a testable support type. |
| Adding edit/remove controls to all records | Risks implying or implementing real scheduler mutation. | Gate manual actions by `.manualRecords` source only. |
| Live-machine tests | Contributor machines have different scripts and paths. | Use injected directories, synthetic fixtures, and stub stores. |
| Hiding confidence in detail/sidebar | Users cannot tell Candidate or Manual from proven scheduled jobs. | Add visible confidence/origin display in Phase 7 integration. |

## Sources

- Repository files verified locally: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/v1.1-MILESTONE-AUDIT.md`, Phase 6 `SUMMARY.md` and `VERIFICATION.md` files, `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`, `Sources/AutomationHealth/Views/DetailView.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`, `docs/scheduled-job-sources.md`, and `docs/scanner-extension-guide.md`.
- Local architectural evidence: scanner IO lives in `ActiveJobsCore`; SwiftUI views consume `JobStore` and `JobPresentation`; current self-tests use injected paths and command runners.
