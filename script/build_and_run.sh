#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="AutomationHealth"
DISPLAY_NAME="Automation Health"
BUNDLE_ID="org.automationhealth.AutomationHealth"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICON_NAME="AutomationHealth"
# AutomationHealth.icns is copied into Contents/Resources for CFBundleIconFile.
ICON_SOURCE="$ROOT_DIR/Assets/AppIcon/automation-health-icon-source.png"
ICON_FILE="$ROOT_DIR/Assets/AppIcon/$ICON_NAME.icns"
ICON_SCRIPT="$ROOT_DIR/script/generate_app_icon.sh"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

if [[ ! -f "$ICON_SOURCE" || ! -f "$ICON_FILE" || "$ICON_SOURCE" -nt "$ICON_FILE" || "$ICON_SCRIPT" -nt "$ICON_FILE" ]]; then
  "$ICON_SCRIPT"
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ICON_FILE" "$APP_RESOURCES/$ICON_NAME.icns"

cat >"$INFO_PLIST" <<PLIST
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
  <string>$ICON_NAME.icns</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
PLIST

if [ -n "${SU_PUBLIC_ED_KEY:-}" ]; then
  cat >>"$INFO_PLIST" <<PLIST
  <key>SUPublicEDKey</key>
  <string>$SU_PUBLIC_ED_KEY</string>
PLIST
fi

cat >>"$INFO_PLIST" <<PLIST
  <key>CFBundleShortVersionString</key>
  <string>0.0.0-dev</string>
  <key>CFBundleVersion</key>
  <string>0.0.0-dev</string>
</dict>
</plist>
PLIST

"$ROOT_DIR/script/embed_sparkle_framework.sh" "$APP_BUNDLE" debug
codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
