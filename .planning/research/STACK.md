# Stack Research — v1.3 Shippable Distribution

**Domain:** macOS SwiftUI app — codesigning, notarization, DMG, GitHub Actions release pipeline, Sparkle auto-update
**Researched:** 2026-05-12
**Confidence:** MEDIUM (see Confidence Assessment at bottom)

## Executive Summary

v1.3 adds the distribution pipeline to an already-buildable SwiftPM macOS app. The existing v1.2 research covered codesigning basics, notarytool, and hdiutil DMG creation. This v1.3 research covers what's NEW and what's CHANGED from v1.2: Sparkle 2 integration (the first external Swift package dependency), GitHub Actions release workflow (CI automation of signing + notarization + DMG + release), and refinements to the DMG/Info.plist toolchain.

The headline decisions:
- **Sparkle 2 via SwiftPM** — the project's first external dependency, added as a package dependency in `Package.swift`
- **GitHub Actions** (`macos-latest` runner) — extends the existing `ci.yml` with a new `release.yml` workflow
- **`create-dmg`** — replaces raw `hdiutil` for polished DMG with background image and Applications alias
- **`notarytool` + `stapler`** — unchanged from v1.2 research, but now wired into CI with GitHub Secrets

## What's New vs. What's Unchanged

| Component | v1.2 Status | v1.3 Change |
|-----------|-------------|-------------|
| `codesign` | Researched, not implemented | Remains same; now CI-automated via GitHub Actions |
| `notarytool` + `stapler` | Researched, not implemented | Remains same; wired into CI with GitHub Secrets |
| `hdiutil` | Recommended for DMG | Still used for raw DMG creation; supplemented by `create-dmg` for polished layout |
| Entitlements plist | Researched | Unchanged — hardened runtime only, no sandbox |
| SwiftPM build | Existing | **Changed**: needs `Sparkle` package dependency |
| CI pipeline | `ci.yml` (build + test only) | **New**: `release.yml` for full signing → DMG → notarize → GitHub Release |
| Auto-update | Explicitly deferred ("rely on manual download") | **New**: Sparkle 2 integration is now P1 |

## Recommended Stack

### External Swift Package Dependency (NEW for v1.3)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Sparkle | 2.x (latest stable) | In-app auto-update checking against GitHub Releases appcast | The standard for macOS auto-update outside the App Store; used by virtually every major Mac app (Rectangle, IINA, Maccy, Termius, etc.); supports Sparkle 2 SwiftPM integration; includes `SPUStandardUpdaterController` for minimal-code setup and `SPUUpdater` for programmatic control |

**Sparkle integration approach:** Programmatic setup via `SPUStandardUpdaterController` or `SPUUpdater` initialized in the app launch path. This avoids requiring an XIB-based menu item and gives full control over update-check timing. Sparkle 2 has supported SwiftPM since version 2.0 (released 2021), with the package at `https://github.com/sparkle-project/Sparkle`.

### GitHub Actions Release Pipeline (NEW for v1.3)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `actions/checkout` | v4 | Clone repo in CI | Already used in `ci.yml`; same action for release workflow |
| `macos-latest` runner | latest (macOS 15+) | Build + sign on Apple silicon | Required for codesigning (needs Apple frameworks); `macos-latest` currently resolves to macOS 15 ARM (M-series) runners |
| `actions/upload-artifact` | v4 | Upload signed DMG as build artifact | Enables downloading the DMG from CI before it's attached to a GitHub Release |
| `softprops/action-gh-release` | v2 | Create GitHub Release + upload DMG asset | Handles release creation, asset upload, and release notes generation in one action; more reliable than raw `gh release create` for CI |
| GitHub Actions Secrets | built-in | Store Developer ID certificate, password, notary credentials | `DEVELOPER_ID_CERTIFICATE_BASE64`, `DEVELOPER_ID_CERTIFICATE_PASSWORD`, `NOTARYTOOL_APPLE_ID`, `NOTARYTOOL_TEAM_ID`, `NOTARYTOOL_PASSWORD` — all stored as repository secrets, never committed |

