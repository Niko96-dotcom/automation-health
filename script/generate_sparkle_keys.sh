#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPARKLE_VERSION="2.9.1"
SPARKLE_ZIP="Sparkle-for-Swift-Package-Manager.zip"
SPARKLE_URL="https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/${SPARKLE_ZIP}"
SPARKLE_DL_DIR="$ROOT_DIR/.sparkle-tools"

echo "=== Sparkle EdDSA Key Generator ==="
echo ""

# Step 1: Download Sparkle release if not already cached
if [[ ! -d "$SPARKLE_DL_DIR" ]]; then
  echo "=== Downloading Sparkle ${SPARKLE_VERSION} tools ==="
  mkdir -p "$SPARKLE_DL_DIR"
  curl -fsSL -o "$SPARKLE_DL_DIR/$SPARKLE_ZIP" "$SPARKLE_URL"
  unzip -q -o "$SPARKLE_DL_DIR/$SPARKLE_ZIP" -d "$SPARKLE_DL_DIR"
  echo "Sparkle tools extracted to $SPARKLE_DL_DIR"
else
  echo "Sparkle tools already cached at $SPARKLE_DL_DIR"
fi

# Step 2: Locate generate_keys binary
GENERATE_KEYS="$(find "$SPARKLE_DL_DIR" -name "generate_keys" -type f -perm +111 2>/dev/null | head -1)"
if [[ -z "$GENERATE_KEYS" ]]; then
  echo "Error: Could not find generate_keys binary in Sparkle release." >&2
  echo "Check $SPARKLE_DL_DIR for contents." >&2
  exit 1
fi

echo "=== Running generate_keys ==="
echo ""

# Run generate_keys
PUBLIC_KEY="$("$GENERATE_KEYS" 2>/dev/null)"
GEN_EXIT=$?

if [[ $GEN_EXIT -ne 0 ]]; then
  echo "Error: generate_keys failed with exit code $GEN_EXIT" >&2
  echo "Run manually: $GENERATE_KEYS" >&2
  exit $GEN_EXIT
fi

if [[ -z "$PUBLIC_KEY" ]]; then
  echo "Error: generate_keys produced no output." >&2
  exit 1
fi

echo "=== Key Generation Complete ==="
echo ""
echo "Public key (for Info.plist SUPublicEDKey):"
echo "  $PUBLIC_KEY"
echo ""
echo "The private key has been saved to your login Keychain."
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Add the public key to the app's Info.plist:"
echo "   <key>SUPublicEDKey</key>"
echo "   <string>$PUBLIC_KEY</string>"
echo ""
echo "2. Export the private key for CI:"
echo "   security find-generic-password -s 'Sparkle Private Key' -w"
echo ""
echo "3. Save the private key as a GitHub Secret: SPARKLE_EDDSA_PRIVATE_KEY"
echo ""
echo "4. Clean up Sparkle tools when done:"
echo "   rm -rf $SPARKLE_DL_DIR"
