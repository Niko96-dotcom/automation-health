# Domain Pitfalls — v1.3 Shippable Distribution

**Domain:** macOS SwiftUI app — adding codesigning, notarization, DMG packaging, CI-based notarization, and Sparkle auto-update to an existing unsigned SwiftPM build
**Researched:** 2026-05-12
**Confidence:** HIGH

## Context

Automation Health is a brownfield macOS SwiftUI app with these relevant characteristics for distribution work:

- **Build:** Pure SwiftPM (`swift build`), no Xcode project
- **Signing:** Currently entirely unsigned (`script/build_and_run.sh` assembles a minimal unsigned `.app`)
- **Dependencies:** Zero external Swift package dependencies
- **Network:** No network layer (no `URLSession`, no HTTP client)
- **Functionality:** Read-only filesystem scanning that calls `/bin/launchctl` via `Process`
- **Target:** macOS 14+

The distribution pitfalls below are scoped to **adding** codesigning, notarization, DMG, CI, and Sparkle to this specific starting point. General macOS distribution pitfalls are included only when they interact with the brownfield nature of this project.

---

## Critical Pitfalls

Mistakes that cause rewrites, certificate revocation, or undownloadable releases.

### Pitfall 1: SwiftPM Dynamic Swift Runtime Linking Blocks Notarization

**What goes wrong:**
The notarization service rejects the signed `.app` with "The binary is not signed" or "invalid signature" because the binary links against unsigned Swift runtime dylibs in `/usr/lib/swift`. `swift build` (Release configuration) produces a dynamically-linked executable by default. The `otool -L` output shows `@rpath/libswiftCore.dylib` (and friends), which exist only on the build machine. On the notarization service, these unsigned library references cause rejection.

**Why it happens:**
SwiftPM's default build mode on macOS dynamically links the Swift standard library and runtime. These libraries are present on the build machine (via Xcode CLT) but are not embedded in the app bundle. Apple's notarization service scans every linked library — unsigned or missing library references cause "invalid signature" errors even when the main binary is correctly signed.

**Consequences:**
Notarization fails with opaque error logs. Hours wasted trying different signing flags and entitlements when the root cause is linking. First-time notarization of a SwiftPM app is the most common place this bites.

**How to avoid:**
Two approaches, in order of preference:

1. **Static linking (recommended for this project):** Add `-Xswiftc -static-executable` to `swift build` flags. This links the Swift runtime statically into the binary. The resulting binary is 10-20 MB larger but has zero external Swift dependencies. This is the simpler path for a command-line-style app bundled into an `.app`.

```bash
swift build -c release -Xswiftc -static-executable
```

2. **Runtime embedding (fallback):** Copy the Swift runtime dylibs from the toolchain into the app bundle's `Contents/Frameworks/` directory, then code-sign them before signing the main binary. This is more complex and error-prone; Apple's own documentation recommends static linking for non-Xcode builds.

**Verification:**
```bash
# After build, verify no Swift dylib references:
otool -L AutomationHealth.app/Contents/MacOS/AutomationHealth | grep swift
# Should produce NO output for a static build
```

**Detection:**
- `notarytool log <submission-id>` shows "The binary is not signed" but `codesign -vvv` on the binary passes locally
- `otool -L` on the binary shows `@rpath/libswift*.dylib` entries
- Binary is suspiciously small (<5 MB for Release build)

**Phase to address:** First codesigning attempt (Phase 13). Must verify linking before first notarization submission.

---

### Pitfall 2: Hardened Runtime Blocks `launchctl` Subprocess Execution

**What goes wrong:**
After signing with `codesign -o runtime` (Hardened Runtime), the app launches and runs fine until it tries to invoke `/bin/launchctl` via `Process`. The `Process` execution silently returns empty or error output. No crash, no diagnostic — just zero results from the launchd scanner. The UI shows "No runtime state" or empty job lists for launchd sources.

**Why it happens:**
Hardened Runtime restricts `fork()`/`exec()` by default. While `Process` (NSTask) is generally allowed under Hardened Runtime for helper tools, execution of binaries outside the app bundle is subject to additional restrictions. More critically, `Process` inherits the hardened runtime of the parent process. The `/bin/launchctl` binary runs with the app's hardened runtime restrictions, which can interfere with its ability to read system state.

The actual behavior depends on macOS version and the specific `launchctl` subcommands used. `launchctl print` may work in some configurations but fail silently in others. The inconsistency is what makes this pitfall dangerous — it might work on the developer's machine but fail on a user's Mac.

**How to avoid:**
1. **Critical:** Test the signed Release binary's `launchctl` scanning on a **different Mac** (not the development machine) to surface environmental differences
2. If `launchctl print` fails under Hardened Runtime, add `com.apple.security.cs.disable-executable-page-protection` to entitlements (this is unlikely to be needed but is the standard escape hatch for process execution)
3. **DO NOT** add `com.apple.security.get-task-allow` — this is for debug builds only and blocks notarization in distribution
4. Add a self-test that invokes `LaunchAgentScanner` from the signed Release binary and verifies it returns expected job data (can use synthetic fixtures if no real launchd jobs exist on CI)
5. Document which specific `launchctl` subcommands are used and test each

**Detection:**
- Self-test passes in Debug/unsigned build but launchd-dependent tests return zero jobs in signed Release
- No error output — just empty results
- The app appears to work but launchd-sourced jobs vanish

**Phase to address:** Codesigning phase (Phase 13). Must verify `launchctl` subprocess works on the signed binary before proceeding to notarization.

---

### Pitfall 3: Incomplete Info.plist Causes Notarization Rejection

**What goes wrong:**
The hand-assembled `Info.plist` in `script/build_and_run.sh` has only minimal keys (`CFBundleName`, `CFBundleIdentifier`, `CFBundleExecutable`, `CFBundlePackageType`, `CFBundleIconFile`). Notarization requires additional keys: `CFBundleVersion`, `CFBundleShortVersionString`, `NSHumanReadableCopyright`, and `LSApplicationCategoryType`. Missing any of these causes instant notarization rejection with "invalid Info.plist."

