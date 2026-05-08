# Codebase Structure

**Analysis Date:** 2026-05-08

## Directory Layout

```text
AutomationHealth/
├── Package.swift                         # SwiftPM manifest for library and executable products
├── Makefile                              # Developer aliases for build, test, CI, run, verify, debug, logs, clean
├── README.md                             # Product overview, supported sources, build commands, limitations
├── CONTRIBUTING.md                       # Contribution workflow and PR guidance
├── Sources/
│   ├── ActiveJobsCore/
│   │   ├── Models/                       # Shared domain models
│   │   ├── Services/                     # Scanner protocol, inventory, concrete source scanners
│   │   └── Support/                      # Date parsing, humanization, bounded output reading
│   ├── AutomationHealth/
│   │   ├── App/                          # SwiftUI app entry point and app delegate
│   │   ├── Models/                       # UI presentation models
│   │   ├── Stores/                       # Observable application state
│   │   └── Views/                        # SwiftUI and AppKit-backed views
│   └── ActiveJobsCoreSelfTest/           # Executable self-test target
├── Tests/
│   └── ActiveJobsCoreTests/              # Empty SwiftPM test directory placeholder
├── docs/                                 # Architecture, development, and supported-source docs
├── script/                               # Build, test, CI, and local app bundle scripts
├── .github/                              # GitHub Actions and contribution templates
├── .codex/                               # Codex environment configuration
├── .planning/codebase/                   # GSD codebase mapping documents
├── .build/                               # Generated SwiftPM build output
└── dist/                                 # Generated local `.app` bundle output
```

## Directory Purposes

**`Sources/ActiveJobsCore`:**
- Purpose: Domain and scanner library for scheduled automation discovery.
- Contains: `ScheduledJob`, `JobSource`, `JobScanning`, `JobInventory`, concrete scanners, support helpers.
- Key files: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`

**`Sources/ActiveJobsCore/Models`:**
- Purpose: Shared domain models that all scanners return and the app consumes.
- Contains: Swift value types and enums.
- Key files: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`

**`Sources/ActiveJobsCore/Services`:**
- Purpose: Scanner contracts, scanner composition, and source-specific filesystem/process IO.
- Contains: `JobScanning`, `JobInventory`, `LaunchAgentScanner`, `HermesCronScanner`.
- Key files: `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`

**`Sources/ActiveJobsCore/Support`:**
- Purpose: Internal helpers shared by core scanners and domain extensions.
- Contains: Date parsing, display humanization, health heuristics, bounded text snippet reading.
- Key files: `Sources/ActiveJobsCore/Support/DateParsing.swift`, `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`

**`Sources/AutomationHealth`:**
- Purpose: SwiftUI app target that depends on `ActiveJobsCore`.
- Contains: App entry point, presentation models, observable store, and UI views.
- Key files: `Sources/AutomationHealth/App/AutomationHealthApp.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Views/ContentView.swift`

**`Sources/AutomationHealth/App`:**
- Purpose: App lifecycle and macOS window/command configuration.
- Contains: `AppDelegate`, `AutomationHealthApp`.
- Key files: `Sources/AutomationHealth/App/AutomationHealthApp.swift`

**`Sources/AutomationHealth/Models`:**
- Purpose: UI-facing wrappers around core models.
- Contains: `JobPresentation`, `SidebarJobSummary`.
- Key files: `Sources/AutomationHealth/Models/JobPresentation.swift`

**`Sources/AutomationHealth/Stores`:**
- Purpose: Observable state and refresh orchestration for the app.
- Contains: `JobStore`, `AppDateFormatters`.
- Key files: `Sources/AutomationHealth/Stores/JobStore.swift`

**`Sources/AutomationHealth/Views`:**
- Purpose: SwiftUI view hierarchy and AppKit interop for read-only log text and Finder reveal.
- Contains: `ContentView`, `SidebarView`, `DetailView`, private view components, shared `HealthDot`.
- Key files: `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`, `Sources/AutomationHealth/Views/DetailView.swift`

**`Sources/ActiveJobsCoreSelfTest`:**
- Purpose: Executable smoke/unit test suite for the core library.
- Contains: top-level test calls, temporary filesystem fixtures, static scanner stub, `ScheduledJob` fixtures.
- Key files: `Sources/ActiveJobsCoreSelfTest/main.swift`

