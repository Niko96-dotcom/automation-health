# Phase 2: Keyboard Navigation - Research

**Researched:** 2026-05-08
**Domain:** SwiftUI macOS sidebar keyboard navigation, focus scoping, and scroll synchronization
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

**CRITICAL:** These decisions are copied from `02-CONTEXT.md` and must be honored by the planner.

### Selection Start And Boundaries
- **D-01:** When no visible row is currently selected, arrow navigation should enter the visible list: Down selects the first visible job and Up selects the last visible job.
- **D-02:** Boundary presses should keep the current selection. Up on the first visible job and Down on the last visible job should not wrap, clear selection, or move focus away.
- **D-03:** If `selectedJobID` points to a job hidden by the current search filter, keyboard navigation should treat it like no visible selection: Down selects the first visible job and Up selects the last visible job.

### Sidebar Focus Behavior
- **D-04:** The sidebar should handle Up/Down only when the sidebar row/list area is focused, including after a user clicks a sidebar row.
- **D-05:** The sidebar search field should keep normal text-editing arrow behavior; typing in search should not be hijacked by row navigation.
- **D-06:** Clicking a sidebar row should both select the row and make the sidebar/list ready for immediate Up/Down keyboard navigation.
- **D-07:** Phase 2 should rely on subtle/native focus behavior if it appears naturally, but should not add a custom focus ring or new focus visual treatment.

### Search And Refresh Interactions
- **D-08:** When search changes and the current selected job becomes hidden, preserve the existing selection and detail pane until the user explicitly presses Up/Down or chooses another row.
- **D-09:** When search changes and the selected job remains visible, keep that row as the keyboard-navigation anchor inside the filtered visible list.
- **D-10:** After refresh, if the selected job still exists, preserve it and continue keyboard navigation from its updated visible position.
- **D-11:** If refresh removes the selected job, use the existing `JobStore.refresh()` fallback behavior: select the first available refreshed job.

### Scroll Alignment
- **D-12:** Keyboard navigation should scroll only enough to reveal the newly selected row when it is outside the current viewport. It should not center the row on every movement.
- **D-13:** If the newly selected row is already visible, keyboard navigation should not adjust scroll position.
- **D-14:** Phase 2 scroll-to-selection behavior applies to keyboard navigation only. Mouse clicks and refresh selection changes should not introduce extra scroll movement beyond normal user action.

### the agent's Discretion
- Exact SwiftUI/AppKit focus plumbing may be chosen during planning/implementation as long as it honors the narrow focus scope above.
- Exact helper names and file placement may follow the existing presentation/view pattern, with focused coverage added where navigation behavior is extracted into testable helpers.
</user_constraints>

<project_constraints>
## Project Constraints (from AGENTS.md and planning docs)

- Keep scanner IO out of views; sidebar work must use presentation/store data, not direct filesystem reads. [VERIFIED: `AGENTS.md`, `.planning/codebase/ARCHITECTURE.md`]
- Preserve read-only behavior; keyboard navigation must only update UI selection and must not mutate scheduled jobs. [VERIFIED: `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`]
- Avoid new third-party packages; this phase can be implemented with SwiftUI/AppKit already available through macOS 14. [VERIFIED: `Package.swift`, `.planning/codebase/STACK.md`]
- Use the existing SwiftPM scripts for validation. `swift build` is the reliable compile gate; `./script/ci.sh` currently reaches a known pre-existing self-test failure in `testHumanizesSchedulesAndRunTimes()`. [VERIFIED: `.planning/phases/01-sidebar-grouping-foundation/01-03-SUMMARY.md`, `.planning/codebase/TESTING.md`]
- Do not create, rename, or switch git branches during plan-phase. [VERIFIED: `plan-phase.md`]
- The worktree had pre-existing source changes when planning started; execution plans must warn implementers to preserve unrelated edits. [VERIFIED: `.planning/STATE.md`, `git status --short`]
</project_constraints>

