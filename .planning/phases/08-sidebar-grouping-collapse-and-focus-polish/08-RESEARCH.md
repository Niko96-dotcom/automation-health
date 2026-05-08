# Phase 8: Sidebar Grouping, Collapse, And Focus Polish - Research

**Researched:** 2026-05-08
**Domain:** Native macOS SwiftUI sidebar grouping, collapsible sections, visible-row keyboard navigation, and accessible custom focus styling
**Confidence:** HIGH

## Context Status

`08-CONTEXT.md` exists and is the primary source of truth for this phase. It locks the grouping choices, deterministic group order, collapse/search/selection behavior, trigger labels, focus styling boundary, read-only posture, and no-persistence boundary for Phase 8.

Phase 8 depends on Phase 7. The current working tree already contains the Phase 7 inventory surface:

- `JobSource` includes `launchd`, `hermesCron`, `cron`, `shortcuts`, `automator`, `candidateScripts`, and `manualRecords` in sidebar display order.
- `JobConfidence` includes `Scheduled`, `Registered`, `Candidate`, and `Manual`.
- `JobOrigin` includes `User-authored`, `Third-party app`, `System`, and `Unknown`.
- `JobPresentation` already exposes source, confidence, origin, schedule, health, search text, and sidebar row summaries.
- `SidebarJobSection.sections(for:)` currently groups only by source.
- `SidebarNavigation.targetJobID(in:selectedJobID:direction:)` already isolates Up/Down behavior over a supplied visible row list.
- `JobStore.selectedJob` is independent from filtered sidebar rows, so collapsed hidden selections can keep showing detail.

Because Phase 8 has `UI hint: yes`, the UI-SPEC gate is applicable before `PLAN.md` files are generated.

## Phase Scope

Phase 8 should turn the sidebar into a richer native navigation surface:

- Add grouping modes: `Source`, `Origin`, `Health`, `Trigger`, and `Confidence`.
- Default to `Source`.
- Group with deterministic domain order instead of alphabetical order.
- Add in-memory collapse state keyed by grouping mode and section identity.
- Preserve selected detail when the selected row is hidden by collapse or search.
- Keep Up/Down navigation over visible job rows only.
- Temporarily reveal matching search rows without mutating collapsed state.
- Replace the oversized default blue focus rectangle with a restrained app-matched focus cue that remains accessible.

Out of scope:

- Persisting grouping or collapse preferences. Future `PREF-01` owns persistence.
- Scanner IO, scheduler mutation, script analysis, shell history inspection, or source-specific filesystem reads in views.
- New third-party packages.
- A broad app-shell redesign, large cards, decorative sidebar layout, or new management actions.

## Requirements Mapping

| Requirement | Planning Implication |
|-------------|----------------------|
| SIDE-01 | Add collapsible sidebar sections without clearing or moving `JobStore.selectedJobID`. |
| SIDE-02 | Navigation helpers must flatten only visible rows after search and collapse are applied. |
| SIDE-03 | Model all five grouping modes in presentation code and expose a compact sidebar-local control. |
| SIDE-04 | Use stable group and row order so refreshes do not visually reshuffle unrelated records. |
| SIDE-05 | Origin grouping must separate `launchd` records by `JobOrigin` while row subtitles still show scheduler source. |
| SIDE-06 | Replace the default focus rectangle with a cue that matches the existing dark sidebar/search treatment. |
| SIDE-07 | Focus cue must remain visible to keyboard users in active, inactive, and high-contrast contexts. |

## Current Architecture Findings

`JobPresentation.swift` is the right home for non-IO sidebar presentation helpers. The file already owns `SidebarJobSummary`, `SidebarNavigation`, and `SidebarJobSection`, which means grouping modes, trigger classification, section identity, row subtitle variation, and visible-row navigation can be tested without SwiftUI UI automation.

`ContentView.swift` currently owns `searchText` and derives `filteredJobs`, `showsFilteredEmptyState`, and `sidebarSections`. It is the natural owner for `@State private var sidebarGroupingMode = .source` and in-memory collapsed sections, then it can pass grouped/expanded state into `SidebarView`.

`SidebarView.swift` currently renders source headers as passive views and rows as plain buttons inside one focusable scroll view. It should gain disclosure-style section headers and a sidebar-local grouping menu near `SidebarHeader`, while keeping job selection limited to automation rows.

