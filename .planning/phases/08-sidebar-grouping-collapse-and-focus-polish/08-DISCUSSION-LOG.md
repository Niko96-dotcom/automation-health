# Phase 08: Sidebar Grouping, Collapse, And Focus Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 08-sidebar-grouping-collapse-and-focus-polish
**Areas discussed:** Area selection fallback, Grouping controls and defaults, Collapse/search/selection behavior, Trigger type grouping, Focus treatment

---

## Area Selection Fallback

| Option | Description | Selected |
|--------|-------------|----------|
| All key areas | Lock grouping defaults, collapse/search behavior, trigger buckets, focus styling, and the persistence boundary. | yes |
| Navigation first | Focus on collapse, search, selection, keyboard movement, and accessible focus behavior. | |
| Grouping first | Focus on grouping modes, ordering, launchd origin separation, and trigger type categories. | |

**User's choice:** The Codex interactive question tool was unavailable in Default mode. Per the GSD workflow fallback, the agent selected the recommended option.
**Notes:** The context explicitly marks these as fallback-selected recommended defaults, not hidden user answers.

---

## Grouping Controls And Defaults

| Option | Description | Selected |
|--------|-------------|----------|
| Source default with compact sidebar control | Preserve shipped source grouping by default, then add Source, Origin, Health, Trigger, and Confidence choices in the sidebar. | yes |
| Origin default | Lead with ownership separation so launchd user/app/system differences are immediately visible. | |
| Health default | Lead with attention-first browsing, useful for triage but less stable as the default navigation structure. | |

**User's choice:** Workflow fallback selected the recommended default.
**Notes:** The requirements ask for multiple grouping modes but do not require a new default. Keeping Source as default reduces churn while still adding richer browsing.

---

## Collapse, Search, And Selection Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve selected detail when hidden | Collapsing hides rows but keeps the selected detail intact; keyboard navigation operates on visible rows. | yes |
| Move selection on collapse | When a selected row is hidden, immediately select a nearby visible row. | |
| Disable collapse for selected section | Prevent users from collapsing the selected job's section. | |

**User's choice:** Workflow fallback selected the recommended default.
**Notes:** This most directly satisfies `SIDE-01`: users can collapse sections without losing the selected job detail.

---

## Search Interaction With Collapse

| Option | Description | Selected |
|--------|-------------|----------|
| Search temporarily reveals matches | Active search shows matching rows in matching groups without mutating saved in-memory collapse state. | yes |
| Search honors collapsed sections | Collapsed sections continue hiding matches until expanded. | |
| Search resets collapse state | Searching expands everything and overwrites prior collapse state. | |

**User's choice:** Workflow fallback selected the recommended default.
**Notes:** This keeps search useful while preserving the user's session-local collapse choices when search is cleared.

---

## Trigger Type Grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Conservative presentation buckets | Classify from existing schedule/source/confidence fields into Time-based, Login/Keep Alive, File/Queue Trigger, Registered Only, Candidate Scripts, and Manual/Unspecified. | yes |
| Source-derived buckets only | Avoid schedule parsing and map each source to a broad trigger bucket. | |
| Deep inference | Inspect scripts or extra local files to infer trigger behavior. | |

**User's choice:** Workflow fallback selected the recommended default.
**Notes:** Deep inference would violate the read-only/no-view-IO spirit and could overclaim schedule evidence for Candidate or Manual records.

---

## Focus Treatment

| Option | Description | Selected |
|--------|-------------|----------|
| Custom compact outline cue | Keep selected-row fill, add a restrained focus outline/stroke that fits the dark sidebar and remains accessible. | yes |
| Default macOS blue rectangle | Keep the current oversized default focus rectangle. | |
| Selection only | Remove the focus cue and rely entirely on selected-row fill. | |

**User's choice:** Workflow fallback selected the recommended default.
**Notes:** The selected option directly addresses `SIDE-06` and `SIDE-07`: app-matched styling with a visible keyboard cue.

---

## the agent's Discretion

- Exact Swift type/helper names for grouping and trigger presentation.
- Exact SwiftUI control style for the grouping picker/menu, as long as it is compact and sidebar-local.
- Exact focus overlay implementation, as long as it suppresses the oversized default rectangle and remains visible/accessibility-friendly.

## Deferred Ideas

- Persisted grouping and collapsed-section preferences remain future `PREF-01` work.
- Additional keyboard shortcuts beyond predictable Up/Down row navigation and normal focus/disclosure behavior remain future polish.
- Full design-system redesign, settings screens, signed distribution, and new automation source scanners remain outside Phase 8.
