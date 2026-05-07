# Architecture

Automation Health is organized as a small SwiftPM package with three main layers.

## Core Scanner Layer

Location: `Sources/ActiveJobsCore`

`ActiveJobsCore` owns the source scanners, shared domain model, and normalization logic.

- `ScheduledJob` is the common model returned by every scanner.
- `JobSource` identifies where a job came from.
- `JobScanning` is the protocol implemented by each scanner.
- `JobInventory.live()` composes the live scanner list and returns sorted, de-duplicated jobs.
- `LaunchAgentScanner` reads launchd plist files and asks `launchctl` for runtime state when available.
- `HermesCronScanner` reads Hermes cron metadata and latest markdown output.
- Support helpers humanize schedules, parse flexible dates, and read short text snippets from output files.

This layer is read-only and has no dependency on SwiftUI.

## Presentation Layer

Location: `Sources/AutomationHealth/Models` and `Sources/AutomationHealth/Stores`

The presentation layer adapts scanner data for the UI.

- `JobStore` is the main observable state object. It refreshes jobs on a detached task, publishes scan state, remembers the selected job, and stores scan errors.
- `JobPresentation` wraps `ScheduledJob` with display-ready fields such as source names, human schedule text, relative run text, health summaries, and search text.

This layer keeps formatting and selection behavior out of the scanner layer.

## SwiftUI App Layer

Location: `Sources/AutomationHealth/App` and `Sources/AutomationHealth/Views`

The SwiftUI layer renders the app shell and user interactions.

- `AutomationHealthApp` configures the macOS app, main window, and rescan command.
- `ContentView` owns the split-view layout, search field, and toolbar refresh action.
- `SidebarView` lists discovered automations and scan summary state.
- `DetailView` renders the selected job's health, schedule, source, technical details, configured task text, and latest output.

The app layer calls into `JobStore`; it does not scan files directly.