**Why it happens:**
The current `script/build_and_run.sh` creates a minimal `Info.plist` sufficient for `open` to launch the app. Notarization enforces Apple's bundle structure requirements more strictly than local launch. The app was built for local development, not distribution.

**How to avoid:**
Create a proper `Info.plist` with all required keys. The recommended template:

```xml
<key>CFBundleName</key>
<string>Automation Health</string>
<key>CFBundleIdentifier</key>
<string>org.automationhealth.AutomationHealth</string>
<key>CFBundleExecutable</key>
<string>AutomationHealth</string>
<key>CFBundlePackageType</key>
<string>APPL</string>
<key>CFBundleIconFile</key>
<string>AppIcon</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.3.0</string>
<key>LSMinimumSystemVersion</key>
<string>14.0</string>
<key>NSHumanReadableCopyright</key>
<string>Copyright (c) 2026 Automation Health contributors. MIT License.</string>
<key>LSApplicationCategoryType</key>
<string>public.app-category.developer-tools</string>
```

For CI: derive `CFBundleShortVersionString` and `CFBundleVersion` from the git tag or `VERSION` file so they are not manually maintained.

**Detection:**
- `notarytool submit` returns validation errors mentioning "CFBundleVersion" or "CFBundleShortVersionString"
- `plutil -lint AutomationHealth.app/Contents/Info.plist` shows warnings on the minimal plist
- `notarytool log <id>` shows "The Info.plist is missing required keys"

**Phase to address:** Notarization recipe (Phase 13). Must validate Info.plist before first notarization submission.

---

### Pitfall 4: DMG Creation Destroys Code Signature (Ordering and Cleanliness)

**What goes wrong:**
The signed `.app` is copied into a DMG, but the resulting extracted `.app` fails `codesign -vvv` with "code object is not signed at all." Users who download the DMG and attempt to launch see a "damaged" warning from Gatekeeper.

**Why it happens (three distinct causes):**

1. **Opening the signed app before DMG creation:** Finder writes `.DS_Store`, extended attributes (`com.apple.quarantine`), or Spotlight metadata into the `.app` bundle when it's opened/mounted. These files are unsigned and invalidate the bundle's signature. The most common scenario: developer signs the app, double-clicks to test it works, then creates the DMG.

2. **Using `hdiutil create -srcfolder` on a directory with Finder artifacts:** Even without opening the app, if the source directory was previously opened in Finder, `.DS_Store` files can exist in subdirectories.

3. **Not signing the DMG itself:** `codesign` on the `.app` does not sign the DMG container. Gatekeeper checks the DMG signature. An unsigned DMG containing a signed app still triggers warnings.

**How to avoid:**
1. **Build fresh for release — every time.** The release script must start from a clean build, sign, and immediately feed the signed `.app` into DMG creation without any intermediate steps.
2. **Never open or mount the signed app before DMG creation.** Trust the build pipeline, test later from the DMG.
3. **Sign the `.app` as the last step before DMG creation.**
4. **Create DMG from a clean directory:**
```bash
# Clean workspace
rm -rf dist/signed
mkdir -p dist/signed

# Copy signed app into clean directory
cp -R dist/AutomationHealth.app dist/signed/

# Create and sign DMG
hdiutil create -volname "Automation Health" \
    -srcfolder dist/signed \
    -ov -format UDZO \
    dist/AutomationHealth-1.3.0.dmg

# Sign the DMG with Developer ID Application certificate
codesign --sign "Developer ID Application: ..." \
    --timestamp \
    dist/AutomationHealth-1.3.0.dmg
```
5. **Notarize the DMG, not the .app.** Apple requires a container (`dmg`, `pkg`, `zip`) for notarization.
6. **Staple the notarization ticket to the DMG after approval:**
```bash
xcrun stapler staple dist/AutomationHealth-1.3.0.dmg
```
7. **Verify the DMG:**
```bash
spctl --assess -vv --type install dist/AutomationHealth-1.3.0.dmg
```

**Detection:**
- `codesign -vvv dist/AutomationHealth.app` passes, but extracting the app from DMG and running `codesign -vvv` fails
- `ls -la dist/signed/AutomationHealth.app/Contents/` shows `.DS_Store` files
- Finder shows "Automation Health.app is damaged" when opening downloaded DMG
- DMG itself has no code signature: `codesign -dvvv dist/*.dmg` returns "not signed"

**Phase to address:** DMG packaging (Phase 13). Must verify signature survives extraction before publishing.

---

### Pitfall 5: Developer ID Secret Leakage in CI Logs or Committed Scripts

**What goes wrong:**
The Developer ID certificate (`.p12` base64), its import password, the Apple ID app-specific password for `notarytool`, and the Team ID are committed to the repository, logged in CI output, or written into CI workflow YAML as plaintext. Anyone with read access to the repo or CI logs can extract these credentials and sign malware with the project's Developer ID.

**Why it happens:**
The most direct path to a working release script involves hardcoding credential paths or values. `set -x` in bash scripts prints every command including `--password` arguments. GitHub Actions `echo` steps with secrets produce log output. The CI workflow YAML itself is committed and visible — any literal secret in it is public. Even temporary keychain passwords used in CI become visible if `security unlock-keychain -p $PASSWORD` runs under `set -x`.

**Consequences:**
Apple revokes the Developer ID certificate upon detecting misuse. The certificate revocation is permanent — a new certificate must be issued, but the old one remains revoked. All previously-signed releases become invalid because the certificate chain is broken. Users who downloaded previous releases see "damaged" warnings. The distribution pipeline is dead until a new certificate is provisioned and all releases are re-signed.

**How to avoid:**
1. **Store ALL secrets in GitHub Actions encrypted secrets:**
   - `DEVELOPER_ID_CERTIFICATE_BASE64` — the `.p12` file base64-encoded
   - `DEVELOPER_ID_CERTIFICATE_PASSWORD` — the password used to export the `.p12`
   - `NOTARYTOOL_APPLE_ID` — Apple ID email
   - `NOTARYTOOL_TEAM_ID` — Team ID (not secret in itself but combine with password)
   - `NOTARYTOOL_PASSWORD` — app-specific password (generated at appleid.apple.com)

