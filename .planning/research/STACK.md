# Stack Research — v1.2 Preferences, Polish, and Shippable Distribution

**Domain:** macOS SwiftUI app — persisted preferences, keyboard navigation, codesigning/notarization/DMG
**Researched:** 2026-05-10
**Confidence:** HIGH

## Recommendation

**No new Swift package dependencies.** All v1.2 features use built-in macOS/SwiftUI/Foundation capabilities already available on the target platform (macOS 14+). The only additions are shell-script-based signing and packaging toolchains that Apple ships with Xcode Command Line Tools.

## Recommended Stack

### Core Technologies — Preferences

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `@AppStorage` | SwiftUI (macOS 14+) | Persist simple preference values (grouping mode, collapse state) in SwiftUI views | Native SwiftUI property wrapper; auto-invalidates views on change; no boilerplate; supports String, Int, Bool, Double, URL, Data, RawRepresentable enums |
| `UserDefaults.standard` | Foundation (macOS 14+) | Read/write preferences from non-view code (JobStore, JobPresentation) | AppStorage is view-only; store/presentation layers must use direct UserDefaults access; use same keys as @AppStorage for consistency |
| `@SceneStorage` | SwiftUI (macOS 14+) | Per-window transient state (NOT for app-wide preferences) | Per-scene storage only; do NOT use for grouping mode or collapse state — those must be app-wide via @AppStorage/UserDefaults |
| `JSONEncoder` / `JSONDecoder` | Foundation (built-in) | Encode complex preference types (e.g., custom ordering arrays) into `Data` for UserDefaults | Built-in, zero-dependency; use only for types that @AppStorage can't handle directly |

### Core Technologies — Keyboard Shortcuts & Focus

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `.keyboardShortcut(_:modifiers:)` | SwiftUI (macOS 11+) | Attach keyboard shortcuts to any SwiftUI control | Native modifier; resolves shortcuts through view hierarchy; supports KeyEquivalent + EventModifiers |
| `focusedSceneValue(_:)` / `@FocusedValue` | SwiftUI (macOS 14+) | Share context (selected job, current grouping) between focused view and menu commands | Required for menu-bar keyboard shortcuts that need to know which view is active; enables context-sensitive commands |
| `Commands` / `CommandMenu` | SwiftUI (macOS 11+) | Define menu-bar commands with key equivalents | Declarative menu definition; shortcuts registered here work globally in the app; integrates with FocusedValue for context-aware enable/disable |
| `@FocusState` | SwiftUI (macOS 12+) | Manage focus within a single view (search field focus) | For "focus search" shortcut; programmatically move focus to search TextField |
| `NSMenuItem` key equivalents | Not needed | SwiftUI `Commands` handles this natively | Use `.keyboardShortcut` on `Button` within `Commands` — SwiftUI generates the NSMenuItem automatically |

### Core Technologies — Code Signing

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `codesign` | Built-in (Xcode CLT) | Sign the .app bundle and DMG with Developer ID certificate | Apple's official tool; required for notarization; `--timestamp --options runtime` for hardened runtime |
| `security find-identity` | Built-in (macOS) | Verify Developer ID certificates are available | Lists valid signing identities before attempting sign |
| Developer ID Application certificate | Apple Developer Program | Sign app bundles for distribution outside App Store | Required for notarization; available only with paid Apple Developer membership |
| Hardened Runtime (`-o runtime`) | codesign flag | Enable runtime protections required by notarization | Mandatory for notarization success; no additional entitlements needed for this app |

### Core Technologies — Notarization

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `notarytool` | Xcode 13+ (built-in via `xcrun`) | Submit app/DMG to Apple notary service | Replaces deprecated `altool`; faster uploads; `--wait` flag for synchronous workflow; `store-credentials` for keychain-based auth |
| `stapler` | Built-in (via `xcrun`) | Attach notarization ticket to DMG | Enables offline Gatekeeper verification; prevents extra network round-trip on user's machine |
| `spctl` | Built-in (macOS) | Verify notarization status after stapling | `spctl --assess -vv --type install` confirms Gatekeeper acceptance |

