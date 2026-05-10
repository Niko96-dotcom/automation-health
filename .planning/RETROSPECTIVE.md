# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 - Sidebar Navigation

**Shipped:** 2026-05-08
**Phases:** 3 | **Plans:** 8 | **Tasks:** 23

### What Was Built

- Source-ordered sidebar section data from visible `JobPresentation` values.
- Filter-then-group sidebar rendering with compact source headers and row-only selection.
- Up and Down keyboard navigation across visible jobs, including boundary behavior and hidden-selection handling.
- Keyboard-originated scroll reveal that keeps selected visible rows in view without affecting mouse selection, search changes, or refresh preservation.
- Compact sidebar polish with a non-selectable filtered empty state and quiet row hover feedback.
- Milestone audit fix for deterministic relative run labels, restoring the full local CI gate.

### What Worked

- Keeping grouping and navigation logic in presentation helpers made the SwiftUI surface smaller and easier to verify.
- The phase summaries and verification files gave the milestone audit enough evidence to cross-check requirements without re-discovering the whole codebase.
- Manual sidebar verification stayed lightweight by recording evidence in the existing phase summary instead of creating another artifact stream.

### What Was Inefficient

- The date-sensitive self-test failure was carried as an unrelated warning through multiple phases before being fixed at milestone close.
- QUAL-04 was interpreted as acceptable with warning during phase verification, but the milestone audit correctly treated the non-zero CI gate as a blocker.

### Patterns Established

- Filter visible jobs before grouping so section counts and keyboard traversal share the same source of truth.
- Keep sidebar section headers organizational only; selection and keyboard traversal should operate only on real job rows.
- Use deterministic reference dates in humanizer tests and implementations.

### Key Lessons

1. A full release gate should stay binary: a non-zero CI command is a blocker, even if the immediate feature appears unrelated.
2. Presentation helpers are a good place for non-UI behavior that needs focused self-test coverage in this SwiftPM app.
3. Audit-time fixes should be committed before milestone archive/tag work so the shipped tag includes the release gate repair.

### Cost Observations

- Model mix: not tracked.
- Sessions: not tracked.
- Notable: The GSD audit caught a real quality gate gap after phase-level verification had accepted it as a warning.

---

## Milestone: v1.1 — Open Source Readiness and Broad Inventory

**Shipped:** 2026-05-10
**Phases:** 6 | **Plans:** 16 | **Tasks:** 63

### What Was Built

- Public repository health files, privacy-safe issue/PR templates, scanner extension guide, and clearly named local CI workflow (Phase 4).
- Pulse Grid app icon source art and deterministic local iconset/ICNS pipeline integrated into the local `.app` bundle (Phase 5).
- Source-neutral `JobConfidence`/`JobOrigin`/`JobScanResult`/`ScanNote` contract plus CronScanner, ShortcutsScanner, AutomatorScanner (Phase 6).
- Bounded CandidateScriptScanner and app-owned ManualRecordStore with create/edit/remove SwiftUI flows (Phase 7).
- Shared `AutomationHealthCore` presentation target, five sidebar grouping modes with disclosure-section collapse, search-aware reveal, and restrained custom focus cue (Phase 8).
- Private-neutral display-name normalization, sanitized public-visual guidance, and full publication verification (CI, app bundle, smoke evidence, traceability) (Phase 9).

### What Worked

- Strong evidence chain across SUMMARY → VERIFICATION → audit allowed the milestone to be closed even after a major commit-discipline failure during execution.
- Forensic recovery: when the executor's atomic-commit step never fired across 11 consecutive plans, the per-plan SUMMARYs (with explicit `Files Created/Modified` lists) made post-hoc reconstruction tractable.
- Phase-level commit granularity (one commit per phase) struck a clean balance between honest chronology and per-plan over-granularization for a multi-file working tree we could not cleanly split per-hunk.
- The `AutomationHealthCore` SwiftPM target split (Phase 8-01) enabled non-UI sidebar behavior to be covered by the existing self-test executable without adding XCTest dependencies.

### What Was Inefficient