2. **Use ephemeral keychain in CI:**
```yaml
- name: Setup signing
  env:
    CERT_BASE64: ${{ secrets.DEVELOPER_ID_CERTIFICATE_BASE64 }}
    CERT_PASSWORD: ${{ secrets.DEVELOPER_ID_CERTIFICATE_PASSWORD }}
  run: |
    # Create temporary keychain
    KEYCHAIN_PATH=$(mktemp -d)/Signing.keychain
    KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    
    # Import certificate
    echo "$CERT_BASE64" | base64 --decode > cert.p12
    security import cert.p12 -k "$KEYCHAIN_PATH" -P "$CERT_PASSWORD" -A -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    
    # Set as default keychain for this step
    security list-keychains -d user -s "$KEYCHAIN_PATH"
    rm cert.p12
```

3. **Mask secrets in CI output:**
```yaml
- name: Notarize
  run: |
    echo "::add-mask::${{ secrets.NOTARYTOOL_PASSWORD }}"
    xcrun notarytool submit dist/*.dmg \
      --apple-id "${{ secrets.NOTARYTOOL_APPLE_ID }}" \
      --team-id "${{ secrets.NOTARYTOOL_TEAM_ID }}" \
      --password "${{ secrets.NOTARYTOOL_PASSWORD }}" \
      --wait
```

4. **Never use `set -x` in release scripts that touch secrets.**
5. **Committed release scripts use placeholder environment variables:** `$DEVELOPER_ID`, `$NOTARYTOOL_KEYCHAIN_PROFILE` — never literal values.
6. **Delete the ephemeral keychain at the end of the CI job:**
```yaml
- name: Cleanup
  if: always()
  run: |
    security delete-keychain "$KEYCHAIN_PATH" || true
    rm -f cert.p12
```

**Detection:**
- Any committed file containing `--password` with a literal string value
- CI workflow YAML lacking `secrets: inherit` or explicit `${{ secrets.* }}` references
- `security import` or `security unlock-keychain` with literal passwords
- GitHub Actions logs showing certificate common names, keychain paths, or password artifacts
- `git grep` on the repository for `p12`, `certificate`, `DEVELOPER_ID`, or `app-specific` that resolves to actual values

**Phase to address:** Release process documentation and CI pipeline (Phases 13-14). Secrets handling is a cross-cutting CI concern that must be designed before the first CI release run.

---

### Pitfall 6: Sparkle `SUFeedURL` Must Be HTTPS — Plain HTTP Blocks Update Checks

**What goes wrong:**
Sparkle's `SUFeedURL` in `Info.plist` is set to a GitHub Releases appcast URL using `http://` (or a self-hosted non-HTTPS URL). On macOS 10.13+, App Transport Security (ATS) blocks non-HTTPS connections by default. Sparkle's update check fails silently — the `SUUpdater` receives a network error and treats it as "no update available." Users never see an update prompt and the app remains outdated.

**Why it happens:**
GitHub Pages and GitHub Releases both serve content over HTTPS by default, but custom appcast hosting, local mirrors, or test environments may use HTTP. The developer tests update checks on their local network (where HTTP might work or ATS exceptions exist) and doesn't notice the HTTPS requirement. More commonly: the `SUFeedURL` value is set before the final release URL is known and the placeholder `http://localhost:8080/appcast.xml` is accidentally committed.

**How to avoid:**
1. **Always use HTTPS for `SUFeedURL`.** GitHub Releases serves assets over `https://github.com/OWNER/REPO/releases/`, and the appcast XML generated by Sparkle's `generate_appcast` tool should be hosted at an HTTPS URL.
2. **For Sparkle with GitHub Releases:** Use the `sparkle:version` and `sparkle:shortVersionString` elements in the release description, or use `generate_appcast` against a local directory listing of releases and host the resulting `appcast.xml` at an HTTPS URL (e.g., GitHub Pages on the `gh-pages` branch).
3. **Verify ATS compliance:**
```bash
# Check if the URL is HTTPS
echo "$SUFeedURL" | grep -q '^https://' || echo "WARNING: SUFeedURL must use HTTPS"
```

**Detection:**
- Sparkle update check runs but never finds updates even after a new GitHub Release is published
- Console.app shows ATS blocking errors for Sparkle domain (filter for "ATS" or "App Transport Security")
- `SUFeedURL` in `Info.plist` starts with `http://`

**Phase to address:** Sparkle integration (Phase 14). Must verify HTTPS feed URL before first release that enables Sparkle.

---

### Pitfall 7: Sparkle EdDSA Signing Key Generation and Storage — Key Loss Breaks All Future Updates

**What goes wrong:**
Sparkle 2 uses EdDSA (Ed25519) cryptographic signatures for update security. The private key is generated once (`generate_keys`) and must be kept secure forever. If the private key is lost, regenerated, or committed to the repository without protection, every subsequent release after the key change fails update verification — users are stuck on the last release signed with the old key, unable to auto-update.

**Why it happens:**
The `generate_keys` tool creates a key pair. The public key goes into the app's `Info.plist` (`SUPublicEDKey`). The private key is used to sign each release's appcast entry. If the developer treats the private key as a per-release artifact (generating a new one each release) or loses it during machine migration, all future updates break for existing installations. If the private key is committed to the repository, anyone can sign malicious updates that Sparkle will accept.

**How to avoid:**
1. **Generate keys exactly once:**
```bash
# Store keys in a secure location, NOT in the repo
mkdir -p ~/.automatiohealth-release-keys
./Sparkle/bin/generate_keys -p ~/.automatiohealth-release-keys/sparkle_private.pem
```
This outputs the public key to stdout — copy it into `Info.plist`.

2. **Store the private key as a GitHub Actions secret:**
   - `SPARKLE_PRIVATE_KEY` — the entire contents of the `.pem` file
   - Never commit this file to the repository (add `*_private.pem` to `.gitignore`)

3. **Document key recovery in a secure location** (not public docs): Where the key is stored, how to rotate if compromised, and that loss is catastrophic.

