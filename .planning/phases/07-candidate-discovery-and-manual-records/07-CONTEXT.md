# Phase 07: Candidate Discovery And Manual Records - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 lets users account for automations that Automation Health cannot prove as scheduled jobs. It adds bounded Candidate script discovery, app-only Manual record create/edit/remove flows, local manual-record persistence, and presentation updates so Candidate and Manual records move through the same inventory, search, sidebar, selection, and detail surfaces as scheduled and registered records.

This phase preserves the read-only product boundary for real automations. It must not edit, remove, run, validate, rewrite, schedule, or infer execution for scheduler jobs, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata.

</domain>

<spec_lock>
## UI Design Contract (locked via UI-SPEC)

The Phase 7 UI contract is approved. Downstream agents MUST read `.planning/phases/07-candidate-discovery-and-manual-records/07-UI-SPEC.md` before planning or implementing. Requirements and visual/copy details are not duplicated in full here.

**In scope (from UI-SPEC):**
- Show candidate script discoveries as Candidate records with no schedule evidence.
- Add, edit, and remove Manual records through app-owned storage only.
- Make confidence and origin visible in sidebar/detail presentation.
- Update search, empty-state, toolbar, and detail copy from scheduler-only language to supported automation inventory language.
- Keep scanner IO and manual persistence behind `ActiveJobsCore` and `JobStore`; SwiftUI views must not read scheduler files, script files, or manual JSON directly.

**Out of scope (from UI-SPEC):**
- Editing, removing, running, validating, or rewriting real scheduler jobs, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata.
- User-configurable candidate scan folders or ignore rules; future preferences own that.
- Sidebar grouping modes, collapsible sections, and custom focus treatment; Phase 8 owns those.
- Inferring that a script is scheduled by reading shell history, editor history, terminal history, or broad home-directory content.

</spec_lock>

<decisions>
## Implementation Decisions

### Candidate Scan Bounds
- **D-01:** Candidate discovery should scan only these documented bounded default roots: `~/Scripts`, `~/bin`, `~/.local/bin`, `~/Library/Scripts`, and `~/Documents/Scripts`.
- **D-02:** Candidate discovery should traverse at most two directory levels below each configured root.
- **D-03:** Candidate discovery should skip hidden files/directories and known build, dependency, cache, or virtual-environment directories such as `.git`, `.build`, `build`, `dist`, `DerivedData`, `node_modules`, `vendor`, `.venv`, `venv`, `__pycache__`, and `.swiftpm`.
- **D-04:** Candidate discovery should include script-like extensions (`.sh`, `.zsh`, `.bash`, `.command`, `.py`, `.rb`, `.js`, `.swift`, `.scpt`, `.applescript`, `.pl`) and extensionless executable regular files only inside explicitly script-like roots such as `~/bin` and `~/.local/bin`.
- **D-05:** Candidate discovery should avoid full file-content reads. It may use metadata, path, executable bit, size, and at most a tiny first-line/shebang read if needed.
- **D-06:** Candidate discovery should cap visited files and results, using the research defaults unless planning finds a stronger local reason: `maxVisitedFiles = 2_000`, `maxResults = 200`, and `maximumCandidateBytes = 1_000_000`.
- **D-07:** Candidate discovery should emit `ScanNote` values when roots are missing/unreadable, files are skipped for size/rules, or traversal/result caps are reached.
- **D-08:** Candidate records must never infer execution, last run, next run, or scheduling from file presence, metadata, or script contents. Use `JobConfidence.candidate`, `JobSource.candidateScripts`, `origin = .userAuthored`, `state = "candidate"`, and schedule text `Script candidate (no schedule evidence)`.

