#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-quick}"
APP_NAME="AutomationHealth"
README_FILE="Assets/AppIcon/README.md"
SOURCE_PNG="Assets/AppIcon/automation-health-icon-source.png"
ICONSET_DIR="Assets/AppIcon/AutomationHealth.iconset"
ICNS_FILE="Assets/AppIcon/AutomationHealth.icns"
BUILD_SCRIPT="script/build_and_run.sh"
GENERATOR_SCRIPT="script/generate_app_icon.sh"
DEVELOPMENT_DOC="docs/development.md"

fail() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

require_executable() {
  [[ -x "$1" ]] || fail "not executable: $1"
}

require_non_empty_file() {
  [[ -s "$1" ]] || fail "missing or empty file: $1"
}

require_text() {
  local file="$1"
  local text="$2"
  /usr/bin/grep -Fq -- "$text" "$file" || fail "$file is missing: $text"
}

reject_text() {
  local file="$1"
  local text="$2"
  if /usr/bin/grep -Fq -- "$text" "$file"; then
    fail "$file still contains: $text"
  fi
}

png_dimension() {
  local file="$1"
  local key="$2"
  sips -g "$key" "$file" | awk -v key="$key:" '$1 == key { print $2 }'
}

require_png_size() {
  local file="$1"
  local expected="$2"
  local width
  local height

  require_non_empty_file "$file"
  width="$(png_dimension "$file" pixelWidth)"
  height="$(png_dimension "$file" pixelHeight)"

  [[ "$width" == "$expected" ]] || fail "$file width is $width, expected $expected"
  [[ "$height" == "$expected" ]] || fail "$file height is $height, expected $expected"
}

reject_private_asset_strings() {
  local file="$1"
  if strings "$file" | /usr/bin/grep -Eiq '(/Users/|launchctl|LaunchAgent|Hermes|cron|terminal output|scheduler|screenshot|hostname|token|secret|password)'; then
    fail "$file contains private-looking or scheduler-specific strings"
  fi
}

case "$MODE" in
  quick|--bundle|bundle)
    ;;
  *)
    echo "usage: $0 [quick|--bundle]" >&2
    exit 2
    ;;
esac

require_file "$README_FILE"
require_file "$SOURCE_PNG"
require_executable "$GENERATOR_SCRIPT"

require_text "$README_FILE" "ChatGPT Image Prompt"
require_text "$README_FILE" "Create 4 polished macOS app icon variants"
require_text "$README_FILE" "Pulse Grid"
require_text "$README_FILE" "no text"
require_text "$README_FILE" "no private data"
require_text "$README_FILE" "no terminal output"
require_text "$README_FILE" "$SOURCE_PNG"
require_text "$README_FILE" "Selected variant:"
require_text "$README_FILE" "Privacy check: no text, no private data, no screenshots, no local paths, no terminal output, and no real scheduler details."
reject_text "$README_FILE" "TBD"

SOURCE_WIDTH="$(png_dimension "$SOURCE_PNG" pixelWidth)"
SOURCE_HEIGHT="$(png_dimension "$SOURCE_PNG" pixelHeight)"
[[ "$SOURCE_WIDTH" == "$SOURCE_HEIGHT" ]] || fail "$SOURCE_PNG must be square; got ${SOURCE_WIDTH}x${SOURCE_HEIGHT}"
[[ "$SOURCE_WIDTH" -ge 1024 ]] || fail "$SOURCE_PNG width is $SOURCE_WIDTH, expected at least 1024"

"$GENERATOR_SCRIPT" >/dev/null

ICON_SPECS=(
  "icon_16x16.png:16"
  "icon_16x16@2x.png:32"
  "icon_32x32.png:32"
  "icon_32x32@2x.png:64"
  "icon_128x128.png:128"
  "icon_128x128@2x.png:256"
  "icon_256x256.png:256"
  "icon_256x256@2x.png:512"
  "icon_512x512.png:512"
  "icon_512x512@2x.png:1024"
)

for spec in "${ICON_SPECS[@]}"; do
  icon_name="${spec%%:*}"
  icon_size="${spec##*:}"
  require_png_size "$ICONSET_DIR/$icon_name" "$icon_size"
done

require_non_empty_file "$ICNS_FILE"
reject_private_asset_strings "$SOURCE_PNG"
reject_private_asset_strings "$ICNS_FILE"

require_text "$BUILD_SCRIPT" 'ICON_FILE="$ROOT_DIR/Assets/AppIcon/$ICON_NAME.icns"'
require_text "$BUILD_SCRIPT" 'ICON_SCRIPT="$ROOT_DIR/script/generate_app_icon.sh"'
require_text "$BUILD_SCRIPT" 'cp "$ICON_FILE" "$APP_RESOURCES/$ICON_NAME.icns"'
require_text "$BUILD_SCRIPT" "CFBundleIconFile"
require_text "$BUILD_SCRIPT" '<string>$ICON_NAME.icns</string>'

require_text "$DEVELOPMENT_DOC" "App Icon Assets"
require_text "$DEVELOPMENT_DOC" "./script/generate_app_icon.sh"
require_text "$DEVELOPMENT_DOC" "AutomationHealth.icns"
require_text "$DEVELOPMENT_DOC" "no API key"
require_text "README.md" "App icon assets are generated locally from committed source art; see docs/development.md for regeneration steps."

if [[ "$MODE" == "--bundle" || "$MODE" == "bundle" ]]; then
  trap 'pkill -x "$APP_NAME" >/dev/null 2>&1 || true' EXIT
  ./script/build_and_run.sh --verify
  require_non_empty_file "dist/AutomationHealth.app/Contents/Resources/AutomationHealth.icns"
  BUNDLE_ICON="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" dist/AutomationHealth.app/Contents/Info.plist)"
  [[ "$BUNDLE_ICON" == "AutomationHealth.icns" ]] || fail "CFBundleIconFile is $BUNDLE_ICON"
fi

echo "App icon validation passed ($MODE)"