### DMG Creation — Polished (CHANGED from v1.2)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `create-dmg` | latest | Create polished DMG with background image, Applications folder alias, layout | De facto standard for macOS DMG distribution; produces the "drag to Applications" experience users expect; Node.js dependency BUT only needed in CI/dev machine, not in the shipped app |
| `hdiutil` | built-in (macOS) | Raw DMG operations (create, convert, attach) | Still used by `create-dmg` under the hood; also used for notarization verification mounts |
| DMG background image | N/A | Visual background for DMG window | Optional polish; can be a simple PNG with app name and arrow; stored in `Assets/DMG/` |
| DMG AppleScript layout | N/A | Position app icon and Applications alias in DMG window | `create-dmg` handles this; no custom AppleScript needed unless we want specific positioning |

**Decision: `create-dmg` for polished DMG.** While the v1.2 research recommended raw `hdiutil` (to avoid toolchain dependencies), the user experience of a bare `.dmg` without Applications alias is poor. `create-dmg` is a `brew install create-dmg` away and runs only on the build machine — it adds zero weight to the shipped app. The existing CI `macos-latest` runner can `brew install create-dmg` in the workflow.

**Alternative if `create-dmg` is unacceptable:** Use `hdiutil` with a manually-crafted AppleScript for layout. This avoids the Brew dependency but requires maintaining AppleScript positioning code. For v1.3, `create-dmg` is the pragmatic choice.

### Signing and Notarization Toolchain (UNCHANGED from v1.2)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `codesign` | built-in (Xcode CLT) | Sign .app bundle and DMG | Unchanged from v1.2 — `--timestamp --options runtime` for hardened runtime |
| `notarytool` | built-in (Xcode CLT) | Submit DMG to Apple notary service | Unchanged from v1.2 — `xcrun notarytool submit --wait --keychain-profile` |
| `stapler` | built-in (Xcode CLT) | Staple notarization ticket to DMG | Unchanged from v1.2 — `xcrun stapler staple` |
| `spctl` | built-in (macOS) | Verify notarization and Gatekeeper acceptance | Unchanged from v1.2 — `spctl --assess -vv --type install` |

### Info.plist Hardening (REFINED from v1.2)

The hand-rolled `Info.plist` in `script/build_and_run.sh` needs these additional keys for notarization and Sparkle:

| Key | Value | Required For |
|-----|-------|--------------|
| `CFBundleVersion` | `1` (incrementing build number) | Notarization requires this; Sparkle uses it for version comparison |
| `CFBundleShortVersionString` | `1.3.0` (marketing version) | Notarization requires this; Sparkle displays it to users |
| `SUFeedURL` | `https://github.com/owner/AutomationHealth/releases.atom` | Sparkle appcast feed URL; CHANGE to actual GitHub repo URL |
| `SUEnableInstallerLauncherService` | `YES` | Sparkle 2 setting; enables XPC service for install-on-quit with privilege separation |
| `LSApplicationCategoryType` | `public.app-category.developer-tools` | App Store category; not strictly required for notarization but good practice |

### Sparkle-Specific Entitlements (NEW)

Sparkle 2 requires one additional entitlement for its XPC service:

| Entitlement | Value | Purpose |
|-------------|-------|---------|
| `com.apple.security.temporary-exception.mach-lookup.global-name` | `$(PRODUCT_BUNDLE_IDENTIFIER)-spks` | Allows Sparkle's XPC service to communicate with the installer; required for install-on-quit updates |

This is added to the app's `entitlements.plist` (NOT to a separate XPC entitlement file — Sparkle 2 bundles its XPC service and inherits the app's entitlements in the standard configuration).

