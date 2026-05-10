# Architecture Research: v1.2 Preferences, Polish, and Shippable Distribution

**Domain:** macOS SwiftUI read-only automation scanner app — integration of preferences persistence, advanced grouping, keyboard shortcuts, codesigning/notarization, and Settings scene
**Researched:** 2026-05-10
**Confidence:** HIGH (verified against current codebase via direct file reads + Apple SwiftUI docs via Context7)

## System Overview — Post-Integration Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        SwiftUI macOS App Layer                           │
│  Automat ionHealthApp ── WindowGroup ── Settings ── CommandMenu          │
│   @StateObject store        │            scene       (keyboard shortcuts)│
│   @StateObject preferences  │            │                               │
├─────────────────────────────┼────────────┼───────────────────────────────┤
│                      ContentView                                          │
│  @ObservedObject store    @ObservedObject preferences                    │
│  @State searchText          ↓ provides groupingMode/collapseState        │
├─────────────────────────────┼────────────────────────────────────────────┤
│              SidebarView             │          DetailView                │
│  sections: [SidebarJobSection]       │   job: JobPresentation?           │
│  keyboard: Up/Down/letters + jump    │   manual record edit/remove       │
│  focus: @FocusState(.jobList)        │   Finder reveal, log text         │
├──────────────────────────────────────┴────────────────────────────────────┤
│                    Presentation State Layer                               │
│  ┌──────────────────┐  ┌──────────────────────────────┐                  │
│  │   JobStore        │  │   PreferencesStore (NEW)     │                  │
│  │ (@MainActor)      │  │ (@MainActor ObservableObject)│                  │
│  │ @Published jobs   │  │ @Published groupingMode      │                  │
│  │ @Published sel.*  │  │ @Published collapseState     │                  │
│  │ @Published scan*  │  │ @Published scanOnLaunch      │                  │
│  │ refresh()         │  │ UserDefaults ↔ published     │                  │
│  └───────┬──────────┘  └──────────────────────────────┘                  │
│          │                                                                │
│  ┌───────┴──────────────────────────────────────────┐                    │
│  │  AutomationHealthCore (JobPresentation.swift)     │                    │
│  │  SidebarGroupingMode (extended: +schedule,+custom) │                    │
│  │  SidebarCollapseState (NEW: Codable)              │                    │
│  │  SidebarJobSection.sections(for:...)              │                    │
│  │  SidebarNavigation (unchanged)                    │                    │
│  └──────────────────────┬───────────────────────────┘                    │
├─────────────────────────┼────────────────────────────────────────────────┤
│              ActiveJobsCore (Core Scanner Library Layer)                  │
│  ┌──────────────────────┴───────────────────────────┐                    │
│  │ Models: ScheduledJob, JobSource, JobConfidence,   │                    │
│  │ JobOrigin, ScanNote                              │                    │
│  │ Services: JobScanning, JobInventory,              │                    │
│  │ LaunchAgentScanner, HermesCronScanner,            │                    │
│  │ CronScanner, ShortcutsScanner, AutomatorScanner,  │                    │
│  │ CandidateScriptScanner, ManualRecordStore         │                    │
│  │ Support: JobHumanizer, DateParsing,               │                    │
│  │ TextSnippetReader                                │                    │
│  └──────────────────────────────────────────────────┘                    │
├──────────────────────────────────────────────────────────────────────────┤
│              Local Scheduler Sources (read-only, unchanged)              │
│  launchd plists, Hermes cron JSON, cron tabs,                           │
│  Shortcuts DB, Automator workflows, candidate scripts                   │
└──────────────────────────────────────────────────────────────────────────┘

                     Build & Distribution Layer (NEW scripts)
┌──────────────────────────────────────────────────────────────────────────┐
│  script/                                                                 │
│  ├── build_and_run.sh  (MODIFIED: +sign mode, +entitlements)            │
│  ├── ci.sh             (MODIFIED: +notarize dry-run check)              │
│  ├── test.sh           (unchanged)                                      │
│  ├── sign.sh           (NEW: codesign with Developer ID, entitlements)  │
│  ├── notarize.sh       (NEW: notarytool submit + stapler staple)        │
│  └── package.sh         (NEW: hdiutil DMG, LICENSE bundling)            │
│  dist/                                                                   │
│  ├── AutomationHealth.app  (signed, notarized, stapled)                  │
│  └── AutomationHealth-v1.2.dmg                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## New Components

