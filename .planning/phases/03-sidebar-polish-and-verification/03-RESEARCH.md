# Phase 3: Sidebar Polish And Verification - Research

**Researched:** 2026-05-08
**Domain:** Native macOS SwiftUI sidebar polish, filtered empty states, and local verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

**CRITICAL:** These decisions are copied from `03-CONTEXT.md` and must be honored by the planner and executor.

### Rows And Section Headers
- **D-01:** Section headers should use a compact label-plus-count treatment with a subtle divider, rather than the current parenthetical count style or a count badge.
- **D-02:** Header styling should stay quiet and native-feeling. Phase 1 decisions still apply: source order is launchd first then Hermes cron, and counts represent only currently visible jobs.
- **D-03:** Job rows should receive light polish only: keep the current row structure and preserve display name, subtitle, health dot, and selected-row behavior.
- **D-04:** Preserve the current soft accent selected-row fill. Implementation may tune opacity, spacing, or corner radius if needed, but should not switch to a much stronger native-list selection treatment.
- **D-05:** Add a quiet hover background if straightforward in the existing SwiftUI view structure. Do not add custom focus rings or a new explicit focus visual treatment.

### Filtered Empty State
- **D-06:** When a non-empty search query produces no visible jobs, show a small inline sidebar empty state.
- **D-07:** The new empty state is only for filtered searches. If the scan finds no jobs at all, keep that broader app/detail empty behavior out of this phase.
- **D-08:** The empty state must not be a selectable placeholder row. Up/Down keyboard navigation should do nothing when there are no visible jobs.
- **D-09:** Empty-state copy should be plain and functional: `No matching automations` and `Try a different search.`

### Verification
- **D-10:** The required automated gate is `./script/ci.sh`.
- **D-11:** The manual sidebar behavior check should verify that rows still show display name, subtitle, health dot, and selection styling; search no-results shows the inline empty state; and clearing search restores grouped Up/Down keyboard navigation.
- **D-12:** Document the manual check in the phase plan only. Do not add a separate checklist document or a new script for this phase.
- **D-13:** If CI fails because of pre-existing unrelated modified files or unrelated self-test failures, report and isolate the failure. Only fix issues caused by Phase 3, and record whether unrelated failures block phase acceptance.
</user_constraints>

<project_constraints>
## Project Constraints

- Keep scanner IO out of views; Phase 3 should use `SidebarJobSection`, `SidebarJobSummary`, `searchText`, and existing store state only.
- Preserve the read-only product boundary. Sidebar polish must not edit scheduled jobs, launchd plists, Hermes cron metadata, or output files.
- Avoid third-party dependencies. SwiftUI and AppKit are already available through the macOS 14 SwiftPM app target.
- Continue the established grouped sidebar and keyboard navigation contracts from Phases 1 and 2.
- Use the existing local gate: `./script/ci.sh`, which runs `swift build` and `./script/test.sh`.
- The worktree may contain pre-existing source edits. Execution must preserve unrelated changes and isolate any verification failures that are not caused by Phase 3.
</project_constraints>

<research_summary>
## Summary

Phase 3 is a focused UI polish and verification pass over the already-grouped, keyboard-navigable sidebar. The current code has the right ownership shape: `ContentView` owns search filtering, `SidebarJobSection.sections(for:)` groups already-visible jobs, and `SidebarView` renders headers, rows, key handling, scroll reveal, and the scan footer.

The safest implementation shape is:

1. Pass a derived filtered-empty signal from `ContentView` into `SidebarView`, using a trimmed non-empty `searchText` and an empty `filteredJobs` or `sidebarSections` result. This keeps empty-state intent at the search owner and avoids scanner IO in the view.
2. Render a private inline empty-state view in the sidebar list area only when that signal is true. Do not add the empty state to `visibleJobs`, do not give it a row id, and do not attach a button/action/focus target to it.
3. Update `SourceSectionHeader` from `"\(section.title) (\(section.visibleCount))"` to a compact leading label plus trailing count with a subtle divider. Preserve `section.title`, `section.visibleCount`, and Phase 1 source ordering.
4. Keep `SidebarJobRow` as a plain button with `HealthDot`, display name, subtitle, and soft selected background. Optional hover can be local row presentation state such as `@State private var isHovered = false` and `.onHover`.
5. Use `./script/ci.sh` as the final automated gate and record a manual sidebar behavior check in `03-02-SUMMARY.md`.