**`Tests/ActiveJobsCoreTests`:**
- Purpose: Reserved directory for a conventional SwiftPM test target.
- Contains: No test files detected.
- Key files: Not detected

**`docs`:**
- Purpose: Human-readable product and engineering documentation.
- Contains: Architecture overview, development workflow, supported scheduler-source details.
- Key files: `docs/architecture.md`, `docs/development.md`, `docs/scheduled-job-sources.md`

**`script`:**
- Purpose: Shell workflows for local development and CI.
- Contains: App bundle builder, self-test runner, CI gate.
- Key files: `script/build_and_run.sh`, `script/test.sh`, `script/ci.sh`

**`.github`:**
- Purpose: GitHub workflow and repository templates.
- Contains: CI workflow, issue templates, PR template, Dependabot config.
- Key files: `.github/workflows/ci.yml`, `.github/pull_request_template.md`, `.github/dependabot.yml`

**`.planning/codebase`:**
- Purpose: Generated GSD codebase mapping documents for planning and execution agents.
- Contains: Architecture and structure maps for this focus pass.
- Key files: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`

## Key File Locations

**Entry Points:**
- `Sources/AutomationHealth/App/AutomationHealthApp.swift`: SwiftUI `@main` app entry, app delegate, shared `JobStore`, main window, initial scan, rescan command.
- `Sources/ActiveJobsCoreSelfTest/main.swift`: Executable self-test entry run by `swift run ActiveJobsCoreSelfTest`.
- `Package.swift`: SwiftPM package manifest declaring `ActiveJobsCore`, `AutomationHealth`, and `ActiveJobsCoreSelfTest`.
- `script/ci.sh`: Local and CI gate entry point.
- `script/build_and_run.sh`: Local `.app` bundle builder and launcher.

**Configuration:**
- `Package.swift`: Swift tools version, macOS platform, products, targets, and target dependencies.
- `.editorconfig`: Editor formatting rules for Swift, Markdown, YAML, JSON, TOML, and Makefile files.
- `.gitignore`: Ignores SwiftPM build output, local app bundles, logs, temporary files, environment files, and editor state.
- `.github/workflows/ci.yml`: GitHub Actions macOS build-and-test workflow.
- `.codex/environments/environment.toml`: Codex environment configuration.

**Core Logic:**
- `Sources/ActiveJobsCore/Models/ScheduledJob.swift`: Normalized scheduled-job model and source enum.
- `Sources/ActiveJobsCore/Services/JobScanning.swift`: Scanner protocol and inventory aggregator.
- `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`: launchd plist scanner and `launchctl` status reader.
- `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`: Hermes cron metadata and output scanner.
- `Sources/ActiveJobsCore/Support/JobHumanizer.swift`: Display names, schedule text, relative run text, and health summaries.
- `Sources/ActiveJobsCore/Support/DateParsing.swift`: ISO8601 date parsing and short date formatting.
- `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`: Bounded log/output tail reader.

**Presentation And UI:**
- `Sources/AutomationHealth/Stores/JobStore.swift`: Main app state and scan orchestration.
- `Sources/AutomationHealth/Models/JobPresentation.swift`: UI-facing computed data and search index.
- `Sources/AutomationHealth/Views/ContentView.swift`: Split-view shell, search, toolbar refresh.
- `Sources/AutomationHealth/Views/SidebarView.swift`: Job list, status summary, health dot.
- `Sources/AutomationHealth/Views/DetailView.swift`: Detail sections, status cards, read-only log view, Finder reveal.

**Testing:**
- `Sources/ActiveJobsCoreSelfTest/main.swift`: Scanner, aggregator, humanizer, and health self-tests.
- `script/test.sh`: Runs the self-test executable with `TZ=Europe/Berlin`.
- `script/ci.sh`: Runs `swift build` and `./script/test.sh`.
- `Tests/ActiveJobsCoreTests`: Empty conventional test directory.

**Documentation:**
- `README.md`: User-facing overview, scan sources, build/run commands, products, limitations.
- `docs/architecture.md`: Concise architecture summary.
- `docs/development.md`: Developer commands, package layout, PR checklist, notes.
- `docs/scheduled-job-sources.md`: Source-specific scanner behavior and limitations.
- `CONTRIBUTING.md`: Contribution workflow.

## Naming Conventions

**Files:**
- Swift files use UpperCamelCase matching the primary type: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Support/JobHumanizer.swift`.
- Swift executable entry files may use lowercase `main.swift`: `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Shell scripts use lower_snake_case action names: `script/build_and_run.sh`, `script/test.sh`, `script/ci.sh`.
- Documentation files use lowercase kebab-case or standard root names: `docs/scheduled-job-sources.md`, `docs/development.md`, `README.md`, `CONTRIBUTING.md`.

**Directories:**
- SwiftPM target directories use product/target UpperCamelCase: `Sources/ActiveJobsCore`, `Sources/AutomationHealth`, `Sources/ActiveJobsCoreSelfTest`.
- Within app and library targets, subdirectories use plural category names: `Models`, `Services`, `Support`, `Stores`, `Views`.
- Operational directories use lowercase names: `docs`, `script`.
- Generated planning docs use uppercase Markdown filenames: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`.