| Component | File (NEW or MODIFIED) | Responsibility |
|-----------|------------------------|----------------|
| `PreferencesStore` | `Sources/AutomationHealth/Stores/PreferencesStore.swift` (NEW) | `@MainActor ObservableObject` bridging UserDefaults to `@Published`; owns grouping mode, collapse state, scan-on-launch toggle, and any future persisted preferences |
| `SettingsView` | `Sources/AutomationHealth/Views/SettingsView.swift` (NEW) | SwiftUI form for grouping default, scan behavior, keyboard shortcut reference |
| `SidebarScheduleKind` | `Sources/AutomationHealthCore/JobPresentation.swift` (MODIFIED — new enum) | Classification enum for schedule-based grouping: morning/afternoon/evening/night, daily/weekly/monthly/on-demand |
| `CustomOrderStore` | `Sources/AutomationHealth/Stores/CustomOrderStore.swift` (NEW, deferred) | JSON-backed custom job ordering (per grouping mode); may be in-scope or deferred based on complexity |
| `entitlements.plist` | `entitlements.plist` (NEW) | Hardened runtime entitlements for codesigning (minimal: `com.apple.security.cs.disable-library-validation` not needed for SwiftPM app) |
| `script/sign.sh` | `script/sign.sh` (NEW) | Codesign `.app` bundle with Developer ID, verify signature |
| `script/notarize.sh` | `script/notarize.sh` (NEW) | Zip, submit to notarytool, wait, staple ticket |
| `script/package.sh` | `script/package.sh` (NEW) | Create DMG from stapled `.app`, bundle LICENSE |
| Enhanced `CommandMenu` entries | `Sources/AutomationHealth/App/AutomationHealthApp.swift` (MODIFIED) | View menu and Navigation menu with keyboard shortcuts |

## Modified Components

| Component | What Changes | Why |
|-----------|-------------|-----|
| `AutomationHealthApp` | Add `@StateObject private var preferences = PreferencesStore()`; add `Settings` scene; expand `.commands` with View shortcuts; pass `preferences` to `ContentView` | PreferencesStore needs to live at app scope for CommandMenu access and Settings scene |
| `ContentView` | Replace `@State sidebarGroupingMode` and `@State sidebarCollapseState` with `@ObservedObject preferences` bindings; add `@FocusState private var searchFieldFocused` for Cmd+F | Grouping state must be shared between views and CommandMenu; Cmd+F needs search field focus binding |
| `SidebarView` | Add `.onKeyPress` handlers for letter-key jump-to; add binding for `searchFieldFocused` | Letter-jump navigation is a sidebar-local concern; focus-search shortcut needs to reach the search field |
| `SidebarGroupingMode` | Add `scheduleTimeOfDay` and `custom` cases | Per milestone requirements for new grouping affordances |
| `SidebarCollapseState` | Add `Codable` conformance; add `expandAll()` and `collapseAll()` mutating methods | Collapse state must persist in UserDefaults JSON; expand/collapse all is needed for keyboard shortcuts |
| `SidebarSectionID` | Add `Codable` conformance | Required for `SidebarCollapseState` serialization |
| `SidebarJobSection.groupDefinitions(for:)` | Add switch cases for `.scheduleTimeOfDay` and `.custom` | Core grouping logic for new modes |
| `JobPresentation` | Add `scheduleTimeOfDay` computed property for schedule classification | New grouping dimension needs classification on the presentation model |
| `build_and_run.sh` | Add optional `--sign` mode, `CODE_SIGN_IDENTITY` variable, hardened runtime flag, entitlements reference | Local build should optionally support signing for testing |
| `Makefile` | Add `make sign`, `make notarize`, `make package`, `make release` targets | Developer convenience for distribution pipeline |

## Integration Points (New → Existing Connections)

### Integration Point 1: PreferencesStore → ContentView → SidebarView
- **Current:** `ContentView` holds `@State private var sidebarGroupingMode: SidebarGroupingMode = .defaultMode` and `@State private var sidebarCollapseState = SidebarCollapseState()` (lines 8-9)
- **Change:** Replace both `@State` with `@ObservedObject var preferences: PreferencesStore` injected from `AutomationHealthApp`
- **Binding path:** `$preferences.groupingMode` and `$preferences.collapseState` flow into `SidebarView` via existing `@Binding` parameters (already accept Bindings)
- **Risk:** LOW — `SidebarView` already receives these as `@Binding`; only the source of the binding changes from `@State` to `@Published` via `@ObservedObject`

