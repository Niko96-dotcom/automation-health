#!/usr/bin/env bash
# Shared Sparkle CLI toolchain helpers. Keep SPARKLE_VERSION in sync with Package.swift.
set -euo pipefail

SPARKLE_VERSION="${SPARKLE_VERSION:-2.9.1}"
SPARKLE_ZIP="Sparkle-for-Swift-Package-Manager.zip"
SPARKLE_URL="https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/${SPARKLE_ZIP}"

sparkle_tools_dir() {
  local root_dir="${1:?repository root required}"
  echo "$root_dir/.sparkle-tools"
}

find_sparkle_tool() {
  local root_dir="${1:?repository root required}"
  local tool_name="${2:?tool name required}"
  local tools_dir
  tools_dir="$(sparkle_tools_dir "$root_dir")"
  find "$tools_dir" -name "$tool_name" -type f -perm +111 2>/dev/null | head -1
}

ensure_sparkle_tools() {
  local root_dir="${1:?repository root required}"
  local tools_dir
  tools_dir="$(sparkle_tools_dir "$root_dir")"

  if [[ -n "$(find_sparkle_tool "$root_dir" generate_appcast)" || -n "$(find_sparkle_tool "$root_dir" generate_keys)" ]]; then
    echo "$tools_dir"
    return 0
  fi

  echo "=== Downloading Sparkle ${SPARKLE_VERSION} tools ===" >&2
  mkdir -p "$tools_dir"
  curl -fsSL -o "$tools_dir/$SPARKLE_ZIP" "$SPARKLE_URL"
  unzip -q -o "$tools_dir/$SPARKLE_ZIP" -d "$tools_dir"
  echo "Sparkle tools extracted to $tools_dir" >&2
  echo "$tools_dir"
}