<architectural_responsibility_map>
## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Compute previous/next visible job selection | Presentation State Layer | SwiftUI App Layer | The input is already-filtered visible sidebar rows, not raw scanner records. This belongs near `JobPresentation`/sidebar presentation helpers or as a private app-target helper. [VERIFIED: `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Views/ContentView.swift`] |
| Scope Up/Down handling to the sidebar row/list area | SwiftUI App Layer | Presentation State Layer | Focus and key events are view concerns; the helper should only decide target ids. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`] |
| Preserve search behavior | SwiftUI App Layer | Store Layer | `ContentView` owns `.searchable`; key handling must avoid intercepting arrow keys while the search field is focused. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`, `02-CONTEXT.md`] |
| Keep detail selection synchronized | Store Layer | SwiftUI App Layer | Detail already reads `store.selectedJob`, which follows `store.selectedJobID`; keyboard navigation should update that same binding. [VERIFIED: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Views/ContentView.swift`] |
| Scroll selected rows into view | SwiftUI App Layer | Presentation State Layer | The view owns the `ScrollView`; `ScrollViewReader` can reveal row ids after keyboard-driven selection changes. [VERIFIED: local SwiftUI swiftinterface, `Sources/AutomationHealth/Views/SidebarView.swift`] |
</architectural_responsibility_map>

<research_summary>
## Summary

Phase 2 should build directly on the Phase 1 grouped sidebar surface. `SidebarView` already receives `[SidebarJobSection]` and exposes a local `visibleJobs` flattening via `sections.flatMap(\.jobs)`, which is the canonical visible navigation order. Source headers, summary text, empty states, and footer controls are already outside that flattened row list, so the navigation policy can skip them by construction. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`]

The safest implementation shape is three small moves:

1. Add a pure visible-row navigation helper that takes visible row ids, current `selectedJobID`, and a direction, then returns the next selected id under D-01 through D-03 and D-06. [VERIFIED: `02-CONTEXT.md`]
2. Add focus/key handling in `SidebarView` using SwiftUI's macOS 14 `onKeyPress` and focus APIs so Up/Down are handled only by the sidebar row/list focus scope, while `.searchable` text editing keeps normal arrow behavior. [VERIFIED: local SwiftUI swiftinterface, `Sources/AutomationHealth/Views/ContentView.swift`]
3. Wrap the existing scroll surface in `ScrollViewReader` and call `scrollTo(selectedID, anchor: nil)` only for keyboard navigation changes. This asks SwiftUI to reveal the row without forcing a center anchor on every movement. [VERIFIED: local SwiftUI swiftinterface, `02-CONTEXT.md`]

The planner should keep implementation local to `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`, and possibly `Sources/AutomationHealth/Views/ContentView.swift`. `JobStore.refresh()` already preserves selected jobs and falls back to the first refreshed job when needed, so Phase 2 should not duplicate refresh policy in the view layer. [VERIFIED: `Sources/AutomationHealth/Stores/JobStore.swift`]

**Planning gate note:** Phase 2 has `UI hint: yes`, but `.planning/phases/02-keyboard-navigation/02-UI-SPEC.md` is currently missing. The GSD plan-phase workflow's UI design contract gate blocks PLAN.md generation for manual UI phases until `$gsd-ui-phase 2` has produced that contract or the workflow is rerun with `--skip-ui`. [VERIFIED: `.planning/ROADMAP.md`, `plan-phase.md`]
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Swift | Apple Swift 6.3 in this workspace | App and helper implementation | Existing project language and SwiftPM toolchain. [VERIFIED: `swift --version`, `Package.swift`] |
| SwiftUI | macOS 14 target | Focus, key handling, scroll, sidebar layout | Existing UI framework; `onKeyPress` is available for macOS 14 and `ScrollViewReader` is available before the deployment target. [VERIFIED: local SwiftUI swiftinterface, `Package.swift`] |
| ActiveJobsCore | Internal SwiftPM library | Job source, health, scanner data consumed by presentation models | Existing domain boundary; no Phase 2 scanner changes required. [VERIFIED: `.planning/codebase/ARCHITECTURE.md`] |
| ActiveJobsCoreSelfTest | Internal executable target | Existing self-test harness | Useful for core contracts, but it cannot currently import the `AutomationHealth` executable target. [VERIFIED: `Package.swift`, `.planning/codebase/TESTING.md`] |