4. **In CI, the private key is written to a temporary file for signing, then destroyed:**
```yaml
- name: Sign appcast
  run: |
    echo "${{ secrets.SPARKLE_PRIVATE_KEY }}" > /tmp/sparkle_private.pem
    ./Sparkle/bin/sign_update <binary> -s /tmp/sparkle_private.pem
    rm /tmp/sparkle_private.pem
```

**Detection:**
- Private key file appears in `git status` or working tree
- `git grep` finds `"ed25519"` or `"PRIVATE KEY"` strings in committed files
- CI secret `SPARKLE_PRIVATE_KEY` is not configured
- New releases fail update verification with "The update is improperly signed"

**Phase to address:** Sparkle integration (Phase 14). Key generation must happen before the first Sparkle-enabled release.

---

### Pitfall 8: Sparkle Framework Bundling with SwiftPM — No Xcode Project Means Manual Framework Packaging

**What goes wrong:**
Sparkle's standard integration path assumes an Xcode project — SPM package dependency, copy-frameworks build phase, etc. With a pure SwiftPM build (no Xcode project), there is no build phase to copy Sparkle's frameworks into the app bundle. Even if Sparkle is added as an SPM dependency, the framework/XPC services are not automatically placed in `Contents/Frameworks/` and `Contents/XPCServices/`.

**Why it happens:**
Sparkle is not a pure Swift library — it includes:
- `Sparkle.framework` — the main framework with `SUUpdater`
- `Sparkle.framework/XPCServices/Installer.xpc` — for handling updates
- `Sparkle.framework/XPCServices/Downloader.xpc` — for downloading updates
- `Autoupdate` — the privilege-separation helper

These must be physically present in the app bundle at specific paths with correct code signing. SwiftPM can download Sparkle but does not handle framework embedding. A Mac app built via `swift build` has no `Copy Files` build phase.

**How to avoid:**
1. **Download Sparkle as a pre-built framework** (not an SPM dependency):
```bash
curl -L -o Sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.6.4/Sparkle-2.6.4.tar.xz
tar -xf Sparkle.tar.xz
```

2. **Copy the framework into the app bundle manually:**
```bash
# After swift build, before signing:
mkdir -p dist/AutomationHealth.app/Contents/Frameworks
cp -R Sparkle.framework dist/AutomationHealth.app/Contents/Frameworks/

# Sign the framework BEFORE signing the app (inside-out signing order):
codesign --sign "Developer ID Application: ..." \
    --timestamp --options runtime \
    --deep dist/AutomationHealth.app/Contents/Frameworks/Sparkle.framework

# Then sign the .app bundle
codesign --sign "Developer ID Application: ..." \
    --timestamp --options runtime \
    dist/AutomationHealth.app
```

3. **Add Sparkle to the binary's load commands** (if using Sparkle programmatically):
   - For a SwiftPM executable, link Sparkle by adding it as a linker flag: `-Xlinker -F/path/to/Sparkle.framework -Xlinker -framework -Xlinker Sparkle`
   - Or: Add Sparkle as a `.binaryTarget` in `Package.swift` (requires Sparkle to be distributed as an `.xcframework`)

4. **Alternative — use Sparkle's command-line interface:** Sparkle 2 supports a mode where `SUUpdater` is driven entirely through Info.plist keys and requires minimal code integration. This is the recommended path for this project:
   - Set `SUEnableAutomaticChecks = YES` in Info.plist
   - Set `SUFeedURL` in Info.plist
   - No Swift import of Sparkle needed
   - Framework still must be bundled

**Detection:**
- App launches but Sparkle update check never fires
- Console.app shows `dyld: Library not loaded: @rpath/Sparkle.framework`
- `ls -R AutomationHealth.app/Contents/Frameworks/` shows no Sparkle.framework
- XPC errors about missing Downloader or Installer services

**Phase to address:** Sparkle integration (Phase 14). Framework bundling must be decided before implementing Sparkle update logic.

---

### Pitfall 9: Sparkle Hardened Runtime Entitlement for XPC Services

**What goes wrong:**
Sparkle's XPC services (`Installer.xpc`, `Downloader.xpc`) execute as separate processes under the app's Hardened Runtime. Without the correct entitlement exceptions, these XPC services fail to launch or communicate. The app launches fine but Sparkle silently cannot download or install updates. Users see "Update available" but clicking "Install" does nothing, or downloads fail with no error.

**Why it happens:**
Under Hardened Runtime, XPC services and their communication with the main app are restricted. Sparkle requires specific entitlements to function:
- The `Installer.xpc` needs to replace the app bundle on disk
- The `Downloader.xpc` needs network access to download updates
- XPC communication between the main app and these services requires file access and process execution entitlements

**How to avoid:**
The minimum entitlements for Sparkle under Hardened Runtime (in addition to any app-specific entitlements):

```xml
<key>com.apple.security.cs.disable-library-validation</key>
<true/>
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>
```

**DO NOT add `com.apple.security.app-sandbox`** — this app is not sandboxed and adding it would break filesystem scanning entirely.

