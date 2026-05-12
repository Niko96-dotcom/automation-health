---
phase: 13-signed-and-notarized-dmg-with-ci-pipeline
reviewed: 2026-05-12T12:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - entitlements/release.entitlements
  - script/release.sh
  - .github/workflows/release.yml
  - docs/release-process.md
findings:
  critical: 2
  warning: 5
  info: 2
  total: 9
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-05-12T12:00:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the signed-and-notarized DMG release pipeline: the entitlements plist, the release build/sign/notarize script, the GitHub Actions CI workflow, and release documentation. The overall architecture is sound -- the pipeline correctly sequences build, signing with hardened runtime, DMG creation, notarization, and stapling. However, two critical issues (version string corruption and incorrect CFBundleIconFile value) and several warnings around error handling and edge cases should be addressed before relying on this pipeline for production releases.

---

## Critical Issues

### CR-01: GITHUB_REF_NAME contains `refs/tags/` prefix, corrupting version string and file paths

**File:** `script/release.sh:15`
**Issue:** The line `VERSION="${GITHUB_REF_NAME:-$(git -C "$ROOT_DIR" describe --tags --always --dirty)}"` uses `GITHUB_REF_NAME` as a fallback default. However, in GitHub Actions, `GITHUB_REF_NAME` is always the short ref name -- e.g., `v1.3.0` for a tag push. So `GITHUB_REF_NAME` itself would be correct. But if the workflow is ever run via `workflow_dispatch` (which is enabled on line 7 of the workflow) without a tag context, `GITHUB_REF_NAME` could be `main` or a branch name, producing `dist/AutomationHealth-main.dmg`. Furthermore, if `GITHUB_REF_NAME` were ever to contain `refs/tags/v1.3.0` due to a GitHub Actions version change or a manual override, the resulting DMG path `dist/AutomationHealth-refs/tags/v1.3.0.dmg` would create nested directories and an invalid file structure.

Additionally, the `git describe --tags --always --dirty` command embeds `--dirty`, meaning if the working tree is dirty (uncommitted changes), the version string becomes `v1.3.0-1-gabcdef-dirty`. This is a valid git describe format, but the `-dirty` suffix would embed into `CFBundleShortVersionString` in Info.plist, potentially causing issues with version comparison or App Store validation tools.

**Fix:**
```bash
# Strip potential prefix and handle dirty state more gracefully
RAW_VERSION="${GITHUB_REF_NAME:-$(git -C "$ROOT_DIR" describe --tags --always)}"
VERSION="${RAW_VERSION#refs/tags/}"
# Remove leading 'v' if present for Info.plist (or keep it -- be consistent)
# Ensure VERSION is never empty
if [ -z "$VERSION" ]; then
  VERSION="0.0.0-dev"
fi
```

---

### CR-02: CFBundleIconFile includes `.icns` extension, which breaks icon display on some macOS versions

**File:** `script/release.sh:92-93`
**Issue:** The Info.plist writes:
```xml
<key>CFBundleIconFile</key>
<string>$ICON_NAME.icns</string>
```
Apple's [CFBundleIconFile documentation](https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleiconfile) states: "Do not include the filename extension in the value." On some macOS versions, including `.icns` causes the system to look for `AutomationHealth.icns.icns` or fail to find the icon entirely.

**Fix:**
```bash
  <key>CFBundleIconFile</key>
  <string>$ICON_NAME</string>
```

---

## Warnings

### WR-01: hdiutil create with -attach has no error handling for mount failure

**File:** `script/release.sh:122`
**Issue:** `hdiutil create -size 150m -volname "$DISPLAY_NAME" -fs HFS+ -attach "$TMP_DMG"` performs both creation and mounting in one step. If the mount fails (e.g., volume with that name already mounted, sandbox restrictions, disk full), line 124 silently operates on a filesystem path at `/Volumes/$DISPLAY_NAME/` which may not exist or may point to an unrelated volume. With `set -euo pipefail`, the script would exit if `cp` or `ln` fails, but not before potentially polluting the wrong mount point.

**Fix:**
```bash
DISK_ID=$(hdiutil create -size 150m -volname "$DISPLAY_NAME" -fs HFS+ -attach "$TMP_DMG" | awk '/^\/dev\//{print $1}')
if [ -z "$DISK_ID" ]; then
  echo "Error: Failed to create and mount DMG" >&2
  exit 1
fi
MOUNT_POINT=$(hdiutil info | grep "^$DISK_ID" | awk '{print $3}')
if [ ! -d "$MOUNT_POINT" ]; then
  echo "Error: Mount point not found for $DISK_ID" >&2
  exit 1
fi
cp -R "$APP_BUNDLE" "$MOUNT_POINT/"
ln -s /Applications "$MOUNT_POINT/Applications"
```

---

### WR-02: hdiutil info parsing for disk ID is fragile across macOS versions

**File:** `script/release.sh:146`
**Issue:** `hdiutil info | grep "/Volumes/$DISPLAY_NAME" | awk '{print $1}'` relies on specific column alignment in `hdiutil info` output. On different macOS versions or with different locale settings, the field layout could differ. Additionally, if multiple volumes have the same name (matching the grep), the wrong disk ID could be returned.

