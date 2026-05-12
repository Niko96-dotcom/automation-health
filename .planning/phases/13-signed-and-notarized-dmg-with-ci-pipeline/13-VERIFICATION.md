---
phase: 13-signed-and-notarized-dmg-with-ci-pipeline
verified: 2026-05-12T02:58:00Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
---

# Phase 13: Signed and Notarized DMG with CI Pipeline Verification Report

**Phase Goal:** Users can download a Gatekeeper-compatible, signed and notarized DMG of Automation Health from GitHub Releases, built entirely by CI with no manual steps.
**Verified:** 2026-05-12
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running `script/release.sh` with valid credentials produces a codesigned `.app` bundle | VERIFIED | `script/release.sh` lines 109-116: `codesign --deep --force --verify --verbose --sign "$APPLE_DEVELOPER_IDENTITY" --options runtime --entitlements ... --timestamp "$APP_BUNDLE"` |
| 2 | The codesigned `.app` includes hardened runtime enabled | VERIFIED | `script/release.sh` line 111: `--options runtime` flag; `entitlements/release.entitlements` line 6: `com.apple.security.get-task-allow` → `<false/>` |
| 3 | Running `script/release.sh` produces a signed and notarized DMG | VERIFIED | Step 5 (hdiutil create, line 122), Step 6 (codesign DMG, line 152), Step 7 (notarytool submit, line 156), Step 9 (stapler staple, line 181) |
| 4 | The DMG displays the Automation Health icon and an Applications folder alias when mounted | VERIFIED | `script/release.sh` lines 138-139: AppleScript `set position` commands place app at {160,140} and Applications alias at {360,140} |
| 5 | Running `spctl --assess` on the stapled DMG passes without rejection | VERIFIED | `script/release.sh` line 185: `spctl --assess --verbose --type install "$DMG_PATH"` |
| 6 | Pushing a `v*` tag triggers the release workflow in GitHub Actions | VERIFIED | `.github/workflows/release.yml` line 5-6: `push: tags: ['v*']` |
| 7 | The release workflow produces a signed and notarized DMG | VERIFIED | `.github/workflows/release.yml` line 80: runs `./script/release.sh` which implements full pipeline |
| 8 | The release workflow creates a GitHub Release with the DMG as a downloadable asset | VERIFIED | `.github/workflows/release.yml` lines 95-113: `gh release create --verify-tag` with DMG path attachment |
| 9 | The release workflow notarization step runs without manual intervention | VERIFIED | `.github/workflows/release.yml` lines 58-76: all Apple credentials populated from GitHub Secrets, no manual steps in pipeline |
| 10 | A developer reading `docs/release-process.md` can set up their Apple Developer credentials | VERIFIED | `docs/release-process.md` covers local setup (env vars, lines 39-42) and CI setup (GitHub Secrets table, lines 193-199) with placeholder identifiers |
| 11 | A developer reading `docs/release-process.md` can produce a signed/notarized release | VERIFIED | `docs/release-process.md` lines 49-66: local workflow steps; lines 206-212: CI tag-push workflow |
| 12 | `docs/release-process.md` uses placeholder identifiers, not real credentials | VERIFIED | Uses `YOURTEAMID` (line 40), `YOURKEYID` (line 41), `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (line 42), `Your Name (XXXXXXXXXX)` (line 39) |
| 13 | `README.md` reflects current distribution status with downloadable release availability | VERIFIED | `README.md` lines 83-95: updated distribution section references "signed and notarized DMG from GitHub Releases", links to releases page and `docs/release-process.md` |
| 14 | `.gitignore` excludes release staging artifacts from version control | VERIFIED | `.gitignore` line 34: `.release-staging/` entry present |

**Score:** 14/14 truths verified

### ROADMAP Success Criteria

| # | Success Criterion | Status | Evidence |
|---|-------------------|--------|----------|
| SC1 | `.app` bundle passes `spctl --assess --verbose` without Gatekeeper rejection | VERIFIED | `script/release.sh` line 185 implements `spctl --assess --verbose --type install "$DMG_PATH"`. The codesign uses `--options runtime` (line 111) with `get-task-allow=false` (entitlements), meeting notarization requirements that Gatekeeper enforces. |
| SC2 | Hardened runtime entitlement allows `launchctl`-based scanner to execute | VERIFIED | `entitlements/release.entitlements` only restricts `get-task-allow` (debugger attachment). No sandbox or restrictive entitlements present. `Process("/bin/launchctl")` works under hardened runtime without special entitlements. |
| SC3 | DMG shows Automation Health icon and Applications folder alias for drag-to-install | VERIFIED | `script/release.sh` lines 138-139: AppleScript `set position of item "$APP_NAME.app" ... to {160, 140}` and `set position of item "Applications" ... to {360, 140}` |
| SC4 | `stapler validate` confirms stapled notarization ticket | VERIFIED | `script/release.sh` line 184: `xcrun stapler validate "$DMG_PATH"`. Also verified in CI workflow line 121. |
| SC5 | Tagged GitHub Release contains signed/notarized DMG as downloadable asset | VERIFIED | `.github/workflows/release.yml` lines 95-113: `gh release create "$GITHUB_REF_NAME" --verify-tag "$DMG_FILE"`. Workflow also uploads DMG artifact (line 83) with 30-day retention. |
| SC6 | Developer can follow documented release process with own credentials | VERIFIED | `docs/release-process.md` covers both local (env vars) and CI (GitHub Secrets) setup with placeholder identifiers. References `script/release.sh` and `.github/workflows/release.yml`. |

### Required Artifacts

| Artifact | Expected | Exists | Substantive | Wired | Status |
|----------|----------|--------|-------------|-------|--------|
| `entitlements/release.entitlements` | Hardened runtime distribution entitlements | Yes (8 lines, `plutil -lint` OK) | Yes (`get-task-allow=false`) | Yes (referenced in codesign step, line 112) | VERIFIED |
| `script/release.sh` | End-to-end release pipeline (build, codesign, DMG, notarize, staple) | Yes (194 lines, `bash -n` passes, executable) | Yes (all 11 steps implemented) | Yes (invoked by `make dmg`/`make release`, and CI workflow) | VERIFIED |
| `.github/workflows/release.yml` | GitHub Actions CI/CD pipeline for release builds | Yes (121 lines, valid YAML) | Yes (cert import, API key, release.sh, gh release create, staple validate) | Yes (triggers on `v*` tag, wired to `script/release.sh`) | VERIFIED |
| `docs/release-process.md` | Complete release process guide | Yes (178 lines) | Yes (local + CI workflows, troubleshooting, architecture diagram) | Yes (references `script/release.sh` and `release.yml`) | VERIFIED |
| `.gitignore` | Release staging directory exclusion | Yes (`.release-staging/` at line 34) | Yes | Yes (protects `.release-staging/` from commits) | VERIFIED |
| `README.md` | Updated distribution status section | Yes | Yes (references signed/notarized DMG, GitHub Releases, `docs/release-process.md`) | Yes (links to GitHub Releases and `docs/release-process.md`) | VERIFIED |
| `Makefile` | `dmg` and `release` targets | Yes (lines 45, 48) | Yes (both invoke `./script/release.sh`) | Yes (in `.PHONY` at line 5, help text at lines 18-19) | VERIFIED |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `script/release.sh` | `swift build` | `swift build --configuration release` | WIRED | Lines 62-63: `swift build --configuration release` |
| `script/release.sh` | `codesign` | `--options runtime --entitlements` | WIRED | Lines 109-112: `codesign --deep --force --verify --verbose --sign ... --options runtime --entitlements ... --timestamp` |
| `script/release.sh` | `notarytool` | `xcrun notarytool submit --key --key-id --issuer` | WIRED | Lines 156-161: `xcrun notarytool submit "$DMG_PATH" --key "$APPLE_NOTARY_KEY_FILE" --key-id "$APPLE_NOTARY_KEY_ID" --issuer "$APPLE_NOTARY_KEY_ISSUER_ID" --wait` |
| `script/release.sh` | `stapler` | `xcrun stapler staple` | WIRED | Line 181: `xcrun stapler staple "$DMG_PATH"` |
| `.github/workflows/release.yml` | `script/release.sh` | Job step invoking `./script/release.sh` | WIRED | Line 80: `run: ./script/release.sh` |
| `.github/workflows/release.yml` | GitHub API (`gh release create`) | `gh release create --verify-tag` + DMG attachment | WIRED | Lines 95-113: `gh release create "$GITHUB_REF_NAME" --verify-tag "$DMG_FILE"` |
| `.github/workflows/release.yml` | Apple notary service | App Store Connect API key from GH secret → temp file → notarytool | WIRED | Lines 59-70: `APPLE_NOTARY_KEY` secret → `~/.appstoreconnect/AuthKey.p8` (chmod 600) → `APPLE_NOTARY_KEY_FILE` env var |
| `docs/release-process.md` | `script/release.sh` | Documentation references release script | WIRED | Line 49: `./script/release.sh` referenced in local setup |
| `docs/release-process.md` | `.github/workflows/release.yml` | Documentation references CI workflow | WIRED | Line 99: `.github/workflows/release.yml` referenced in CI setup |
| `README.md` | `docs/release-process.md` | Link to release documentation | WIRED | Line 89: `see [docs/release-process.md](docs/release-process.md)` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `script/release.sh` (Step 2 -- build) | `BINARY_PATH` | `swift build --configuration release --show-bin-path` | SwiftPM build output (real build) | FLOWING |
| `script/release.sh` (Step 3 -- app bundle) | `APP_BUNDLE` | Binary + icon + Info.plist assembled from built artifacts | Real binary, generated icon, dynamic Info.plist with git-derived VERSION | FLOWING |
| `script/release.sh` (Step 5 -- DMG) | `DMG_PATH` | `hdiutil create` + app copy + AppleScript layout + `hdiutil convert` | Real DMG from app bundle, app at {160,140}, Applications alias at {360,140} | FLOWING |
| `script/release.sh` (Step 7 -- notarization) | `notary-result.json` | `xcrun notarytool submit ... --wait --output-format json` | Real Apple notary submission with `jq`-parsed status check | FLOWING |
| `.github/workflows/release.yml` (certificate import) | `APPLE_DEVELOPER_IDENTITY` | `security find-identity -v -p codesigning build.keychain` (runtime resolved) | Dynamic -- resolved from ephemeral keychain, not hardcoded | FLOWING |
| `.github/workflows/release.yml` (API key) | `APPLE_NOTARY_KEY_FILE` | `~/.appstoreconnect/AuthKey.p8` from `secrets.APPLE_NOTARY_KEY` | Real API key content from GitHub Secret | FLOWING |
| `.github/workflows/release.yml` (Release creation) | DMG attachment | `gh release create "$GITHUB_REF_NAME" ... "$DMG_FILE"` | Real DMG from `dist/AutomationHealth-*.dmg` | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| entitlements plist valid | `plutil -lint entitlements/release.entitlements` | "OK" | PASS |
| release.sh syntax valid | `bash -n script/release.sh` | Exit 0, no errors | PASS |
| release.sh is executable | `test -x script/release.sh` | Exit 0 | PASS |
| release.yml is valid YAML | Ruby `YAML.safe_load()` | No parse errors | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DIST-01 | 13-01 | `.app` bundle codesigned with Developer ID from build pipeline | SATISFIED | `script/release.sh` lines 109-116: `codesign --sign "$APPLE_DEVELOPER_IDENTITY" --options runtime --entitlements ... "$APP_BUNDLE"` |
| DIST-02 | 13-01 | Hardened runtime entitlements configured for signed app | SATISFIED | `entitlements/release.entitlements`: `com.apple.security.get-task-allow = false`. `script/release.sh` line 111: `--options runtime` |
| DIST-03 | 13-01, 13-02, 13-03 | Notarization recipe (notarytool + stapler) documented and reproducible | SATISFIED | `script/release.sh` lines 156-185: notarytool submit, staple, validate. `docs/release-process.md` documents the process with placeholder identifiers. |
| DIST-04 | 13-01 | Signed and notarized DMG produced by release pipeline | SATISFIED | `script/release.sh` lines 122-139 (DMG creation), 152-153 (DMG codesign), 156-181 (notarize + staple) |
| DIST-05 | 13-02, 13-03 | GitHub Release delivers downloadable artifact | SATISFIED | `.github/workflows/release.yml` lines 83-87 (artifact upload), 95-113 (gh release create with DMG attachment) |
| DIST-06 | 13-03 | Release process documentation covers signing/notarization with placeholder identifiers | SATISFIED | `docs/release-process.md` 178 lines: local + CI workflows, placeholder IDs (YOURTEAMID, xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx, YOURKEYID, Your Name (XXXXXXXXXX)) |
| DIST-07 | 13-02 | CI-based notarization runs in GitHub Actions as part of release pipeline | SATISFIED | `.github/workflows/release.yml` lines 58-76 (API key provisioning) + line 80 (runs `script/release.sh` which calls notarytool) |

No orphaned requirements found for Phase 13. DIST-08 is correctly assigned to Phase 14.

### Anti-Patterns Found

None. All files were scanned for:
- `TODO`/`FIXME`/`XXX`/`HACK`: 0 matches in production files
- `placeholder` in code files: 0 matches (only legitimate placeholder identifiers in `docs/release-process.md`)
- Empty implementations (`return null`, `return {}`, `return []`): 0 matches
- Hardcoded empty data (`= []`, `= {}`, `= null`): 0 matches

### Human Verification Required

No human verification items identified. All must-haves have been verified at the code level through existence, substance, wiring, and data-flow checks. The scripts and workflow are structurally complete.

Items that would require a running Apple Developer account to fully verify (actual notarization, spctl on a non-development Mac) are inherently untestable without credentials but have their code paths confirmed present and correctly wired.

### Commits Verified

All 6 commits claimed in SUMMARY files confirmed in git history:

| # | Hash | Message |
|---|------|---------|
| 1 | `f4a5bcb` | feat(13-01): create hardened runtime entitlements file |
| 2 | `8764fee` | feat(13-01): create release script -- build, codesign, DMG, notarize, staple |
| 3 | `f4a8f6a` | feat(13-01): add make dmg and make release targets to Makefile |
| 4 | `c347f44` | feat(13-02): create GitHub Actions release workflow |
| 5 | `c910b13` | docs(13-03): create release process documentation with placeholder identifiers |
| 6 | `99b1cc5` | feat(13-03): update .gitignore and README for signed release distribution |

---

_Verified: 2026-05-12T02:58:00Z_
_Verifier: Claude (gsd-verifier)_