Also required for the app to be replaceable during updates (Sparkle's `Installer.xpc` replaces the `.app` bundle):
- The app must NOT be running from a read-only location (Disk Images, installer volumes)
- The user must have write permission to the directory containing the `.app`

**Detection:**
- XPC errors in Console.app: "Failed to create XPC connection" or "Service not found"
- Sparkle downloads updates but "Install and Relaunch" does nothing
- `spctl --assess -vv` on the notarized app shows entitlement issues
- The notarization log mentions `com.apple.security.cs.disable-library-validation` warnings (this entitlement triggers a notarization review, but it's standard and accepted for Sparkle)

**Phase to address:** Hardened runtime entitlements (Phase 13) and Sparkle integration (Phase 14). Entitlements must be configured before first notarization submission.

---

### Pitfall 10: CI-Based Notarization Timeouts and Polling Failures

**What goes wrong:**
The CI workflow submits the DMG to notarization via `notarytool submit --wait` but the job times out after 5-10 minutes. Or the CI uses `notarytool submit` without `--wait`, polls with `notarytool info`, and the polling loop fails because notarization takes longer than expected (15-30 minutes is common during peak times).

**Why it happens:**
Apple's notarization service is asynchronous and processing time varies:
- **Typical:** 1-5 minutes
- **Peak load:** 15-30 minutes
- **Entitlement review (Sparkle):** Additional 5-10 minutes for apps using `disable-library-validation`
- **First submission for an app:** Additional review time

GitHub Actions has a default job timeout of 360 minutes, but individual steps can use `timeout-minutes`. If the notarization step has a 10-minute timeout and notarization takes 12 minutes, the CI job fails with a timeout error rather than a notarization error. The DMG is actually notarized — the CI just didn't wait for it.

**How to avoid:**
1. **Use `--wait` with a generous timeout in CI:**
```yaml
- name: Notarize DMG
  timeout-minutes: 30
  run: |
    xcrun notarytool submit dist/*.dmg \
      --apple-id "${{ secrets.NOTARYTOOL_APPLE_ID }}" \
      --team-id "${{ secrets.NOTARYTOOL_TEAM_ID }}" \
      --password "${{ secrets.NOTARYTOOL_PASSWORD }}" \
      --wait
```

2. **Handle the `--wait` exit code explicitly:**
```bash
SUBMISSION_OUTPUT=$(xcrun notarytool submit dist/*.dmg \
    --apple-id "$NOTARY_APPLE_ID" \
    --team-id "$NOTARY_TEAM_ID" \
    --password "$NOTARY_PASSWORD" \
    --wait 2>&1)
    
if echo "$SUBMISSION_OUTPUT" | grep -q '"status":"Accepted"'; then
    echo "Notarization accepted"
else
    echo "Notarization failed or pending: $SUBMISSION_OUTPUT"
    # Fetch detailed log
    SUBMISSION_ID=$(echo "$SUBMISSION_OUTPUT" | grep -o 'id: [a-f0-9-]*' | cut -d' ' -f2)
    xcrun notarytool log "$SUBMISSION_ID" \
        --apple-id "$NOTARY_APPLE_ID" \
        --team-id "$NOTARY_TEAM_ID" \
        --password "$NOTARY_PASSWORD"
    exit 1
fi
```

3. **Set the CI workflow's notarization step to `timeout-minutes: 45`** to account for worst-case notarization time plus polling.

4. **For manual/scripted notarization outside CI:** Use `notarytool submit --wait`, which polls internally and exits when complete.

**Detection:**
- CI job fails with "The operation was canceled" or step timeout, but `notarytool info <id>` shows the submission is "In Progress" or "Accepted"
- `notarytool submit --wait` returns a non-zero exit code but the submission eventually completes
- GitHub Actions log shows "##[error]The action has timed out"

**Phase to address:** CI-based notarization (Phase 13). Timeout must be configured before first CI release run.

---

### Pitfall 11: Notarization Staple Applied to Wrong Container

**What goes wrong:**
The app is signed. The app is notarized. The staple is applied to the `.app` bundle instead of the DMG. Users download the DMG, mount it, and Gatekeeper triggers a network check because the offline ticket is in the wrong container. On machines without internet access, the app refuses to launch.

**Why it happens:**
Apple notarizes the submitted container (the DMG). The notarization ticket must be stapled to that same container. If the developer submits the `.app` directly (possible via `zip`), notarization works but the eventual user-facing container (the DMG) has no ticket. Alternatively, the developer staples the `.app` inside the DMG, but Gatekeeper checks the DMG itself first.

**How to avoid:**
**Always notarize and staple the user-facing container (the DMG), not the intermediate `.app`:**

```bash
# WRONG: Notarize .app, staple .app, then create DMG
xcrun notarytool submit MyApp.app.zip --wait
xcrun stapler staple MyApp.app
hdiutil create ... MyApp.dmg  # DMG has no ticket!

# CORRECT: Package DMG first, then notarize and staple the DMG
hdiutil create ... MyApp.dmg                    # Create container
xcrun notarytool submit MyApp.dmg --wait       # Notarize container
xcrun stapler staple MyApp.dmg                 # Staple container
```

**Detection:**
- `stapler validate MyApp.dmg` returns "does not have a ticket stapled to it" after the notarization workflow
- Users report Gatekeeper online check when launching from DMG (even though the app was notarized)
- `spctl --assess -vv --type install MyApp.dmg` rejects (but `spctl --assess -vv --type execute MyApp.app` accepts)

**Phase to address:** Notarization recipe (Phase 13).

---

### Pitfall 12: GitHub Release Sparkle Appcast Requires Manual EdDSA Signing Per Release

**What goes wrong:**
Sparkle auto-update against GitHub Releases seems to "just work" — the `SUFeedURL` points to the GitHub Releases API, a new release is published, and the app detects it. But clicking "Install Update" fails because Sparkle cannot verify the update's EdDSA signature. The appcast (release metadata) must include an EdDSA signature for each binary asset, and GitHub Releases doesn't generate these automatically.

**Why it happens:**
Sparkle 2 requires every update to be cryptographically signed with the app's EdDSA private key. The signature is included in the appcast XML entry for each release. When using GitHub Releases as the appcast source, the appcast is generated from the GitHub Releases API — but the API does not include EdDSA signatures. Two approaches exist:

1. **`generate_appcast` with local mirrors:** Download all DMGs, run `generate_appcast`, host the resulting XML on GitHub Pages
2. **Sparkle's GitHub Releases integration (Sparkle 2.5+):** Sparkle can parse GitHub Releases atom feed directly, but still requires `sparkle:edSignature` in the release body

Without the EdDSA signature, Sparkle's security model blocks the update.

**How to avoid:**
1. **Generate the EdDSA signature for the DMG after building it:**
```bash
# After building and notarizing the DMG:
./Sparkle/bin/sign_update dist/AutomationHealth-1.3.0.dmg \
    -s /path/to/sparkle_private.pem
# Output: sparkle:edSignature="base64encoded..."
```

2. **Include the signature in the GitHub Release body or as an asset:**
Option A: Add `sparkle:edSignature="..." sparkle:version="..." sparkle:shortVersionString="..."` to the release description (Sparkle 2 can parse these from the release body)
Option B: Run `generate_appcast` locally and upload the generated `appcast.xml` as a release asset
Option C: Host a dedicated appcast XML on GitHub Pages (more work, but doesn't require parsing the release body)

3. **In CI, automate the signing step:**
```yaml
- name: Sign update for Sparkle
  run: |
    echo "${{ secrets.SPARKLE_PRIVATE_KEY }}" > /tmp/sparkle_private.pem
    SIGNATURE=$(./Sparkle/bin/sign_update dist/*.dmg -s /tmp/sparkle_private.pem)
    rm /tmp/sparkle_private.pem
    echo "ED_SIGNATURE=$SIGNATURE" >> $GITHUB_ENV
    
- name: Create GitHub Release with Sparkle signature
  run: |
    gh release create v1.3.0 dist/*.dmg \
      --title "Automation Health v1.3.0" \
      --notes "$(cat <<EOF
    ${{ env.ED_SIGNATURE }}
    
    ## Changes
    - Signed, notarized DMG distribution
    - Sparkle auto-update integration
    EOF
    )"
```

**Detection:**
- Sparkle detects the update, shows release notes, but "Install" fails or the update does not proceed
- Console.app shows "The update is improperly signed" or "EdDSA signature verification failed"
- The GitHub Release body does not contain `sparkle:edSignature` or `sparkle:version` elements

**Phase to address:** Sparkle integration (Phase 14). Must implement per-release signing before the first Sparkle-enabled release.

---

### Pitfall 13: Sparkle Update Channel Mismatch — Beta Updates Shown to Stable Users

**What goes wrong:**
During development, Sparkle's `SUFeedURL` points to a "latest release" endpoint that includes pre-releases or draft releases. Stable users are prompted to update to a beta or development build. Conversely, if the feed only includes stable releases, beta testers never see updates.

**Why it happens:**
GitHub Releases does not differentiate between stable, beta, and pre-release channels natively. The GitHub Releases API returns all releases (including pre-releases) by default. Without channel filtering in the appcast or Sparkle configuration, every release is offered to every user.

**How to avoid:**
For this project (single channel, no beta program), the simplest approach:

1. **Use Sparkle's minimum auto-update version.** Set `SUMinimumAutoupdateVersion` in Info.plist to prevent auto-update across major versions if needed.

2. **Mark pre-releases on GitHub as "pre-release"** (not "latest"). Sparkle 2's GitHub Releases integration respects the `prerelease` flag — if a release is marked as pre-release, Sparkle will not offer it for automatic updates.

3. **For future multi-channel needs:** Host separate appcast XML files for `stable` and `beta` channels, with different `SUFeedURL` values in the respective builds. But this is out of scope for v1.3.

**Detection:**
- Stable users see "Update to version 2.0.0-beta1" or similar pre-release
- GitHub Release marked as "latest" but intended as a test release
- `SUFeedURL` points to an API endpoint without prerelease filtering

**Phase to address:** Sparkle integration (Phase 14). Channel strategy is a configuration decision.

---

## Integration-Specific Pitfalls

Combined pitfalls where two or more systems interact.

### Integration 1: Sparkle + Hardened Runtime + Entitlements Review → Notarization Delay

**The interaction:** Sparkle requires `com.apple.security.cs.disable-library-validation`. This entitlement triggers additional notarization review by Apple (a human may need to approve it). Combined with `com.apple.security.cs.allow-unsigned-executable-memory` (also needed for Sparkle), the notarization review takes longer and has a higher risk of rejection on first submission.

**Mitigation:** Expect notarization to take 15-30 minutes for the first submission with Sparkle-entitled hardened runtime. Submit early, not at the end of a work session. If rejected, the notarization log will specify which entitlement triggered the review — respond with a clear explanation in the notarization notes field (`--notarization-tool-args`).

### Integration 2: DMG Code Signature + Sparkle Update Installation

**The interaction:** Sparkle downloads the new DMG, mounts it, and attempts to install it by replacing the old `.app` bundle. If the DMG is mounted from within the app's sandbox (not applicable here — app is unsandboxed) OR if the DMG's code signature doesn't survive the network transfer, Sparkle's installation step fails.

**Mitigation:** Verify the DMG's code signature after download (Sparkle does this internally via the EdDSA signature check). Ensure DMG is notarized and stapled so Gatekeeper doesn't block the extracted `.app`. Test the full update cycle: download, mount, install, relaunch — not just the "update available" detection.

### Integration 3: SwiftPM Static Linking + Sparkle Framework Dynamic Link

**The interaction:** The app binary is statically linked (`-static-executable`), but Sparkle.framework is dynamically loaded. Static linking of the main binary and dynamic loading of Sparkle is perfectly fine — the main executable loads Sparkle at runtime via `dlopen` or the dynamic linker. However, the `-static-executable` flag should NOT prevent the binary from loading external frameworks. Verify with:

```bash
# Should show Sparkle.framework as dynamically linked, Swift runtime absent
otool -L AutomationHealth.app/Contents/MacOS/AutomationHealth
```

**Mitigation:** Use `-Xlinker -F/path/to/Frameworks` to tell the linker where Sparkle lives. The static-executable flag affects Swift runtime linking, not all dynamic linking.

### Integration 4: CI Secrets Rotation + Sparkle Key Rotation

**The interaction:** If the Apple Developer ID certificate is revoked (e.g., after a leak), all existing releases become invalid. If the Sparkle EdDSA key is rotated at the same time, existing installations can no longer receive updates — even the emergency fix release is unverifiable because the key changed.

**Mitigation:** The Sparkle private key must be rotated independently of the Apple signing certificate, and only when absolutely necessary. If the certificate is revoked but the Sparkle key is intact, re-sign the new release and include BOTH the old and new Sparkle public keys in `Info.plist` during the transition (Sparke 2 supports multiple public keys for key rotation). Never rotate both simultaneously without a transition period.

---

## Moderate Pitfalls

### Pitfall M1: `com.apple.security.get-task-allow` Left in Distribution Build

**What goes wrong:** Debug-entitlement `com.apple.security.get-task-allow` is left in the entitlements file used for distribution signing. Notarization fails with "get-task-allow is not permitted in distribution builds." This happens when a single entitlements file is used for both Debug and Release.

**Mitigation:** Use separate entitlements files: `entitlements.debug.plist` (with `get-task-allow`) and `entitlements.release.plist` (without). Reference the correct file in the build/release script.

### Pitfall M2: `CFBundleVersion` as String Causes Notarization Rejection

**What goes wrong:** `CFBundleVersion` is set to a semver string like "1.3.0" instead of an integer build number. Notarization may accept this, but `CFBundleVersion` is semantically a build number (integer). Using a version string here can cause App Store Connect validation failures if the app ever targets the App Store.

**Mitigation:** Set `CFBundleVersion` to a monotonically increasing integer (e.g., `1` for the first release, increment on each release). Put the semver in `CFBundleShortVersionString`.

### Pitfall M3: DMG Volume Name Contains Characters That Break Mounting

**What goes wrong:** DMG volume name contains slashes, colons, or special characters. `hdiutil` creates the DMG but the volume fails to mount silently on some macOS versions.

**Mitigation:** Use only alphanumeric characters, spaces, hyphens, and underscores in the volume name: `Automation Health` is fine.

### Pitfall M4: Sparkle Framework Version Mismatch with `generate_keys`/`sign_update` Tools

**What goes wrong:** The Sparkle framework version bundled in the app (e.g., 2.6.0) differs from the version of `generate_keys` and `sign_update` used to sign updates (e.g., 2.5.0). Key format or signing algorithm changes between versions cause update verification failures.

**Mitigation:** Use the same Sparkle version for: (1) the framework bundled in the app, (2) `generate_keys` for key generation, and (3) `sign_update`/`generate_appcast` in the release pipeline. Pin the Sparkle version in release documentation. Download all tools from the same GitHub Release.

### Pitfall M5: CI Runner Architecture Mismatch for `swift build`

**What goes wrong:** The release pipeline runs `swift build -c release` on a GitHub Actions macOS runner that produces an `arm64` binary, but the release is intended for Intel Macs. Universal binaries (`arm64` + `x86_64`) require explicit `--arch` flags. Building for the wrong architecture produces a DMG that fails to launch on half the user base.

**Mitigation:** For maximum compatibility, build a universal binary:
```bash
swift build -c release --arch arm64 --arch x86_64
```
Or, if targeting macOS 14+ only (Apple Silicon is the vast majority), `arm64` alone is acceptable. Document the architecture decision in release process docs. The app's minimum target is macOS 14 (Sonoma), which only supports Apple Silicon Macs and Intel Macs with a T2 chip — both support `arm64` binaries via Rosetta 2 on Intel.

### Pitfall M6: Sparkle Downloaded Update Fails to Replace Running App (File Permissions)

**What goes wrong:** The app is installed in `/Applications/` but the user doesn't have write permission to that directory (unlikely for user-installed apps, but possible with managed devices). Sparkle's `Installer.xpc` copies the new `.app` to a temporary location and tries to swap it — if the final swap fails due to permissions, the app remains at the old version after "successful" update.

**Mitigation:** This is rare for user-installed apps. If it occurs, Sparkle shows an error and the app continues running the old version (safe fallback). No action needed beyond documentation.

---

## Minor Pitfalls

### Pitfall L1: Sparkle Update UI Appears Behind the App Window

**What goes wrong:** Sparkle's update alert window appears behind the main app window and is not visible. Users don't know an update is available.

**Mitigation:** Set `SUEnableInstallerLauncherService = NO` in Info.plist (default) and ensure Sparkle's `SUUpdater` is presented as a modal sheet or frontmost window. Test update UI visibility with the app in full-screen mode.

### Pitfall L2: `gh release create` With `--generate-notes` Produces Empty or Generic Release Body

**What goes wrong:** The GitHub Release is created with auto-generated notes that contain only commit hashes and no Sparkle signature elements. Sparkle cannot find `sparkle:edSignature` in the release body.

**Mitigation:** Use `--notes` (custom) instead of `--generate-notes` for Sparkle-enabled releases. Include both human-readable change notes and Sparkle metadata.

### Pitfall L3: Notarization Submission Returns "Accepted" But Staple Fails

**What goes wrong:** `notarytool submit --wait` returns `Accepted`, but `xcrun stapler staple DMG.dmg` fails with "does not have a ticket." This happens when the notarization ticket hasn't propagated to the stapler cache yet — there's a brief delay between notarization completion and ticket availability.

**Mitigation:** Wait 30-60 seconds between notarization acceptance and stapling. Use a retry loop:
```bash
for i in $(seq 1 5); do
    xcrun stapler staple "$DMG" && break
    echo "Staple attempt $i failed, retrying in 10s..."
    sleep 10
done
```

### Pitfall L4: Entitlements File Forgotten During Signing

**What goes wrong:** `codesign --sign "Developer ID" --timestamp --options runtime` is run without `--entitlements entitlements.plist`. The app signs successfully but with default (maximally restrictive) Hardened Runtime. Sparkle features break.

**Mitigation:** Always include `--entitlements` in the codesign command. Verify entitlements on the signed binary:
```bash
codesign -d --entitlements - AutomationHealth.app
```

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Codesigning (Phase 13) | Hardened Runtime blocks `launchctl` subprocess execution | Test signed Release binary on different Mac; add entitlements if needed |
| Codesigning (Phase 13) | SwiftPM dynamic Swift runtime linking blocks notarization | Build with `-static-executable`; verify with `otool -L` |
| Notarization (Phase 13) | Incomplete Info.plist causes notarization rejection | Add all required keys; validate with `plutil -lint` |
| Notarization (Phase 13) | CI notarization timeout during peak hours | Set `timeout-minutes: 45` on notarization step |
| DMG packaging (Phase 13) | Opening signed .app before DMG creation destroys signature | Fresh build, sign, immediately package into DMG — never open |
| DMG packaging (Phase 13) | Staple applied to wrong container | Notarize and staple the DMG, not the .app |
| CI secrets (Phase 13) | Developer ID certificate leaked in logs or committed scripts | Ephemeral keychain, secret masking, environment variables only |
| Release process (Phase 13) | `--generate-notes` produces body without Sparkle metadata | Use custom `--notes` with EdDSA signature in release body |
| Sparkle integration (Phase 14) | SUFeedURL using http:// blocks updates | HTTPS-only feed URL |
| Sparkle integration (Phase 14) | EdDSA key generation/loss/rotation failure | Generate once, store private key in CI secrets, document recovery |
| Sparkle integration (Phase 14) | Framework not bundled in SwiftPM build | Manual framework copying, signing in inside-out order |
| Sparkle integration (Phase 14) | XPC services fail under Hardened Runtime | Required entitlements: `disable-library-validation`, `allow-unsigned-executable-memory` |
| Sparkle + Release (Phases 13-14) | Per-release EdDSA signing missing from GitHub Release | `sign_update` run in CI, signature added to release body |

---

## Pre-Submission Verification Checklist

Things to verify before considering distribution "shipped":

- [ ] **Static linking:** `otool -L AutomationHealth.app/Contents/MacOS/AutomationHealth | grep swift` returns nothing
- [ ] **Info.plist:** Contains `CFBundleVersion`, `CFBundleShortVersionString`, `NSHumanReadableCopyright`, `LSApplicationCategoryType`
- [ ] **Entitlements:** `codesign -d --entitlements - AutomationHealth.app` shows expected entitlements (no `get-task-allow`)
- [ ] **Code signature on .app:** `codesign --verify --deep --strict --verbose=2 AutomationHealth.app` passes
- [ ] **Code signature on DMG:** `codesign -dvvv dist/*.dmg` shows Developer ID signature
- [ ] **Notarization:** `spctl --assess -vv --type install dist/*.dmg` passes
- [ ] **Staple:** `xcrun stapler validate dist/*.dmg` passes
- [ ] **Signature survives DMG extraction:** Mount DMG, `codesign -vvv /Volumes/Automation\ Health/AutomationHealth.app` passes
- [ ] **launchctl works on signed binary:** Self-test or manual check that launchd scanner returns results
- [ ] **CI secrets configured:** All 5 secrets present in GitHub repo settings (cert base64, cert password, Apple ID, team ID, app-specific password)
- [ ] **CI no secrets in logs:** Review last CI release run output — no certificate data, no passwords visible
- [ ] **Release docs use placeholders:** `docs/release-process.md` references `$DEVELOPER_ID`, `$TEAM_ID`, not literal values
- [ ] **Sparkle keys generated and stored:** Private key in CI secret, public key in `Info.plist` (`SUPublicEDKey`)
- [ ] **Sparkle SUFeedURL is HTTPS:** Verified with `grep SUFeedURL Info.plist`
- [ ] **Sparkle framework bundled:** `ls AutomationHealth.app/Contents/Frameworks/Sparkle.framework` exists
- [ ] **Sparkle framework signed:** `codesign -vvv AutomationHealth.app/Contents/Frameworks/Sparkle.framework` passes
- [ ] **Sparkle entitlements present:** `com.apple.security.cs.disable-library-validation` and `com.apple.security.cs.allow-unsigned-executable-memory` in release entitlements
- [ ] **Release body contains Sparkle metadata:** `sparkle:edSignature` and `sparkle:version` in GitHub Release description
- [ ] **GitHub Release asset downloadable:** Download URL works, DMG size matches, DMG mounts on clean macOS install
- [ ] **Full update cycle tested:** Install old version, trigger update check, download update, install, verify new version launches

---

## Sources

- **Apple Developer Documentation** — "Hardened Runtime" — Entitlement reference, default restrictions, `get-task-allow` prohibition for distribution builds. HIGH confidence.
- **Apple Developer Documentation** — "Notarizing macOS Software Before Distribution" — `notarytool` workflow, staple requirements, common notarization issues, Info.plist requirements. HIGH confidence.
- **Apple Developer Documentation** — "Creating Distribution-Signed Code for macOS" — Signing order (inside-out), `--deep` warning, entitlements per code item. HIGH confidence.
- **Apple Developer Forums** — Quinn "The Eskimo!" posts on codesigning: batch signing pitfalls, `--deep` alternatives, verification steps. HIGH confidence.
- **Sparkle Project Documentation** (sparkle-project.org) — EdDSA key generation, `sign_update` usage, GitHub Releases integration, XPC service entitlements, Hardened Runtime requirements. HIGH confidence.
- **Scripting OS X** (scriptingosx.com) — Practical notarization recipes for SwiftPM command-line tools, `notarytool` + `stapler` + `spctl` workflow. MEDIUM confidence.
- **GitHub Docs** — "Encrypted secrets", Release asset management, CI workflow security. HIGH confidence.
- **Swift Forums** — Static linking discussions for SwiftPM executables, `-static-executable` flag behavior on macOS. HIGH confidence.
- **Project codebase evidence:**
  - `Package.swift` — Pure SwiftPM, no external dependencies, `macOS(.v14)` platform target. HIGH confidence.
  - `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` — Uses `Process` to invoke `/bin/launchctl`, reads plists from `~/Library/LaunchAgents`. HIGH confidence.
  - `script/build_and_run.sh` — Minimal unsigned `.app` assembly, hand-rolled `Info.plist`. HIGH confidence.
  - `.github/workflows/ci.yml` — Uses `macos-latest`, no signing steps, no secrets. HIGH confidence.
  - `Makefile` — `build`, `test`, `ci`, `run` targets; no release/sign/notarize target. HIGH confidence.
  - `.planning/codebase/INTEGRATIONS.md` — Confirms no network layer, no external Swift deps, no secrets currently used in CI. HIGH confidence.

---

*Pitfalls research for: Automation Health v1.3 — codesigning, notarization, DMG, CI, Sparkle auto-update*
*Researched: 2026-05-12*
*Confidence: HIGH — all pitfalls validated against official Apple and Sparkle documentation; verified against project's current unsigned SwiftPM state via codebase files*
