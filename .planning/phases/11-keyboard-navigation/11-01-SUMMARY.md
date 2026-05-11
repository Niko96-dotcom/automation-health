---
phase: 11-keyboard-navigation
plan: 01
subsystem: ui
tags: [swiftui, appkit, keyboard-shortcuts, commandmenu, focus-state]

# Dependency graph
requires: []
provides:
  - "PreferencesStore sidebarExpandAllOverride transient override property"
  - "PreferencesStore requestSearchFieldFocus and requestJobListFocus focus bridge flags"
  - "View CommandMenu with 8 keyboard shortcuts (Focus, Expand/Collapse, 5 grouping modes)"
  - "ContentView NSSearchField programmatic focus control"
  - "ContentView Escape handler clearing search and returning focus to job list"
affects:
  - "11-02 (type-to-select, expand override rendering in SidebarView)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Transient @Published bridge flags for CommandMenu→view focus communication"
    - "AppKit NSToolbar iteration to locate NSSearchField for programmatic focus"
    - "onKeyPress(.escape) with NSEvent.modifierFlags guard for modifier passthrough"

key-files:
  created: []
  modified:
    - Sources/AutomationHealth/Stores/PreferencesStore.swift
    - Sources/AutomationHealth/App/AutomationHealthApp.swift
    - Sources/AutomationHealth/Views/ContentView.swift

key-decisions:
  - "Keyboard shortcut infrastructure uses transient @Published bridge flags (not UserDefaults) — focus and expand/collapse requests reset immediately after consumption"
  - "NSSearchField located via NSToolbar.visibleItems iteration rather than environment injection — standard AppKit approach for .searchable-placed fields"
  - "Escape handler guards against modifier keys (NSEvent.modifierFlags.isEmpty) so Option+Escape and other system shortcuts pass through"

patterns-established:
  - "Transient @Published bridge: CommandMenu sets flag=true, view observes via .onChange, acts, resets to false"
  - "AppKit NSSearchField focus: iterate NSToolbar visibleItems, cast to NSSearchField, call makeFirstResponder"

requirements-completed: [NAV-01, NAV-02, NAV-03, NAV-04]

# Metrics
duration: 1min
completed: 2026-05-11
---

# Phase 11 Plan 01: Keyboard Shortcut Foundation

**PreferencesStore transient bridge properties, View CommandMenu with 8 shortcuts, and AppKit search field focus wiring — the app-level infrastructure for keyboard navigation**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-11T07:16:05Z
- **Completed:** 2026-05-11T07:16:22Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Added `sidebarExpandAllOverride: Bool?`, `requestSearchFieldFocus`, and `requestJobListFocus` transient properties to PreferencesStore — all non-persisted, bridging CommandMenu actions to view focus state
- Registered View CommandMenu with 8 keyboard shortcuts: Focus Search (⇧⌘F), Expand All Sections (⇧⌘E), Collapse All Sections (⇧⌘W), and Group by Source/Origin/Health/Trigger/Confidence (⌘1-⌘5)
- Wired ContentView to focus NSSearchField via AppKit when Cmd+Shift+F fires, and to clear search text + signal job list focus on Escape
- Existing Automations menu with Rescan (⌘R) preserved unchanged

## Task Commits

Each task was committed atomically:

1. **Task 1: Add expand/collapse override and focus request flags to PreferencesStore** - `5c89e1e` (feat)
2. **Task 2: Add View CommandMenu with all keyboard shortcuts to AutomationHealthApp** - `532b530` (feat)
3. **Task 3: Add search field focus and Escape handling to ContentView** - `87634b0` (feat)

## Files Modified
- `Sources/AutomationHealth/Stores/PreferencesStore.swift` — Added 3 transient @Published properties (sidebarExpandAllOverride, requestSearchFieldFocus, requestJobListFocus)
- `Sources/AutomationHealth/App/AutomationHealthApp.swift` — Added View CommandMenu with 8 keyboard shortcuts before existing Automations menu
- `Sources/AutomationHealth/Views/ContentView.swift` — Added import AppKit, focusSearchField() helper, .onChange for search focus, .onKeyPress for Escape

## Decisions Made
- **Transient bridge pattern:** CommandMenu actions write to transient `@Published` flags on PreferencesStore; views observe, act, and reset. No UserDefaults persistence — these are ephemeral UI signals, not preferences
- **AppKit search field discovery:** `NSSearchField` located by iterating `NSToolbar.visibleItems` and casting views — standard approach since `.searchable` places the field in the toolbar automatically
- **Modifier guard on Escape:** `NSEvent.modifierFlags.isEmpty` check ensures modifier-key Escape combos (e.g., Option+Escape) pass through to system handlers

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — all three tasks compiled and verified on first attempt. `swift build` and `swift run ActiveJobsCoreSelfTest` passed with zero errors.

## Known Stubs

None — all wiring is functional at the infrastructure level. The job list focus response to `requestJobListFocus` is the responsibility of SidebarView in Plan 02.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes beyond the documented trust boundaries in the plan's threat model.

## Verification

- `swift build` — passed, zero errors across all targets
- `swift run ActiveJobsCoreSelfTest` — passed, all 33 existing tests green
- All 15 acceptance criteria verified via grep counts
- No UserDefaults persistence on the three new transient properties

## Next Phase Readiness

Ready for Plan 02 — SidebarView can now observe:
- `preferences.sidebarExpandAllOverride` to force expand/collapse all sections
- `preferences.requestJobListFocus` to set `focusedTarget = .jobList` on Escape
- Type-to-select buffer and expand override reset on manual disclosure click remain to be implemented

---
*Phase: 11-keyboard-navigation*
*Completed: 2026-05-11*
