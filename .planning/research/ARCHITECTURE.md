# Architecture Research: v1.3 Signed/Notarized Distribution + Sparkle Auto-Update

**Domain:** macOS SwiftUI read-only automation scanner app — integration of codesigning, notarization, DMG packaging, GitHub Actions release pipeline, and Sparkle auto-update framework
**Researched:** 2026-05-12
**Confidence:** MEDIUM-HIGH (Sparkle integration patterns from established framework docs and community reference implementations; codesigning/notarization patterns confirmed in prior v1.2 STACK.md research; GitHub Actions patterns from standard CI/CD practice)

## System Overview — Post-v1.3 Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    SwiftUI macOS App Layer (EXISTING)                     │
│                                                                          │
│  AutomationHealthApp ── WindowGroup ── Settings ── CommandMenu           │
│   @StateObject store          │            scene       (keyboard shots)   │
│   @StateObject preferences    │                                           │
│   [NEW] SUUpdater injection   │                                           │
├───────────────────────────────┼───────────────────────────────────────────┤
│                        ContentView                                        │
│   @ObservedObject store    @ObservedObject preferences                   │
│   [UNCHANGED]                                                             │
├───────────────────────────────┼───────────────────────────────────────────┤
│   SidebarView  │  DetailView  │  SettingsView [MODIFIED: +Updates tab]   │
│   [UNCHANGED]  │  [UNCHANGED] │  Sparkle update check button, auto-check │
│                                │  toggle, release notes link             │
├────────────────────────────────┴──────────────────────────────────────────┤
│                   Presentation + State Layer (EXISTING)                    │
│  JobStore  │  PreferencesStore  │  [NEW] UpdateState (optional, simple)  │
│            │  [UNCHANGED]       │                                        │
├───────────────────────────────────────────────────────────────────────────┤
│  AutomationHealthCore (JobPresentation.swift) [UNCHANGED]                 │
├───────────────────────────────────────────────────────────────────────────┤
│  ActiveJobsCore (Scanner Library Layer) [UNCHANGED]                       │
└───────────────────────────────────────────────────────────────────────────┘

                         Sparkle Framework Layer (NEW)
