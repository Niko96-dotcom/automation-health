# Phase 1: Sidebar Grouping Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 1-Sidebar Grouping Foundation
**Areas discussed:** Source Section Ordering, Section Header Content, Filtered Count Behavior

---

## Source Section Ordering

| Option | Description | Selected |
|--------|-------------|----------|
| Known source order | Launchd first, Hermes cron second. Stable and aligned with known source cases. | yes |
| Most jobs first | Sections with more visible jobs appear higher. | |
| Alphabetical | Sort sections by source display name. | |
| You decide | Let the planner choose the most native-feeling option. | |

**User's choice:** Known source order.
**Notes:** Lock Launchd first, Hermes cron second.

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve existing job order | Keep current inventory order inside each source, already stable by next run then name. | yes |
| Alphabetical by display name | Easier name scanning, but changes today's timing-first feel. | |
| You decide | Let the planner choose based on the simplest fit. | |

**User's choice:** Preserve existing job order.
**Notes:** Grouping should not reshuffle the current job ordering inside a source.

| Option | Description | Selected |
|--------|-------------|----------|
| Hide empty sections entirely | Matches ORG-03 and keeps filtered results compact. | yes |
| Show disabled empty headers | Make filtered-out categories explicit. | |
| You decide | Let the planner choose. | |

**User's choice:** Hide empty sections entirely.
**Notes:** Applies under search filtering too.

---

## Section Header Content

| Option | Description | Selected |
|--------|-------------|----------|
| Source name plus visible count | Satisfies ORG-02 and stays compact. | yes |
| Source name only | Cleaner, but loses the count requirement. | |
| Source name plus health summary | More informative, but likely too busy for Phase 1. | |
| You decide | Let the planner choose. | |

**User's choice:** Source name plus visible count.
**Notes:** Header should show readable source name and visible job count.

| Option | Description | Selected |
|--------|-------------|----------|
| Remove source from row subtitle | Header already carries the source, making rows easier to scan. | yes |
| Keep source in row subtitle | Preserves current row text exactly, but duplicates the header. | |
| You decide | Let the planner choose. | |

**User's choice:** Remove source from row subtitle.
**Notes:** Row subtitle should focus on timing or schedule text.

---

## Filtered Count Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Visible filtered count | Source count means number of jobs matching the current search. | yes |
| Total source count | Shows matches plus total, but adds visual noise. | |
| You decide | Let the planner choose. | |

**User's choice:** Visible filtered count.
**Notes:** Section counts should reflect filtered visible jobs when search is active.

| Option | Description | Selected |
|--------|-------------|----------|
| Visible filtered count | Top summary matches the currently visible result list. | yes |
| Total inventory count | Keep showing all jobs even when search narrows the list. | |
| Visible plus total | Useful but busier. | |
| You decide | Let the planner choose. | |

**User's choice:** Visible filtered count.
**Notes:** Top sidebar summary count should use the same visible-count semantics as the grouped section headers.

---

## The Agent's Discretion

- Exact header typography, spacing, and count separator.

## Deferred Ideas

- None.