### Integration Point 2: PreferencesStore → UserDefaults
- **Current:** No persistence exists; `SidebarGroupingMode.rawValue` is a `String` suitable for `@AppStorage`
- **Change:** `PreferencesStore` reads `UserDefaults.standard` in `init()`, writes on `didSet` of each `@Published` property
- **Keys:** `"sidebarGroupingMode"` (String), `"sidebarCollapseState"` (Data/JSON), `"scanOnLaunch"` (Bool)
- **Risk:** LOW — this is entirely new code, no existing UserDefaults keys to conflict with

### Integration Point 3: Settings Scene → AutomationHealthApp
- **Current:** `AutomationHealthApp` has only `WindowGroup` with a single `ContentView` (lines 17-24)
- **Change:** Add `Settings { SettingsView(preferences: preferences) }` as a sibling scene to `WindowGroup`, conditional on `#if os(macOS)` (already macOS-only by `Package.swift` platform constraint)
- **SwiftUI automatically adds** Settings menu item to the app menu; no manual menu wiring needed
- **Risk:** LOW — standard SwiftUI pattern documented by Apple; Settings view is a simple form binding to `PreferencesStore`

### Integration Point 4: CommandMenu Shortcuts → PreferencesStore / JobStore
- **Current:** One `CommandMenu("Automations")` with Cmd+R rescan (lines 25-31)
- **Change:** Add `CommandMenu("View")` with expand/collapse all, grouping mode cycling, focus search; add `CommandMenu("Navigate")` for sidebar navigation shortcuts
- **Access pattern:** `AutomationHealthApp` owns both `store` and `preferences` as `@StateObject`; CommandMenu closures capture them directly (same pattern as existing Cmd+R)
- **Risk:** LOW — same pattern as existing Cmd+R shortcut

### Integration Point 5: New Grouping Modes → SidebarJobSection.groupDefinitions
- **Current:** `groupDefinitions(for:)` has 5 switch cases (source, origin, health, trigger, confidence) (lines 414-463)
- **Change:** Add `.scheduleTimeOfDay` case (classifies by time-of-day or frequency) and `.custom` case (user-defined order)
- **New classification:** Requires `JobPresentation` to expose schedule characteristics: next-run hour → time-of-day bucket, frequency pattern → schedule type
- **Risk:** MEDIUM — schedule classification heuristics must handle nil next-run values (registered/candidate/manual records have no schedule evidence); must preserve the existing invariant that these records never claim schedule they don't have

### Integration Point 6: Letter-Jump → SidebarView Focus Handling
- **Current:** `SidebarView` handles `.downArrow` and `.upArrow` via `onKeyPress` (lines 108-109)
- **Change:** Add `.onKeyPress` for character keys (a-z) that finds the first visible job whose `displayName` starts with the pressed letter
- **Implementation:** Use `.onKeyPress(characters: .alphanumeric)` or individual `onKeyPress(KeyEquivalent)` handlers; compute the matching `SidebarJobSummary.id` and set `selectedJobID`
- **Risk:** LOW — straightforward extension of existing keyboard navigation pattern

### Integration Point 7: Codesigning → build_and_run.sh
- **Current:** `build_and_run.sh` assembles `.app` bundle without signing (lines 35-64)
- **Change:** After `cp "$BUILD_BINARY" "$APP_BINARY"`, conditionally run `codesign` when `--sign` mode or when `CODE_SIGN_IDENTITY` env var is set
- **Entitlements:** New `entitlements.plist` with hardened runtime: `com.apple.security.cs.allow-unsigned-executable-memory` (may be needed for Swift runtime), `com.apple.security.automation.apple-events` only if future features need it
- **Risk:** LOW — codesigning is additive; unsigned builds continue to work for local development

### Integration Point 8: Notarization/DMG → New Scripts
- **Current:** No notarization or DMG packaging exists
- **Change:** New `script/notarize.sh` and `script/package.sh` run after signing; DMG bundles the stapled `.app` + LICENSE
- **No changes to existing scripts** — these are entirely new
- **Risk:** LOW — fully additive, run independently

## Data Flow Changes

### Flow: Preferences → Grouping → Sidebar (NEW persistent path)