### Core Technologies — DMG Creation

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `hdiutil` | Built-in (macOS) | Create, attach, convert disk images | Apple's built-in tool; creates compressed DMGs; no third-party dependency |
| `hdiutil create -srcfolder` | Built-in | Create a DMG from the `.app` bundle directory | Simplest approach: one command creates distributable DMG |

### Core Technologies — LICENSE

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| MIT License | Standard | Permissive open-source license for the project | Most common choice for open-source macOS tools; GitHub auto-detects; permissive; allows private use, modification, distribution |
| `LICENSE` file | Repository root | Machine-detectable license file | GitHub recognizes `LICENSE` or `LICENSE.md` in root; displayed on repo page; enables license-based search filtering |

## Installation

No new Swift package dependencies to install. The signing/notarization/DMG toolchain requires:

```bash
# Verify Xcode Command Line Tools are installed (provides codesign, notarytool, stapler, hdiutil)
xcode-select --print-path

# Verify Developer ID certificates exist
security find-identity -p codesigning -v

# Store notarytool credentials (one-time setup per machine)
xcrun notarytool store-credentials --apple-id "your@email.com" --team-id "YOURTEAMID"
```

## Detailed Pattern Guidance

### @AppStorage vs UserDefaults: When to Use Each

| Context | Use | Reason |
|---------|-----|--------|
| SwiftUI View (Settings scene, sidebar picker) | `@AppStorage("key")` | Auto-updates UI; SwiftUI-native; supports `$` binding |
| JobStore (ObservableObject) | `UserDefaults.standard.integer(forKey:)` / `.set(_:forKey:)` | @AppStorage is view-only; store layer must use direct API |
| JobPresentation (value-type adapter) | Accept values as parameters, don't read UserDefaults | Keep presentation layer pure; pass values from JobStore |
| Complex types (custom ordering arrays) | `UserDefaults.standard.data(forKey:)` + `JSONDecoder` | @AppStorage doesn't support Codable natively; JSON round-trip via Data works |
| Default values | Always provide defaults in both places | `@AppStorage var mode = "source"` / `UserDefaults.standard.register(defaults:)` |

### Keyboard Shortcut Implementation Pattern

```
Shortcut                | SwiftUI Implementation
------------------------|--------------------------------------------------
Switch grouping mode    | CommandMenu { Button { } .keyboardShortcut("g", modifiers: .command) }
Focus search field      | CommandMenu { Button { } .keyboardShortcut("f", modifiers: .command) }
  → or @FocusState      | .focused($isSearchFocused) on TextField + programmatic focus
Expand all sections     | Button { } .keyboardShortcut("e", modifiers: .command)
Collapse all sections   | Button { } .keyboardShortcut("e", modifiers: [.command, .shift])
Jump to letter          | FocusedValue + onKeyPress on sidebar List
  → or .onKeyPress      | .onKeyPress { keyPress in handleLetterJump(keyPress.characters) }
```

**Important:** SwiftUI's `.keyboardShortcut` resolves shortcuts through view hierarchy (key window → main window → command groups). For global shortcuts (switch grouping, focus search, expand/collapse all), use `Commands` in the App struct. For view-local shortcuts (jump-to-letter, Up/Down navigation), use `.keyboardShortcut` on the specific view or `.onKeyPress`.

### Code Signing Order (from Apple DTS Engineer guidance)

```
1. Sign nested frameworks/libraries first (if any)
2. Sign nested bundles (appex, plugins) next
3. Sign the .app bundle last
4. Sign the DMG after bundling

For this project (no nested code), signing order is simply:
1. codesign the .app bundle
2. codesign the .dmg
```

**Do NOT use `--deep` flag.** It applies the same options to all nested code, which is wrong for apps with mixed entitlements. Explicit per-item signing is the correct pattern per Apple DTS (Quinn "The Eskimo!").

### DMG Creation Pattern with hdiutil

