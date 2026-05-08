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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | not tracked | 3 | Established grouped-sidebar planning, phase verification, milestone audit, archive, and retrospective flow. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | ActiveJobsCoreSelfTest plus manual app verification | Focused scanner/presentation checks | 0 |

### Top Lessons

1. Treat the repository CI script as the milestone release authority.
2. Keep read-only scanner boundaries explicit when improving UI navigation.
