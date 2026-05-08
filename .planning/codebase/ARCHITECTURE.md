<!-- refreshed: 2026-05-08 -->
# Architecture

**Analysis Date:** 2026-05-08

## System Overview

```text
+------------------------------------------------------------------+
|                     SwiftUI macOS App Layer                      |
|              `Sources/AutomationHealth/App`                      |
|              `Sources/AutomationHealth/Views`                    |
+-------------------------+-------------------------+--------------+
| `AutomationHealthApp`   | `ContentView`           | Detail/Side  |
| app entry and commands  | split view and search   | bar views    |
+------------+------------+-------------+-----------+--------------+
             |                          |
             v                          v
+------------------------------------------------------------------+
|                 Presentation State Layer                         |
| `Sources/AutomationHealth/Stores/JobStore.swift`                 |
| `Sources/AutomationHealth/Models/JobPresentation.swift`          |
+----------------------------+-------------------------------------+
                             |
                             v
+------------------------------------------------------------------+
|                 Core Scanner Library Layer                       |
| `Sources/ActiveJobsCore/Services`                                |
| `Sources/ActiveJobsCore/Models`                                  |
| `Sources/ActiveJobsCore/Support`                                 |
+----------------------------+-------------------------------------+
                             |
                             v
+------------------------------------------------------------------+
|       Local Scheduler Sources And Output Files                   |
| `~/Library/LaunchAgents`, `/Library/LaunchAgents`,               |
| `/Library/LaunchDaemons`, `~/.hermes/cron/jobs.json`,            |
| `~/.hermes/cron/output/<job-id>/*.md`, `/bin/launchctl`          |
+------------------------------------------------------------------+
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `AutomationHealthApp` | Own the macOS app entry point, create the shared `JobStore`, open the main window, trigger initial scan, and expose the rescan command. | `Sources/AutomationHealth/App/AutomationHealthApp.swift` |
| `ContentView` | Own the `NavigationSplitView`, sidebar search query, toolbar refresh button, and routing from store state into sidebar and detail views. | `Sources/AutomationHealth/Views/ContentView.swift` |
| `SidebarView` | Render scan summary, selectable automation rows, health dot colors, and last-scan footer state. | `Sources/AutomationHealth/Views/SidebarView.swift` |
| `DetailView` | Render the selected job's health, schedule, command, definition, output snippet, and output-file reveal action. | `Sources/AutomationHealth/Views/DetailView.swift` |
| `JobStore` | Main `@MainActor` observable state object; run scanner refresh work off the main actor, publish jobs, selection, errors, scan state, and last scan time. | `Sources/AutomationHealth/Stores/JobStore.swift` |
| `JobPresentation` | Convert `ScheduledJob` into UI-ready display fields, search text, health summaries, and sidebar row summaries. | `Sources/AutomationHealth/Models/JobPresentation.swift` |
| `ScheduledJob` | Shared normalized domain model for all supported scheduler sources. | `Sources/ActiveJobsCore/Models/ScheduledJob.swift` |
| `JobScanning` | Protocol contract for source scanners returning `[ScheduledJob]`. | `Sources/ActiveJobsCore/Services/JobScanning.swift` |
| `JobInventory` | Compose scanners, refresh them, deduplicate source/id pairs, and sort jobs by next run then name. | `Sources/ActiveJobsCore/Services/JobScanning.swift` |
| `LaunchAgentScanner` | Read launchd plist files, derive schedule and command text, tail configured output, and fetch best-effort `launchctl` state. | `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` |
| `HermesCronScanner` | Read Hermes cron metadata, filter enabled non-paused jobs, parse run dates, infer command text, and attach latest markdown output. | `Sources/ActiveJobsCore/Services/HermesCronScanner.swift` |
| `JobHumanizer` | Humanize names, schedules, relative run dates, and health summaries through `ScheduledJob` extensions. | `Sources/ActiveJobsCore/Support/JobHumanizer.swift` |
| `FlexibleDateParser` | Parse ISO8601 timestamps with and without fractional seconds. | `Sources/ActiveJobsCore/Support/DateParsing.swift` |
| `TextSnippetReader` | Read bounded UTF-8 tail snippets from output files for UI responsiveness. | `Sources/ActiveJobsCore/Support/TextSnippetReader.swift` |
| `ActiveJobsCoreSelfTest` | Executable self-test suite for scanners, aggregation, humanization, and health summaries. | `Sources/ActiveJobsCoreSelfTest/main.swift` |

## Pattern Overview

**Overall:** Layered SwiftPM package with a protocol-based scanner pipeline and SwiftUI presentation state.

**Key Characteristics:**
- `Sources/ActiveJobsCore` is the domain and IO boundary; it has no dependency on SwiftUI or app UI code.
- `Sources/AutomationHealth/Stores/JobStore.swift` is the bridge from scanner work into main-actor UI state.
- `Sources/AutomationHealth/Models/JobPresentation.swift` keeps UI formatting and search indexing separate from scanner parsing.
- `Sources/AutomationHealth/Views` consume `JobPresentation` and `JobStore`; views do not read scheduler files directly.
- `Package.swift` declares separate products for the `ActiveJobsCore` library, the `AutomationHealth` app executable, and the `ActiveJobsCoreSelfTest` executable.

## Layers

**SwiftUI App Layer:**
- Purpose: Render the macOS app, route user interactions, and expose scan commands.
- Location: `Sources/AutomationHealth/App`, `Sources/AutomationHealth/Views`
- Contains: `@main` app entry, `WindowGroup`, command menu, `NavigationSplitView`, sidebar rows, detail panels, AppKit interop for log text and file reveal.
- Depends on: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`, `ActiveJobsCore`, `SwiftUI`, `AppKit`.
- Used by: SwiftPM executable product `AutomationHealth` in `Package.swift`.

**Presentation State Layer:**
- Purpose: Hold observable UI state and adapt domain values into display values.
- Location: `Sources/AutomationHealth/Stores`, `Sources/AutomationHealth/Models`
- Contains: `JobStore`, `JobPresentation`, `SidebarJobSummary`, `AppDateFormatters`.
- Depends on: `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `Combine`, `Foundation`.
- Used by: `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/App/AutomationHealthApp.swift`.

**Core Scanner Layer:**
- Purpose: Discover local scheduled jobs and normalize source-specific records into `ScheduledJob`.
- Location: `Sources/ActiveJobsCore`
- Contains: `ScheduledJob`, `JobSource`, `JobScanning`, `JobInventory`, `LaunchAgentScanner`, `HermesCronScanner`, parsing helpers, humanizers, snippet reading.
- Depends on: `Foundation`, local filesystem paths, `PropertyListSerialization`, `JSONDecoder`, `Process` for `/bin/launchctl`.
- Used by: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`.

**Executable Self-Test Layer:**
- Purpose: Validate scanner and humanizer behavior without a SwiftPM test target.
- Location: `Sources/ActiveJobsCoreSelfTest`
- Contains: top-level test calls, temporary fixture writer, static scanner stub, fixture factory.
- Depends on: `ActiveJobsCore`, `Foundation`.
- Used by: `script/test.sh`, `script/ci.sh`, `.github/workflows/ci.yml`.

**Build And Operations Layer:**
- Purpose: Build, run, package, verify, and run CI commands.
- Location: `Package.swift`, `Makefile`, `script`, `.github/workflows/ci.yml`
- Contains: SwiftPM target declarations, local app bundle builder, self-test runner, CI gate, GitHub Actions workflow.
- Depends on: SwiftPM, macOS shell tools, GitHub Actions macOS runner.
- Used by: developers and CI.

## Data Flow

### Primary Scan And Render Path

1. App launch starts at `@main` and creates `@StateObject private var store = JobStore()` (`Sources/AutomationHealth/App/AutomationHealthApp.swift:12`, `Sources/AutomationHealth/App/AutomationHealthApp.swift:15`).
2. The main window renders `ContentView(store: store)` and triggers the first scan through `.task { store.refresh() }` (`Sources/AutomationHealth/App/AutomationHealthApp.swift:18`, `Sources/AutomationHealth/App/AutomationHealthApp.swift:21`).
3. `JobStore.refresh()` prevents overlapping scans, flips `isScanning`, and runs `inventory.refresh()` inside a detached user-initiated task (`Sources/AutomationHealth/Stores/JobStore.swift:33`, `Sources/AutomationHealth/Stores/JobStore.swift:41`).
4. `JobInventory.refresh()` calls each scanner, deduplicates by `source.rawValue:id`, and sorts by `nextRun` then localized name (`Sources/ActiveJobsCore/Services/JobScanning.swift:24`, `Sources/ActiveJobsCore/Services/JobScanning.swift:32`).
5. `LaunchAgentScanner.scan()` traverses configured launchd directories and parses `.plist` files into `ScheduledJob` (`Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift:22`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift:65`).
6. `HermesCronScanner.scan()` reads `~/.hermes/cron/jobs.json`, filters enabled jobs, attaches latest markdown output, and returns `ScheduledJob` values (`Sources/ActiveJobsCore/Services/HermesCronScanner.swift:15`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift:24`).
7. `JobStore` maps each `ScheduledJob` into `JobPresentation`, publishes `jobs`, clears `errorMessage`, updates `lastScannedAt`, and preserves or resets selection (`Sources/AutomationHealth/Stores/JobStore.swift:45`, `Sources/AutomationHealth/Stores/JobStore.swift:51`).
8. `ContentView` filters `store.jobs` by `searchText`, passes row summaries to `SidebarView`, and passes `store.selectedJob` to `DetailView` (`Sources/AutomationHealth/Views/ContentView.swift:8`, `Sources/AutomationHealth/Views/ContentView.swift:22`).

### Manual Rescan Flow

1. The app command menu button calls `store.refresh()` for `Command-r` rescans (`Sources/AutomationHealth/App/AutomationHealthApp.swift:25`, `Sources/AutomationHealth/App/AutomationHealthApp.swift:27`).
2. The toolbar refresh button in `ContentView` also calls `store.refresh()` and disables while `store.isScanning` is true (`Sources/AutomationHealth/Views/ContentView.swift:34`, `Sources/AutomationHealth/Views/ContentView.swift:42`).
3. Both entry points use the same `JobStore.refresh()` guard and scanner pipeline (`Sources/AutomationHealth/Stores/JobStore.swift:33`, `Sources/ActiveJobsCore/Services/JobScanning.swift:24`).

### Output Detail Flow

1. `LaunchAgentScanner` reads `StandardOutPath` or `StandardErrorPath`, captures the output path, and tails readable output through `TextSnippetReader` (`Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift:57`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift:61`).
2. `HermesCronScanner` chooses the latest markdown output file from `~/.hermes/cron/output/<job-id>` and reads it through `TextSnippetReader` (`Sources/ActiveJobsCore/Services/HermesCronScanner.swift:49`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift:70`).
3. `DetailView` renders `lastRunDetails` in `ReadOnlyLogTextView` and reveals `detailPath` through `NSWorkspace.shared.activateFileViewerSelecting` (`Sources/AutomationHealth/Views/DetailView.swift:47`, `Sources/AutomationHealth/Views/DetailView.swift:299`).

**State Management:**
- `Sources/AutomationHealth/App/AutomationHealthApp.swift` owns one `@StateObject` `JobStore` for the app window.
- `Sources/AutomationHealth/Stores/JobStore.swift` publishes `jobs`, `selectedJobID`, `errorMessage`, `isScanning`, and `lastScannedAt`.
- `Sources/AutomationHealth/Views/ContentView.swift` owns local `@State private var searchText` and derives filtered rows without persisting search.
- `Sources/ActiveJobsCore` scanners are stateless value types aside from injected `homeDirectory`, directories, and `FileManager`.
- The app stores no persistent cache; every refresh reads the scheduler sources again.

## Key Abstractions

**`ScheduledJob`:**
- Purpose: Normalized automation record shared across all scanner sources.
- Examples: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`
- Pattern: Immutable `Sendable` value with source, schedule, command, state, run metadata, definition text, and output detail path.

**`JobSource`:**
- Purpose: Enumerate supported scanner sources and expose source display names.
- Examples: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/AutomationHealth/Views/DetailView.swift`
- Pattern: `RawRepresentable`, `CaseIterable`, `Identifiable`, `Sendable` enum.

**`JobScanning`:**
- Purpose: Contract for adding scheduler scanners without changing app UI flow.
- Examples: `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`
- Pattern: Protocol returning `[ScheduledJob]`; concrete scanners implement source-specific IO.

**`JobInventory`:**
- Purpose: Scanner composition root for the core layer.
- Examples: `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`
- Pattern: Value-type aggregator with `.live(homeDirectory:)` factory and injectable scanner list for tests.

**`JobPresentation`:**
- Purpose: UI adapter for display name, source name, humanized schedule/run fields, health, and search text.
- Examples: `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Views/ContentView.swift`
- Pattern: Immutable presentation model wrapping `ScheduledJob`.

**`JobHumanizer`:**
- Purpose: Source-independent display and health heuristics.
- Examples: `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`
- Pattern: Static helper namespace plus `ScheduledJob` extension.

**`TextSnippetReader`:**
- Purpose: Bound large output reads to protect detail-view responsiveness.
- Examples: `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`
- Pattern: Internal support enum with a fixed `maximumBytes` tail read.

## Entry Points

**SwiftUI App Executable:**
- Location: `Sources/AutomationHealth/App/AutomationHealthApp.swift`
- Triggers: SwiftPM executable product `AutomationHealth` from `Package.swift`; local `.app` bundle from `script/build_and_run.sh`.
- Responsibilities: Activate regular macOS app policy, create `JobStore`, create main window, start first scan, register rescan command.

**Core Library Product:**
- Location: `Sources/ActiveJobsCore`
- Triggers: SwiftPM library product `ActiveJobsCore` from `Package.swift`; imports from `Sources/AutomationHealth` and `Sources/ActiveJobsCoreSelfTest`.
- Responsibilities: Provide domain models, scanner protocols, concrete scanners, and support helpers.

**Self-Test Executable:**
- Location: `Sources/ActiveJobsCoreSelfTest/main.swift`
- Triggers: `swift run ActiveJobsCoreSelfTest` from `script/test.sh`.
- Responsibilities: Run top-level scanner, aggregation, humanization, and health checks with temporary fixtures.

**Local CI Gate:**
- Location: `script/ci.sh`
- Triggers: developer command `./script/ci.sh`, `make ci`, and `.github/workflows/ci.yml`.
- Responsibilities: Run `swift build` and `./script/test.sh` with `TZ=Europe/Berlin`.

**Local App Bundle Builder:**
- Location: `script/build_and_run.sh`
- Triggers: `make run`, `make verify`, `make debug`, `make logs`, direct script invocation.
- Responsibilities: Build SwiftPM binary, assemble `dist/AutomationHealth.app`, write `Info.plist`, launch, verify, debug, or stream logs.

## Architectural Constraints

- **Threading:** UI state is main-actor isolated in `Sources/AutomationHealth/Stores/JobStore.swift`; scanner refresh runs in `Task.detached(priority: .userInitiated)` before results are applied back to `@Published` properties.
- **Sendability:** `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` and `Sources/ActiveJobsCore/Services/HermesCronScanner.swift` conform to `JobScanning` with `@unchecked Sendable` because they hold `FileManager`.
- **Global state:** Static date formatters and helper constants live in `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/ActiveJobsCore/Support/DateParsing.swift`, `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, and `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`.
- **Circular imports:** Not detected; `Sources/ActiveJobsCore` imports only `Foundation`, while `Sources/AutomationHealth` imports `ActiveJobsCore`.
- **IO boundary:** Scheduler reads are local and read-only in `Sources/ActiveJobsCore/Services`; app views use `JobStore` and do not scan files directly.
- **Platform:** `Package.swift` targets macOS 14 through SwiftPM and uses SwiftUI/AppKit APIs in `Sources/AutomationHealth`.
- **External process use:** `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` shells out to `/bin/launchctl` through `Process` for best-effort runtime state.
- **Persistence:** Not applicable; no database, cache, settings store, or user document persistence is detected.

## Anti-Patterns

### Scanner-Specific UI Branching

**What happens:** `Sources/AutomationHealth/Views/DetailView.swift` branches on `job.job.source == .hermesCron` for the header icon.
**Why it's wrong:** Expanding source-specific branching in views duplicates source knowledge that belongs in `Sources/ActiveJobsCore/Models/ScheduledJob.swift` or `Sources/AutomationHealth/Models/JobPresentation.swift`.
**Do this instead:** Add source display attributes to `JobSource` in `Sources/ActiveJobsCore/Models/ScheduledJob.swift` or to `JobPresentation` in `Sources/AutomationHealth/Models/JobPresentation.swift`, then keep views source-agnostic.

### Direct Scanner Calls From Views

**What happens:** App views route refreshes through `JobStore`; direct scanner calls are limited to the self-test executable in `Sources/ActiveJobsCoreSelfTest/main.swift`.
**Why it's wrong:** Calling `LaunchAgentScanner` or `HermesCronScanner` from `Sources/AutomationHealth/Views` would move filesystem IO onto UI components and bypass `isScanning`, error, and selection behavior in `Sources/AutomationHealth/Stores/JobStore.swift`.
**Do this instead:** Add scanner work behind `JobScanning` in `Sources/ActiveJobsCore/Services`, compose it in `JobInventory.live()` in `Sources/ActiveJobsCore/Services/JobScanning.swift`, and let `JobStore.refresh()` publish results.

## Error Handling

**Strategy:** Scanner methods throw for source-level read/decode failures, skip malformed optional records where appropriate, and convert app-level failures into a published error string.

**Patterns:**
- Missing launchd directories return an empty array in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.
- Unreadable or malformed plist files return `nil` from `parsePlist` in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.
- Missing Hermes metadata returns an empty array in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`; unreadable or invalid JSON throws through `JSONDecoder`.
- `launchctl` process failures return `nil` status values in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.
- `JobStore.refresh()` wraps scanner work in `Result` and publishes `errorMessage` on failure in `Sources/AutomationHealth/Stores/JobStore.swift`.
- `DetailView` displays `errorMessage` through `ContentUnavailableView` when no job is selected in `Sources/AutomationHealth/Views/DetailView.swift`.

## Cross-Cutting Concerns

**Logging:** Runtime logging is not detected in source files; `script/build_and_run.sh` can stream process logs or subsystem logs for the app bundle.
**Validation:** Source validation is performed through typed `Decodable` models in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, plist key checks in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, and ISO8601 parsing in `Sources/ActiveJobsCore/Support/DateParsing.swift`.
**Authentication:** Not applicable; the app reads local files available to the current macOS user and does not authenticate with external services.
**Permissions:** Filesystem access is best effort; unreadable launchd files, Hermes metadata, and output files are skipped or surfaced through scanner errors in `Sources/ActiveJobsCore/Services`.
**Accessibility:** Detail output caps accessibility text length in `Sources/AutomationHealth/Views/DetailView.swift`; health dots expose help text in `Sources/AutomationHealth/Views/SidebarView.swift`.

---

*Architecture analysis: 2026-05-08*
