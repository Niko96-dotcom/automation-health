# Release Process

Automation Health ships as a signed, notarized DMG from GitHub Releases. This document describes how to set up credentials and produce a release.

## Prerequisites

You need:

1. **An Apple Developer Program membership** ($99/year). Required for code signing and notarization. Sign up at [developer.apple.com](https://developer.apple.com).
2. **A Developer ID Application certificate**. Created in Xcode or via `certtool`, installed in your keychain.
3. **An App Store Connect API key** for notarization. Created at [App Store Connect > Users and Access > Integrations > App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).

## Local Release Setup

### Step 1: Export your Developer ID certificate

Find your Developer ID Application certificate in Keychain Access. Export it as a `.p12` file with a password.

```bash
# List available Developer ID certificates
security find-identity -v -p codesigning | grep "Developer ID Application"

# Example output:
# 1) ABC123... "Developer ID Application: Your Name (XXXXXXXXXX)"
```

### Step 2: Create an App Store Connect API Key

1. Go to [App Store Connect > Users and Access > Integrations > App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Click the "+" button to create a new key
3. Name it "Automation Health Notarization"
4. Select the "Developer" role
5. Download the `.p8` private key file (you can only download it once)
6. Note the **Key ID** (10 characters) and **Issuer ID** (UUID format)

### Step 3: Set up environment variables

```bash
export APPLE_DEVELOPER_IDENTITY="Developer ID Application: Your Name (XXXXXXXXXX)"
export APPLE_DEVELOPER_TEAM_ID="YOURTEAMID"  # 10-char alphanumeric, from developer.apple.com/account
export APPLE_NOTARY_KEY_ID="YOURKEYID"        # From App Store Connect API Keys page
export APPLE_NOTARY_KEY_FILE="$HOME/.appstoreconnect/AuthKey.p8"  # Path to downloaded .p8 file
export APPLE_NOTARY_KEY_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # UUID from App Store Connect
```

### Step 4: Run the release script

```bash
./script/release.sh
```

The script will:
1. Validate all credentials are set
2. Build the app with `swift build --configuration release`
3. Assemble the `.app` bundle
4. Codesign with hardened runtime using `entitlements/release.entitlements`
5. Create a DMG with drag-to-install layout
6. Submit the DMG for notarization via `xcrun notarytool`
7. Wait for notarization to complete
8. Staple the notarization ticket to the DMG
9. Verify the staple and Gatekeeper assessment

The output DMG is written to `dist/AutomationHealth-<version>.dmg`.

## CI Release Setup

### Step 1: Encode your certificate for CI

```bash
# Export your .p12 to base64 (one line)
base64 -i path/to/developerID_application.p12 | tr -d '\n' | pbcopy
```

### Step 2: Add GitHub Secrets

Go to your GitHub repository > Settings > Secrets and variables > Actions. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `APPLE_DEVELOPER_CERTIFICATE_P12` | Base64-encoded .p12 file (from step 1) |
| `APPLE_DEVELOPER_CERTIFICATE_PASSWORD` | Password you set when exporting the .p12 |
| `APPLE_DEVELOPER_TEAM_ID` | Your 10-character Apple Team ID |
| `APPLE_NOTARY_KEY_ID` | App Store Connect API Key ID |
| `APPLE_NOTARY_KEY` | **Full contents** of the `.p8` private key file (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines) |
| `APPLE_NOTARY_KEY_ISSUER_ID` | App Store Connect Issuer ID (UUID) |

### Step 3: Enable workflow write permissions

In repository Settings > Actions > General > Workflow permissions, select **"Read and write permissions"**.

### Step 4: Create a release

```bash
# Tag the version
git tag -a v1.3.0 -m "Automation Health v1.3.0"
git push origin v1.3.0
```

The `.github/workflows/release.yml` workflow triggers automatically on any `v*` tag push. You can monitor progress in the Actions tab.

The CI workflow:
1. Checks out the repository at the tag
2. Imports the Developer ID certificate into a temporary keychain
3. Writes the App Store Connect API key to a secure temp file
4. Runs `./script/release.sh`
5. Uploads the DMG as a build artifact (30-day retention)
6. Creates a GitHub Release with the DMG attached

## Verification

After a release is created, verify it works:

```bash
# Download and verify the DMG
xcrun stapler validate AutomationHealth-x.y.z.dmg

# Check Gatekeeper (on a non-development Mac)
spctl --assess --verbose --type install AutomationHealth-x.y.z.dmg

# Mount the DMG and verify the app
hdiutil attach AutomationHealth-x.y.z.dmg
codesign --verify --verbose /Volumes/Automation\ Health/AutomationHealth.app
```

## Troubleshooting

### "Developer ID Application certificate not found"

Your Apple Developer Program membership may have expired (check [developer.apple.com/account](https://developer.apple.com/account)), or the certificate may have expired. Developer ID Application certificates are valid for 5 years.

### "notarytool: Unable to authenticate"

- Verify your API key file path is correct
- Verify `APPLE_NOTARY_KEY_ID` and `APPLE_NOTARY_KEY_ISSUER_ID` match the values on the App Store Connect API Keys page
- The API key must have the "Developer" role, not "App Manager"

### "The binary is not signed"

The codesign step failed. Check `APPLE_DEVELOPER_IDENTITY` matches the exact Common Name of your certificate (including spaces and parentheses).

### "Notarization rejected"

Check the notarization log:
```bash
xcrun notarytool log <submission-id> --key "$APPLE_NOTARY_KEY_FILE" --key-id "$APPLE_NOTARY_KEY_ID" --issuer "$APPLE_NOTARY_KEY_ISSUER_ID"
```

Common rejection reasons:
- Missing hardened runtime (`--options runtime` flag)
- `com.apple.security.get-task-allow` set to `true` (must be `false` for distribution)
- Binary uses deprecated APIs

## Certificate Renewal

Developer ID Application certificates expire after 5 years. Before expiration:

1. Create a new certificate at [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates)
2. Update the CI secrets: `APPLE_DEVELOPER_CERTIFICATE_P12` and `APPLE_DEVELOPER_CERTIFICATE_PASSWORD`
3. Update the local `APPLE_DEVELOPER_IDENTITY` if the certificate name changed

## Architecture

```
git tag v1.3.0 ──> .github/workflows/release.yml
                       │
                       ├── Import cert (secrets.APPLE_DEVELOPER_CERTIFICATE_P12)
                       ├── Write API key (secrets.APPLE_NOTARY_KEY)
                       ├── ./script/release.sh
                       │       ├── swift build --configuration release
                       │       ├── Assemble .app bundle
                       │       ├── codesign (hardened runtime + release.entitlements)
                       │       ├── Create DMG (hdiutil + drag-to-install layout)
                       │       ├── codesign DMG
                       │       ├── notarytool submit (--wait)
                       │       └── stapler staple
                       ├── Upload artifact (retention: 30 days)
                       └── gh release create (DMG attached)
```