- **Silent-execution anti-pattern**: the GSD executor deferred its own commit step 11 times in a row (every plan in phases 6–9) when it saw "pre-existing local edits", but no downstream step required `git status --porcelain == clean` before marking a plan complete. STATE.md flagged the situation as a blocker AND simultaneously recorded `milestone_complete`. Net cost: a multi-step forensic recovery and 5 reconstructed phase commits at milestone close. See `.planning/forensics/report-20260510-214900.md`.
- **Smuggled-payload commits**: three planning-doc commits (`55a2f1d`, `224aa61`, `e4a0578`) silently carried the prior phase's full execution doc bundle under unrelated subject lines because each next-phase planner ran `git add` broadly. This corrupted the git-log attribution for Phase 6/7/8 verification.
- Phase 5 historical wording still says "Pulse Calendar" in older artifacts even though the shipped source art is "Pulse Grid" — minor doc drift not worth retroactive cleanup.

### Patterns Established

- **Forensic recovery from broken commit chains**: when `git log` shows missing `feat(N-NN)` commits for completed plans, check whether subsequent docs commits secretly bundled the prior phase's leftovers, then reconstruct atomic commits from the file lists in each plan's SUMMARY.
- **Phase-level commits with explicit accumulation notes**: when files span multiple phases and only the final working-tree state is recoverable, attribute whole files to the first-touching phase and have each later phase's commit body name what's bundled forward.
- Confidence/origin/scan-note labels carried on every scanner result, so the UI never has to encode source-specific schedule-evidence rules.
- `JobScanResult.notes` carries non-fatal source limitations (missing tools, unreadable paths, traversal caps) without failing the whole inventory refresh.

### Key Lessons

1. **The GSD state machine needs a clean-tree gate before marking a plan complete.** Specifically: `git status --porcelain` must be empty (or contain only files the plan declared) before the executor records a SUMMARY and ticks REQUIREMENTS/ROADMAP. Without this gate, a defensive commit-deferral by the executor can silently snowball across an entire milestone. Filed for upstream GSD framework follow-up.
2. **Planners should never `git add -A` or `git add .`** — they should stage only the files they own. The smuggled-payload commits at this milestone happened because next-phase planners swept the previous phase's untracked execution docs into their own commits.
3. **The audit-after-execution loop catches what phase-level verification misses.** v1.1's milestone audit (run mid-milestone) correctly flagged that Phases 7-9 were "absent" — that audit was stale by the time the milestone actually closed but it had served its purpose.
4. **Module splits make per-feature self-testing tractable.** Moving sidebar presentation into `AutomationHealthCore` (Phase 8-01) gave Phase 8's grouping/collapse behavior a non-UI testable surface without an XCTest dependency.
5. **Phase verification ≠ source committed.** Future GSD: verification reports should embed a `git rev-parse HEAD` reference so a `passed` verdict can be traced to the exact commit it covered.

### Cost Observations

- Model mix: not tracked.
- Sessions: not tracked.
- Notable: The forensic recovery at milestone close took roughly one extra session after the unrelated commit-discipline failure was diagnosed. Without the per-plan SUMMARYs already on disk, reconstruction would have been substantially more expensive.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | not tracked | 3 | Established grouped-sidebar planning, phase verification, milestone audit, archive, and retrospective flow. |
| v1.1 | not tracked | 6 | Added publication readiness (privacy scrub, public docs, icon pipeline), broad inventory (confidence/origin/scan-notes, cron/Shortcuts/Automator/candidate/manual sources), sidebar grouping polish, and module-split testable presentation. Exposed and worked around a GSD executor commit-deferral gap. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | ActiveJobsCoreSelfTest plus manual app verification | Focused scanner/presentation checks | 0 |
| v1.1 | ActiveJobsCoreSelfTest expanded ~750 lines: model, aggregation, cron, Shortcuts, Automator, candidate, manual, presentation, and grouping coverage; plus app-icon validation and CI gate | Inventory contract + 5 new scanners + manual store + sidebar grouping/collapse/navigation helpers | 0 |

### Top Lessons

1. Treat the repository CI script as the milestone release authority.
2. Keep read-only scanner boundaries explicit when improving UI navigation.
3. Verify atomic commit hygiene every phase: `git status --porcelain` should be clean when a plan is ticked complete. Silent commit-deferral compounds invisibly across phases.
4. SUMMARY.md files are the recovery anchor — keep their `Files Created/Modified` sections explicit and accurate even when the executor would otherwise be skipping the git step.
