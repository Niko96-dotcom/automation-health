#!/usr/bin/env bash
set -euo pipefail

# Embed Sparkle.framework into a .app bundle built via SwiftPM.
# Usage: embed_sparkle_framework.sh <path-to.app> [debug|release]

APP_BUNDLE="${1:?App bundle path required}"
BUILD_CONFIGURATION="${2:-debug}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_EXECUTABLE="$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$APP_BUNDLE/Contents/Info.plist")"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_EXECUTABLE"
FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"

sparkle_src=""
for candidate in \
  "$ROOT_DIR/.build/arm64-apple-macosx/$BUILD_CONFIGURATION/Sparkle.framework" \
  "$ROOT_DIR/.build/x86_64-apple-macosx/$BUILD_CONFIGURATION/Sparkle.framework"; do
  if [[ -d "$candidate" ]]; then
    sparkle_src="$candidate"
    break
  fi
done

if [[ -z "$sparkle_src" ]]; then
  sparkle_src="$(find "$ROOT_DIR/.build" -path "*/$BUILD_CONFIGURATION/Sparkle.framework" -type d 2>/dev/null | head -1)"
fi

if [[ -z "$sparkle_src" ]]; then
  sparkle_src="$(find "$ROOT_DIR/.build/artifacts" -path "*macos*/Sparkle.framework" -type d 2>/dev/null | head -1)"
fi

if [[ -z "$sparkle_src" || ! -d "$sparkle_src" ]]; then
  echo "Error: Sparkle.framework not found after swift build ($BUILD_CONFIGURATION)." >&2
  echo "Run: swift build --configuration $BUILD_CONFIGURATION" >&2
  exit 1
fi

mkdir -p "$FRAMEWORKS_DIR"
rm -rf "$FRAMEWORKS_DIR/Sparkle.framework"
cp -R "$sparkle_src" "$FRAMEWORKS_DIR/"

if ! otool -l "$APP_BINARY" | grep -q '@executable_path/../Frameworks'; then
  install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY"
fi

echo "Embedded Sparkle from: $sparkle_src"