### Relevant SwiftUI APIs Verified Locally
| API | Availability | Use In Phase 2 |
|-----|--------------|----------------|
| `View.onKeyPress(_ key: KeyEquivalent, action:)` | macOS 14+ | Handle `.upArrow` and `.downArrow` in the focused sidebar list. |
| `View.onKeyPress(keys:phases:action:)` | macOS 14+ | Alternative for one handler covering both arrow keys and repeat behavior. |
| `KeyEquivalent.upArrow` / `KeyEquivalent.downArrow` | Available in SwiftUI | Exact keys for row navigation. |
| `FocusState` and `View.focused(...)` | macOS 12+ | Track whether the sidebar row/list area owns focus. |
| `View.focusable(_:)` | macOS 12+ | Make the row/list container eligible for keyboard focus. |
| `ScrollViewReader` and `ScrollViewProxy.scrollTo(_:anchor:)` | macOS 11+ | Reveal keyboard-selected rows by id. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftUI key handling | AppKit `NSViewRepresentable` key monitor | More control, but larger surface area and more custom plumbing than needed for Up/Down in a macOS 14 SwiftUI app. |
| `ScrollViewReader.scrollTo(..., anchor: .center)` | `scrollTo(..., anchor: nil)` | Centering on every keypress violates D-12/D-13; nil anchor is the calmer reveal behavior to try first. |
| Moving selection policy into `JobStore` | Keep policy in sidebar presentation/view helpers | `JobStore` owns global selection and refresh, but visible filtered rows are local to `ContentView`/`SidebarView`, so store-level navigation would need search-specific UI knowledge. |
| New SwiftPM test target | Existing build/self-test workflow | A test target may be worthwhile later, but Phase 2 can stay within current project conventions unless the planner intentionally expands test infrastructure. |
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Current Data Flow

```text
JobStore.jobs
    |
    v
ContentView.filteredJobs(searchText)
    |
    v
SidebarJobSection.sections(for: filteredJobs)
    |
    v
SidebarView.sections
    |
    v
SidebarView.visibleJobs = sections.flatMap(\.jobs)
    |
    v
Keyboard direction + selectedJobID -> next visible job id
    |
    v
selectedJobID binding -> JobStore.selectedJob -> DetailView
```

### Recommended Project Structure

```text
Sources/AutomationHealth/
├── Models/
│   └── JobPresentation.swift        # Add pure visible-row navigation helper if extracted
├── Views/
│   ├── ContentView.swift            # Keep search ownership; pass current section data unchanged unless focus state must lift
│   └── SidebarView.swift            # Add focus, key handling, and keyboard-only scroll-to-selection
└── Stores/
    └── JobStore.swift               # No Phase 2 changes expected
```

### Pattern 1: Navigate The Flattened Visible Row List
**What:** Use `sections.flatMap(\.jobs)` as the only keyboard traversal source. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`]
**Why:** This list already excludes section headers, sidebar summary, empty states, and footer controls, and it already reflects search filtering from `ContentView`. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`, `02-CONTEXT.md`]
**Planning implication:** Plan 02-01 should define navigation in terms of `[SidebarJobSummary]` or `[String]` ids, not `JobSource`, source headers, or raw `ScheduledJob` values.

### Pattern 2: Keep Selection Writes On The Existing Binding
**What:** Keyboard navigation should set `selectedJobID = targetID`, exactly like row click selection sets `selectedJobID = job.id`. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`]
**Why:** The detail pane and store selection id already synchronize through that binding. [VERIFIED: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Views/ContentView.swift`]
**Planning implication:** Do not create parallel selection state for keyboard navigation. If transient state is needed, limit it to "last change was keyboard-driven" for scroll behavior.