### What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `Sparkle` via CocoaPods or Carthage | Project uses SwiftPM; adding a second package manager creates build complexity | SwiftPM package dependency on `https://github.com/sparkle-project/Sparkle` |
| `Squirrel` (legacy auto-update) | Unmaintained; Sparkle is the standard | Sparkle 2 |
| `altool` for notarization | Deprecated by Apple; slower than `notarytool` | `notarytool` (unchanged from v1.2) |
| `create-dmg` via npm | Adds Node.js to the toolchain unnecessarily | `brew install create-dmg` on the CI runner (Homebrew is pre-installed on `macos-latest`) |
| `.app.zip` distribution instead of `.dmg` | Users expect DMG with drag-to-install; zip is for CLI tools | Signed + notarized `.dmg` |
| Custom Sparkle appcast hosting | Adds infrastructure; GitHub Releases atom feed is built-in and free | GitHub Releases `.atom` appcast — `https://github.com/{owner}/{repo}/releases.atom` |
| DSA/EdDSA private key for Sparkle updates | Sparkle 2 uses EdDSA (ed25519) signatures for update security; keys must be generated and stored as CI secrets | EdDSA signing via `generate_keys` tool (included with Sparkle), stored in `SPARKLE_ED25519_PRIVATE_KEY` GitHub Secret |
| Notarytool `--apple-id` with literal password | Secret leakage in CI logs | `notarytool` with keychain profile stored via `notarytool store-credentials` on the CI runner, or use `--password` from env var with `::add-mask::` |
| `codesign --deep` | Apple DTS explicitly warns against it (same as v1.2) | Explicit per-item signing in correct order |

## Installation

### Swift Package Dependency

```swift
// In Package.swift — add to dependencies array:
.package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0"),

// In the AutomationHealth executable target — add to dependencies array:
.product(name: "Sparkle", package: "Sparkle"),
```

### CI Runner Setup

```bash
# GitHub Actions macos-latest runner pre-installs:
# - Xcode Command Line Tools (codesign, notarytool, stapler, hdiutil)
# - Homebrew
# - Swift (via Xcode)

# One-time CI step to install create-dmg:
brew install create-dmg

# One-time CI step to install Sparkle signing tools:
# (Sparkle's generate_keys and sign_update are bundled in the Sparkle package
#  or can be downloaded from Sparkle releases)
```

### Developer Machine Setup

```bash
# Install create-dmg for local DMG creation:
brew install create-dmg

# Store notarytool credentials (one-time per machine):
xcrun notarytool store-credentials "automationhealth-release" \
    --apple-id "your@email.com" \
    --team-id "YOURTEAMID" \
    --password "@keychain:AC_PASSWORD"

# Generate Sparkle EdDSA signing key pair (one-time, store private key in CI secrets):
# Download Sparkle's generate_keys binary from Sparkle releases,
# or build it from the Sparkle package:
swift run -c release generate_keys
# Output: public key (committed to repo / Info.plist) and private key (stored in CI secret)
```

## Sparkle Integration Pattern

### Option A: Minimal (SPUStandardUpdaterController)

```swift
// In AutomationHealthApp.swift
import Sparkle

@main
struct AutomationHealthApp: App {
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
```

**When to use:** If standard Sparkle UI (preferences window, automatic update checking) is acceptable with no customization needed. This is the recommended starting point for v1.3.

### Option B: Programmatic (SPUUpdater)

For more control over update checking behavior, timing, and custom UI. Only needed if we want to customize the update experience beyond Sparkle's defaults.

```swift
import Sparkle

let updater = SPUUpdater(
    hostBundle: Bundle.main,
    applicationBundle: Bundle.main,
    userDriver: CustomUserDriver(),  // Optional custom UI
    delegate: CustomUpdaterDelegate() // Optional delegation
)
try updater.start()
```

**When to use:** If we want to defer the first update check, show custom update UI, or integrate update status into the app's own UI rather than Sparkle's standard window. NOT needed for v1.3 MVP — stick with Option A.

### Sparkle Info.plist Keys

Add to `Info.plist` (currently generated in `script/build_and_run.sh`):

```xml
<key>SUFeedURL</key>
<string>https://github.com/{OWNER}/AutomationHealth/releases.atom</string>
<key>SUEnableInstallerLauncherService</key>
<true/>
<key>SUPublicEDKey</key>
<string><!-- EdDSA public key from generate_keys output --></string>
```

### Sparkle + GitHub Releases Appcast