## Where to Add New Code

**New Scheduler Source:**
- Primary code: `Sources/ActiveJobsCore/Services/<SourceName>Scanner.swift`
- Source enum update: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`
- Composition update: `Sources/ActiveJobsCore/Services/JobScanning.swift`
- Tests: `Sources/ActiveJobsCoreSelfTest/main.swift`
- Documentation: `docs/scheduled-job-sources.md`

**New Core Model Field:**
- Primary code: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`
- Scanner population: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, or the relevant new scanner.
- Presentation adaptation: `Sources/AutomationHealth/Models/JobPresentation.swift`
- Detail display: `Sources/AutomationHealth/Views/DetailView.swift`
- Tests: `Sources/ActiveJobsCoreSelfTest/main.swift`

**New Presentation Formatting:**
- Primary code: `Sources/AutomationHealth/Models/JobPresentation.swift`
- Shared humanization: `Sources/ActiveJobsCore/Support/JobHumanizer.swift`
- View consumption: `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`, `Sources/AutomationHealth/Views/DetailView.swift`
- Tests: `Sources/ActiveJobsCoreSelfTest/main.swift`

**New SwiftUI View Or UI Section:**
- Implementation: `Sources/AutomationHealth/Views/<FeatureName>View.swift`
- App shell integration: `Sources/AutomationHealth/Views/ContentView.swift`
- Detail integration: `Sources/AutomationHealth/Views/DetailView.swift`
- Shared state integration: `Sources/AutomationHealth/Stores/JobStore.swift`

**New Store State Or Refresh Behavior:**
- Primary code: `Sources/AutomationHealth/Stores/JobStore.swift`
- Presentation model updates: `Sources/AutomationHealth/Models/JobPresentation.swift`
- UI bindings: `Sources/AutomationHealth/Views/ContentView.swift`

**New Shared Core Utility:**
- Shared helpers: `Sources/ActiveJobsCore/Support/<UtilityName>.swift`
- Core usage: `Sources/ActiveJobsCore/Services`
- Tests: `Sources/ActiveJobsCoreSelfTest/main.swift`

**New Developer Command:**
- Script: `script/<command_name>.sh`
- Make alias: `Makefile`
- CI integration: `script/ci.sh` or `.github/workflows/ci.yml`
- Documentation: `docs/development.md`

**New Documentation:**
- Product docs: `README.md`
- Developer docs: `docs/development.md`
- Architecture docs: `docs/architecture.md`
- Source docs: `docs/scheduled-job-sources.md`
- Planning docs: `.planning/codebase`

## Special Directories

**`.planning/codebase`:**
- Purpose: GSD-generated reference documents consumed by planning and execution workflows.
- Generated: Yes
- Committed: Yes

**`.build`:**
- Purpose: SwiftPM build output.
- Generated: Yes
- Committed: No

**`dist`:**
- Purpose: Local `AutomationHealth.app` bundle built by `script/build_and_run.sh`.
- Generated: Yes
- Committed: No

**`Tests/ActiveJobsCoreTests`:**
- Purpose: Reserved directory for conventional SwiftPM tests.
- Generated: No
- Committed: Yes

**`.codex`:**
- Purpose: Codex environment configuration for the repository.
- Generated: No
- Committed: Yes

**`.github`:**
- Purpose: GitHub workflow automation and repository contribution templates.
- Generated: No
- Committed: Yes

---

*Structure analysis: 2026-05-08*
