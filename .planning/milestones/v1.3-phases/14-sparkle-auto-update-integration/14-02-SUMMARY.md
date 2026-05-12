---
phase: 14-sparkle-auto-update-integration
plan: 02
subsystem: ui
tags: [sparkle, swiftui, auto-update, macOS, settings, menu]

requires:
  - phase: 14-sparkle-auto-update-integration
    plan: 01
    provides: "UpdateStore with SPUUpdater wrapper, UpdateState enum, SPUUpdaterDelegate bridge"
provides:
  - "Sparkle updater lifecycle management in AutomationHealthApp (SPUUpdater creation, start, delegate wiring)"
  - "Check for Updates menu item under app menu (CommandGroup after .appInfo)"
  - "Updates section in SettingsView with version display, auto-check toggle, manual check button"
  - "Error state when Sparkle cannot initialize (missing EdDSA key)"
  - "feedURLString(for:) implementation on UpdateStoreDelegate with GitHub Releases URL pattern"
affects: [14-03]

tech-stack:
  added: []
  patterns:
    - "@StateObject UpdateStore pattern following existing PreferencesStore/JobStore convention"
    - "Configurable delegate pattern: UpdateStoreDelegate with settable store reference resolves SPUUpdater init circular dependency"
    - "CommandGroup(after: .appInfo) for macOS-standard Check for Updates menu placement"

key-files:
  created: []
  modified:
    - "Sources/AutomationHealth/App/AutomationHealthApp.swift"
    - "Sources/AutomationHealth/Stores/UpdateStore.swift"
    - "Sources/AutomationHealth/Views/SettingsView.swift"

key-decisions:
  - "Used existing UpdateStoreDelegate (from plan 14-01) instead of creating separate AppUpdaterDelegate — avoids duplicate delegate implementations and keeps updateState transitions wired"
  - "Added feedURLString(for:) to UpdateStoreDelegate rather than creating a second delegate class — single delegate handles both appcast URL provision and update state bridging"
  - "Made UpdateStoreDelegate.store a settable optional var to resolve circular init dependency (SPUUpdater needs delegate, UpdateStoreDelegate needs store, UpdateStore needs SPUUpdater)"
  - "Deferred Settings scene update to Task 2 so each task compiles independently"

patterns-established:
  - "Two-phase delegate initialization: create delegate, create updater with delegate, create store with updater, then wire store back to delegate"
  - "Conditional SettingsView section rendering based on UpdateState enum (error vs normal/checking)"
  - "Manual Binding wrapper for automaticallyChecksForUpdates toggle (non-Binding @Published property)"

requirements-completed: [DIST-08]

metrics:
  duration: 7min
  completed: 2026-05-12
---

# Phase 14 Plan 02: Wire Sparkle Updater into App and Settings Summary

**Sparkle auto-update integration: SPUUpdater lifecycle in app entry point, Check for Updates menu item, and Updates section in native Settings with version display, auto-check toggle, manual check button, and graceful error state.**

## Performance

- **Duration:** 7min
- **Started:** 2026-05-12T08:46:32Z
- **Completed:** 2026-05-12T08:52:25Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created SPUUpdater with SPUStandardUserDriver and UpdateStoreDelegate in App.init(), started in WindowGroup.task
- Added "Check for Updates..." menu item under app menu (CommandGroup after .appInfo) following macOS HIG conventions
- Added Updates section to SettingsView with version display, ProgressView spinner during checking, auto-check toggle, and manual check button
- Implemented error state showing "Update checking is unavailable" with Sparkle error message as caption text
- Wired feedURLString(for:) on UpdateStoreDelegate using GitHub Releases appcast URL pattern with dev-build exclusion

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire Sparkle updater lifecycle in AutomationHealthApp** - `f5c320a` (feat)
2. **Task 2: Add Updates section to SettingsView** - `c7005ab` (feat)

## Files Created/Modified