### Manual Record Lifecycle
- **D-09:** Manual records live only in app-owned JSON under `~/Library/Application Support/AutomationHealth/manual-records.json`.
- **D-10:** Manual record storage should use a small testable store with injected file URL and JSON encoding/decoding. It should create the Application Support directory as needed and write atomically where practical.
- **D-11:** Manual record fields should follow the approved UI-SPEC: required `Name`, required `Origin` picker defaulting to `Unknown`, optional `Schedule description`, optional `Command or path`, and optional multiline `Notes`.
- **D-12:** Manual persisted fields should include stable identity and timestamps: `id`, `name`, `notes`, `command`, `scheduleDescription`, `origin`, `createdAt`, and `updatedAt`.
- **D-13:** Manual records convert to `ScheduledJob` with `JobSource.manualRecords`, `JobConfidence.manual`, the stored origin, `state = "manual"`, schedule text from the record or `Manual record (no schedule evidence)`, and definition from notes or `Manual app record: {name}`.
- **D-14:** Add/edit/remove methods belong on `JobStore` or a store-level facade; SwiftUI views should call those methods and must not read/write manual JSON directly.
- **D-15:** After create, select the created Manual record. After edit, keep the edited Manual record selected. After remove, move selection to the next visible record when possible, otherwise the first visible record.
- **D-16:** Malformed manual JSON should be surfaced as a recoverable app-storage error or scan note. Do not silently delete, overwrite, or regenerate the file in a way that loses user-entered records.

### Inventory Presentation Fit
- **D-17:** Phase 7 should keep the current source-sectioned sidebar model. Do not introduce grouping modes, collapsible sections, or custom focus treatment; those remain Phase 8 scope.
- **D-18:** Sidebar rows should add visible confidence text in the secondary line using the UI-SPEC format `{confidenceName} - {schedule or next run}` inside source sections.
- **D-19:** Detail should add visible `Confidence` and `Origin` status cards and source-specific SF Symbol mapping for launchd, Hermes cron, cron, Shortcuts, Automator, Candidate scripts, and Manual records.
- **D-20:** Candidate detail copy should use the approved fallbacks: `Script candidate (no schedule evidence)`, `Candidate script discovered at {path}.`, `Candidate records do not include run output until a scheduler source proves execution.`, and reveal label `Reveal Script`.
- **D-21:** Manual detail copy should use the approved fallbacks: `Manual record (no schedule evidence)`, `Manual app record: {name}`, `Manual records do not include run output.`, edit label `Edit Manual Record`, and destructive label `Remove Manual Record`.
- **D-22:** Search should include name, source, confidence, origin, schedule, command/path, definition, manual notes, and candidate paths.
- **D-23:** Existing launchd, Hermes cron, cron, Shortcuts, and Automator records must continue through the same inventory, `JobStore`, `JobPresentation`, sidebar, detail, search, selection, scan-note, and CI paths after Candidate and Manual sources are added.
- **D-24:** Copy should shift from scheduler-only wording to `automation records` and `inventory`, while never implying Automation Health can edit, repair, schedule, run, or delete real automations.

