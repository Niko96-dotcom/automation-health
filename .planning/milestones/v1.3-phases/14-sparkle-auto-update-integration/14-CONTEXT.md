# Phase 14: Sparkle Auto-Update Integration - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Users with a running Automation Health app receive in-app update notifications and can install new versions published to GitHub Releases.

This phase integrates the Sparkle 2 auto-update framework (the project's first external dependency), adds an Updates section to the native Settings window, wires a "Check for Updates" menu item, embeds the EdDSA public key for update signature verification, and creates the key generation and appcast tooling for the release pipeline.
</domain>

<decisions>
## Implementation Decisions

### Sparkle Integration Architecture
- Sparkle 2 distributed via Swift Package Manager — consistent with existing SwiftPM-only build; Sparkle 2 has official SPM support
- Updater lifecycle owned by AutomationHealthApp — AppDelegate's `applicationDidFinishLaunching` starts the updater; App struct holds the reference
- New `UpdateStore` @StateObject — ObservableObject wrapping SPUUpdater, publishes current version string and update availability state to SwiftUI views
- EdDSA public key embedded in app bundle Resources — Sparkle standard; verified before any update installation is offered

### Update UI
- "Check for Updates" menu item placed under the existing Automations menu (or standard app-name menu) — following macOS convention
- New "Updates" Section added to existing SettingsView — consistent with current grouped Form layout, shows version label + "Check for Updates" button + auto-check toggle
- Auto-update checks use Sparkle's default interval (daily) — standard behavior, users can manually check via menu item
- Sparkle's standard update alert window — native macOS, includes release notes display, download progress, signature verification, and install-and-relaunch flow

### Signing & Release Integration
- EdDSA key pair generated via `./script/generate_sparkle_keys.sh` — uses Sparkle's `generate_keys` tool, outputs private key (stored as CI secret) and public key (embedded in app bundle)
- Sparkle appcast.xml hosted on GitHub Releases — Phase 13 already publishes DMG there; appcast references release assets
- `script/release.sh` updated to generate/update appcast entries — generates appcast.xml entry for the new release, signs the update with EdDSA private key, uploads alongside DMG asset
- `docs/release-process.md` updated with Sparkle setup — key generation, appcast configuration, and update signing steps for reproducible releases

### Claude's Discretion
- Exact SPI (Sparkle API) calls and thread-safety patterns for the UpdateStore ObservableObject
- SPUUpdater initialization parameters (host bundle, application bundle, etc.)
- SettingsView layout specifics for the Updates section within the existing Form
- Error handling for Sparkle initialization failures (e.g., missing EdDSA key)
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Sources/AutomationHealth/App/AutomationHealthApp.swift` — AppDelegate already set up, owns @StateObject stores, registers Settings scene, holds command menus
- `Sources/AutomationHealth/Views/SettingsView.swift` — Native grouped Form with Sections, Picker, Toggle, Slider controls, 480pt width
- `Sources/AutomationHealth/Stores/PreferencesStore.swift` — Pattern for @Published ObservableObject stores with UserDefaults persistence
- `Package.swift` — SwiftPM manifest, no external dependencies currently, macOS 14 platform target
- `script/release.sh` — Release pipeline from Phase 13, will be extended for appcast generation
- `docs/release-process.md` — Release docs from Phase 13, will be updated with Sparkle steps

### Established Patterns
- @StateObject stores created once in App.init(), shared via references (PreferencesStore, JobStore pattern)
- Settings scene as sibling to WindowGroup — SwiftUI auto-registers Cmd+,
- @Published properties in ObservableObject stores for UI state
- Shell scripts in `script/` with `set -euo pipefail` for build/packaging operations

### Integration Points
- `AutomationHealthApp.init()` — create UpdateStore, pass to views
- `AutomationHealthApp.body` — register Sparkle updater in WindowGroup or Settings scene
- `SettingsView` — add Updates section after existing "Candidate Scanning" section
- `Package.swift` — add Sparkle 2 SPM dependency
- `script/release.sh` — add appcast generation + signing steps
- `script/generate_sparkle_keys.sh` — new key generation script
</code_context>

<specifics>
## Specific Ideas

- The Updates section should display the current app version prominently (read from Bundle.main)
- "Check for Updates" button should trigger Sparkle's manual update check
- Auto-check toggle should bind to Sparkle's `automaticallyChecksForUpdates` property
- The appcast.xml will be hosted alongside release assets on GitHub Releases (e.g., `https://github.com/nikomohr/AutomationHealth/releases/download/v1.3.0/appcast.xml`)
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.
</deferred>
