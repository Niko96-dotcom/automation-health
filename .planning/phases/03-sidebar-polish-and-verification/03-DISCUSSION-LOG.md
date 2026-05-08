# Phase 3: Sidebar Polish And Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 03-sidebar-polish-and-verification
**Areas discussed:** Rows And Section Headers, Filtered Empty State, Verification Check

---

## Rows And Section Headers

| Option | Description | Selected |
|--------|-------------|----------|
| Compact label + count, subtle divider | Use a compact source label and visible count with muted styling and subtle group separation. | yes |
| Current parenthetical style | Keep `launchd (12)` style and only tune spacing or weight. | |
| Badge count | Put source label on the left and a small count pill on the right. | |

**User's choice:** Compact label + count, subtle divider.
**Notes:** This should preserve Phase 1's source order and visible-count semantics.

| Option | Description | Selected |
|--------|-------------|----------|
| Light polish only | Keep the current row structure, tighten spacing and typography, preserve health dot and selected background. | yes |
| More Finder-like row | Slightly denser row with stronger selected state and quiet hover/focus affordance. | |
| Richer status row | Add more hierarchy around status and timing while staying compact. | |

**User's choice:** Light polish only.
**Notes:** The row should not become a redesign.

| Option | Description | Selected |
|--------|-------------|----------|
| Current soft accent fill | Keep the gentle rounded selected background and tune opacity/radius only if needed. | yes |
| Native list selection feel | Use a stronger blue selected row closer to macOS source-list selection. | |
| Minimal selection | Use mostly text or indicator changes with very little fill. | |

**User's choice:** Current soft accent fill.
**Notes:** Selected-row behavior should remain familiar from the existing sidebar.

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle hover only | Add a quiet hover background if straightforward and avoid custom focus rings. | yes |
| No new hover/focus styling | Rely fully on selection and native focus behavior. | |
| Clear focus affordance | Add an explicit focused-list or focused-row visual for keyboard users. | |

**User's choice:** Subtle hover only.
**Notes:** Phase 2 already avoided custom focus visuals; that remains true here.

---

## Filtered Empty State

| Option | Description | Selected |
|--------|-------------|----------|
| Small inline empty state | Show quiet text below the sidebar summary with a short hint to adjust search. | yes |
| macOS ContentUnavailableView style | Use a more formal empty state with icon, title, and message. | |
| Bare minimum | Show only `No matching automations`. | |

**User's choice:** Small inline empty state.
**Notes:** The empty state should feel like part of the sidebar, not a full replacement view.

| Option | Description | Selected |
|--------|-------------|----------|
| Only filtered searches | Limit the new empty state to search returning zero visible jobs. | yes |
| Any empty sidebar | Use the same empty state when scan finds no jobs at all. | |
| Different copy per case | Filtered searches and truly empty scans get separate messages. | |

**User's choice:** Only filtered searches.
**Notes:** Truly empty scan behavior stays outside this phase.

| Option | Description | Selected |
|--------|-------------|----------|
| Non-focusable, navigation ignored | No selectable placeholder; Up/Down does nothing when no jobs are visible. | yes |
| Keep sidebar focus, but no row movement | Visually retain list focus with no explicit placeholder. | |
| Move focus back to search | Encourage search editing when no results exist. | |

**User's choice:** Non-focusable, navigation ignored.
**Notes:** This preserves the Phase 2 rule that keyboard navigation moves only through visible jobs.

| Option | Description | Selected |
|--------|-------------|----------|
| Plain and functional | `No matching automations` / `Try a different search.` | yes |
| More specific | `No jobs match "query"` / `Search names, sources, schedules, or commands.` | |
| Tiny single line | `No matching automations`. | |

**User's choice:** Plain and functional.
**Notes:** Keep copy quiet and utility-focused.

---

## Verification Check

| Option | Description | Selected |
|--------|-------------|----------|
| Run `./script/ci.sh` | Use the documented local gate: `swift build` plus self-test runner. | yes |
| Run only `swift build` | Faster but weaker than the documented gate. | |
| Run `make verify` too | Add local app bundle verification if planning finds it useful. | |

**User's choice:** Run `./script/ci.sh`.
**Notes:** This matches Phase 3 success criteria.

| Option | Description | Selected |
|--------|-------------|----------|
| Search + empty + keyboard regression | Check row visuals, no-results empty state, and Up/Down after clearing search. | yes |
| Visual-only check | Inspect compactness, section headers, selected row, and empty state appearance. | |
| Keyboard-heavy check | Mostly validate Up/Down through grouped and filtered lists. | |

**User's choice:** Search + empty + keyboard regression.
**Notes:** Manual verification should cover what the automated gate cannot see.

| Option | Description | Selected |
|--------|-------------|----------|
| Phase plan only | Keep manual verification as explicit steps in `03-02-PLAN.md`; no new script needed. | yes |
| Add a small checklist doc | Add a reusable checklist artifact. | |
| Add script support | Automate additional checks beyond CI. | |

**User's choice:** Phase plan only.
**Notes:** No new checklist document or script for this phase.

| Option | Description | Selected |
|--------|-------------|----------|
| Report and isolate | Record unrelated failures and only fix Phase 3 regressions. | yes |
| Fix anything needed | Broaden scope enough to get CI green. | |
| Skip CI if unrelated | Rely on manual verification if failure seems unrelated. | |

**User's choice:** Report and isolate.
**Notes:** The worktree had pre-existing source changes; planning should avoid silently taking ownership of unrelated failures.

## The Agent's Discretion

- Exact visual constants for font size, padding, divider opacity, hover opacity, and corner radius may be selected during implementation.
- If hover styling proves awkward in the existing SwiftUI structure, implementation may keep the row polish focused on spacing/header/empty-state improvements and document the tradeoff.

## Deferred Ideas

- None from this discussion.
- Existing project-level deferred items remain out of scope: health-based grouping, schedule-based grouping, persisted custom grouping modes, collapsible groups, additional keyboard shortcuts beyond Up/Down, and type-ahead navigation.