### the agent's Discretion
Downstream agents may choose exact Swift type names, helper breakdown, JSON coding details, cap constant names, deterministic fixture shapes, and whether manual persistence is modeled as one store or a store plus scanner facade. They must preserve the UI-SPEC, the read-only boundary for real automation sources, the bounded candidate defaults, and the existing `ActiveJobsCore`/`JobStore`/presentation separation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` — Defines Phase 7 goal, success criteria, planned waves, dependencies, and fixed phase boundary.
- `.planning/REQUIREMENTS.md` — Defines Phase 7 requirements `DISC-06`, `DISC-08`, `MAN-01`, `MAN-02`, `MAN-03`, and `QUAL-03`, plus read-only and bounded-discovery out-of-scope constraints.
- `.planning/PROJECT.md` — Captures core value, read-only posture, confidence/origin decisions, and current milestone context.
- `.planning/STATE.md` — Current GSD state and warning about preserving unrelated working-tree changes.

### Phase 7 Contracts
- `.planning/phases/07-candidate-discovery-and-manual-records/07-UI-SPEC.md` — Approved UI design contract, copy, form fields, source/state contract, accessibility requirements, and Phase 8 exclusions.
- `.planning/phases/07-candidate-discovery-and-manual-records/07-RESEARCH.md` — Research defaults for candidate scan roots, bounds, ignore rules, manual store shape, validation architecture, and security pitfalls.

### Existing Scanner And Documentation Contracts
- `docs/scanner-extension-guide.md` — Scanner adapter recipe, `JobScanResult`/`ScanNote` contract, confidence/origin semantics, fixture guidance, and view IO boundary.
- `docs/scheduled-job-sources.md` — Existing supported-source documentation to update with Candidate scripts and Manual records while preserving honest evidence language.
- `README.md` — Public source-support and limitation summary to update from scheduler-only inventory to broader automation records.

### Existing Source Files
- `Sources/ActiveJobsCore/Models/ScheduledJob.swift` — Add Candidate/Manual `JobSource` cases and preserve source-independent confidence/origin model.
- `Sources/ActiveJobsCore/Services/JobScanning.swift` — Live inventory composition and result aggregation integration point.
- `Sources/AutomationHealth/Stores/JobStore.swift` — Refresh/selection owner and correct place to expose manual create/edit/remove methods to SwiftUI.
- `Sources/AutomationHealth/Models/JobPresentation.swift` — Search text, source/confidence/origin display, sidebar summaries, and section generation.
- `Sources/AutomationHealth/Views/ContentView.swift` — Toolbar action and inventory search shell.
- `Sources/AutomationHealth/Views/SidebarView.swift` — Source-sectioned row rendering, scan-note footer, and Up/Down navigation through visible jobs.
- `Sources/AutomationHealth/Views/DetailView.swift` — Detail status cards, fallback copy, source icon mapping, reveal/edit/remove action surfaces, and AppKit reveal integration.
- `Sources/ActiveJobsCoreSelfTest/main.swift` — Existing executable self-test target for fixture coverage.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `JobConfidence`, `JobOrigin`, `ScanNote`, and `JobScanResult` already exist in `Sources/ActiveJobsCore/Models/ScheduledJob.swift` and `Sources/ActiveJobsCore/Services/JobScanning.swift`.
- `JobInventory.live(homeDirectory:)` already composes deterministic scanners and can add Candidate and Manual sources without changing SwiftUI view IO.
- `JobPresentation` already exposes `confidenceName`, `originName`, and `searchText`; Phase 7 should extend those fields for notes/paths rather than inventing source-specific view branches.
- `SidebarJobSection.sections(for:)` already groups visible jobs by `JobSource.allCases`; adding `candidateScripts` and `manualRecords` to `JobSource` should naturally add source sections.
- `JobStore.refresh()` already preserves selection when possible and selects the first refreshed job otherwise; manual mutation methods should align with that selection policy.
- `DetailView` already has status cards, text sections, read-only selectable log text, and Finder reveal via `NSWorkspace`.

### Established Patterns
- Scanner IO belongs in `Sources/ActiveJobsCore`; SwiftUI views consume `JobStore`, `JobPresentation`, and normalized `ScheduledJob` values.
- New scanners should accept injected paths, file managers, or command runners so tests do not depend on live machine state.
- Source limitations and confidence boundaries should be visible as `ScanNote` values, not fatal refresh failures when the rest of inventory can still load.
- No new third-party Swift dependencies are needed for this phase.
- Fixture/self-test coverage lives in `Sources/ActiveJobsCoreSelfTest/main.swift` and is run by `./script/ci.sh`.

### Integration Points
- Add `CandidateScriptScanner` under `Sources/ActiveJobsCore/Services` and compose it in `JobInventory.live(homeDirectory:)`.
- Add app-owned manual persistence below the view layer, then expose add/update/remove methods through `JobStore`.
- Update `ContentView` toolbar copy and add the manual-record action surface without giving mutation controls to non-manual records.
- Update `SidebarView` row subtitle and empty-state copy to use inventory/automation-record language.
- Update `DetailView` source icon mapping, Confidence/Origin cards, Candidate/Manual fallback text, reveal behavior, and manual edit/remove controls.
- Update `docs/scheduled-job-sources.md`, `docs/scanner-extension-guide.md` if needed, and `README.md` to document candidate/manual evidence boundaries.

</code_context>

<specifics>
## Specific Ideas

- Candidate source display name should be `Candidate scripts`; manual source display name should be `Manual records`.
- Candidate records should use SF Symbol `doc.text.magnifyingglass`; Manual records should use `square.and.pencil`.
- The primary toolbar actions should be `Add Manual Record` with `plus` and `Rescan Inventory` with `arrow.clockwise`.
- Manual remove confirmation must explicitly say real scheduler files and scripts are not changed.
- Prompt UI was unavailable in this Codex mode, so this context uses the workflow fallback: all three gray areas were discussed with recommended defaults selected from the approved UI-SPEC and Phase 7 research.

</specifics>

<deferred>
## Deferred Ideas

- User-configurable candidate scan folders and ignore rules belong to future preferences work.
- Sidebar grouping modes, collapsible sections, and custom focus treatment remain Phase 8 scope.

</deferred>

---

*Phase: 07-candidate-discovery-and-manual-records*
*Context gathered: 2026-05-08*