No `ActiveJobsCore` scanner, model, parsing, filesystem, or process code needs to change. No new test harness is required for the UI-only polish; the verification plan should rely on `swift build`, `./script/ci.sh`, grep-verifiable source checks, and a manual sidebar pass.
</research_summary>

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
SidebarView.sections + showsFilteredEmptyState
    |
    v
Header / rows / inline filtered empty state
```

### Pattern 1: Let ContentView Derive Search-Empty Intent

`ContentView` already trims and lowercases `searchText` to filter jobs. It should derive a boolean such as:

```swift
private var hasSearchQuery: Bool {
    !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

private var showsFilteredEmptyState: Bool {
    hasSearchQuery && filteredJobs.isEmpty
}
```

Then pass that boolean to `SidebarView`. This avoids making `SidebarView` inspect search text or re-run filtering.

### Pattern 2: Keep Empty State Outside Navigation

`SidebarView.visibleJobs` is still the only Up/Down traversal source:

```swift
private var visibleJobs: [SidebarJobSummary] {
    sections.flatMap(\.jobs)
}
```

When filtered search produces no rows, `visibleJobs` is empty, so `SidebarNavigation.targetJobID(...)` returns nil and `navigate(_:)` returns `.ignored`. The empty state must remain plain view content, not a `SidebarJobSummary`, not a `Button`, and not a scroll target id.

### Pattern 3: Polish Existing Row Components

`SidebarJobRow` already has the required row structure:

```swift
HStack(spacing: 10) {
    HealthDot(kind: job.healthKind)
    VStack(alignment: .leading, spacing: 2) {
        Text(job.displayName)
        Text(job.subtitle)
    }
    Spacer(minLength: 0)
}
```

Keep this shape. Phase 3 may tune padding, min height, selected background opacity, and add quiet hover state, but must not remove the health dot, title, subtitle, button behavior, or selected-row fill.

### Pattern 4: Use Semantic Native Styling

The UI contract requires semantic macOS colors and system font sizes. Prefer `.foregroundStyle(.secondary)`, `Color.accentColor.opacity(...)`, `Color.primary.opacity(...)`, `Divider().opacity(...)`, and `.font(.system(size:weight:))` over hard-coded RGB colors.
</architecture_patterns>

<pitfalls>
## Pitfalls To Avoid

- Do not use parenthetical section counts after Phase 3; the target is leading label plus trailing count.
- Do not implement a count badge; the UI spec explicitly rejects badges for this phase.
- Do not add a selectable placeholder row for no search results.
- Do not change selection when search becomes empty or no-results; navigation should only move on explicit row choice or Up/Down with visible jobs.
- Do not hijack search-field arrow behavior while polishing the list.
- Do not move search filtering into `SidebarView`.
- Do not add source grouping preferences, collapsible sections, type-ahead navigation, new shortcuts, scanner changes, or job mutation controls.
- Do not add a new checklist document or script for manual verification; record it in the execution summary.
</pitfalls>

<verification_guidance>
## Verification Guidance

Automated:
- `swift build`
- `./script/ci.sh`
- grep/read checks that `SidebarView` contains the exact empty-state copy, no scanner IO, no `/bin/launchctl`, and the row still renders `HealthDot`, `job.displayName`, and `job.subtitle`.
- grep/read checks that `ContentView` still owns `.searchable(text: $searchText, placement: .sidebar)` and passes a derived filtered-empty boolean.

Manual:
- Confirm grouped rows still display display name, subtitle, health dot, and soft selected-row styling.
- Type a search that hides all visible rows and confirm the inline sidebar copy says `No matching automations` and `Try a different search.`
- Press Up/Down with no visible rows and confirm selection does not move to an empty placeholder.
- Clear search and confirm grouped Up/Down navigation still traverses visible jobs.
</verification_guidance>