`JobStore.swift` already preserves selection across refresh when the selected record still exists. That behavior should remain unchanged. Collapse and search should hide rows from navigation, not remove jobs from store state.

`ActiveJobsCore` does not need new scanner work. Trigger grouping is a conservative presentation classification over existing `ScheduledJob` fields only.

## Recommended Implementation Split

1. **Grouping and navigation model:** Add `SidebarGroupingMode`, group key/order helpers, `SidebarTriggerKind`, generalized `SidebarJobSection`, `SidebarCollapseState`, and visible-row navigation helpers with self-test coverage.
2. **Sidebar controls and collapsible rendering:** Move `ContentView.sidebarSections` through the new grouping/collapse helpers, add the compact grouping menu, interactive section headers, counts, help text for origin, and search-aware expansion without persisted state.
3. **Focus treatment and visual verification:** Apply a custom keyboard focus overlay around the existing sidebar surface/rows, keep selection distinct from focus, and verify with local build/run or screenshot/manual checks.

This split matches the three planned roadmap waves and keeps risky UI rendering after the testable presentation helpers.

## Grouping Model Research

Recommended type shape in `JobPresentation.swift`:

- `enum SidebarGroupingMode: String, CaseIterable, Identifiable, Sendable`
- Cases and labels: `.source` = `Source`, `.origin` = `Origin`, `.health` = `Health`, `.trigger` = `Trigger`, `.confidence` = `Confidence`
- `struct SidebarSectionID: Hashable, Sendable` or string-backed IDs combining grouping mode and group key.
- `struct SidebarCollapseState: Sendable` with an internal `Set<SidebarSectionID>` and helpers such as `isCollapsed(sectionID:mode:)`, `toggle(sectionID:mode:)`, and `isEffectivelyCollapsed(sectionID:hasSearchQuery:)`.

Required group order:

- Source: `JobSource.allCases`
- Origin: `.userAuthored`, `.thirdPartyApp`, `.system`, `.unknown`
- Confidence: `.scheduled`, `.registered`, `.candidate`, `.manual`
- Health: `.failed`, `.stale`, `.waiting`, `.alive`, `.unknown`
- Trigger: `.timeBased`, `.loginKeepAlive`, `.fileQueueTrigger`, `.registeredOnly`, `.candidateScripts`, `.manualUnspecified`

Required group titles:

- Origin: `User-authored`, `Third-party app`, `System`, `Unknown`
- Health: `Needs attention`, `Stale`, `Waiting`, `Alive`, `Unknown`
- Trigger: `Time-based`, `Login / Keep Alive`, `File / Queue Trigger`, `Registered Only`, `Candidate Scripts`, `Manual / Unspecified`

Health grouping should use `JobPresentation.health.kind` and map `.failed` to `Needs attention`.

Origin grouping should use `job.job.origin`, not scheduler source. This is what separates user-authored, third-party, system, and unknown `launchd` rows without inventing launchd pseudo-sources.

Confidence grouping should use `job.job.confidence`.

Source grouping should preserve the existing `JobSource.allCases` order and omit source from row subtitles.

## Trigger Classification Research

Trigger grouping must be presentation-only and conservative. Recommended evidence priority:

1. If `job.job.confidence == .candidate` or `job.job.source == .candidateScripts`, classify as `Candidate Scripts`.
2. If `job.job.confidence == .manual` or `job.job.source == .manualRecords`, classify as `Manual / Unspecified`.
3. If `job.job.confidence == .registered`, classify as `Registered Only`.
4. If `job.job.schedule` or `job.scheduleText` contains `watch`, `watched files`, `queue`, or `files are queued`, classify as `File / Queue Trigger`.
5. If it contains `login`, `keep alive`, `RunAtLoad`, or `stays running`, classify as `Login / Keep Alive`.
6. If `job.job.nextRun != nil`, a cron-like five-field string is present, an `@hourly` style cron token is present, the schedule includes clock times, or `scheduleText` starts with `Daily`, `Every`, `Monthly`, or a weekday, classify as `Time-based`.
7. Fall back to `Manual / Unspecified`.

This avoids reading scripts, parsing plist files from SwiftUI, or claiming that registered Shortcuts/Automator records are scheduled without direct evidence.