```
App Launch
    │
    ▼
PreferencesStore.init()
    │ reads UserDefaults.standard
    ├─ "sidebarGroupingMode" → SidebarGroupingMode(rawValue:)
    └─ "sidebarCollapseState" → JSONDecoder → SidebarCollapseState
    │
    ▼
@Published groupingMode ──────┐
@Published collapseState ─────┤
    │                         │
    ▼                         ▼
ContentView receives via @ObservedObject
    │
    ├─ groupingMode → SidebarView header menu (Picker/Menu)
    ├─ collapseState → SidebarView section toggle callbacks
    │
    ▼
SidebarJobSection.sections(for: jobs, groupingMode: mode, collapseState: state, hasSearchQuery: hasQuery)
    │
    ├─ groupDefinitions(for: mode) → [SidebarGroupDefinition]
    │   ├─ .source        → JobSource.allCases
    │   ├─ .origin        → JobOrigin.allCases
    │   ├─ .health        → [failed, stale, waiting, alive, unknown]
    │   ├─ .trigger       → SidebarTriggerKind.allCases
    │   ├─ .confidence    → JobConfidence.allCases
    │   ├─ .scheduleTimeOfDay  → [morning, afternoon, evening, night, onDemand] (NEW)
    │   └─ .custom        → CustomOrderStore.jobIDs (NEW, deferred)
    │
    └─ For each definition: filter visibleJobs by .matches, apply collapse state

User changes grouping mode (menu picker or Cmd+1..N shortcut)
    │
    ▼
preferences.groupingMode = newValue
    │
    ├─ didSet → UserDefaults.standard.set(newValue.rawValue, forKey: "sidebarGroupingMode")
    └─ @Published fires → ContentView recomputes sidebarSections → SidebarView re-renders

User toggles section collapse (chevron click or Cmd+Shift+E/C)
    │
    ▼
preferences.collapseState.toggle(sectionID)  OR  .expandAll() / .collapseAll()
    │
    ├─ didSet → encode to JSON → UserDefaults.standard.set(jsonData, forKey: "sidebarCollapseState")
    └─ @Published fires → ContentView recomputes → SidebarView re-renders

Preferences window (Cmd+,) opens Settings scene
    │
    ▼
SettingsView(preferences: preferences)
    │ reads/writes preferences.groupingMode, preferences.scanOnLaunch
    │ via Toggle, Picker bound to $preferences.*
    │
    ▼
Same didSet → UserDefaults persistence and @Published publishing as above
```

### Flow: Keyboard Shortcuts → State Changes

```
Cmd+R          → store.refresh()                               (existing)
Cmd+,          → opens Settings scene                          (automatic from Settings scene)
Cmd+Shift+F    → focus search field                            (NEW: @FocusState in ContentView)
Cmd+Shift+E    → preferences.collapseState.expandAll()         (NEW)
Cmd+Shift+C    → preferences.collapseState.collapseAll()       (NEW)
Cmd+1..Cmd+N   → preferences.groupingMode = specific mode     (NEW: one per mode)
Cmd+[          → navigate(.previous) in sidebar                (NEW: same as Up arrow)
Cmd+]          → navigate(.next) in sidebar                    (NEW: same as Down arrow)
Up/Down        → navigate(.previous/.next) in sidebar          (existing)
Letters a-z    → jump to first job starting with letter         (NEW: onKeyPress in SidebarView)
```

**Implementation note for Cmd+Shift+F:** The `.searchable(text:placement:)` modifier in `ContentView` (line 51) is on `SidebarView`, which is inside `NavigationSplitView`. To focus the search field from CommandMenu, we need:
1. Add `@FocusState private var isSearchFocused: Bool` to `ContentView`
2. Add `.searchable(text: $searchText, placement: .sidebar)` with `.searchFocused($isSearchFocused)` if available (macOS 14+)
3. Or expose a `FocusState` binding through to the search field
4. CommandMenu button sets `isSearchFocused = true`

## Suggested Build Order

Based on dependency analysis:

### Phase 1: Preferences Foundation (no visual change, pure infrastructure)
```
PreferencesStore          (NEW)
  ↓ depends on
SidebarCollapseState      (MODIFIED: +Codable, +expandAll, +collapseAll)
SidebarSectionID          (MODIFIED: +Codable)
  ↓ no dependency
```
**Rationale:** PreferencesStore is the prerequisite for persisted grouping mode (needed by keyboard shortcuts and Settings scene). Making collapse state Codable is a small, self-contained change.