```bash
# 1. Sign the .app bundle
codesign --sign "Developer ID Application: ..." \
         --timestamp --options runtime \
         --entitlements entitlements.plist \
         "dist/AutomationHealth.app"

# 2. Create DMG from signed .app
hdiutil create -volname "Automation Health" \
               -srcfolder "dist/AutomationHealth.app" \
               -ov -format UDZO \
               "dist/AutomationHealth-1.2.0.dmg"

# 3. Sign the DMG
codesign --sign "Developer ID Application: ..." \
         --timestamp \
         "dist/AutomationHealth-1.2.0.dmg"

# 4. Notarize the DMG
xcrun notarytool submit "dist/AutomationHealth-1.2.0.dmg" \
    --keychain-profile "automationhealth" \
    --wait

# 5. Staple the notarization ticket
xcrun stapler staple "dist/AutomationHealth-1.2.0.dmg"

# 6. Verify
spctl --assess -vv --type install "dist/AutomationHealth-1.2.0.dmg"
```

### Settings Scene Integration Pattern

```swift
// In AutomationHealthApp.swift, add a Settings scene:
@main
struct AutomationHealthApp: App {
    @StateObject private var jobStore = JobStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobStore)
        }
        .commands {
            // Keyboard shortcut commands here
        }
        
        Settings {
            PreferencesView()
        }
    }
}

// PreferencesView.swift uses @AppStorage directly:
struct PreferencesView: View {
    @AppStorage("groupingMode") private var groupingMode = "source"
    @AppStorage("showCollapsed") private var showCollapsed = false
    
    var body: some View {
        Form {
            Picker("Group By", selection: $groupingMode) { ... }
            Toggle("Collapse Empty Sections", isOn: $showCollapsed)
        }
        .frame(width: 400)
    }
}
```

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `@AppStorage` + direct `UserDefaults` | Third-party preferences library (Defaults, SwiftyUserDefaults) | Adds external dependency; @AppStorage is SwiftUI-native and sufficient for all needed types |
| Built-in `hdiutil` | `create-dmg` (Node.js) or `dmgbuild` (Python) | Adds toolchain dependencies (Node, Python); `hdiutil` creates valid compressed DMGs without extra tools |
| `notarytool` (Xcode 13+) | `altool` (deprecated) | `altool` is deprecated and slower; `notarytool` has `--wait` and keychain credential storage |
| MIT License | GPL, Apache 2.0 | MIT is simplest permissive license; no copyleft complexity; GitHub's most common choice for macOS tools |
| Built-in `codesign` | `rcodesign` (third-party) | Adds external dependency; Apple's `codesign` is authoritative and always available on macOS |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `@SceneStorage` for app-wide preferences | Per-scene storage won't persist across window close/reopen; grouping mode must be app-wide | `@AppStorage` in views, `UserDefaults` in stores |
| `--deep` flag with `codesign` | Applies same signing options to all nested code; Apple DTS explicitly warns against it | Explicit per-item signing in correct order |
| `altool` for notarization | Deprecated; slower; lacks `--wait` flag | `notarytool` (available since Xcode 13, required on macOS 14+) |
| Third-party DMG tools (create-dmg, node-appdmg) | Adds Node.js dependency; project has no JS toolchain | Built-in `hdiutil create -srcfolder` |
| Third-party preferences libraries | Adds external Swift dependency against project constraint; no benefit over @AppStorage | Direct @AppStorage + UserDefaults |
| `@AppStorage` in non-view code (JobStore) | Property wrapper only works in SwiftUI View types | Direct `UserDefaults.standard` access |
| Raw `Data` persistence without encoding | Debugging nightmare; can't inspect stored values with `defaults read` | JSONEncode complex types to Data, store with descriptive keys |
| Xcode project (.xcodeproj) for signing | Project already uses SwiftPM; converting adds complexity | Use `codesign` CLI directly on the `.app` bundle built by SwiftPM |

## Entitlements for Hardened Runtime