## Collapse, Search, And Navigation Research

Collapse state should be keyed by grouping mode plus stable section identity. All sections should be expanded the first time a mode is visited.

Search behavior should be derived, not mutating:

- `hasSearchQuery == true` means matching groups display matching rows even if the section was collapsed before search.
- Counts under search reflect filtered visible result count.
- Clearing search returns to the stored collapsed/expanded state.

Selection behavior:

- Section headers are not job rows and must not receive `selectedJobID`.
- Collapsing a section containing the selected job does not clear or move selection.
- The detail view continues showing `store.selectedJob` because store selection is independent from visible sidebar rows.

Navigation behavior:

- Visible navigation input should be `sections.flatMap(\.visibleJobs)` or equivalent, after collapse/search filtering.
- If selected job is visible, Up/Down moves to the previous/next visible ID.
- If selected job is hidden by collapse, the helper should use the selected job's original grouped position when available. For Down, move to the next visible row after the hidden row or section boundary; for Up, move to the previous visible row before it. If no positional context is available, fall back to first/last visible row by direction.
- If search yields no rows, navigation returns nil and the filtered empty state remains non-selectable.

Recommended test fixtures should create mixed sources/origins/confidences and verify section order, row subtitles, collapsed visible rows, search reveal behavior, selected-hidden navigation, and empty navigation.

## Sidebar UI Research

Keep the sidebar compact and native:

- Put a small grouping `Menu` or compact `Picker` in/near `SidebarHeader`.
- Use exact menu labels: `Source`, `Origin`, `Health`, `Trigger`, `Confidence`.
- Use SF Symbols where helpful, but do not turn the sidebar header into a large toolbar.
- Section headers can be buttons with a disclosure chevron and count. They should have `.buttonStyle(.plain)`, `.contentShape(Rectangle())`, a clear accessibility label, and `help` text where the origin/source distinction needs concise explanation.
- Row subtitle should adapt by grouping mode:
  - Source: `Confidence - schedule/next run`
  - Origin: `Source - Confidence - schedule/next run`
  - Health: `Source - Confidence - schedule/next run`
  - Trigger: `Source - Confidence - schedule/next run`
  - Confidence: `Source - schedule/next run`

Avoid explanatory in-app paragraphs. Any help for `SIDE-05` should be concise `help` text on the origin grouping control or origin section headers.

## Focus Treatment Research

The current focusable `ScrollView` can show the default macOS blue focus rectangle. Phase 8 should prefer SwiftUI styling before AppKit interop:

- Keep the scroll area keyboard focusable so `.onKeyPress(.downArrow)` and `.onKeyPress(.upArrow)` continue to work.
- Add a custom focus cue using an overlay or inset stroke on the sidebar list surface when `focusedTarget == .jobList`.
- Prefer a thin accent or high-contrast-aware stroke over a filled overlay. Selection should remain the row fill; focus should be a separate outline/stroke cue.
- Test active and inactive window appearance. In inactive state, the cue should remain visible but can reduce opacity.
- If SwiftUI cannot suppress the oversized default focus ring, use minimal AppKit interop around the hosted scroll/list surface as a fallback. Do not introduce broad AppKit rewrites.

Suggested visual target:

- Selected row: existing compact `Color.accentColor.opacity(0.18)` fill.
- Focus cue: 1-2 px rounded inset stroke around the focused list area or focused selected row, using accent/primary contrast and not relying on color alone.
- No bright full-size blue rectangle and no large card treatment.

## Validation Architecture

Phase 8 can use the existing SwiftPM and executable self-test flow:

- Quick command: `./script/test.sh`
- Full command: `./script/ci.sh`
- Core fixture target: `Sources/ActiveJobsCoreSelfTest/main.swift`
- UI/manual command: `./script/build_and_run.sh --verify` or `make verify` after implementation builds.

Automated tests should cover:

- `SidebarGroupingMode.allCases` labels are exactly `Source`, `Origin`, `Health`, `Trigger`, and `Confidence`.
- Source sections follow `JobSource.allCases`.
- Origin sections follow `User-authored`, `Third-party app`, `System`, `Unknown`.
- Health sections follow `Needs attention`, `Stale`, `Waiting`, `Alive`, `Unknown`.
- Confidence sections follow `Scheduled`, `Registered`, `Candidate`, `Manual`.
- Trigger sections follow `Time-based`, `Login / Keep Alive`, `File / Queue Trigger`, `Registered Only`, `Candidate Scripts`, `Manual / Unspecified`.
- Launchd records with different `JobOrigin` values split into different origin groups while preserving `sourceName` in row subtitles.
- Trigger classification does not classify registered Shortcuts or Automator records as scheduled unless direct schedule evidence exists.
- Collapsed sections hide rows from the visible navigation list without clearing selected job IDs.
- Search reveals matching rows without mutating stored collapse state.
- `SidebarNavigation` skips hidden rows and handles hidden selected IDs predictably.
- The view-layer grep still proves scanner IO stays out of SwiftUI views:
  `! rg -n "Data\\(contentsOf:|FileManager\\.default|contentsOfDirectory|JSONEncoder|JSONDecoder|crontab|shortcuts list|launchctl" Sources/AutomationHealth/Views`

Manual verification should cover:

- Switch through all grouping modes and confirm deterministic order.
- Collapse/expand sections and confirm selected detail remains coherent.
- Search with collapsed sections and confirm matches appear, then clearing search restores collapse state.
- Use keyboard Up/Down through visible rows with collapsed and filtered sections.
- Verify the default blue focus rectangle is gone and a visible custom focus cue remains in dark mode, light mode, inactive window state, and high-contrast mode where practical.

## Security Domain

Security enforcement is applicable. The main risks are accidental scheduler mutation, source-specific view IO, misleading evidence labels, and accessibility regressions that hide keyboard focus.

Threat model topics for every plan:

- **T-08-01 real automation mutation:** Sidebar grouping, collapse, and focus changes must not add edit, run, repair, remove, or write behavior for real scheduler files, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata.
- **T-08-02 view-layer IO regression:** SwiftUI views must not read scheduler files, script files, command outputs, manual JSON, or source directories directly.
- **T-08-03 evidence spoofing:** Trigger and grouping labels must not imply that registered/candidate/manual records are proven scheduled jobs.
- **T-08-04 hidden-selection confusion:** Collapsing or searching must not silently select a different job or show detail for a record the user did not choose.
- **T-08-05 keyboard accessibility regression:** Custom focus styling must remain visible and keyboard navigation must skip hidden rows.
- **T-08-06 preference leakage/scope creep:** Grouping and collapse preferences stay in memory and are not persisted until future `PREF-01` work.

## Common Pitfalls

| Pitfall | Why It Matters | Plan Guardrail |
|---------|----------------|----------------|
| Persisting grouping/collapse state now | Violates Phase 8 boundary and preempts `PREF-01`. | Keep `@State` or lightweight in-memory presentation state only. |
| Making section headers selectable jobs | Breaks selection model and keyboard navigation. | Headers toggle collapse only; job rows own selection. |
| Deriving trigger groups from script contents or plist reads in views | Breaks no-view-IO and can overstate evidence. | Use existing `ScheduledJob` fields only. |
| Alphabetical group sorting | Can bury important attention or evidence groups. | Encode group-specific ordering arrays. |
| Clearing selection when a group collapses | Makes detail jump unexpectedly. | Keep `selectedJobID` unchanged when rows hide. |
| Letting search mutate collapse state | Users lose their section organization after clearing search. | Treat search expansion as derived display state. |
| Removing focus entirely to hide the blue ring | Fails keyboard accessibility. | Replace with a custom visible shape/stroke cue. |
| Adding broad cards or oversized headers | Conflicts with the compact macOS navigation surface. | Keep controls small and sidebar-local. |

## Sources

- Repository files verified locally: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/phases/08-sidebar-grouping-collapse-and-focus-polish/08-CONTEXT.md`, `.planning/phases/07-candidate-discovery-and-manual-records/07-UI-SPEC.md`, `AGENTS.md`, `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`, `docs/scheduled-job-sources.md`, and `docs/scanner-extension-guide.md`.
- Local architectural evidence: scanner IO lives in `ActiveJobsCore`; sidebar presentation helpers already live in `JobPresentation.swift`; SwiftUI views consume store/presentation values; current regression coverage uses `ActiveJobsCoreSelfTest` plus `./script/ci.sh`.