┌──────────────────────────────────────────────────────────────────────────┐
│  Sparkle 2.x (Swift Package Manager dependency)                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ SPUStandardUpdaterController  (or programmatic SPUUpdater)         │  │
│  │   ├── Reads SUFeedURL from Info.plist                              │  │
│  │   ├── Checks GitHub Releases appcast for new versions              │  │
│  │   ├── Downloads update .dmg or .tar.xz                             │  │
│  │   ├── Presents update UI (install on quit, release notes)          │  │
│  │   └── Validates EdDSA signature on update                          │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│  Integration points:                                                      │
│    1. Package.swift: .package(url: "https://github.com/sparkle-project/  │
│       Sparkle", from: "2.6.0")                                            │
│    2. AutomationHealth target: depends on "Sparkle"                       │
│    3. AppDelegate: instantiate SPUStandardUpdaterController               │
│    4. Info.plist: SUFeedURL, SUPublicEDKey, SUEnableAutomaticChecks       │
│    5. SettingsView: "Check for Updates" button, auto-check toggle         │
│    6. entitlements.plist: com.apple.security.automation.apple-events for  │
│       Sparkle's install-on-quit mechanism (if needed)                     │
└───────────────────────────────────────────────────────────────────────────┘

                        Build & Distribution Pipeline (NEW)
┌──────────────────────────────────────────────────────────────────────────┐
│  script/                                                                  │
│  ├── build_and_run.sh    (MODIFIED: +Sparkle framework bundle copy)      │
│  ├── sign.sh             (NEW: codesign with Dev ID + entitlements)      │
│  ├── notarize.sh         (NEW: notarytool submit + stapler staple)       │
│  ├── package.sh          (NEW: hdiutil DMG creation + DMG signing)       │
│  └── release.sh          (NEW: orchestrates full release pipeline)       │
│                                                                           │
│  .github/workflows/                                                       │
│  ├── ci.yml              (EXISTING: PR/push build+test)                   │
│  └── release.yml         (NEW: tag-triggered signed release pipeline)    │
│                                                                           │
│  config/                                                                  │
│  ├── entitlements.plist  (NEW: hardened runtime + Sparkle exceptions)    │
│  ├── Info.plist          (EXISTING, inline in build_and_run.sh → NEW:    │
│  │                         persisted template with Sparkle keys)          │
│  └── dmg-background.png  (NEW: optional DMG background image)             │
│                                                                           │
│  dist/                                                                   │
│  ├── AutomationHealth.app    (signed, notarized, stapled)                │
│  └── AutomationHealth-v1.3.0.dmg  (signed, notarized, stapled)           │
└──────────────────────────────────────────────────────────────────────────┘
```

## New Components

| Component | File | Responsibility | Why New |
|-----------|------|---------------|---------|
| **Sparkle dependency** | `Package.swift` (modified) | Add `https://github.com/sparkle-project/Sparkle` as SPM package, link `Sparkle` product to `AutomationHealth` target | First external Swift package dependency; Sparkle provides the auto-update framework including update checking, download, signature verification, and install-on-quit |
| **SPUStandardUpdaterController** | `Sources/AutomationHealth/App/AutomationHealthApp.swift` (modified via AppDelegate) | Instantiate in `AppDelegate.applicationDidFinishLaunching(_:)`, hold as `private var updaterController: SPUStandardUpdaterController` | Sparkle's simplest integration path for non-sandboxed apps; automatically reads Info.plist keys (SUFeedURL, SUScheduledCheckInterval, SUEnableAutomaticChecks); presents update UI including release notes |
| **Info.plist — Sparkle keys** | `script/build_and_run.sh` (modified) or static `config/Info.plist` (NEW) | Add `SUFeedURL`, `SUPublicEDKey`, `SUEnableAutomaticChecks` to app bundle's Info.plist | Sparkle reads these keys from the bundle's Info.plist at runtime; feed URL points to GitHub Releases appcast atom feed; ED public key enables signature verification of updates |
| **entitlements.plist** | `entitlements.plist` or `config/entitlements.plist` (NEW) | Hardened runtime entitlements: disable-library-validation (for Sparkle framework loading), possibly com.apple.security.automation.apple-events | Required for codesigning with hardened runtime; Sparkle framework loaded from app bundle requires library validation disabled for non-Apple-signed frameworks |
| **sign.sh** | `script/sign.sh` (NEW) | Codesign the .app bundle with Developer ID Application certificate using explicit per-item signing (never `--deep`) | Separates signing from build-and-run; needs to run in CI with secrets; must verify identity exists before signing |
| **notarize.sh** | `script/notarize.sh` (NEW) | Submit signed .dmg to Apple notary service via `notarytool`, wait for completion, staple ticket | Notarization is Apple-required for Distribution outside App Store; `notarytool --wait` + `stapler staple` pattern |
| **package.sh** | `script/package.sh` (NEW) | Create compressed DMG from signed .app via `hdiutil create -srcfolder`, sign the DMG | DMG is the standard macOS distribution format; creates a mountable disk image users drag to /Applications |
| **release.sh** | `script/release.sh` (NEW) | Orchestrator: version detection → build → sign → DMG → notarize → staple → GitHub Release draft | Single-entry-point CI script; detects version from git tag, coordinates all steps, uploads artifact |
| **release.yml** | `.github/workflows/release.yml` (NEW) | GitHub Actions workflow triggered by tag push (`v*`); runs on `macos-latest`; uses Apple Developer ID secrets; creates GitHub Release with uploaded .dmg | CI automation of entire signed+notarized release pipeline; triggered by pushing a version tag |
| **SettingsView — Updates tab** | `Sources/AutomationHealth/Views/SettingsView.swift` (MODIFIED) | Add "Updates" section with "Check for Updates…" button (triggers `updaterController.checkForUpdates()`), auto-check toggle (writes `SUEnableAutomaticChecks` to UserDefaults) | Users need discoverable update UI; Sparkle provides the check/install UI but the trigger button must be in the app |
| **AppIcon for DMG** | Existing `Assets/AppIcon/` + `config/dmg-background.png` (NEW, optional) | DMG background image with arrow pointing to /Applications shortcut | Polished DMG appearance; not strictly required for functionality but standard expectation for macOS apps |

## Modified Components

| Component | What Changes | Why |
|-----------|-------------|-----|
| **Package.swift** | Add `.package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")` to dependencies; add `"Sparkle"` to AutomationHealth executable target dependencies | Sparkle is the first external dependency; must be declared in Package.swift for SPM to resolve and link |
| **AppDelegate** (in AutomationHealthApp.swift) | Add `private var updaterController = SPUStandardUpdaterController(startingUpdater: true)` property; import Sparkle | AppDelegate already exists for NSApp.setActivationPolicy; Sparkle initialization must happen early in app lifecycle |
| **AutomationHealthApp** | No structural changes needed if updaterController is held by AppDelegate; if programmatic setup needed, pass updaterController to SettingsView via environment | SPUStandardUpdaterController is self-contained once instantiated; the Settings scene needs a reference to trigger `checkForUpdates()` |
| **SettingsView** | Add new `Section("Updates")` with auto-check toggle and "Check for Updates…" button | Users need visibility into update settings; Sparkle's check/install UI is separate but the trigger lives here |
| **build_and_run.sh** | Add Sparkle-specific Info.plist keys (SUFeedURL, SUPublicEDKey, SUEnableAutomaticChecks); copy Sparkle framework into app bundle if needed for development builds | Info.plist is currently generated inline in build_and_run.sh; Sparkle keys must be present for update checking to work even in dev builds (with placeholder/localhost feed for development) |
| **Makefile** | Add `make release` target; add `make sign`, `make notarize`, `make package` as sub-targets | Developer convenience; Makefile is the existing project entry point |

## Data Flow: Update Check Cycle

```
┌──────────────────────────────────────────────────────────────────────┐
│                      UPDATE CHECK CYCLE                              │
│                                                                      │
│  1. App Launch                                                       │
│     └→ AppDelegate.applicationDidFinishLaunching()                   │
│        └→ SPUStandardUpdaterController(startingUpdater: true)        │
│           └→ Reads Info.plist: SUFeedURL, SUScheduledCheckInterval   │
│              └→ Schedules periodic update checks (default: daily)   │
│                                                                      │
│  2. Scheduled Check (or Manual via Settings → "Check for Updates")   │
│     └→ HTTP GET to SUFeedURL                                         │
│        └→ Parse appcast XML (atom feed from GitHub Releases)        │
│           └→ Compare version (<CFBundleVersion> or <CFBundleShort-  │
│              VersionString>) against installed app version           │
│              └→ If new version available:                            │
│                 ├→ Download update .dmg from <enclosure> URL        │
│                 ├→ Verify EdDSA signature (SUPublicEDKey)           │
│                 ├→ Present Sparkle update window (release notes,    │
│                 │   "Install on Quit", "Skip This Version")         │
│                 └→ On quit: mount .dmg, copy .app to /Applications, │
│                    relaunch new version                              │
│                                                                      │
│  3. GitHub Releases as Appcast                                       │
│     └→ Appcast feed URL:                                             │
│        https://github.com/{owner}/AutomationHealth/releases.atom     │
│        └→ Alternative: custom appcast.xml hosted via GitHub Pages   │
│           (required if using EdDSA signing)                          │
│           └→ appcast.xml generated by Sparkle's generate_appcast    │
│              tool, committed to gh-pages branch or release asset    │
└──────────────────────────────────────────────────────────────────────┘
```

## Data Flow: Release Pipeline

```
┌──────────────────────────────────────────────────────────────────────┐
│                     RELEASE PIPELINE                                 │
│                                                                      │
│  Trigger: git tag v1.3.0 pushed to main                              │
│     │                                                                │
│     ├── 1. GitHub Actions: release.yml workflow                      │
│     │      └── Checkout code at tag                                  │
│     │      └── Install Apple Developer ID certificate from secrets   │
│     │      └── Install provisioning profile (if needed)              │
│     │                                                                │
│     ├── 2. Build                                                     │
│     │      └── swift build -c release                                │
│     │      └── Construct .app bundle: binary + Resources + Info.plist│
│     │      └── Copy Sparkle framework into .app/Contents/Frameworks/ │
│     │                                                                │
│     ├── 3. Sign App Bundle                                           │
│     │      └── codesign --deep Sparkle framework (required: it's a   │
│     │         nested framework)                                      │
│     │      └── codesign --sign "Developer ID Application: ..."       │
│     │         --timestamp --options runtime                           │
│     │         --entitlements config/entitlements.plist               │
│     │         dist/AutomationHealth.app                              │
│     │      └── codesign --verify --verbose                           │
│     │                                                                │
│     ├── 4. Create DMG                                                │
│     │      └── hdiutil create -volname "Automation Health"           │
│     │         -srcfolder dist/AutomationHealth.app                   │
│     │         -ov -format UDZO                                        │
│     │         dist/AutomationHealth-1.3.0.dmg                        │
│     │      └── codesign --sign "Developer ID Application: ..."       │
│     │         --timestamp dist/AutomationHealth-1.3.0.dmg           │
│     │                                                                │
│     ├── 5. Notarize DMG                                              │
│     │      └── xcrun notarytool submit dist/AutomationHealth.dmg     │
│     │         --keychain-profile "automationhealth"                  │
│     │         --wait                                                 │
│     │      └── xcrun stapler staple dist/AutomationHealth.dmg        │
│     │      └── spctl --assess -vv --type install dist/*.dmg          │
│     │                                                                │
│     ├── 6. Generate Appcast (if using custom appcast)                │
│     │      └── Download Sparkle's generate_appcast tool              │
│     │      └── ./generate_appcast --ed-key-file ed25519-private.pem  │
│     │         dist/                                                  │
│     │      └── Produces appcast.xml + signatures for each .dmg       │
│     │                                                                │
│     └── 7. Create GitHub Release                                     │
│            └── gh release create v1.3.0                              │
│               --title "Automation Health v1.3.0"                     │
│               --notes-file CHANGELOG.md                               │
│               dist/AutomationHealth-1.3.0.dmg                         │
│               dist/appcast.xml (if custom appcast)                    │
└──────────────────────────────────────────────────────────────────────┘
```

## Integration Points — Detailed

### 1. Package.swift — Sparkle Dependency

```swift
// Add to Package.swift dependencies array:
.package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),

// Add to AutomationHealth executable target dependencies:
.executableTarget(
    name: "AutomationHealth",
    dependencies: [
        "ActiveJobsCore",
        "AutomationHealthCore",
        .product(name: "Sparkle", package: "Sparkle")
    ]
),
```

**SPM product name:** The Sparkle package exposes a `Sparkle` library product. AutomatichHealth target links against it.

**Version pinning:** Use `from: "2.6.0"` (semantic versioning). Sparkle 2.x is the current major version; 2.6.0 is a recent stable release. This is a LOW confidence version number — verify current release at integration time.

### 2. AppDelegate — Updater Initialization

The existing `AppDelegate` in `AutomationHealthApp.swift` gains Sparkle initialization:

```swift
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    // SPUStandardUpdaterController automatically reads Info.plist keys
    // and starts the update check cycle.
    private var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Initialize Sparkle — reads SUFeedURL, SUEnableAutomaticChecks,
        // SUScheduledCheckInterval from Info.plist
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true
        )
    }
}
```

**Why `SPUStandardUpdaterController`:** This is Sparkle 2's simplest integration path. It:
- Creates an `SPUUpdater` with default settings
- Reads configuration from Info.plist automatically
- Handles the update check lifecycle (schedule, manual trigger, download, install)
- Exposes `checkForUpdates(_:)` for manual trigger from Settings UI
- Holds the updater as a strong reference (stored property prevents deallocation)

**Alternative — programmatic `SPUUpdater`:** If more control is needed (custom user driver, custom delegate), use `SPUUpdater` directly. For this project, `SPUStandardUpdaterController` is sufficient.

### 3. Info.plist — Sparkle Configuration Keys

Add these keys to the Info.plist generated in `build_and_run.sh` (or to a persisted `config/Info.plist` template):

| Key | Value | Purpose |
|-----|-------|---------|
| `SUFeedURL` | `https://github.com/{org}/AutomationHealth/releases.atom` | Primary appcast feed. GitHub Releases atom feed publishes every release automatically. Alternative: `https://{org}.github.io/AutomationHealth/appcast.xml` for custom appcast with EdDSA signing |
| `SUPublicEDKey` | `(generated EdDSA public key string)` | Public key for verifying update signatures. Generate with Sparkle's `generate_keys` tool. If using custom appcast with EdDSA signing |
| `SUEnableAutomaticChecks` | `YES` (Boolean) | Enable automatic update checks on launch and periodically |
| `SUScheduledCheckInterval` | `86400` (Number, seconds) | Check interval — 86400 = daily. Sparkle default is daily |
| `SUAutomaticallyUpdate` | `NO` (Boolean) | Do not auto-install updates without user consent for v1.3 |
| `CFBundleVersion` | `(version number)` | Build number — Sparkle uses this for version comparison |
| `CFBundleShortVersionString` | `(version string)` | Marketing version — displayed in update UI |

**For development builds:** Set `SUFeedURL` to a placeholder (e.g., `http://localhost:8080/appcast.xml`) or omit it entirely (Sparkle will not check for updates if no feed URL is configured). The build_and_run.sh for local dev should NOT include real feed URLs.

### 4. SettingsView — Updates UI

Add an "Updates" section to the existing Settings form:

```swift
// In SettingsView.swift, add a new Section:
Section("Updates") {
    HStack {
        Text("Automation Health checks for updates automatically.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    Button("Check for Updates…") {
        // Access updaterController via environment or shared reference
        SUUpdater.shared().checkForUpdates(nil)
    }

    Toggle("Automatically check for updates", isOn: $autoCheckEnabled)
        .onChange(of: autoCheckEnabled) { newValue in
            UserDefaults.standard.set(newValue, forKey: "SUEnableAutomaticChecks")
        }
}
```

**How SettingsView reaches the updater:** The simplest approach for `SPUStandardUpdaterController` is to access it via `SUUpdater.shared()` which is available when Sparkle is linked. Alternatively, inject the updater controller reference through the SwiftUI environment or as a parameter.

**Note:** The actual update check UI (download progress, release notes, install prompt) is provided by Sparkle itself. The Settings button only triggers `checkForUpdates()` which opens Sparkle's own window.

### 5. entitlements.plist — Hardened Runtime Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Allow Sparkle framework to load from app bundle
         (Sparkle is not signed by Apple, so library validation
         would block it under Hardened Runtime) -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>

    <!-- Allow Sparkle to install updates on quit
         (needs to mount DMG and copy files to /Applications) -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

**Why `disable-library-validation`:** Sparkle.framework is distributed as a binary framework embedded in the app bundle. Under Hardened Runtime, library validation rejects libraries not signed by Apple or the same Developer ID. Sparkle is signed by the Sparkle project, not by Apple, so `disable-library-validation` is required. This is the standard approach documented by Sparkle and Apple.

**Note on sandbox:** The app is NOT sandboxed. If sandboxing were enabled (it is not), additional entitlements would be needed for Sparkle's install mechanism. The app already reads system scheduler files outside sandbox controls, so sandboxing is not in scope.

### 6. CI Pipeline — release.yml

The new GitHub Actions release workflow (separate from `ci.yml`):

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version tag (e.g., v1.3.0)'
        required: true

permissions:
  contents: write  # Needed for creating releases

jobs:
  release:
    name: Build, Sign, Notarize, and Release
    runs-on: macos-latest
    timeout-minutes: 45

    steps:
      - uses: actions/checkout@v4

      - name: Install Apple Developer ID Certificate
        env:
          DEVELOPER_CERTIFICATE_BASE64: ${{ secrets.DEVELOPER_CERTIFICATE_BASE64 }}
          DEVELOPER_CERTIFICATE_PASSWORD: ${{ secrets.DEVELOPER_CERTIFICATE_PASSWORD }}
        run: |
          # Decode and install signing certificate to temporary keychain
          ./script/ci/install-signing-cert.sh

      - name: Build Release App Bundle
        run: swift build -c release

      - name: Create App Bundle
        run: ./script/package.sh

      - name: Sign App Bundle
        run: ./script/sign.sh

      - name: Create DMG
        run: ./script/create-dmg.sh

      - name: Notarize DMG
        env:
          APPLE_NOTARY_PROFILE: ${{ secrets.APPLE_NOTARY_PROFILE }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
        run: ./script/notarize.sh

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: dist/AutomationHealth-*.dmg
          generate_release_notes: true
```

**GitHub Secrets Required:**
| Secret | Purpose |
|--------|---------|
| `DEVELOPER_CERTIFICATE_BASE64` | Base64-encoded .p12 Developer ID Application certificate |
| `DEVELOPER_CERTIFICATE_PASSWORD` | Password for the .p12 certificate |
| `APPLE_ID` | Apple ID for notarization |
| `APPLE_TEAM_ID` | Apple Developer Program team ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password for Apple ID (notarization auth) |

### 7. Build Script Changes — build_and_run.sh

The existing `build_and_run.sh` constructs the `.app` bundle with inline Info.plist. Changes needed:

1. **Sparkle framework bundling:** After building, copy `Sparkle.framework` (from SPM build artifacts) into `$APP_CONTENTS/Frameworks/Sparkle.framework`. SPM places built frameworks in `.build/debug/` or `.build/release/` — need to locate and copy.

2. **Info.plist keys:** Add Sparkle configuration keys. For dev builds, use placeholder values:
   - `SUFeedURL`: `http://localhost:8080/appcast.xml` or empty
   - `SUEnableAutomaticChecks`: `NO` (don't check for updates in dev builds)
   - Other Sparkle keys can be omitted for dev builds

3. **Optionally extract Info.plist to a template file** (`config/Info.plist`) that scripts read and modify, rather than inline generation. This is cleaner as the number of Info.plist keys grows.

### 8. New Script Files

| Script | Inputs | Outputs | Key Tool |
|--------|--------|---------|----------|
| `script/sign.sh` | `dist/AutomationHealth.app`, `config/entitlements.plist`, Dev ID cert in keychain | Signed `.app` bundle | `codesign` |
| `script/notarize.sh` | `dist/AutomationHealth-*.dmg`, keychain profile | Notarized + stapled `.dmg` | `notarytool`, `stapler`, `spctl` |
| `script/package.sh` | `dist/AutomationHealth.app`, version string | `dist/AutomationHealth-{version}.dmg` | `hdiutil` |
| `script/release.sh` | Git tag, signing identity | Signed, notarized, stapled `.dmg` | Orchestrates above scripts |
| `script/ci/install-signing-cert.sh` | `$DEVELOPER_CERTIFICATE_BASE64`, `$DEVELOPER_CERTIFICATE_PASSWORD` | Temporary keychain with Dev ID cert | `security import`, `security set-key-partition-list` |

## Component Boundaries

| Component | Responsibility | Communicates With | New or Existing |
|-----------|---------------|-------------------|-----------------|
| `AutomationHealthApp` | App entry, scene graph, CommandMenu | WindowGroup, Settings, ContentView | EXISTING (unchanged structurally) |
| `AppDelegate` | App lifecycle, Sparkle init, activation policy | SPUStandardUpdaterController, NSApp | MODIFIED (+Sparkle updater) |
| `SPUStandardUpdaterController` | Update check scheduling, download, install, UI | Sparkle framework internals, GitHub Releases HTTP | NEW (third-party) |
| `ContentView` | Layout shell, search, sidebar/detail bridge | SidebarView, DetailView, JobStore | EXISTING (unchanged) |
| `SettingsView` | Preferences + Updates UI | PreferencesStore, SPUStandardUpdaterController | MODIFIED (+Updates section) |
| `JobStore` | Scan, job data, selection | ContentView, JobPresentation | EXISTING (unchanged) |
| `PreferencesStore` | UserDefaults persistence | SettingsView, ContentView | EXISTING (unchanged) |
| `Package.swift` | Dependency declaration | SwiftPM resolver | MODIFIED (+Sparkle) |
| `build_and_run.sh` | Dev app bundle creation | Swift compiler, hdiutil | MODIFIED (+Sparkle framework copy, Info.plist keys) |
| `sign.sh` | Code signing | codesign, keychain | NEW |
| `notarize.sh` | Notarization | notarytool, stapler | NEW |
| `package.sh` | DMG creation | hdiutil | NEW |
| `release.sh` | Release orchestration | sign.sh, notarize.sh, package.sh | NEW |
| `release.yml` | CI/CD automation | GitHub Actions, all scripts | NEW |
| `entitlements.plist` | Hardened runtime config | codesign tool | NEW |
| `Info.plist` (extended) | Bundle metadata + Sparkle config | App bundle, Sparkle framework | MODIFIED (+new keys) |

## Build Order Dependencies

The distribution pipeline has a strict dependency chain. Each step requires the previous:

```
Build Release App Bundle
    │
    ├── Requires: SwiftPM build succeeds (all targets compile with Sparkle)
    │
    ▼
Create App Bundle Structure (.app)
    │
    ├── Requires: Binary built, Sparkle.framework located and copied
    ├── Requires: Info.plist generated with Sparkle keys
    ├── Requires: App icon in Resources
    │
    ▼
Sign App Bundle (codesign)
    │
    ├── Requires: .app bundle structure complete
    ├── Requires: entitlements.plist present
    ├── Requires: Developer ID certificate in keychain
    ├── Signing order: Sparkle.framework first, then .app bundle
    │
    ▼
Create DMG (hdiutil)
    │
    ├── Requires: Signed .app bundle
    │
    ▼
Sign DMG (codesign)
    │
    ├── Requires: DMG created
    │
    ▼
Notarize DMG (notarytool)
    │
    ├── Requires: Signed DMG
    ├── Requires: Apple ID + team ID credentials
    │
    ▼
Staple DMG (stapler)
    │
    ├── Requires: Notarization approved
    │
    ▼
Verify (spctl)
    │
    ├── Requires: Stapled DMG
    │
    ▼
Upload to GitHub Release
    │
    ├── Requires: Verified DMG
    └── Optional: Generate appcast.xml if using custom appcast
```

**Sparkle integration testing** can begin BEFORE the full signing pipeline works:
1. Add Sparkle dependency to Package.swift → compile check
2. Add updaterController to AppDelegate → app launches, no update check (no feed URL in dev)
3. Add Updates section to Settings → button renders, checkForUpdates triggers
4. Test with local appcast: configure SUFeedURL to localhost, run Sparkle's generate_appcast, verify update detection works locally
5. Full integration: GitHub Release → real appcast → end-to-end update flow

## Anti-Patterns to Avoid

### Anti-Pattern 1: Using `codesign --deep` on the App Bundle

**What:** Signing with `--deep` flag applies the same signing options to all nested code (frameworks, bundles) automatically.

**Why bad:** Apple DTS explicitly warns against it. Different nested items may need different signing options. Explicit per-item signing with the correct order is the proper pattern.

**Instead:** Sign Sparkle.framework first with its own flags, then sign the .app bundle.

### Anti-Pattern 2: Hardcoding Developer ID or Feed URL in Source Code

**What:** Putting signing identities, certificate names, or production feed URLs in Swift source files or committed scripts.

**Why bad:** Certificate names change between team members. Feed URLs differ between dev/staging/production. Committing production credentials is a security issue.

**Instead:** Use environment variables (`$DEVELOPER_ID_APPLICATION`), CI secrets, and placeholder values in dev builds. The `build_and_run.sh` should use localhost/no-op feed URL for development.

### Anti-Pattern 3: Notarizing the .app Directly Instead of the DMG

**What:** Submitting the .app bundle to notarization, then building the DMG afterward.

**Why bad:** Notarization validates the delivered artifact. If you notarize the .app then create a DMG, the DMG is not notarized. Users downloading the DMG get a Gatekeeper warning. You'd need to notarize the DMG anyway, doubling the process.

**Instead:** Sign .app → create DMG → sign DMG → notarize DMG → staple DMG. One notarization submission, one delivered artifact.

### Anti-Pattern 4: Adding Sparkle as a Runtime Dependency in All Build Configurations

**What:** Always linking Sparkle.framework and initializing the updater, even in debug/dev builds.

**Why bad:** In dev builds, the updater may try to check a production feed URL (if Info.plist isn't carefully managed), download updates over the running dev build, or interfere with debugging (Sparkle's XPC services can cause confusion).

**Instead:** In dev builds (detected via `#if DEBUG` or environment variable), either skip Sparkle initialization or configure with a no-op/localhost feed URL. The `build_and_run.sh` dev build should set `SUFeedURL` to empty or a localhost placeholder.

### Anti-Pattern 5: Over-Engineering the Release Pipeline Before It Works Locally

**What:** Building the full GitHub Actions release.yml with secrets, certificate import, and notarization before verifying each step works manually from the command line.

**Why bad:** Debugging CI-based signing and notarization is slow (each iteration takes minutes). Certificate import issues, notarytool auth problems, and DMG verification failures are much easier to diagnose and fix locally.

**Instead:** Build and test each step locally first:
1. `swift build -c release` → creates app bundle → verify app launches
2. `codesign ...` → verify with `codesign --verify --verbose`
3. `hdiutil create ...` → verify DMG mounts
4. `notarytool submit ...` → verify notarization succeeds
5. `spctl --assess ...` → verify Gatekeeper acceptance
Only then encode these steps in CI.

## Scalability Considerations

| Concern | MVP (v1.3) | Future |
|---------|-----------|--------|
| **Update feed** | GitHub Releases atom feed (free, automatic) | Custom appcast.xml with EdDSA signing for security |
| **DMG size** | < 50 MB (SwiftUI app + Sparkle framework) | Delta updates via Sparkle (only download changed files) |
| **Build time** | ~5 min (release build) + ~10 min (notarization wait) | Same; notarization is the bottleneck, not build |
| **CI cost** | GitHub Actions free tier (macOS minutes included) | Same for infrequent releases |
| **Certificates** | Single Developer ID Application certificate | Same; no provisioning profiles needed (outside App Store) |
| **Update channels** | Single production channel | Beta channel via separate appcast feed (out of scope for v1.3) |

## Sources

- **Apple Developer Documentation** — "Code Signing Guide": codesign, hardened runtime, entitlements, Developer ID — HIGH confidence (stable, well-documented Apple technology)
- **Apple Developer Documentation** — "Notarizing macOS Software Before Distribution": notarytool, stapler, spctl, keychain profiles — HIGH confidence
- **Sparkle Project** — `github.com/sparkle-project/Sparkle`: SPM integration, SPUStandardUpdaterController, Info.plist keys, EdDSA signing, appcast format — MEDIUM confidence (version-specific details should be verified at integration time via official docs)
- **Scripting OS X** (scriptingosx.com) — "Notarize a Command Line Tool with notarytool" (Jul 2021) and "Build a notarized package with a Swift Package Manager executable" (Aug 2023) — HIGH confidence (confirmed patterns in prior v1.2 STACK.md research)
- **Apple Developer Forums** — DTS Engineer Quinn "The Eskimo!" on codesign ordering, avoiding `--deep`, Developer ID certs — HIGH confidence (authoritative DTS guidance)
- **Prior v1.2 research** — `.planning/research/STACK.md` and `.planning/research/PITFALLS.md` cover codesigning, notarization, DMG creation patterns in detail — HIGH confidence (already validated against Apple docs and Context7)
- **GitHub Actions** — `softprops/action-gh-release`, `actions/checkout`, macOS runner documentation — HIGH confidence (standard CI patterns)
- **Existing codebase** — `Sources/AutomationHealth/App/AutomationHealthApp.swift`, `script/build_and_run.sh`, `Package.swift`, `.github/workflows/ci.yml` — HIGH confidence (direct file reads)