### Pattern 3: Keep Search Focus Separate From List Focus
**What:** Treat the search field and sidebar row/list area as distinct focus scopes. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`, local SwiftUI swiftinterface]
**Why:** D-05 requires search text editing arrows to remain native. [VERIFIED: `02-CONTEXT.md`]
**Planning implication:** `onKeyPress` should be attached to a focusable sidebar list container or otherwise gated by list focus, not globally on the whole split view.

### Pattern 4: Keyboard-Only Scroll Reveal
**What:** Scroll after a keyboard navigation action selects a new row; avoid scroll changes for mouse clicks, search changes, and refresh preservation. [VERIFIED: `02-CONTEXT.md`]
**Why:** D-12 through D-14 require calm reveal behavior and no extra movement for non-keyboard selection changes.
**Planning implication:** The implementation may need a private `@State` flag or pending id such as `keyboardNavigationTargetID` that is set only in the key handler and consumed by `ScrollViewReader`.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Scheduler reads | Any filesystem scan or `launchctl` call in the sidebar | Existing `JobStore.jobs` and presentation values | Violates the IO boundary and read-only scanner architecture. |
| Visible filtering | A second search filter inside `SidebarView` | `ContentView.filteredJobs` before grouping | Search already happens before grouping and section counts depend on that ordering. |
| Detail synchronization | Separate selected job state in the view | Existing `selectedJobID` binding | Detail selection already follows `JobStore.selectedJob`. |
| Arrow key API | App-wide event monitor | SwiftUI `onKeyPress` gated by focus | Available on macOS 14 and keeps behavior local to the view. |
| Scroll physics | Manual geometry and offset math as a first step | `ScrollViewReader.scrollTo(_:anchor: nil)` | Simpler and likely enough to reveal selected rows without recentering. |
| Test harness churn | Importing the executable app target into `ActiveJobsCoreSelfTest` | `swift build` plus focused helper checks where target boundaries allow | Current SwiftPM structure has no app test target; avoid architecture churn unless explicitly planned. |
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Handling Arrow Keys While Search Is Focused
**What goes wrong:** Pressing Left/Right/Up/Down while editing search unexpectedly changes row selection or steals focus. [VERIFIED: `02-CONTEXT.md`]
**Why it happens:** Key handling is attached too high in `ContentView` or `NavigationSplitView`.
**How to avoid:** Attach/gate key handling to the sidebar row/list focus area and verify `.searchable` keeps normal text-editing arrows.
**Warning signs:** The implementation has an ungated `.onKeyPress(.downArrow)` on the whole split view.

### Pitfall 2: Using All Store Jobs Instead Of Visible Jobs
**What goes wrong:** Keyboard navigation moves into jobs hidden by the search query, violating SRCH-02. [VERIFIED: `.planning/REQUIREMENTS.md`, `02-CONTEXT.md`]
**Why it happens:** The helper reads `store.jobs` or raw grouped source data instead of `SidebarView.visibleJobs`.
**How to avoid:** Pass only `sections.flatMap(\.jobs)` or their ids into the navigation helper.
**Warning signs:** A plan says to navigate `store.jobs` from `SidebarView`.

### Pitfall 3: Clearing Selection At Boundaries
**What goes wrong:** Up at the first row or Down at the last row sets `selectedJobID` to nil or wraps unexpectedly. [VERIFIED: `02-CONTEXT.md`]
**Why it happens:** Index math returns nil for out-of-range movement and writes it back to the binding.
**How to avoid:** Clamp to the current selected id at boundaries and return nil only when there are no visible rows.
**Warning signs:** Helper names like `nextIndex` produce optional nil for boundary cases without a clamp rule.

### Pitfall 4: Recreating Refresh Policy In SidebarView
**What goes wrong:** Refresh selection preservation behaves differently depending on whether refresh, search, mouse, or keyboard initiated the selection change. [VERIFIED: `Sources/AutomationHealth/Stores/JobStore.swift`, `02-CONTEXT.md`]
**Why it happens:** The view tries to repair `selectedJobID` on `sections` changes.
**How to avoid:** Keep `JobStore.refresh()` as the only refresh fallback owner; keyboard navigation only reacts to explicit arrow presses.
**Warning signs:** `SidebarView` has `.onChange(of: sections)` code that changes `selectedJobID` because a row became hidden.

### Pitfall 5: Centering Or Animating Every Selection Change
**What goes wrong:** The sidebar feels jumpy during keyboard navigation or scrolls on mouse clicks/search updates. [VERIFIED: `02-CONTEXT.md`]
**Why it happens:** `scrollTo(selectedJobID, anchor: .center)` is run for every selected id change.
**How to avoid:** Track keyboard-originated selection changes separately and use `anchor: nil` first.
**Warning signs:** `.onChange(of: selectedJobID)` always calls `scrollTo` with `.center`.
</common_pitfalls>

<code_examples>
## Code Examples

### Existing Visible Row Source

```swift
// Source: Sources/AutomationHealth/Views/SidebarView.swift
private var visibleJobs: [SidebarJobSummary] {
    sections.flatMap(\.jobs)
}
```

Use this as the navigation order. It is already search-filtered and header-free. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`]

### Existing Selection Write