### Phase 2: Settings Scene + Grouping Mode Persistence
```
Content View              (MODIFIED: @State → @ObservedObject preferences)
AutomationHealthApp       (MODIFIED: +PreferencesStore, +Settings scene, +View CommandMenu)
SettingsView              (NEW)
```
**Rationale:** Migrates grouping state to persisted store. Settings scene uses the same PreferencesStore. Keyboard shortcut CommandMenu entries for grouping mode cycling use PreferencesStore. This phase visible-izes the Phase 1 infrastructure.

### Phase 3: New Grouping Modes
```
SidebarGroupingMode       (MODIFIED: +scheduleTimeOfDay, +custom)
JobPresentation           (MODIFIED: +scheduleTimeOfDay computed property)
SidebarJobSection         (MODIFIED: +groupDefinitions cases)
SidebarScheduleKind       (NEW enum in AutomationHealthCore)
CustomOrderStore          (NEW, possibly deferred)
```
**Rationale:** New grouping modes build on the persisted grouping mode from Phase 2. Schedule classification needs the JobPresentation model.

### Phase 4: Keyboard Shortcuts
```
AutomationHealthApp       (MODIFIED: expand .commands with Navigate menu)
SidebarView               (MODIFIED: +onKeyPress for letter-jump)
ContentView               (MODIFIED: +@FocusState for search field)
```
**Rationale:** Keyboard shortcuts for expand/collapse all and grouping mode switching depend on PreferencesStore (Phase 1). Letter-jump depends on SidebarView which is unchanged by Phases 1-3. Cmd+Shift+F depends on ContentView search field.

### Phase 5: Distribution Pipeline
```
script/sign.sh            (NEW)
script/notarize.sh        (NEW)
script/package.sh         (NEW)
script/build_and_run.sh   (MODIFIED: +sign mode)
Makefile                  (MODIFIED: +sign/notarize/package targets)
entitlements.plist        (NEW)
LICENSE                   (NEW)
```
**Rationale:** Distribution is independent of UI features — no dependency on Phases 1-4. Can run in parallel or at any point. Only requirement: the app must build and run correctly (which it does from v1.1 baseline).

## Architectural Refactors Required Before Adding Features

### Refactor 1: Migrate grouping state from @State to persisted store (REQUIRED)
**What:** `ContentView` lines 8-9 currently hold `@State private var sidebarGroupingMode` and `@State private var sidebarCollapseState`. These must move into a shared store so CommandMenu shortcuts and the Settings scene can read/write them.
**Impact:** `AutomationHealthApp` adds `@StateObject private var preferences = PreferencesStore()`. `ContentView` receives `preferences: PreferencesStore` as parameter. Binding sites in `ContentView` line 30-34 and `SidebarView` lines 12-13 change source but keep the same `@Binding` types.
**Files touched:** `AutomationHealthApp.swift` (+8 lines), `ContentView.swift` (change 2 `@State` to `@ObservedObject` access), `SidebarView.swift` (unchanged — already takes `@Binding`).

### Refactor 2: Make SidebarCollapseState and SidebarSectionID Codable (REQUIRED)
**What:** `SidebarCollapseState` and `SidebarSectionID` (in `AutomationHealthCore/JobPresentation.swift`) need `Codable` conformance for UserDefaults JSON persistence.
**Impact:** Trivial — `SidebarSectionID` stores `groupingMode: SidebarGroupingMode` (String-RawRepresentable → Codable trivially) and `groupKey: String`. `SidebarCollapseState` stores `Set<SidebarSectionID>` — encode as array.
**Files touched:** `AutomationHealthCore/JobPresentation.swift` (add `Codable` to two struct conformances, ~5 lines).

### Refactor 3: Extract PreferencesStore to clean separation (RECOMMENDED, not strictly required)
**What:** Instead of mixing preferences into `JobStore`, create a dedicated `PreferencesStore`. `JobStore` stays focused on scan state, selection, manual record operations.
**Why:** `JobStore` is already 157 lines with refresh queuing, selection preservation, manual record CRUD. Adding grouping/collapse/scan-config state would violate single responsibility. A separate store keeps the mental model clear: JobStore = "what the scanner found," PreferencesStore = "how the user wants to view it."
**Files touched:** New file `Sources/AutomationHealth/Stores/PreferencesStore.swift`.

