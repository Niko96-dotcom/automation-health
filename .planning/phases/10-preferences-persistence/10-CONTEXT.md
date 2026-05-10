# Phase 10: Preferences Persistence - Context

**Gathered:** 2026-05-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Persist sidebar grouping mode, collapse state, and candidate scan configuration across app launches using `@AppStorage`/`UserDefaults`. Add a native macOS Settings scene (Cmd+,) exposing scannable configuration fields. Add an MIT LICENSE file to the repository root.

**In scope:**
- `PreferencesStore` (@MainActor ObservableObject) bridging UserDefaults to published properties
- Grouping mode persisted via `@AppStorage` (String-raw-representable SidebarGroupingMode)
- Collapse state persisted via UserDefaults (JSON-encoded SidebarCollapseState codable)
- Candidate scan configuration persisted via UserDefaults (depth, results cap, scan-on-launch toggle)
- Settings scene (Cmd+,) exposing default grouping mode and scan config knobs
- MIT LICENSE file at repository root

**Out of scope:**
- Keyboard shortcuts (Phase 11)
- Schedule-based grouping or new grouping modes (Phase 12)
- Code signing, notarization, DMG packaging (Phase 13)
- Drag-to-reorder custom grouping
- Cloud sync, telemetry, accounts
</domain>

<decisions>
## Implementation Decisions

### Preferences Store Architecture
- **D-01:** Use a separate `PreferencesStore` (@MainActor ObservableObject) — not merged into JobStore. JobStore stays focused on scanner state, selection, and manual record CRUD. Two @StateObjects in AutomationHealthApp.
- **D-02:** `PreferencesStore` owns `@Published groupingMode: SidebarGroupingMode`, `@Published collapseState: SidebarCollapseState`, `@Published scanOnLaunch: Bool`, `@Published scanMaxDepth: Int`, `@Published scanMaxResults: Int`. Each writes to UserDefaults on change. Reads defaults on init.

### Scan Configuration Knobs
- **D-03:** Settings exposes three knobs: maxDepth (slider 0–5, default 2), maxResults (slider 10–500, default 200), "Scan candidate scripts on launch" toggle (default: on). Script extensions and ignored directories stay at compile-time defaults from `CandidateScriptScanner.Configuration.default`.
- **D-04:** Scan config values feed into `CandidateScriptScanner` via its `Configuration` struct at inventory construction time — not through global mutable state.

### Settings Scene Scope
- **D-05:** Settings scene (Cmd+,) exposes: default grouping mode picker, candidate scan knobs (depth slider, results slider, on/off toggle). No keyboard shortcut reference table.

### LICENSE
- **D-06:** MIT license in repository root. Copyright line: `Copyright (c) 2026 Niko`.

### Agent's Discretion
- Collapse state serialization: JSON-encode `Set<SidebarSectionID>` to `Data` for UserDefaults. Requires adding `Codable` conformance to `SidebarSectionID` and `SidebarCollapseState`.
- PreferencesStore UserDefaults key naming (e.g., `"sidebarGroupingMode"`, `"sidebarCollapseState"`, `"scanOnLaunch"`, `"scanMaxDepth"`, `"scanMaxResults"`).
- Settings view layout — standard SwiftUI Form with grouped sections, `Picker` for grouping mode, `Slider` for depth/results, `Toggle` for scan-on-launch.
- `PreferencesStore` should use `UserDefaults.standard.register(defaults:)` for initial defaults on first launch.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Research & Architecture
- `.planning/research/STACK.md` — Technology stack for preferences (@AppStorage, UserDefaults, Settings scene), pattern guidance, what to avoid
- `.planning/research/ARCHITECTURE.md` — Complete proposed architecture with component diagram, data flow, integration points, build order, and refactors required
- `.planning/REQUIREMENTS.md` — Requirements PREFS-01 through PREFS-05 and DIST-01 with acceptance criteria

### Source Code
- `Sources/AutomationHealthCore/JobPresentation.swift` — SidebarGroupingMode enum (5 modes, RawRepresentable String), SidebarCollapseState (needs Codable), SidebarSectionID (needs Codable), SidebarJobSection.sections(for:groupingMode:collapseState:hasSearchQuery:) — the code that must be re-wired from @State to persisted store
- `Sources/ActiveJobsCore/Services/CandidateScriptScanner.swift` — Configuration struct with 6 parameters and `.default` static — the scan config that needs persistence
- `Sources/AutomationHealth/App/AutomationHealthApp.swift` — App entry point where PreferencesStore must be created as @StateObject and Settings scene added
- `Sources/AutomationHealth/Stores/JobStore.swift` — @MainActor ObservableObject pattern to follow for PreferencesStore
- `Sources/AutomationHealth/Views/ContentView.swift` — Lines 8-9 hold the @State groupingMode and collapseState that must be migrated to PreferencesStore
- `Package.swift` — Target declarations; AutomationHealthCore already exists as a library product
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SidebarGroupingMode`: `RawRepresentable` as `String` — directly `@AppStorage`-compatible. Add `@AppStorage("sidebarGroupingMode") var groupingMode = "source"`.
- `SidebarCollapseState`: Stores `Set<SidebarSectionID>`. Both need `Codable` conformance. Encode to `Data` via `JSONEncoder` for UserDefaults storage.
- `CandidateScriptScanner.Configuration`: Has static `.default` with all 6 fields. New PreferencesStore values (depth, results) are used to construct a Configuration at scan time.
- `SidebarJobSection.sections(for:groupingMode:collapseState:hasSearchQuery:)`: Already accepts groupingMode and collapseState as parameters — no change to its signature, only the source of those values changes from @State to @ObservedObject.

### Established Patterns
- `JobStore` as `@MainActor final class: ObservableObject` with `@Published` properties, explicit `init()`, and no SwiftUI imports — PreferencesStore follows the same pattern.
- `AutomationHealthApp` owns store as `@StateObject`, passes it to `ContentView` — add `@StateObject private var preferences = PreferencesStore()` and pass alongside `store`.
- Dependency injection in init: `JobStore.init(inventory:manualRecordStore:)` — `PreferencesStore` can accept `UserDefaults` for testability.
- No third-party dependencies in Package.swift — use only Foundation/SwiftUI.

### Integration Points
- `ContentView` lines 8-9: Replace `@State private var sidebarGroupingMode` and `@State private var sidebarCollapseState` with `@ObservedObject var preferences: PreferencesStore`. Bindings `$preferences.groupingMode` and `$preferences.collapseState` pass unchanged to SidebarView.
- `AutomationHealthApp`: Add `@StateObject private var preferences = PreferencesStore()`, add `Settings { SettingsView(preferences: preferences) }` as sibling scene to WindowGroup, pass `preferences` to `ContentView`.
- `CandidateScriptScanner` initialization in `JobInventory.live()`: Accept a `Configuration` parameter from PreferencesStore values.
</code_context>

<specifics>
## Specific Ideas

No specific visual or UX references provided — Settings scene uses standard macOS SwiftUI `Settings` scene with `Form` and `.formStyle(.grouped)`.

Collapse state persistence should be per-grouping-mode (i.e., collapse state is tied to `SidebarSectionID` which already includes `groupingMode`). When the user switches grouping modes, the collapse state for the previous mode is preserved and the collapse state for the new mode is restored.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.
</deferred>

---

*Phase: 10-preferences-persistence*
*Context gathered: 2026-05-10*
