---
phase: 13-signed-and-notarized-dmg-with-ci-pipeline
plan: 01
subsystem: distribution
tags: [codesigning, notarization, DMG, release-pipeline, hardened-runtime]
dependency-graph:
  requires: []
  provides: [entitlements/release.entitlements, script/release.sh, Makefile dmg/release targets]
  affects: [CI release workflow (plan 13-02), release docs (plan 13-03)]
decisions: []
tech-stack:
  added: [entitlements plist, notarytool, stapler, hdiutil, osascript DMG layout]
  patterns: [Bash scripts with set -euo pipefail, Makefile PHONY targets, env var credential validation]
key-files:
  created:
    - entitlements/release.entitlements (hardened runtime entitlements)
    - script/release.sh (11-step release pipeline, 194 lines)
  modified:
    - Makefile (dmg and release targets)
metrics:
  completed_date: "2026-05-12"
  duration: 3 min
  task_count: 3
  file_count: 3
---

# Phase 13 Plan 01: Release Pipeline Script and Entitlements Summary

**One-liner:** End-to-end release script that builds, codesigns with hardened runtime, packages into DMG, notarizes via notarytool, and staples the notarization ticket — plus hardened runtime entitlements file and Makefile targets.

## Plan Goal

Create `script/release.sh` — a single-invocation Bash script that takes Apple Developer credentials from environment variables and produces a Gatekeeper-compatible signed-and-notarized DMG ready for distribution. Also create the hardened runtime entitlements file required for notarization, and wire `make dmg` / `make release` targets in the Makefile.

## What Was Built

### Task 1: Hardened Runtime Entitlements (`entitlements/release.entitlements`)

Created `entitlements/release.entitlements` with a single entitlement: `com.apple.security.get-task-allow` set to `false`. This prevents debugger attachment to distribution builds and is required by Apple for notarization. The hardened runtime itself is activated by the `--options runtime` codesign flag in the release script.

### Task 2: Release Pipeline Script (`script/release.sh`)

Created a 194-line Bash script implementing an 11-step release pipeline:

1. **Validate credentials** — checks all 6 env vars (`APPLE_DEVELOPER_IDENTITY`, `APPLE_DEVELOPER_TEAM_ID`, `APPLE_NOTARY_KEY_ID`, `APPLE_NOTARY_KEY_FILE`, `APPLE_NOTARY_KEY_ISSUER_ID`, `GITHUB_TOKEN`) with actionable error messages per variable
2. **Build release binary** — `swift build --configuration release`
3. **Assemble .app bundle** — copies binary, generates icon (if stale), writes Info.plist with version from `GITHUB_REF_NAME` or `git describe`
4. **Codesign with hardened runtime** — `codesign --deep --force --verify --verbose --sign "$APPLE_DEVELOPER_IDENTITY" --options runtime --entitlements entitlements/release.entitlements --timestamp`
5. **Create DMG** — `hdiutil create` + AppleScript Finder layout (app at {160,140}, Applications alias at {360,140}) + convert to UDZO compressed read-only
6. **Codesign the DMG** — signs with `--timestamp` and verifies
7. **Submit for notarization** — `xcrun notarytool submit ... --wait --output-format json`, checks status is "Accepted"
8. **Log notary submission** — `xcrun notarytool log` with the submission ID
9. **Staple notarization ticket** — `xcrun stapler staple`
10. **Verify** — `xcrun stapler validate` + `spctl --assess`
11. **Success summary** — prints DMG path, size, notarization status

All intermediate files go into `.release-staging/` (gitignored). DMG output is `dist/AutomationHealth-{version}.dmg`.

### Task 3: Makefile Targets

Added `dmg` and `release` targets to the Makefile (both invoke `./script/release.sh`), updated `.PHONY` declaration, and added help text. All 8 existing targets (build, test, ci, run, verify, debug, logs, clean) remain unchanged.

## Success Criteria Met

- [x] `entitlements/release.entitlements` exists with `com.apple.security.get-task-allow = false`
- [x] `script/release.sh` is a complete release pipeline (build -> codesign -> DMG -> notarize -> staple -> verify)
- [x] Makefile targets `make dmg` and `make release` exist
- [x] DIST-01 (Developer ID codesign), DIST-02 (hardened runtime entitlements), DIST-03 (notarization recipe), DIST-04 (signed+notarized DMG) all have corresponding implementation

## Deviations from Plan

None — plan executed exactly as written. All three tasks completed with all acceptance criteria passing. No Rule 1-4 deviations encountered.

## Deferred Items

None.

## Known Stubs

None.

## Threat Flags

None. All threat surfaces match the plan's threat model.

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | f4a5bcb | feat(13-01): create hardened runtime entitlements file |
| 2 | 8764fee | feat(13-01): create release script — build, codesign, DMG, notarize, staple |
| 3 | f4a8f6a | feat(13-01): add make dmg and make release targets to Makefile |

## Files

| File | Status | Lines |
|------|--------|-------|
| entitlements/release.entitlements | created | 8 |
| script/release.sh | created | 194 |
| Makefile | modified | +9/-1 |

## Self-Check: PASSED

- [x] entitlements/release.entitlements exists
- [x] script/release.sh exists and is executable
- [x] Makefile has dmg/release targets
- [x] Commit f4a5bcb exists
- [x] Commit 8764fee exists
- [x] Commit f4a8f6a exists
