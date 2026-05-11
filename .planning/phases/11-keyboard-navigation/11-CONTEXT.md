# Phase 11: Keyboard Navigation - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Add keyboard shortcuts to the sidebar: focus search (Cmd+Shift+F), expand/collapse all sections (Cmd+Shift+E / Cmd+Shift+W), switch grouping modes (Cmd+1 through Cmd+5), and type-to-select letter navigation. All shortcuts must coexist with existing Up/Down arrow navigation and work regardless of current grouping mode or collapse state.

**In scope:**
- Cmd+Shift+F to focus the sidebar search field from anywhere
- Cmd+Shift+E to expand all sidebar sections; Cmd+Shift+W to collapse all
- Cmd+1 through Cmd+5 to switch between grouping modes
- Multi-character type-to-select (300ms buffer) that scrolls to and selects the first matching job
- Escape to clear search text and defocus the search field
- Self-test coverage for new navigation logic
- All shortcuts work with existing Up/Down arrow navigation

**Out of scope:**
- Schedule-based grouping (Phase 12)
- Code signing, notarization, packaging (Phase 13)
- Drag-to-reorder or custom grouping
- Tab key navigation between sections
- Enter key behavior changes
</domain>

<decisions>
## Implementation Decisions

### Shortcut Design
- **D-01:** Cmd+Shift+F focuses the search field. Standard macOS pattern (Finder, Safari, Mail).
- **D-02:** Cmd+Shift+E expands all sections; Cmd+Shift+W collapses all. Mnemonic pair, unlikely to conflict with system shortcuts.
- **D-03:** Cmd+1 through Cmd+5 switch grouping modes in enum case order: Source=1, Origin=2, Health=3, Trigger=4, Confidence=5. macOS convention for view switching.
- **D-04:** Type-to-select uses multi-character buffer with 300ms timeout. User types letters, sidebar scrolls to and selects first matching job. Silent no-op if no match.

### Implementation Architecture
- **D-05:** `@FocusState private var isSearchFieldFocused: Bool` lives in ContentView (already owns searchText). Focus shortcut dispatched via `.commands` modifier.
- **D-06:** Temporary expand/collapse override via `@Published var sidebarExpandAllOverride: Bool? = nil` in PreferencesStore. When non-nil, SidebarView forces all sections open/closed. Reset to nil when user manually clicks any disclosure triangle.
- **D-07:** Global shortcuts (Cmd+Shift+F, Cmd+1..5) go in AutomationHealthApp `.commands` modifier. View-local shortcuts (type-to-select, expand/collapse, Escape) go in SidebarView or ContentView via `.onKeyPress`.
- **D-08:** Expand/collapse injects the PreferencesStore binding; no need for separate notification or environment object since ContentView already holds the reference.
- **D-09:** Type-to-select reuses existing ScrollViewReader + keyboardNavigationTargetID pattern. A PassthroughSubject or Combine publisher collects typed characters, resolves target job ID via SidebarNavigation helpers, triggers scroll+select.

### Edge Cases
- **D-10:** Type-to-select with no match: silent no-op, stay on current selection.
- **D-11:** Escape key: clears searchText AND defocuses search field, returning focus to job list so arrow keys work.
- **D-12:** Expand all override resets on any manual collapse/expand click — user clicks a disclosure triangle and the override clears.
- **D-13:** All 5 grouping mode shortcuts always registered, regardless of grouping mode count (enum is fixed).

### the agent's Discretion
- Exact implementation of type-to-select buffer (NSTimer vs DispatchQueue.main.asyncAfter vs Combine debounce)
- Whether to use a FocusedValue or direct property for search field focus state
- Specific placement of expand/collapse override toggle button appearance
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SidebarNavigation.targetJobID(in:sections:selectedJobID:direction:)` — already computes next/previous visible job from collapsed sections
- `ScrollViewReader` + `keyboardNavigationTargetID` pattern in SidebarView — proven scroll-to-target mechanism
- `@FocusState private var focusedTarget: SidebarFocusTarget?` — existing job list focus state, extendable
- `SidebarGroupingMode` enum with 5 cases, already Codable for persistence
- `PreferencesStore` with `@Published var groupingMode`, `@Published var collapseState` — ready for expand override

### Established Patterns
- `.searchable(text: $searchText, placement: .sidebar)` in ContentView — no focus binding currently
- Up/Down arrow handled via `.onKeyPress` with `.phases(.down)` pattern
- `.equatable()` on SidebarJobRow for efficient diffing
- `.id(job.id)` on ForEach for ScrollViewReader targeting
- `Binding<String?>` for selectedJobID passed from ContentView through to SidebarView

### Integration Points
- `AutomationHealthApp.swift` `.commands` modifier — global shortcuts land here
- `ContentView.swift` — owns searchText and will own search FocusState
- `SidebarView.swift` — receives PreferencesStore, owns job list FocusState and ScrollViewReader
- `JobPresentation.swift` — SidebarNavigation static helpers for job ID resolution
- `PreferencesStore.swift` — needs new `sidebarExpandAllOverride` property
</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond ROADMAP success criteria and grey area decisions captured above.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.
</deferred>