### Refactor 4: Split JobPresentation.swift into focused files (OPTIONAL, cleanup)
**What:** `AutomationHealthCore/JobPresentation.swift` is 576 lines containing `JobPresentation`, `SidebarGroupingMode`, `SidebarTriggerKind`, `SidebarSectionID`, `SidebarCollapseState`, `SidebarJobSummary`, `SidebarNavigation`, `SidebarJobSection`, `SidebarGroupDefinition`, and `SidebarTriggerClassifier`.
**Recommendation:** Not required for v1.2 — keeping the existing organization avoids churn. Only split if adding schedule-based grouping pushes the file past ~700 lines.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Putting preferences in JobStore
**What:** Adding `@Published var groupingMode`, `@Published var collapseState` to `JobStore` alongside scan state.
**Why wrong:** `JobStore.refresh()` runs heavy IO on detached tasks; mixing persistent preferences with ephemeral scan data conflates two different lifecycles. The `didSet` UserDefaults writes on JobStore would trigger on every scan refresh when the publish happens, even if the value didn't change (unnecessary writes).
**Instead:** Create a separate `PreferencesStore`. If you must consolidate, at least gate writes with `if newValue != oldValue`.

### Anti-Pattern 2: Scanner-specific branching in new grouping logic
**What:** Adding `switch job.job.source` inside `groupDefinitions(for: .scheduleTimeOfDay)` to handle launchd vs cron vs shortcuts differently.
**Why wrong:** Same anti-pattern already documented in codebase architecture. The classification should work on `ScheduledJob` fields (nextRun, schedule text) or `JobPresentation` computed properties, not on source identity.
**Instead:** Add a `scheduleTimeOfDay` computed property on `JobPresentation` that classifies based on `job.nextRun` (if present) or schedule text patterns, falling back to `.onDemand` for records with no schedule evidence.

### Anti-Pattern 3: Hardcoding Developer ID in build scripts
**What:** Putting the actual Apple Developer ID certificate name in `build_and_run.sh` or `entitlements.plist`.
**Why wrong:** The app is open source; Developer ID is personal/team credential. Committing it leaks identity and blocks contributors from building.
**Instead:** Use environment variables (`CODE_SIGN_IDENTITY`, `APPLE_ID`, `TEAM_ID`, `APP_SPECIFIC_PASSWORD`) with placeholder documentation. `script/sign.sh` reads from environment, fails with clear message if unset.

### Anti-Pattern 4: Using @AppStorage directly in views for shared preferences
**What:** `@AppStorage("sidebarGroupingMode")` in `ContentView` AND `SettingsView` independently, each with its own default.
**Why wrong:** Duplicated key strings and defaults create inconsistency; harder to change keys later; no centralized validation.
**Instead:** `PreferencesStore` is the single source of truth. Views bind to `@Published` properties. `PreferencesStore.init()` handles defaults and migration.

## Scalability Considerations

This is a local macOS app with a single user. Scaling concerns are about code complexity, not load:

| Concern | Current (v1.1) | v1.2 Target | Notes |
|---------|---------------|-------------|-------|
| Preferences count | 0 persisted keys | ~5-8 keys | Trivial for UserDefaults |
| Grouping modes | 5 modes | 7 modes | `groupDefinitions` switch grows linearly |
| Keyboard shortcuts | 2 shortcuts | ~15 shortcuts | CommandMenu entries scale well |
| Build pipeline complexity | 1 script (build_and_run) | 4 scripts (+sign/notarize/package) | Each script is independent, ~30-50 lines |
| State objects in App | 1 (@StateObject store) | 2 (+preferences) | Minimal overhead |

**What breaks first at scale:** Nothing — this is a single-user local app. The primary concern is code maintainability as `JobPresentation.swift` grows with new grouping logic. If it exceeds ~700 lines, split grouping enums/logic into `Grouping/` subdirectory in `AutomationHealthCore`.

## Sources

- **HIGH confidence:** Direct file reads of all Swift source files in `/Users/niko/Documents/AutomationHealth/Sources/`
- **HIGH confidence:** Apple SwiftUI documentation via Context7 (`/websites/developer_apple_swiftui`) — Settings scene, AppStorage, keyboardShortcut, CommandMenu
- **HIGH confidence:** `.planning/codebase/ARCHITECTURE.md` and `.planning/codebase/INTEGRATIONS.md` — verified against source
- **HIGH confidence:** `.planning/PROJECT.md` — verified requirements against current source state
- **MEDIUM confidence:** notarytool and codesign details — based on training data (notarytool CLI), verified patterns from Apple's `xcrun notarytool` documentation; no Context7 library for notarytool exists

---

*Architecture research for: Automation Health v1.2 — Preferences, Polish, and Shippable Distribution*
*Researched: 2026-05-10*