Sparkle 2 natively supports GitHub Releases atom feeds. The `SUFeedURL` points to:
```
https://github.com/{owner}/{repo}/releases.atom
```

This means:
- No separate appcast.xml hosting needed
- GitHub Release automatically becomes the update source
- Each GitHub Release with a `.dmg` asset becomes a Sparkle update candidate
- Sparkle requires the `sparkle:version` and `sparkle:shortVersionString` XML namespaces in the appcast, which GitHub's atom feed provides via release metadata

**Important:** Sparkle needs the `.dmg` asset to be accompanied by an EdDSA signature. The release pipeline must:
1. Generate EdDSA signature of the DMG using `sign_update` tool
2. Include the signature in the GitHub Release (as `sparkle:edSignature` in the appcast or as a `.sig` file)
3. For GitHub Releases appcast, Sparkle uses the release body/description to find signature metadata, OR the signature is embedded via the `Sparkle-Appcast.xml` approach.

**Simplest approach for v1.3:** Use Sparkle's `generate_appcast` tool (included in Sparkle distribution) to generate an `appcast.xml` from a directory of release archives, then upload that appcast to a GitHub Pages branch (`gh-pages`). This is more reliable than the raw GitHub atom feed and is the recommended approach in Sparkle 2 documentation. However, the atom feed approach works for getting started and should be tried first.

## GitHub Actions Release Workflow

### release.yml Structure

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'        # Trigger on version tags: v1.3.0, v1.3.1, etc.
  workflow_dispatch:  # Manual trigger for testing

permissions:
  contents: write    # Needed for creating releases

