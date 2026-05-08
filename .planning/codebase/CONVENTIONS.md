# Coding Conventions

**Analysis Date:** 2026-05-08

## Naming Patterns

**Files:**
- Use one primary Swift type per file and name the file after that type, as in `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, and `Sources/AutomationHealth/Stores/JobStore.swift`.
- Use SwiftPM target directories in PascalCase under `Sources/`, including `Sources/ActiveJobsCore`, `Sources/AutomationHealth`, and `Sources/ActiveJobsCoreSelfTest`.
- Use descriptive SwiftUI view filenames ending in `View.swift`, such as `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`, and `Sources/AutomationHealth/Views/DetailView.swift`.
- Use snake_case for repository scripts, as in `script/build_and_run.sh`, `script/test.sh`, and `script/ci.sh`.

**Functions:**
- Use lowerCamelCase with verb phrases for behavior, such as `scan()` in `Sources/ActiveJobsCore/Services/JobScanning.swift`, `refresh()` in `Sources/AutomationHealth/Stores/JobStore.swift`, and `scheduleDescription(_:)` in `Sources/ActiveJobsCore/Support/JobHumanizer.swift`.
- Use explicit helper names that include domain nouns, such as `latestOutput(for:)` in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift` and `calendarDescription(_:)` in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.
- Use `test...` names for executable self-test functions in `Sources/ActiveJobsCoreSelfTest/main.swift`, such as `testParsesEnabledHermesCronJobsWithLatestOutput()` and `testHealthSummaries()`.

**Variables:**
- Use lowerCamelCase for local values and properties, as in `homeDirectory`, `launchAgentDirectories`, and `fileManager` in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.
- Use boolean names that read as state, such as `isScanning` in `Sources/AutomationHealth/Stores/JobStore.swift` and `isSelected` in `Sources/AutomationHealth/Views/SidebarView.swift`.
- Use immutable `let` properties by default for model and presentation data in `Sources/ActiveJobsCore/Models/ScheduledJob.swift` and `Sources/AutomationHealth/Models/JobPresentation.swift`.

**Types:**
- Use PascalCase for types and protocols, such as `ScheduledJob`, `JobSource`, `JobScanning`, `JobInventory`, `JobPresentation`, and `SidebarJobSummary` in `Sources/ActiveJobsCore` and `Sources/AutomationHealth`.
- Use `Kind` suffixes for enum classifications, as in `JobHealthKind` in `Sources/ActiveJobsCore/Support/JobHumanizer.swift`.
- Keep nested or file-private support types private when they serve one implementation, such as `HermesJobsFile` and `HermesJob` in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, and `LaunchctlStatusReader` in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.

## Code Style

