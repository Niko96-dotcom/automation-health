---
phase: 13-signed-and-notarized-dmg-with-ci-pipeline
fixed_at: 2026-05-12T09:50:00Z
review_path: .planning/phases/13-signed-and-notarized-dmg-with-ci-pipeline/13-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 13: Code Review Fix Report

**Fixed at:** 2026-05-12T09:50:00Z
**Source review:** .planning/phases/13-signed-and-notarized-dmg-with-ci-pipeline/13-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (2 critical, 5 warning)
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: GITHUB_REF_NAME used for version, corrupting version strings on workflow_dispatch

**Files modified:** `script/release.sh`
**Commit:** de138fc
**Applied fix:** Replaced `GITHUB_REF_NAME` / `git describe --tags --always --dirty` with `git describe --tags --abbrev=0`, stripped leading `v`, and added a safe fallback to `0.0.0-dev`. Removed `--dirty` flag.

### CR-02: CFBundleIconFile includes .icns extension, breaking icon display

**Files modified:** `script/release.sh`
**Commit:** 80bf3eb
**Applied fix:** Changed `<string>$ICON_NAME.icns</string>` to `<string>$ICON_NAME</string>` in Info.plist template, per Apple's CFBundleIconFile documentation.

### WR-01: hdiutil create -attach has no error handling

**Files modified:** `script/release.sh`
**Commit:** 4070386 (combined with WR-02)
**Applied fix:** Capture hdiutil exit code; exit non-zero on failure. Confirm mount point exists before writing to it. Use `$MOUNT_POINT` variable instead of inline `/Volumes/$DISPLAY_NAME`.

### WR-02: hdiutil info text parsing for disk ID is fragile

**Files modified:** `script/release.sh`
**Commit:** 4070386 (combined with WR-01)
**Applied fix:** Switched from `hdiutil info | grep | awk` to `hdiutil create -plist` output mode with `plutil` to extract `dev-entry`. Removed the fragile `hdiutil info` parsing entirely.

### WR-03: spctl assessment failure silently downgraded to a warning

**Files modified:** `script/release.sh`
**Commit:** 6cf05ff
**Applied fix:** Replaced `spctl ... || echo "Warning..."` with an explicit `if/else` block that captures the exit code and calls `exit $SPCTL_EXIT` on failure.

### WR-04: Release step picks wrong DMG if multiple match the glob

**Files modified:** `.github/workflows/release.yml`
**Commit:** 8994dec
**Applied fix:** Added `DMG_PATH` env extraction from the build step output via `tee /tmp/release-output.txt`. Replaced all `ls dist/AutomationHealth-*.dmg | head -1` patterns with `$DMG_PATH`. Added `if-no-files-found: error` to the artifact upload step.

### WR-05: Developer ID identity grep could match an expired certificate

**Files modified:** `.github/workflows/release.yml`
**Commit:** 44358e7
**Applied fix:** Added `grep -iv "EXPIRED"` filter to the `security find-identity` pipeline to exclude expired certificates before selecting the first match.

---

_Fixed: 2026-05-12T09:50:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