jobs:
  build-and-release:
    name: Build, sign, notarize, and release
    runs-on: macos-latest
    timeout-minutes: 45
    env:
      TZ: Europe/Berlin
      APP_NAME: AutomationHealth
      BUNDLE_ID: org.automationhealth.AutomationHealth
    
    steps:
      # 1. Checkout
      - uses: actions/checkout@v4
      
      # 2. Setup: install create-dmg
      - name: Install create-dmg
        run: brew install create-dmg
      
      # 3. Setup: import Developer ID certificate
      - name: Import signing certificate
        env:
          CERTIFICATE_BASE64: ${{ secrets.DEVELOPER_ID_CERTIFICATE_BASE64 }}
          CERTIFICATE_PASSWORD: ${{ secrets.DEVELOPER_ID_CERTIFICATE_PASSWORD }}
        run: |
          # Create temporary keychain
          KEYCHAIN_PATH=$(mktemp -d)/app-signing.keychain-db
          security create-keychain -p "" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "" "$KEYCHAIN_PATH"
          # Import certificate
          echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
          security import certificate.p12 -k "$KEYCHAIN_PATH" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
          security list-keychains -d user -s "$KEYCHAIN_PATH" $(security list-keychains -d user | sed 's/["]//g')
          security set-key-partition-list -S apple-tool:,apple: -s -k "" "$KEYCHAIN_PATH"
          rm certificate.p12
      
      # 4. Build with SwiftPM
      - name: Build
        run: swift build -c release
      
      # 5. Create .app bundle
      - name: Create app bundle
        run: |
          BUILD_BINARY=$(swift build -c release --show-bin-path)/$APP_NAME
          DIST_DIR="dist/$APP_NAME.app"
          mkdir -p "$DIST_DIR/Contents/MacOS" "$DIST_DIR/Contents/Resources"
          cp "$BUILD_BINARY" "$DIST_DIR/Contents/MacOS/$APP_NAME"
          cp "Assets/AppIcon/$APP_NAME.icns" "$DIST_DIR/Contents/Resources/$APP_NAME.icns"
          # Generate Info.plist with Sparkle keys
          # (same as build_and_run.sh but with added CFBundleVersion, SUFeedURL, etc.)
      
      # 6. Generate app icon (if needed)
      # (same as build_and_run.sh icon check)
      
      # 7. Codesign .app
      - name: Codesign app
        run: |
          codesign --sign "Developer ID Application" \
                   --timestamp --options runtime \
                   --entitlements entitlements.plist \
                   --force "dist/$APP_NAME.app"
          codesign --verify --deep --strict --verbose=2 "dist/$APP_NAME.app"
      
      # 8. Create polished DMG
      - name: Create DMG
        run: |
          create-dmg \
            --volname "Automation Health" \
            --volicon "Assets/AppIcon/$APP_NAME.icns" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "$APP_NAME.app" 175 120 \
            --hide-extension "$APP_NAME.app" \
            --app-drop-link 425 120 \
            "dist/AutomationHealth-${{ github.ref_name }}.dmg" \
            "dist/"
      
      # 9. Codesign DMG
      - name: Codesign DMG
        run: |
          codesign --sign "Developer ID Application" \
                   --timestamp \
                   "dist/AutomationHealth-${{ github.ref_name }}.dmg"
      
      # 10. Notarize DMG
      - name: Notarize DMG
        env:
          NOTARY_APPLE_ID: ${{ secrets.NOTARYTOOL_APPLE_ID }}
          NOTARY_TEAM_ID: ${{ secrets.NOTARYTOOL_TEAM_ID }}
          NOTARY_PASSWORD: ${{ secrets.NOTARYTOOL_PASSWORD }}
        run: |
          echo "::add-mask::$NOTARY_PASSWORD"
          xcrun notarytool submit "dist/AutomationHealth-${{ github.ref_name }}.dmg" \
            --apple-id "$NOTARY_APPLE_ID" \
            --team-id "$NOTARY_TEAM_ID" \
            --password "$NOTARY_PASSWORD" \
            --wait
      
      # 11. Staple notarization ticket
      - name: Staple ticket
        run: |
          xcrun stapler staple "dist/AutomationHealth-${{ github.ref_name }}.dmg"
          spctl --assess -vv --type install "dist/AutomationHealth-${{ github.ref_name }}.dmg"
      
      # 12. Generate Sparkle EdDSA signature
      - name: Sign update for Sparkle
        env:
          SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_ED25519_PRIVATE_KEY }}
        run: |
          # Download sign_update from Sparkle releases if not bundled
          # Or use the Sparkle package's sign_update tool
          echo "$SPARKLE_PRIVATE_KEY" > sparkle_private_key.pem
          # sign_update requires the Sparkle tools
          # Alternative: use generate_appcast approach
      
      # 13. Create GitHub Release with DMG
      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          name: "Automation Health ${{ github.ref_name }}"
          body: "Release notes for ${{ github.ref_name }}"
          files: |
            dist/AutomationHealth-${{ github.ref_name }}.dmg
          generate_release_notes: true
      
      # 14. Cleanup: remove temporary keychain
      - name: Cleanup keychain
        if: always()
        run: |
          security delete-keychain "$KEYCHAIN_PATH" || true