**Formatting:**
- Use `.editorconfig` as the repository formatting source: UTF-8, LF endings, final newline, trimmed trailing whitespace, 4-space indentation for `*.swift`, 2-space indentation for Markdown/YAML/JSON/TOML, and tabs for `Makefile`.
- Follow the explicit style guidance in `CONTRIBUTING.md`: 4-space indentation, descriptive names, small focused types, dependency injection for paths and scanners, and `ActiveJobsCore` independent from SwiftUI.
- Keep Swift argument lists multiline when they carry several labeled parameters, as in `ScheduledJob(...)` initializers in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift` and `Sources/ActiveJobsCoreSelfTest/main.swift`.

**Linting:**
- Not detected: no `.swiftlint.yml`, `.swift-format`, `.swiftformat`, or dedicated lint target exists in the repository root.
- Use `swift build` through `script/ci.sh` as the compile-time quality gate for Swift syntax and type checking.
- Use `CONTRIBUTING.md` and `.editorconfig` as the active convention sources when adding code.

**Project Skills:**
- Not detected: no project-local `.codex/skills/*/SKILL.md` or `.agents/skills/*/SKILL.md` files exist. Use repository docs such as `CONTRIBUTING.md` and `docs/development.md` for local conventions.

## Import Organization

**Order:**
1. System frameworks first, such as `Foundation` in `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Combine` and `Foundation` in `Sources/AutomationHealth/Stores/JobStore.swift`, and `AppKit` plus `SwiftUI` in `Sources/AutomationHealth/App/AutomationHealthApp.swift`.
2. Project modules after system frameworks, using `import ActiveJobsCore` in `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Views/DetailView.swift`, and `Sources/ActiveJobsCoreSelfTest/main.swift`.
3. Keep imports contiguous without blank separator groups, matching `Sources/AutomationHealth/Stores/JobStore.swift` and `Sources/AutomationHealth/Views/DetailView.swift`.

**Path Aliases:**
- Not applicable: SwiftPM module imports are used instead of path aliases. The app target imports `ActiveJobsCore` from `Package.swift`, and source files import it directly via `import ActiveJobsCore`.

## Error Handling

**Patterns:**
- Use `throws` for scanner and inventory operations that should fail the caller on unreadable or malformed required data, as in `JobScanning.scan()` and `JobInventory.refresh()` in `Sources/ActiveJobsCore/Services/JobScanning.swift`.
- Return an empty array for absent optional data sources, as in missing LaunchAgent directories in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` and missing Hermes metadata in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`.
- Use `try?` plus `nil` for optional enrichment that should not fail the whole scan, including plist parsing in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, output lookup in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, and text snippet reads in `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`.
- Surface UI refresh failures through `Result` and `error.localizedDescription` in `Sources/AutomationHealth/Stores/JobStore.swift`; keep the SwiftUI views read-only and driven by `errorMessage`.
- Reserve `fatalError` for self-test assertion helpers in `Sources/ActiveJobsCoreSelfTest/main.swift`; production source under `Sources/ActiveJobsCore` and `Sources/AutomationHealth` does not use `fatalError`.

## Logging

**Framework:** console and macOS system tools

**Patterns:**
- Production Swift source does not define a `Logger` or `os_log` wrapper in `Sources/ActiveJobsCore` or `Sources/AutomationHealth`.
- Use `print` only for the self-test success marker in `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Use `script/build_and_run.sh --logs` or `script/build_and_run.sh --telemetry` for local process log streaming through `/usr/bin/log`.

## Comments

**When to Comment:**
- Keep comments rare; source files in `Sources/ActiveJobsCore` and `Sources/AutomationHealth` primarily rely on descriptive names and focused helper functions.
- Use comments only when a rule is not clear from the code structure. Current Swift source has no inline comments apart from the Swift tools version in `Package.swift`.

**JSDoc/TSDoc:**
- Not applicable for this Swift project.
- Swift doc comments are not used in current source files under `Sources/ActiveJobsCore` or `Sources/AutomationHealth`.

## Function Design

**Size:** Use small helpers for parsing, formatting, and UI subviews. Follow `LaunchAgentScanner` helpers in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, formatter helpers in `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, and private SwiftUI subviews in `Sources/AutomationHealth/Views/DetailView.swift`.

**Parameters:** Prefer dependency injection with live defaults for filesystem paths, scanners, and file managers, as in `LaunchAgentScanner.init(...)`, `HermesCronScanner.init(...)`, `JobInventory.live(homeDirectory:)`, and `JobStore.init(inventory:)`.

**Return Values:** Return immutable value models (`ScheduledJob`, `JobPresentation`, `JobHealth`) and optionals for unavailable data. Use arrays for scan results and `nil` for absent optional detail in `Sources/ActiveJobsCore/Services` and `Sources/ActiveJobsCore/Support`.

## Module Design

**Exports:** Export only reusable scanner-layer APIs from `Sources/ActiveJobsCore` with `public`. Keep app-only models, stores, and views internal in `Sources/AutomationHealth`. Keep implementation-only helpers `private` within the file that owns them.

**Barrel Files:** Not detected. There are no barrel files; SwiftPM module boundaries in `Package.swift` define `ActiveJobsCore`, `AutomationHealth`, and `ActiveJobsCoreSelfTest`.

---

*Convention analysis: 2026-05-08*
