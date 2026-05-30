#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=sparkle_tools.sh
source "$ROOT_DIR/script/sparkle_tools.sh"

echo "=== Sparkle EdDSA Key Generator ==="
echo ""

TOOLS_DIR="$(ensure_sparkle_tools "$ROOT_DIR")"
echo "Using Sparkle tools at $TOOLS_DIR"
echo ""

GENERATE_KEYS="$(find_sparkle_tool "$ROOT_DIR" generate_keys)"
if [[ -z "$GENERATE_KEYS" ]]; then
  echo "Error: Could not find generate_keys binary in Sparkle release." >&2
  echo "Check $TOOLS_DIR for contents." >&2
  exit 1
fi

echo "=== Running generate_keys ==="
echo ""

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
echo "   $GENERATE_KEYS -x /tmp/sparkle-ed25519.key"
echo "   base64 < /tmp/sparkle-ed25519.key | tr -d '\\n' | pbcopy"
echo ""
echo "3. Save the output as GitHub Secret: SPARKLE_EDDSA_PRIVATE_KEY"
echo ""
echo "4. Clean up Sparkle tools when done:"
echo "   rm -rf $TOOLS_DIR"
