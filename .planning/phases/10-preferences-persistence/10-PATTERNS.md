# Phase 10: Preferences Persistence - Pattern Map

**Mapped:** 2026-05-11
**Files analyzed:** 8 (3 NEW, 5 MODIFIED)
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Sources/AutomationHealth/Stores/PreferencesStore.swift` | store | CRUD | `Sources/AutomationHealth/Stores/JobStore.swift` | exact |
| `Sources/AutomationHealth/Views/SettingsView.swift` | view | request-response | `Sources/AutomationHealth/Views/ContentView.swift` (ManualRecordSheetView, lines 166-260) | role-match |
| `Sources/AutomationHealthCore/JobPresentation.swift` | model | N/A (add Codable) | `Sources/AutomationHealthCore/JobPresentation.swift` (itself, lines 114-201) | exact |
| `Sources/AutomationHealth/App/AutomationHealthApp.swift` | controller | request-response | `Sources/AutomationHealth/App/AutomationHealthApp.swift` (itself, lines 12-34) | exact |
| `Sources/AutomationHealth/Views/ContentView.swift` | view | request-response | `Sources/AutomationHealth/Views/ContentView.swift` (itself, lines 5-111) | exact |
| `Sources/AutomationHealth/Stores/JobStore.swift` | store | CRUD | `Sources/AutomationHealth/Stores/JobStore.swift` (itself, lines 23-28) | exact |
| `Sources/ActiveJobsCore/Services/JobScanning.swift` | service | CRUD | `Sources/ActiveJobsCore/Services/JobScanning.swift` (itself, lines 24-42) | exact |
| `LICENSE` | config | N/A | `LICENSE` (itself, line 3) | exact |

## Pattern Assignments

### `Sources/AutomationHealth/Stores/PreferencesStore.swift` (store, CRUD)

**Analog:** `Sources/AutomationHealth/Stores/JobStore.swift`

**Imports pattern** (lines 1-4):
```swift
import Combine
import Foundation
import ActiveJobsCore
import AutomationHealthCore
```

**Class declaration pattern** (line 6-7):
```swift
@MainActor
final class PreferencesStore: ObservableObject {
```
*Copy from JobStore.swift line 6-7 — same `@MainActor final class: ObservableObject` pattern, no SwiftUI imports needed.*

**@Published properties pattern** (lines 12-17 from JobStore):
```swift
@Published var selectedJobID: String?
@Published private(set) var errorMessage: String?
```
*For PreferencesStore, properties are `@Published` without `private(set)` (they're read-write from views via bindings). Apply `didSet` to each for UserDefaults writes:*
```swift
@Published var scanOnLaunch: Bool {
    didSet { UserDefaults.standard.set(scanOnLaunch, forKey: "scanOnLaunch") }
}
@Published var scanMaxDepth: Int {
    didSet { UserDefaults.standard.set(scanMaxDepth, forKey: "scanMaxDepth") }
}
@Published var scanMaxResults: Int {
    didSet { UserDefaults.standard.set(scanMaxResults, forKey: "scanMaxResults") }
}
```

**Dependency injection in init** (lines 23-28 from JobStore):
```swift
init(inventory: JobInventory? = nil, manualRecordStore: ManualRecordStore = .live()) {
    self.manualRecordStore = manualRecordStore
    self.inventory = inventory ?? JobInventory.live(
        homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
        manualRecordStore: manualRecordStore
    )
}
```
*For PreferencesStore, inject UserDefaults for testability:*
```swift
init(userDefaults: UserDefaults = .standard) {
    // 1. Register fallback defaults FIRST (Pitfall 1 prevention)
    userDefaults.register(defaults: [
        "sidebarGroupingMode": SidebarGroupingMode.defaultMode.rawValue,
        "scanOnLaunch": true,
        "scanMaxDepth": 2,
        "scanMaxResults": 200
    ])
    // 2. Read existing values (will use registered defaults if keys absent)
    groupingMode = SidebarGroupingMode(rawValue: userDefaults.string(forKey: "sidebarGroupingMode") ?? "") ?? .defaultMode
    // ...collapseState: decode JSON Data or SidebarCollapseState()
    // ...scanOnLaunch, scanMaxDepth, scanMaxResults: userDefaults.bool/integer
}
```

**Error handling pattern for collapse state** — use `try?` + fallback (same pattern as `try?` in LaunchAgentScanner lines 147-148):
```swift
if let collapseData = userDefaults.data(forKey: "sidebarCollapseState"),
   let decoded = try? JSONDecoder().decode(SidebarCollapseState.self, from: collapseData) {
    collapseState = decoded
} else {
    collapseState = SidebarCollapseState()
}
```

---

### `Sources/AutomationHealth/Views/SettingsView.swift` (view, request-response)

**Analog:** `Sources/AutomationHealth/Views/ContentView.swift` (ManualRecordSheetView, lines 166-260)

**Imports pattern** (lines 1-3, implicit):
```swift
import SwiftUI
import AutomationHealthCore
```

**View + @ObservedObject pattern** (line 6 from ContentView):
```swift
struct ContentView: View {
    @ObservedObject var store: JobStore
```
*Copy: SettingsView uses same `@ObservedObject` pattern, receiving `PreferencesStore`:*
```swift
struct SettingsView: View {
    @ObservedObject var preferences: PreferencesStore
```

**Form + .formStyle(.grouped) pattern** (ContentView lines 211-238):
```swift
Form {
    TextField("Name", text: $name, prompt: Text("Weekly cleanup reminder"))
    Picker("Origin", selection: $origin) {
        ForEach(JobOrigin.allCases) { origin in
            Text(origin.displayName).tag(origin)
        }
    }
}
.formStyle(.grouped)
```
*Copy for SettingsView — two sections with Picker, Toggle, and Sliders:*
```swift
var body: some View {
    Form {
        Section("Default View") {
            Picker("Default Grouping", selection: $preferences.groupingMode) {
                ForEach(SidebarGroupingMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
        }

        Section("Candidate Scanning") {
            Toggle("Scan for candidate scripts on launch", isOn: $preferences.scanOnLaunch)
            // caption Text helper ...

            Slider(value: maxDepthBinding, in: 0...5, step: 1) {
                Text("Maximum Scan Depth")
            }
            // caption Text helper ...

            Slider(value: maxResultsBinding, in: 10...500, step: 10) {
                Text("Maximum Results Per Scan")
            }
            // caption Text helper ...
        }
    }
    .formStyle(.grouped)
    .frame(width: 480)
}
```

**Int-to-Double binding wrapper** (Pitfall 3 mitigation — no direct analog in codebase, from RESEARCH.md):
```swift
private var maxDepthBinding: Binding<Double> {
    Binding(
        get: { Double(preferences.scanMaxDepth) },
        set: { preferences.scanMaxDepth = Int($0) }
    )
}

private var maxResultsBinding: Binding<Double> {
    Binding(
        get: { Double(preferences.scanMaxResults) },
        set: { preferences.scanMaxResults = Int($0) }
    )
}
```

---

### `Sources/AutomationHealthCore/JobPresentation.swift` (model, add Codable)

**Analog:** `Sources/AutomationHealthCore/JobPresentation.swift` (itself, lines 114-201)

**SidebarGroupingMode — add Codable** (line 114, current conformance):
```swift
public enum SidebarGroupingMode: String, CaseIterable, Identifiable, Sendable {
```
*Change to:*
```swift
public enum SidebarGroupingMode: String, CaseIterable, Identifiable, Sendable, Codable {
```

**SidebarSectionID — add Codable** (line 169, current conformance):
```swift
public struct SidebarSectionID: Hashable, Sendable {
```
*Change to:*
```swift
public struct SidebarSectionID: Hashable, Sendable, Codable {
```

**SidebarCollapseState — add Codable** (line 179, current conformance):
```swift
public struct SidebarCollapseState: Hashable, Sendable {
```
*Change to:*
```swift
public struct SidebarCollapseState: Hashable, Sendable, Codable {
```

**Pattern note:** `Set<SidebarSectionID>` encodes as JSON array automatically. `JSONEncoder().encode(collapseState)` serializes the entire struct. `JSONDecoder().decode(SidebarCollapseState.self, from: data)` deserializes. No custom encode/decode methods needed — all three types use `Codable` synthesis.

**Pitfall 2 prevention:** `SidebarGroupingMode` must have explicit `Codable` in its conformance list for `SidebarSectionID` Codable synthesis to work. Swift synthesizes Codable for String-backed enums automatically when `Codable` is declared.

---

### `Sources/AutomationHealth/App/AutomationHealthApp.swift` (controller, request-response)

**Analog:** `Sources/AutomationHealth/App/AutomationHealthApp.swift` (itself, lines 12-34)

**@StateObject pattern** (line 15):
```swift
@StateObject private var store = JobStore()
```
*Add second @StateObject (D-01):*
```swift
@StateObject private var preferences = PreferencesStore()
```

**Adding Settings scene** (NEW — no direct analog in existing code, but follows SwiftUI pattern)::
```swift
var body: some Scene {
    WindowGroup("Automation Health", id: "main") {
        ContentView(store: store, preferences: preferences)  // MODIFIED: pass preferences
            .frame(minWidth: 980, minHeight: 620)
            .task {
                store.refresh()
            }
    }
    .commands {
        CommandMenu("Automations") {
            Button("Rescan Automations") {
                store.refresh()
            }
            .keyboardShortcut("r", modifiers: [.command])
        }
    }

    Settings {                                              // NEW
        SettingsView(preferences: preferences)
    }
}
```

---

### `Sources/AutomationHealth/Views/ContentView.swift` (view, request-response)

**Analog:** `Sources/AutomationHealth/Views/ContentView.swift` (itself, lines 5-111)

**Current @State vars to remove** (lines 8-9):
```swift
@State private var sidebarGroupingMode: SidebarGroupingMode = .defaultMode
@State private var sidebarCollapseState = SidebarCollapseState()
```

**New @ObservedObject to add** (following line 6 pattern):
```swift
@ObservedObject var store: JobStore
@ObservedObject var preferences: PreferencesStore     // NEW
```

**Computed property change** (lines 29-36):
```swift
private var sidebarSections: [SidebarJobSection] {
    SidebarJobSection.sections(
        for: filteredJobs,
        groupingMode: preferences.groupingMode,         // was: sidebarGroupingMode
        collapseState: preferences.collapseState,       // was: sidebarCollapseState
        hasSearchQuery: hasSearchQuery
    )
}
```

**Binding source change** (lines 43-44):
```swift
groupingMode: $preferences.groupingMode,    // was: $sidebarGroupingMode
collapseState: $preferences.collapseState,  // was: $sidebarCollapseState
```

**Note:** `@ObservedObject` projections produce `Binding` for `@Published` properties automatically (same as `@State`), so `$preferences.groupingMode` works as a direct drop-in replacement for `$sidebarGroupingMode` when passing to `SidebarView`.

---

### `Sources/AutomationHealth/Stores/JobStore.swift` (store, add init parameter)

**Analog:** `Sources/AutomationHealth/Stores/JobStore.swift` (itself, lines 23-28)

**Current init** (lines 23-28):
```swift
init(inventory: JobInventory? = nil, manualRecordStore: ManualRecordStore = .live()) {
    self.manualRecordStore = manualRecordStore
    self.inventory = inventory ?? JobInventory.live(
        homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
        manualRecordStore: manualRecordStore
    )
}
```

**Change:** Add optional `candidateConfiguration` parameter and pass it through to `JobInventory.live()`:
```swift
init(
    inventory: JobInventory? = nil,
    manualRecordStore: ManualRecordStore = .live(),
    candidateConfiguration: CandidateScriptScanner.Configuration? = nil
) {
    self.manualRecordStore = manualRecordStore
    self.inventory = inventory ?? JobInventory.live(
        homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
        manualRecordStore: manualRecordStore,
        candidateConfiguration: candidateConfiguration
    )
}
```

**New import needed** (add to line 3):
```swift
import ActiveJobsCore       // already imported — CandidateScriptScanner is in ActiveJobsCore
```

---

### `Sources/ActiveJobsCore/Services/JobScanning.swift` (service, add init parameter)

**Analog:** `Sources/ActiveJobsCore/Services/JobScanning.swift` (itself, lines 24-42)

**Current live() factory** (lines 24-42):
```swift
public static func live(
    homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
    manualRecordStore: ManualRecordStore? = nil
) -> JobInventory {
    let manualRecordStore = manualRecordStore ?? ManualRecordStore.live(homeDirectory: homeDirectory)

    return JobInventory(
        scanners: [
            LaunchAgentScanner(homeDirectory: homeDirectory),
            HermesCronScanner(homeDirectory: homeDirectory),
            CronScanner(),
            ShortcutsScanner(),
            AutomatorScanner(homeDirectory: homeDirectory),
            CandidateScriptScanner(homeDirectory: homeDirectory),
            ManualRecordScanner(store: manualRecordStore)
        ],
        homeDirectory: homeDirectory
    )
}
```

**New factory overload** (add optional Configuration parameter — following D-04):
```swift
public static func live(
    homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
    manualRecordStore: ManualRecordStore? = nil,
    candidateConfiguration: CandidateScriptScanner.Configuration? = nil   // NEW
) -> JobInventory {
    let manualRecordStore = manualRecordStore ?? ManualRecordStore.live(homeDirectory: homeDirectory)
    let config = candidateConfiguration ?? .default

    return JobInventory(
        scanners: [
            LaunchAgentScanner(homeDirectory: homeDirectory),
            HermesCronScanner(homeDirectory: homeDirectory),
            CronScanner(),
            ShortcutsScanner(),
            AutomatorScanner(homeDirectory: homeDirectory),
            CandidateScriptScanner(homeDirectory: homeDirectory, configuration: config),  // MODIFIED
            ManualRecordScanner(store: manualRecordStore)
        ],
        homeDirectory: homeDirectory
    )
}
```

**Note:** Using `candidateConfiguration ?? .default` as the fallback preserves backward compatibility — existing callers that omit the parameter get the same behavior as before.

---

### `LICENSE` (config, copyright line)

**Analog:** `LICENSE` (itself, line 3)

**Current copyright line** (line 3):
```
Copyright (c) 2026 Automation Health contributors
```

**New copyright line** (per D-06):
```
Copyright (c) 2026 Niko
```

---

## Shared Patterns

### ObservableObject Store Pattern
**Source:** `Sources/AutomationHealth/Stores/JobStore.swift` (lines 6-7, 12-17, 23-28)
**Apply to:** `PreferencesStore.swift`
```swift
import Combine
import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    @Published var propertyName: PropertyType {
        didSet { UserDefaults.standard.set(value, forKey: "keyName") }
    }

    init(userDefaults: UserDefaults = .standard) {
        // 1. register(defaults:) FIRST
        // 2. read values
    }
}
```

### Error Handling — `try?` + Fallback
**Source:** `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` (pattern: `try?` with nil fallback)
**Apply to:** `PreferencesStore.swift` (collapse state JSON decode)
```swift
if let data = userDefaults.data(forKey: "sidebarCollapseState"),
   let decoded = try? JSONDecoder().decode(SidebarCollapseState.self, from: data) {
    collapseState = decoded
} else {
    collapseState = SidebarCollapseState()
}
```

### Form + Grouped Style
**Source:** `Sources/AutomationHealth/Views/ContentView.swift` (lines 211-238, ManualRecordSheetView)
**Apply to:** `SettingsView.swift`
```swift
Form {
    Section("Section Title") {
        Picker("Label", selection: $preferences.someProperty) { /* ... */ }
        Toggle("Label", isOn: $preferences.booleanProperty)
    }
}
.formStyle(.grouped)
.frame(width: 480)
```

### Dependency Injection in Init
**Source:** `Sources/AutomationHealth/Stores/JobStore.swift` (lines 23-28)
**Apply to:** `PreferencesStore.init()`, `JobStore.init()`, `JobInventory.live()`
```swift
init(parameter: Type? = nil, dependency: Dependency = .live()) {
    self.parameter = parameter ?? defaultValue
}
```

### Self-Test Function Pattern
**Source:** `Sources/ActiveJobsCoreSelfTest/main.swift` (lines 38-79)
**Apply to:** New Wave 0 tests for Phase 10
```swift
func testCollapseStateCodableRoundTrip() throws {
    // Arrange: create SidebarCollapseState with known values
    // Act: JSONEncoder().encode / JSONDecoder().decode round-trip
    // Assert: expect(decoded == original, "message")
}
```

### Passing @ObservedObject to Child Views
**Source:** `Sources/AutomationHealth/App/AutomationHealthApp.swift` (line 19) + `Sources/AutomationHealth/Views/ContentView.swift` (line 6)
**Apply to:** `AutomationHealthApp` → `ContentView` (passing `preferences`), `ContentView` → `SidebarView` (bindings)
```swift
// Parent: ContentView(store: store, preferences: preferences)
// Child: @ObservedObject var preferences: PreferencesStore
// Binding: $preferences.groupingMode  (works because @Published projects to Binding)
```

## No Analog Found

All 8 files have exact or role-level analogs in the existing codebase. No files fall into the "no analog" category for this phase.

## Metadata

**Analog search scope:** `Sources/AutomationHealth/`, `Sources/AutomationHealthCore/`, `Sources/ActiveJobsCore/`, repository root
**Files scanned:** 9 (JobStore.swift, JobPresentation.swift, AutomationHealthApp.swift, ContentView.swift, SidebarView.swift, DetailView.swift, JobScanning.swift, CandidateScriptScanner.swift, LICENSE)
**Pattern extraction date:** 2026-05-11
**Key decisions from CONTEXT.md:** D-01 through D-06 all applied
