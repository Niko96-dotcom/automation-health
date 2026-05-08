# Phase 2: Keyboard Navigation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 02-keyboard-navigation
**Areas discussed:** Selection start and boundaries, Sidebar focus behavior, Search and refresh interactions, Scroll alignment feel

---

## Selection Start And Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Select nearest | Down selects the first visible job, Up selects the last visible job; this keeps keyboard navigation useful from an empty selection. | ✓ |
| Down only | Down selects the first visible job, but Up does nothing until something is selected. | |
| Do nothing | Arrow keys only move an existing selection and never create one. | |

**User's choice:** Select nearest
**Notes:** Starting from no visible selection should let the keyboard enter the visible list immediately.

| Option | Description | Selected |
|--------|-------------|----------|
| Stay put | Up on the first job and Down on the last job keep the current selection. | ✓ |
| Wrap around | Up on the first job jumps to the last, Down on the last jumps to the first. | |
| Clear selection | Boundary presses remove the selection. | |

**User's choice:** Stay put
**Notes:** Boundary behavior should not wrap or clear selection.

| Option | Description | Selected |
|--------|-------------|----------|
| Start in visible list | Treat a hidden selected job like no visible selection; Down selects first visible, Up selects last visible. | ✓ |
| Keep hidden selection | Arrow keys do nothing until the selected job becomes visible again. | |
| Use original order | Move from the hidden job's global position to the nearest visible neighbor. | |

**User's choice:** Start in visible list
**Notes:** Keyboard navigation is based strictly on the visible filtered list.

---

## Sidebar Focus Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Sidebar focused | Handle arrows when the sidebar/list area has focus, including after clicking a row. | ✓ |
| Sidebar or search | Handle arrows when either the sidebar rows or the sidebar search field is active. | |
| Global window | Handle arrows anywhere in the window unless a text field is actively editing. | |

**User's choice:** Sidebar focused
**Notes:** Keep focus scope narrow so search-field editing is not hijacked.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, activate list | Clicking a row selects it and makes the sidebar ready for arrow navigation. | ✓ |
| Selection only | Clicking selects the row, but the user must separately focus the list before arrows work. | |
| You decide | Let implementation follow the simplest native SwiftUI/AppKit pattern. | |

**User's choice:** Yes, activate list
**Notes:** A clicked row should immediately prepare the list for Up/Down navigation.

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle/native only | Use native focus behavior if it appears naturally, but do not add a custom focus ring in this phase. | ✓ |
| Explicit focus styling | Add a small custom focus treatment so users can tell when arrows will move rows. | |
| No focus styling | Keep visuals exactly as they are even if focus is not obvious. | |

**User's choice:** Subtle/native only
**Notes:** No custom focus styling should be added in Phase 2.

---

## Search And Refresh Interactions

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve detail until arrow | Keep the existing selection/detail, and let the next Up/Down enter the visible filtered list. | ✓ |
| Auto-select first visible | Immediately move selection to the first filtered job. | |
| Clear detail | Clear selection/detail while the selected job is hidden. | |

**User's choice:** Preserve detail until arrow
**Notes:** Search should not move the detail pane around while the user types.

| Option | Description | Selected |
|--------|-------------|----------|
| Continue from selected row | Keep selection and Up/Down move from that row within the filtered visible list. | ✓ |
| Restart at top | Keep detail, but the next Down starts at the first visible result. | |
| You decide | Let implementation choose the simplest predictable behavior. | |

**User's choice:** Continue from selected row
**Notes:** A visible selected row remains the navigation anchor under search.

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve selection | Keep the same selected job, update its row position, and continue Up/Down from its new visible position. | ✓ |
| Reset to first visible | Refresh completion moves selection to the first visible job. | |
| You decide | Let the existing store refresh behavior decide. | |

**User's choice:** Preserve selection
**Notes:** Refresh should preserve selected jobs that still exist and re-anchor navigation at their updated visible position.

| Option | Description | Selected |
|--------|-------------|----------|
| Use existing fallback | Select the first available refreshed job, matching current `JobStore.refresh()` behavior. | ✓ |
| Clear selection | Show no selected job/detail until the user chooses one. | |
| Preserve stale detail | Keep showing the removed job until another row is selected. | |

**User's choice:** Use existing fallback
**Notes:** Do not create a second refresh-selection policy in Phase 2.

---

## Scroll Alignment Feel

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal reveal | Scroll only enough to bring the selected row into view, preserving the user's sense of position. | ✓ |
| Center row | Scroll so the selected row is centered whenever possible. | |
| Native default | Use whatever `ScrollViewReader`/SwiftUI behavior gives with no extra alignment preference. | |

**User's choice:** Minimal reveal
**Notes:** Long lists should remain calm and avoid recentering on each keypress.

| Option | Description | Selected |
|--------|-------------|----------|
| Only if needed | Scroll when the row is outside the viewport; visible rows stay put. | ✓ |
| Every movement | Always adjust scroll to maintain a consistent selected-row position. | |
| You decide | Let the implementation use the simplest reliable behavior. | |

**User's choice:** Only if needed
**Notes:** If the row is already visible, do not move the scroll position.

| Option | Description | Selected |
|--------|-------------|----------|
| Keyboard only | Keyboard movement scrolls into view; clicks and refreshes do not add extra scrolling beyond normal user action. | ✓ |
| All selection changes | Any selection change scrolls the row into view. | |
| Keyboard and refresh | Keyboard movement and refresh fallback scroll, but mouse clicks do not. | |

**User's choice:** Keyboard only
**Notes:** Scroll-to-selection behavior is scoped to keyboard navigation.

---

## The Agent's Discretion

- Exact SwiftUI/AppKit focus plumbing may be selected during implementation.
- Exact helper names and test boundaries may follow established local patterns.

## Deferred Ideas

- None from this discussion. Existing project-level deferred items remain out of scope.
