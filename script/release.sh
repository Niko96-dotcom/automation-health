#!/usr/bin/env bash
set -euo pipefail

APP_NAME="AutomationHealth"
DISPLAY_NAME="Automation Health"
BUNDLE_ID="org.automationhealth.AutomationHealth"
MIN_SYSTEM_VERSION="14.0"
ICON_NAME="AutomationHealth"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SOURCE="$ROOT_DIR/Assets/AppIcon/automation-health-icon-source.png"
ICON_FILE="$ROOT_DIR/Assets/AppIcon/$ICON_NAME.icns"
ICON_SCRIPT="$ROOT_DIR/script/generate_app_icon.sh"

# Derive version from the nearest reachable tag (e.g. v1.3.0).
# GITHUB_REF_NAME is unreliable on workflow_dispatch (could be a branch name).
# Strip the leading 'v' so we get a clean version string like "1.3.0".
RAW_VERSION="$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || true)"
VERSION="${RAW_VERSION#v}"
# If we still have nothing (shallow clone, no tags), fall back.
if [ -z "$VERSION" ]; then
  VERSION="0.0.0-dev"
fi

STAGING="$ROOT_DIR/.release-staging"
APP_BUNDLE="$STAGING/package/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME-$VERSION.dmg"

echo "=== Step 1: Validate credentials ==="

missing_vars=()
for var in APPLE_DEVELOPER_IDENTITY APPLE_DEVELOPER_TEAM_ID APPLE_NOTARY_KEY_ID APPLE_NOTARY_KEY_FILE APPLE_NOTARY_KEY_ISSUER_ID; do
  if [ -z "${!var:-}" ]; then
    missing_vars+=("$var")
  fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
  for var in "${missing_vars[@]}"; do
    case "$var" in
      APPLE_DEVELOPER_IDENTITY)
        echo "Error: APPLE_DEVELOPER_IDENTITY is not set. Set it to your Developer ID Application certificate common name." >&2
        ;;
      APPLE_DEVELOPER_TEAM_ID)
        echo "Error: APPLE_DEVELOPER_TEAM_ID is not set. Set it to your 10-character Apple Developer Team ID." >&2
        ;;
      APPLE_NOTARY_KEY_ID)
        echo "Error: APPLE_NOTARY_KEY_ID is not set. Set it to your App Store Connect API Key ID." >&2
        ;;
      APPLE_NOTARY_KEY_FILE)
        echo "Error: APPLE_NOTARY_KEY_FILE is not set. Set it to the path of your App Store Connect API .p8 private key file." >&2
        ;;
      APPLE_NOTARY_KEY_ISSUER_ID)
        echo "Error: APPLE_NOTARY_KEY_ISSUER_ID is not set. Set it to your App Store Connect API Issuer ID." >&2
        ;;
    esac
  done
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Warning: GITHUB_TOKEN is not set. GitHub Release upload step will be skipped." >&2
fi

echo "=== Step 2: Build release binary ==="
cd "$ROOT_DIR"
swift build --configuration release
BINARY_PATH="$(swift build --configuration release --show-bin-path)/$APP_NAME"

echo "=== Step 3: Assemble .app bundle ==="
rm -rf "$STAGING"
mkdir -p "$STAGING/package"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

echo "=== Step 3b: Copy app icon ==="
if [[ ! -f "$ICON_SOURCE" || ! -f "$ICON_FILE" || "$ICON_SOURCE" -nt "$ICON_FILE" || "$ICON_SCRIPT" -nt "$ICON_FILE" ]]; then
  "$ICON_SCRIPT"
fi
cp "$ICON_FILE" "$RESOURCES_DIR/$ICON_NAME.icns"

echo "=== Step 3c: Write Info.plist ==="
cat >"$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleIconFile</key>
  <string>$ICON_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
</dict>
</plist>
PLIST

echo "=== Step 4: Codesign .app bundle with hardened runtime ==="
codesign --deep --force --verify --verbose \
  --sign "$APPLE_DEVELOPER_IDENTITY" \
  --options runtime \
  --entitlements "$ROOT_DIR/entitlements/release.entitlements" \
  --timestamp \
  "$APP_BUNDLE"

codesign --verify --verbose "$APP_BUNDLE"

echo "=== Step 5: Create DMG with drag-to-install layout ==="
mkdir -p "$ROOT_DIR/dist"
TMP_DMG="$STAGING/tmp.dmg"

hdiutil create -size 150m -volname "$DISPLAY_NAME" -fs HFS+ -attach "$TMP_DMG"

cp -R "$APP_BUNDLE" "/Volumes/$DISPLAY_NAME/"
ln -s /Applications "/Volumes/$DISPLAY_NAME/Applications"

osascript <<END_SCRIPT
tell application "Finder"
  tell disk "$DISPLAY_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {400, 200, 920, 520}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 72
    set position of item "$APP_NAME.app" of container window to {160, 140}
    set position of item "Applications" of container window to {360, 140}
    update without registering applications
    close
  end tell
end tell
END_SCRIPT

DISK_ID="$(hdiutil info | grep "/Volumes/$DISPLAY_NAME" | awk '{print $1}')"
hdiutil detach "$DISK_ID" -force
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"
rm -f "$TMP_DMG"

echo "=== Step 6: Codesign the DMG ==="
codesign --force --sign "$APPLE_DEVELOPER_IDENTITY" --timestamp "$DMG_PATH"
codesign --verify --verbose "$DMG_PATH"

echo "=== Step 7: Submit for notarization ==="
xcrun notarytool submit "$DMG_PATH" \
  --key "$APPLE_NOTARY_KEY_FILE" \
  --key-id "$APPLE_NOTARY_KEY_ID" \
  --issuer "$APPLE_NOTARY_KEY_ISSUER_ID" \
  --wait \
  --output-format json \
  | tee "$STAGING/notary-result.json"

NOTARY_STATUS="$(jq -r '.status // "Unknown"' "$STAGING/notary-result.json")"
if [ "$NOTARY_STATUS" != "Accepted" ]; then
  echo "Error: Notarization status is '$NOTARY_STATUS', expected 'Accepted'." >&2
  echo "Full result:" >&2
  cat "$STAGING/notary-result.json" >&2
  exit 1
fi

echo "=== Step 8: Log notary submission ==="
SUBMISSION_ID="$(jq -r '.id' "$STAGING/notary-result.json")"
xcrun notarytool log "$SUBMISSION_ID" \
  --key "$APPLE_NOTARY_KEY_FILE" \
  --key-id "$APPLE_NOTARY_KEY_ID" \
  --issuer "$APPLE_NOTARY_KEY_ISSUER_ID" \
  "$STAGING/notary-log.json"

echo "=== Step 9: Staple notarization ticket ==="
xcrun stapler staple "$DMG_PATH"

echo "=== Step 10: Verify stapled DMG ==="
xcrun stapler validate "$DMG_PATH"
spctl --assess --verbose --type install "$DMG_PATH" || echo "Warning: spctl assessment requires a non-development Mac or cleared assessment history"

echo "=== Step 11: Success summary ==="
DMG_SIZE="$(ls -lh "$DMG_PATH" | awk '{print $5}')"
echo ""
echo "=== Release Complete ==="
echo "DMG: $DMG_PATH"
echo "Size: $DMG_SIZE"
echo "Notarization: Accepted and stapled"
echo "Gatekeeper assessment: passed (if available)"