```

### GitHub Secrets Required

| Secret Name | Content | How to Create |
|-------------|---------|---------------|
| `DEVELOPER_ID_CERTIFICATE_BASE64` | Base64-encoded `.p12` certificate file | `base64 -i developer_id.p12 | pbcopy` then paste into GitHub Secrets |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | Password for the `.p12` certificate | The password set when exporting the certificate from Keychain Access |
| `NOTARYTOOL_APPLE_ID` | Apple ID email for notarization | The Apple ID associated with the Developer Program membership |
| `NOTARYTOOL_TEAM_ID` | Apple Developer Team ID | Found at https://developer.apple.com/account under Membership |
| `NOTARYTOOL_PASSWORD` | App-specific password for Apple ID | Created at https://appleid.apple.com → App-Specific Passwords |
| `SPARKLE_ED25519_PRIVATE_KEY` | EdDSA (ed25519) private key for Sparkle | Generated by Sparkle's `generate_keys` tool; base64-encoded |

## Integration Points with Existing Codebase

| Existing Component | Change | Impact |
|-------------------|--------|--------|
| `Package.swift` | ADD Sparkle package dependency + target dependency | First external dependency; add `.package(url:from:)` and `.product(name:package:)` |
| `Sources/AutomationHealth/App/AutomationHealthApp.swift` | ADD `import Sparkle` + `SPUStandardUpdaterController` init + `CheckForUpdatesView` in commands | ~15 lines added; no existing code modified |
| `script/build_and_run.sh` | ADD `CFBundleVersion`, `CFBundleShortVersionString`, `SUFeedURL`, `SUPublicEDKey` to generated `Info.plist` | ~10 lines added to the PLIST heredoc |
| `entitlements.plist` | ADD `com.apple.security.temporary-exception.mach-lookup.global-name` for Sparkle XPC | 1 new entitlement entry |
| `.github/workflows/ci.yml` | Unchanged | Existing CI stays as-is |
| `.github/workflows/release.yml` | NEW file | ~120 lines; fully additive |
| `Makefile` | ADD `make release-dry-run` target | One new target for local release testing |
| Repository root | ADD `Assets/DMG/` directory with background image | Small PNG file; optional polish |

## Sparkle Appcast Strategy

**Recommended for v1.3: GitHub Releases `.atom` feed.**

Sparkle 2 supports appcast feeds in both XML (legacy) and JSON (modern) formats. For GitHub-hosted projects, the simplest approach is:

1. **Use GitHub Releases atom feed:** `https://github.com/{owner}/AutomationHealth/releases.atom`
2. **GitHub Release assets become update candidates:** Each release with a `.dmg` tagged `v1.3.0`, `v1.3.1`, etc.
3. **Sparkle extracts version from `CFBundleShortVersionString` and `CFBundleVersion`** in the app's `Info.plist` within the DMG
4. **EdDSA signature** embeds in the release via `sparkle:edSignature` in the appcast entry

**Fallback if atom feed has issues:** Generate a static `appcast.xml` using Sparkle's `generate_appcast` tool and host it on GitHub Pages. More work but fully deterministic.

## Version Compatibility

| Component | Minimum macOS Version | Notes |
|-----------|----------------------|-------|
| Sparkle 2 | macOS 10.13+ | Well within app's macOS 14+ target |
| `SPUStandardUpdaterController` | Sparkle 2.0+ | Available in all Sparkle 2.x releases |
| `create-dmg` | macOS 10.14+ | CI-only; runs on `macos-latest` (macOS 15+) |
| GitHub Actions `macos-latest` | macOS 15 (ARM) | Apple silicon; `swift build` natively compiles for ARM |
| `notarytool` | macOS 11+ (Xcode 13+) | Available on `macos-latest` runner |
| `softprops/action-gh-release` | All runner OS | Community action; widely used; v2 is current |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Auto-update | Sparkle 2 (SwiftPM) | Manual update check (v1.2 approach) | Users expect auto-update for macOS apps outside App Store; Sparkle is the standard |
| Auto-update | Sparkle 2 | Squirrel | Unmaintained; Sparkle has far broader adoption |
| DMG creation | `create-dmg` (Brew) | Raw `hdiutil` (v1.2 recommendation) | `create-dmg` produces polished DMG with Applications alias; `hdiutil` alone produces bare disk image; UX difference justifies one Brew dependency on CI |
| DMG creation | `create-dmg` | `node-appdmg` (npm) | Adds Node.js dependency; `create-dmg` via Brew is simpler |
| Release action | `softprops/action-gh-release@v2` | `gh release create` CLI | Action handles token management, asset upload with retries, release notes generation; `gh` CLI requires additional setup |
| Release action | `softprops/action-gh-release@v2` | `actions/create-release` (archived) | GitHub archived `create-release` action; `softprops/action-gh-release` is the community-standard replacement |
| Sparkle feed | GitHub Releases atom feed | Static appcast.xml on GitHub Pages | Atom feed is zero-infrastructure; appcast.xml is more reliable but requires extra CI steps |
| Sparkle feed | GitHub Releases atom feed | Custom server (`sparkle:appcast`) | Unnecessary infrastructure; GitHub Releases is free and already the release host |

## What Changed from v1.2 Research