**Fix:**
```bash
DISK_ID=$(hdiutil info -plist | plutil -extract "images" json -o - - | \
  jq -r --arg NAME "$DISPLAY_NAME" '
    to_entries[] | .value | 
    select(."system-entities" != null) |
    ."system-entities"[] |
    select(."mount-point" == "/Volumes/\($NAME)") |
    ."dev-entry" // empty'
  )
```
Or, at minimum, use the disk identifier returned by `hdiutil create` in step 5 rather than re-parsing.

---

### WR-03: spctl assessment failure is silently downgraded to a warning

**File:** `script/release.sh:185`
**Issue:** The line `spctl --assess --verbose --type install "$DMG_PATH" || echo "Warning: spctl assessment requires a non-development Mac or cleared assessment history"` silently converts a real spctl failure into a success exit code. If the DMG is genuinely not passing Gatekeeper assessment, the script reports success and the CI pipeline proceeds as if everything is fine.

**Fix:**
```bash
if spctl --assess --verbose --type install "$DMG_PATH"; then
  echo "Gatekeeper assessment: passed"
else
  SPCTL_EXIT=$?
  echo "Warning: spctl assessment returned exit code $SPCTL_EXIT" >&2
  echo "This may be normal on development Macs or if assessment history is stale." >&2
  echo "Verify on a clean non-development Mac before distributing." >&2
  # Do NOT exit 0 here; let the caller decide
  exit $SPCTL_EXIT
fi
```
Alternatively, if the intent is to allow this step to be non-fatal on development machines, make it configurable with a flag like `--skip-gatekeeper-check` and default to failing.

---

### WR-04: Release step silently picks wrong DMG if multiple match the glob

**File:** `.github/workflows/release.yml:93` and `.github/workflows/release.yml:86`
**Issue:** Both `dist/AutomationHealth-*.dmg` globs use `| head -1`, which silently takes the first match. If the `dist/` directory contains an old DMG from a previous failed run or stale artifact, the wrong DMG gets uploaded and released. This is particularly concerning because the version string is embedded in the filename -- the glob could match `dist/AutomationHealth-v1.3.0.dmg` and `dist/AutomationHealth-v1.3.1.dmg`, and `head -1` would select whichever appears first in directory order (not always the newest).

**Fix:**
```yaml
- name: Verify single DMG exists
  run: |
    DMG_COUNT=$(ls dist/AutomationHealth-*.dmg 2>/dev/null | wc -l)
    if [ "$DMG_COUNT" -eq 0 ]; then
      echo "Error: No DMG found in dist/" >&2
      exit 1
    fi
    if [ "$DMG_COUNT" -gt 1 ]; then
      echo "Error: Multiple DMGs found in dist/. Clean up before retrying:" >&2
      ls dist/AutomationHealth-*.dmg >&2
      exit 1
    fi
    echo "DMG_COUNT=1" >> $GITHUB_ENV
```
Then reference the single file explicitly:
```yaml
- name: Upload DMG artifact
  uses: actions/upload-artifact@v4
  with:
    name: automation-health-dmg
    path: dist/AutomationHealth-*.dmg
    if-no-files-found: error
```
The `if-no-files-found: error` flag ensures the step fails if no DMG is found.

---

### WR-05: Developer ID identity grep could match an expired certificate

**File:** `.github/workflows/release.yml:55`
**Issue:** `security find-identity -v -p codesigning build.keychain | grep "Developer ID Application" | head -1` takes the first matching certificate, but if multiple Developer ID Application certificates exist (common when renewing an expiring cert), `head -1` may select the expired one. The codesign step would then fail with an opaque error.

**Fix:**
```bash
DEVELOPER_IDENTITY=$(security find-identity -v -p codesigning build.keychain | \
  grep "Developer ID Application" | \
  grep -v "EXPIRED" | \
  head -1 | \
  sed -E 's/.*"([^"]+)".*/\1/')
```
If `security find-identity` outputs a validity status, filter by that. Alternatively, select the certificate with the latest expiry date.

---

## Info

### IN-01: Hardcoded DMG size (150m) may become insufficient

**File:** `script/release.sh:122`
**Issue:** `hdiutil create -size 150m` hardcodes the DMG size at 150MB. If the binary size grows beyond this limit, DMG creation will fail. While not a bug today, this is a magic number with no documentation about how it was derived or when it should be updated.

**Fix:** Add a comment explaining the sizing rationale, or compute the size dynamically:
```bash
APP_SIZE=$(du -sm "$STAGING/package" | awk '{print $1}')
DMG_SIZE=$((APP_SIZE + 50))  # 50MB padding
```

---

### IN-02: Debug output (--verbose flags) printed in CI logs

**File:** `script/release.sh:109,116,153`
**Issue:** Multiple `codesign --verify --verbose` and `codesign --deep --force --verify --verbose` calls produce verbose output in CI logs. For CI pipelines, this adds noise but is not harmful. However, the `--verbose` output of `codesign` could leak details about the signing certificate that appear in public CI logs if the repository is open-source.

**Fix:** Consider making verbose output conditional:
```bash
CODESIGN_VERBOSE=""
if [ "${VERBOSE:-0}" = "1" ]; then
  CODESIGN_VERBOSE="--verbose"
fi
codesign --deep --force --verify $CODESIGN_VERBOSE --sign "$APPLE_DEVELOPER_IDENTITY" ...
```

---

_Reviewed: 2026-05-12T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