- `Sources/AutomationHealth/App/AutomationHealthApp.swift` - Added import Sparkle, UpdateStore @StateObject, SPUUpdater/SPUStandardUserDriver creation in init(), .task to start updater, CommandGroup for Check for Updates menu item, Settings scene passes updateStore
- `Sources/AutomationHealth/Stores/UpdateStore.swift` - Added feedURLString(for:) to UpdateStoreDelegate with GitHub Releases URL pattern, changed store from private let to settable var for two-phase init, updated delegate methods to use optional chaining
- `Sources/AutomationHealth/Views/SettingsView.swift` - Added import Sparkle, UpdateStore @ObservedObject parameter, Updates section with version label, auto-check toggle, manual check button, and error state

## Decisions Made

1. **Reused UpdateStoreDelegate instead of creating AppUpdaterDelegate** — The plan specified a new file-private `AppUpdaterDelegate` class in AutomationHealthApp.swift, but plan 14-01 already created `UpdateStoreDelegate` with the SPUUpdaterDelegate methods for updating `updateState`. Creating a second delegate would either duplicate state management or require wiring two delegates. Added the missing `feedURLString(for:)` method to the existing delegate instead.

2. **Two-phase delegate initialization** — The circular dependency (SPUUpdater needs delegate, delegate needs store, store needs SPUUpdater) was resolved by making `UpdateStoreDelegate.store` a settable `var?` and wiring it after all objects are created.

3. **Deferred Settings scene update to Task 2** — The plan's Task 1 step 6 (update Settings scene to pass updateStore) would cause a compile error until SettingsView has the updateStore parameter. Moved this to Task 2 so each task compiles and commits independently.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Circular init dependency between UpdateStore, SPUUpdater, and delegate**
- **Found during:** Task 1
- **Issue:** UpdateStore.init(updater:) requires SPUUpdater, SPUUpdater.init(delegate:) requires delegate, but UpdateStoreDelegate.init(store:) requires UpdateStore. Three-way circular dependency.
- **Fix:** Changed UpdateStoreDelegate.store from private let to settable var with optional type; create delegate first, then updater, then store; wire store back to delegate after all objects exist.
- **Files modified:** Sources/AutomationHealth/Stores/UpdateStore.swift
- **Verification:** `swift build` compiles cleanly; all delegate methods use optional chaining on store?
- **Committed in:** f5c320a (Task 1 commit)

**2. [Rule 1 - Bug] Task 1 Settings scene update creates compile error before Task 2**
- **Found during:** Task 1
- **Issue:** Plan specifies updating `SettingsView(preferences: preferences)` to `SettingsView(preferences: preferences, updateStore: updateStore)` in Task 1, but SettingsView doesn't have the updateStore parameter until Task 2.
- **Fix:** Deferred the Settings scene change to Task 2 (combined with SettingsView modifications). Each task now compiles independently.
- **Files modified:** Sources/AutomationHealth/App/AutomationHealthApp.swift
- **Verification:** `swift build` passes after Task 1 commit and again after Task 2 commit.
- **Committed in:** c7005ab (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both bugs arose from the plan not accounting for the delegate created in plan 14-01 and the task sequencing dependency. No scope creep — the same functionality was delivered with cleaner architecture (single delegate instead of two).

## Issues Encountered

None beyond the deviations documented above.

## User Setup Required

None - no external service configuration required. The Sparkle feed URL points to GitHub Releases; actual appcast generation is handled by plan 14-03.

## Next Phase Readiness

- AutomationHealthApp creates and starts SPUUpdater on launch
- SettingsView renders Updates section with full state handling
- Ready for plan 14-03 (Sparkle key generation and appcast tooling)
- The feedURLString implementation expects appcast.xml at `https://github.com/nikomohr/AutomationHealth/releases/download/v{version}/appcast.xml` — plan 14-03 must generate and upload this file

---
*Phase: 14-sparkle-auto-update-integration*
*Completed: 2026-05-12*