```swift
// Source: Sources/AutomationHealth/Views/SidebarView.swift
SidebarJobRow(
    job: job,
    isSelected: selectedJobID == job.id
) {
    selectedJobID = job.id
}
```

Keyboard navigation should update the same binding so `DetailView` follows automatically. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`]

### Existing Search Filter Location

```swift
// Source: Sources/AutomationHealth/Views/ContentView.swift
private var filteredJobs: [JobPresentation] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !query.isEmpty else {
        return store.jobs
    }

    return store.jobs.filter { $0.searchText.contains(query) }
}
```

Do not move or duplicate search filtering in Phase 2. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`]

### Existing Refresh Preservation

```swift
// Source: Sources/AutomationHealth/Stores/JobStore.swift
if let selectedJobID, refreshed.contains(where: { $0.id == selectedJobID }) {
    break
}
selectedJobID = refreshed.first?.id
```

Keep refresh fallback behavior here. [VERIFIED: `Sources/AutomationHealth/Stores/JobStore.swift`]

### Verified SwiftUI Key Handling Shape

```swift
// Verified in local SwiftUI swiftinterface, macOS 14+
nonisolated public func onKeyPress(
    _ key: SwiftUI.KeyEquivalent,
    action: @escaping () -> SwiftUI.KeyPress.Result
) -> some SwiftUICore.View
```

Use `.onKeyPress(.upArrow)` and `.onKeyPress(.downArrow)` or a `keys:` set to keep key handling local. [VERIFIED: local SwiftUI swiftinterface]

### Verified Scroll Reveal Shape

```swift
// Verified in local SwiftUI swiftinterface
public struct ScrollViewProxy {
    public func scrollTo<ID>(_ id: ID, anchor: SwiftUICore.UnitPoint? = nil) where ID : Swift.Hashable
}
```

Use `anchor: nil` first to reveal without forcing center alignment. [VERIFIED: local SwiftUI swiftinterface]
</code_examples>

<planning_recommendations>
## Planning Recommendations

### Recommended Plans
1. **02-01: Define visible-job navigation behavior.** Add a pure helper for previous/next visible row id selection. Acceptance should cover: no selection -> first/last; hidden selection -> first/last; first/last boundary stays selected; empty visible list returns nil without clearing an existing selected id unless the caller explicitly decides not to write.
2. **02-02: Wire sidebar focus and key handling.** Make the sidebar row/list area focusable, have row clicks select and focus that area, and handle Up/Down only in that focus scope. Acceptance should verify `.searchable(text: $searchText, placement: .sidebar)` remains owned by `ContentView` and arrow handling is not attached globally.
3. **02-03: Add keyboard-only scroll reveal and verification.** Wrap the scroll content in `ScrollViewReader`, assign stable row ids, scroll only for keyboard-originated target ids, and run compile/manual checks for search, boundary, refresh, and read-only behavior.

### Verification Strategy
- Run `swift build` after each UI wiring plan.
- Run `./script/ci.sh` at the end if feasible, but record the known pre-existing `testHumanizesSchedulesAndRunTimes()` failure if it persists. Do not silently claim full CI success unless the self-test passes.
- Prefer grep-verifiable acceptance criteria for source changes, such as `SidebarView.swift contains onKeyPress(.upArrow`, `SidebarView.swift contains onKeyPress(.downArrow`, `SidebarView.swift contains ScrollViewReader`, and `SidebarView.swift contains scrollTo(`.
- Add manual verification notes for behavior that compile checks cannot prove: search field arrows, boundary behavior, hidden selection under search, and keyboard-driven scroll reveal.

### Open Decisions For UI-SPEC
- Whether the sidebar row/list focus should use the default system focus effect or suppress it with `focusEffectDisabled(true)` if default visuals are noisy.
- Whether key repeat should be accepted by default (`.down` and `.repeat`) or restricted to discrete keydown events for calmer navigation.
- Whether row click focus should be on each row or the shared scroll/list container.
</planning_recommendations>

<sota_updates>
## State of the Art

No external ecosystem research is required. The relevant APIs are local SwiftUI SDK symbols available for the project's macOS 14 deployment target, and this phase does not require third-party packages, new scheduler integration, or live web lookup. [VERIFIED: `Package.swift`, local SwiftUI swiftinterface]
</sota_updates>

## RESEARCH COMPLETE