For this project, the app needs minimal entitlements. Create `entitlements.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
</dict>
</plist>
```

No sandbox entitlement is needed (the app reads scheduler files via `ActiveJobsCore`, not through sandboxed file access). The hardened runtime alone (enabled via `-o runtime`) is sufficient for notarization.

## Integration Points with Existing Codebase

| Existing Component | Integration | Change Needed |
|-------------------|-------------|--------------|
| `JobStore` (`ObservableObject`) | Read grouping mode from `UserDefaults.standard` on init; observe changes | Add UserDefaults read for `groupingMode` key; add `UserDefaults.didChangeNotification` observer |
| `ContentView` (sidebar/search) | Read collapse state via `@AppStorage`; bind keyboard shortcuts | Add `@AppStorage` properties; add `.keyboardShortcut` modifiers where needed |
| `SidebarView` | Jump-to-letter via `.onKeyPress` | Add key press handler; letter matching against section headers |
| `AutomationHealthApp` | Add `Settings {}` scene; add `Commands {}` for menu shortcuts | Add Settings scene with PreferencesView; add CommandMenu for View/Window commands |
| `script/build_and_run.sh` | Append signing, DMG creation, notarization steps | Add conditional signing/DMG block (gated on presence of Developer ID certificate) |
| `Makefile` | Add `make release` target | Wraps the full signing → DMG → notarize → staple pipeline |
| Repository root | Add `LICENSE` file | Create MIT license text in repository root |
| `Package.swift` | No changes needed | `@AppStorage`, `UserDefaults`, SwiftUI commands are all built-in |

## Version Compatibility

All technologies in this stack are built into macOS 14+ with Xcode Command Line Tools:

| Component | Minimum macOS Version | Notes |
|-----------|----------------------|-------|
| `@AppStorage` | macOS 11.0 | Available; app targets 14.0 |
| `.keyboardShortcut` | macOS 11.0 | Available; app targets 14.0 |
| `@FocusState` | macOS 12.0 | Available; app targets 14.0 |
| `Settings` scene | macOS 13.0 (Ventura) | Available; app targets 14.0 |
| `notarytool` | macOS 11.0+ (Xcode 13+) | Available; run on build machine, not target |
| `codesign` `--options runtime` | macOS 10.14+ | Available; hardened runtime |
| `hdiutil create -srcfolder` | macOS 10.0+ | Available; all versions |
| `stapler` | macOS 10.15+ | Available; all versions |

## Sources

- **Context7** `/websites/developer_apple_swiftui` — AppStorage property wrapper, defaultAppStorage modifier, Settings scene integration, keyboardShortcut modifiers, key equivalents, EventModifiers, FocusedValue, CommandMenu, SceneStorage
- **Apple Developer Forums** — "Creating Distribution-Signed Code for Mac" (DTS Engineer Quinn, Mar 2022, updated Feb 2024): codesign ordering, avoiding `--deep`, entitlements, Developer ID cert requirements — HIGH confidence
- **Scripting OS X** (scriptingosx.com) — "Notarize a Command Line Tool with notarytool" (Jul 2021): notarytool workflow, store-credentials, stapler — HIGH confidence
- **Scripting OS X** — "Build a notarized package with a Swift Package Manager executable" (Aug 2023): SwiftPM-specific signing, pkg creation, notarization automation script — HIGH confidence
- **GitHub Docs** — "Licensing a repository": LICENSE file detection, choosealicense.com, supported license types — HIGH confidence
- **Apple Developer Documentation** — `notarytool` man page, `codesign` man page, `hdiutil` man page — HIGH confidence (verified via Context7 and third-party tutorials)
- **Apple Developer** — "Customizing the Notarization Workflow" — official workflow documentation — MEDIUM confidence (page requires JS; content verified via scriptingosx.com and Apple Forums)

---

*Stack research for: v1.2 Preferences, Polish, and Shippable Distribution*
*Researched: 2026-05-10*
*Confidence: HIGH — all technologies are built-in macOS/SwiftUI/Foundation; no third-party unknowns*