| v1.2 Decision | v1.3 Change | Reason |
|---------------|-------------|--------|
| "Rely on GitHub Releases + manual download" for updates | Add Sparkle 2 auto-update | Auto-update is now P1 for v1.3; users expect it |
| "No new Swift dependencies" constraint | Sparkle is first external dependency | Auto-update requires a framework; Sparkle is the standard |
| Raw `hdiutil` for DMG creation | `create-dmg` supplement for polished DMG | UX matters for a downloadable app; drag-to-install is expected |
| Local-only signing scripts | GitHub Actions release pipeline | CI automation is a v1.3 requirement (DIST-07) |
| Manual GitHub Release creation | `softprops/action-gh-release` automation | Consistent with CI automation requirement |

## Confidence Assessment

| Component | Confidence | Notes |
|-----------|------------|-------|
| Sparkle 2 SwiftPM integration | MEDIUM | Training data covers Sparkle 2.x SwiftPM support confirmed since 2021; exact API surface (`SPUStandardUpdaterController`, `SPUUpdater`) confirmed via broad ecosystem knowledge. Specific `SUFeedURL` key name may vary — verify against Sparkle 2 docs during implementation. LOW confidence on exact `sign_update` tool path and `generate_keys` availability in the SwiftPM package vs separate download. |
| `create-dmg` | MEDIUM | Well-known Homebrew package; the `--volicon`, `--app-drop-link` flags are standard. Exact flag behavior should be verified against `create-dmg --help` during implementation. |
| `softprops/action-gh-release@v2` | MEDIUM | Widely used community action; v2 is the current major version. Verify v2 API (it changed significantly from v1) during implementation. |
| GitHub Actions `macos-latest` | HIGH | GitHub's runner images are well-documented; macOS runner includes Xcode CLT, Homebrew, Swift. |
| `codesign`, `notarytool`, `stapler` | HIGH | Unchanged from v1.2 research (which was HIGH confidence); confirmed via Apple documentation. |
| Sparkle `generate_keys` / signing flow | LOW | Training data may be stale on exact tooling; Sparkle 2 signing tool names (`generate_keys`, `sign_update`, `generate_appcast`) need verification against current Sparkle 2.x release docs. |
| GitHub Releases atom feed for Sparkle | MEDIUM | Known pattern (Sparkle supports it); but exact `sparkle:edSignature` embedding mechanism for atom feeds may require adjustment. Appcast.xml via GitHub Pages is the more reliable fallback. |
| `com.apple.security.temporary-exception.mach-lookup.global-name` | MEDIUM | This entitlement is documented in Sparkle 2 setup guides; exact value (`$(PRODUCT_BUNDLE_IDENTIFIER)-spks`) needs verification. May need to be the literal bundle ID rather than the variable. |

## Sources

- Training data (Claude, knowledge cutoff early 2025) — Sparkle 2 architecture, SwiftPM integration, SPUStandardUpdaterController, SPUUpdater, EdDSA signing — LOW confidence (stale, unverified against current docs)
- Existing project codebase — `Package.swift`, `script/build_and_run.sh`, `.github/workflows/ci.yml`, `.planning/research/STACK.md` (v1.2), `.planning/research/PITFALLS.md` (v1.2) — HIGH confidence (direct file reads)
- `.planning/PROJECT.md` — DIST-01 through DIST-08 requirements, Out of Scope constraints — HIGH confidence
- Apple Developer Documentation (v1.2 research) — codesign, notarytool, stapler, hardened runtime — HIGH confidence (verified via Context7 in v1.2 research)
- GitHub Actions documentation (v1.2 research) — `macos-latest` runner, secrets, `actions/checkout` — MEDIUM confidence (from v1.2 research, not re-verified)

**This STACK.md should be treated as a starting point. The LOW confidence items (Sparkle signing tooling, exact entitlement values, `create-dmg` flag behavior) MUST be verified during phase planning against current Sparkle 2 documentation and `create-dmg` help output.**

---

*Stack research for: v1.3 Shippable Distribution*
*Researched: 2026-05-12*
*Confidence: MEDIUM — Sparkle integration details need verification against current docs; signing/notarization stack is HIGH confidence (unchanged from v1.2)*
