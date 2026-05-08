# Phase 07: Candidate Discovery And Manual Records - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 07-candidate-discovery-and-manual-records
**Areas discussed:** Candidate scan bounds, Manual record lifecycle, Inventory presentation fit

---

## Workflow Note

The structured `AskUserQuestion` equivalent was unavailable in Codex Default mode. Per the skill adapter fallback, the discussion used recommended defaults selected from the approved UI-SPEC, Phase 7 research, current codebase contracts, and prior project decisions.

---

## Candidate Scan Bounds

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded common script folders | Scan `~/Scripts`, `~/bin`, `~/.local/bin`, `~/Library/Scripts`, and `~/Documents/Scripts`. | ✓ |
| Only executable PATH-like folders | Limit candidates to executable files under `~/bin` and `~/.local/bin`. | |
| User-configurable folders | Let users choose folders and ignore rules now. | |

**User's choice:** Fallback selected the recommended bounded common script folders.
**Notes:** User-configurable folders are deferred to future preferences work. Phase 7 should document all defaults and limits.

| Option | Description | Selected |
|--------|-------------|----------|
| Script-like files plus PATH-like executables | Include known script extensions and extensionless executables only inside PATH-like script folders. | ✓ |
| Executable files only | Include only files with executable bits. | |
| Any automation-looking file | Use broader heuristics over filenames or content. | |

**User's choice:** Fallback selected script-like files plus PATH-like executables.
**Notes:** Avoid broad content inspection and do not infer scheduling.

| Option | Description | Selected |
|--------|-------------|----------|
| Strict documented caps | Use max depth, max visited files, max results, max size, and skip rules with scan notes. | ✓ |
| Broader best-effort traversal | Search more widely under user folders. | |
| Configurable traversal | Expose controls for traversal depth and ignore rules now. | |

**User's choice:** Fallback selected strict documented caps.
**Notes:** This matches `QUAL-03` and the product's privacy/performance boundary.

| Option | Description | Selected |
|--------|-------------|----------|
| No execution inference | Candidate records never imply last run, next run, or schedule evidence. | ✓ |
| Infer from metadata | Use file modified dates or executable bits as weak run evidence. | |
| Infer from contents | Read script contents to infer automation status. | |

**User's choice:** Fallback selected no execution inference.
**Notes:** Candidate means possible automation only; stronger evidence belongs to deterministic scanner sources.

---

## Manual Record Lifecycle

| Option | Description | Selected |
|--------|-------------|----------|
| Application Support JSON | Store app-owned manual records in `~/Library/Application Support/AutomationHealth/manual-records.json`. | ✓ |
| Project-local file | Store records in the repository or app working directory. | |
| System scheduler metadata | Store records alongside real scheduler files. | |

**User's choice:** Fallback selected Application Support JSON.
**Notes:** Storage must be app-owned and testable through injected file URLs.

| Option | Description | Selected |
|--------|-------------|----------|
| UI-SPEC form fields | Required name and origin, optional schedule description, command/path, and notes. | ✓ |
| Minimal name-only records | Capture only a manual record name initially. | |
| Advanced scheduler-shaped fields | Ask users to fill fields resembling launchd/cron metadata. | |

**User's choice:** Fallback selected UI-SPEC form fields.
**Notes:** Keep manual records approachable and avoid implying real scheduler control.

| Option | Description | Selected |
|--------|-------------|----------|
| Stable selection behavior | Select created record, keep edited record selected, move sensibly after removal. | ✓ |
| Always reset to first row | Return to the first visible record after every mutation. | |
| Clear selection after mutations | Leave detail empty after create/edit/remove. | |

**User's choice:** Fallback selected stable selection behavior.
**Notes:** Matches existing refresh preservation behavior.

| Option | Description | Selected |
|--------|-------------|----------|
| Recoverable error | Surface malformed JSON as an error/note without deleting or overwriting it. | ✓ |
| Overwrite automatically | Replace malformed storage with an empty valid file. | |
| Ignore silently | Skip manual records without telling the user. | |

**User's choice:** Fallback selected recoverable error.
**Notes:** Protect user-entered manual metadata from silent data loss.

---

## Inventory Presentation Fit

| Option | Description | Selected |
|--------|-------------|----------|
| Source-sectioned with confidence text | Keep current source sections and add confidence to row subtitles. | ✓ |
| New confidence grouping | Group by Scheduled, Registered, Candidate, and Manual now. | |
| Flat list | Remove sections and show one list. | |

**User's choice:** Fallback selected source-sectioned with confidence text.
**Notes:** Grouping modes and collapsible sections are Phase 8 scope.

| Option | Description | Selected |
|--------|-------------|----------|
| Confidence and Origin cards | Add visible detail cards while preserving existing status cards. | ✓ |
| Sidebar labels only | Show confidence/origin in the list but not detail. | |
| Source-specific detail pages | Build separate detail layouts per source. | |

**User's choice:** Fallback selected Confidence and Origin cards.
**Notes:** Keep one shared presentation path.

| Option | Description | Selected |
|--------|-------------|----------|
| Inventory language | Use automation records/inventory copy and evidence-first wording. | ✓ |
| Keep job-only language | Continue referring broadly to jobs and schedulers. | |
| Source-specific marketing language | Use more descriptive labels per source. | |

**User's choice:** Fallback selected inventory language.
**Notes:** Avoid implying the app can edit, run, repair, or delete real automations.

| Option | Description | Selected |
|--------|-------------|----------|
| Same presentation path | Existing and new records flow through `JobStore`, `JobPresentation`, sidebar, detail, and tests. | ✓ |
| Separate candidate/manual views | Build special surfaces for Candidate and Manual records. | |
| Rewrite sidebar architecture | Rebuild sidebar around the broader inventory model now. | |

**User's choice:** Fallback selected same presentation path.
**Notes:** Existing launchd, Hermes cron, cron, Shortcuts, and Automator behavior must not regress.

---

## the agent's Discretion

- Exact Swift type names, helper breakdown, cap constant names, JSON encoding details, and fixture organization.
- Whether manual persistence is modeled as one store or a store plus scanner facade, as long as SwiftUI views do not perform direct JSON IO.

## Deferred Ideas

- User-configurable candidate scan folders and ignore rules belong to future preferences work.
- Sidebar grouping modes, collapsible sections, and custom focus treatment remain Phase 8 scope.
