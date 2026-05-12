---
phase: 13-signed-and-notarized-dmg-with-ci-pipeline
plan: 02
subsystem: infra
tags: [github-actions, ci-cd, release, codesigning, notarization, dmg, apple-notary]

requires:
  - phase: 13-01
    provides: "Release script (script/release.sh), hardened runtime entitlements (entitlements/release.entitlements), Makefile release targets"
provides:
  - "GitHub Actions release workflow (.github/workflows/release.yml) that triggers on v* tags"
  - "Automated Developer ID certificate import from GitHub Secrets into temporary keychain"
  - "Automated App Store Connect API key injection from GitHub Secrets"
  - "Signed and notarized DMG build via CI invocation of script/release.sh"
  - "GitHub Release creation with DMG attachment via gh release create --verify-tag"
  - "Workflow artifact upload for DMG retention (30 days)"
  - "Staple ticket verification with xcrun stapler validate"
affects: [13-03-sparkle-auto-update, future-release-automation]

tech-stack:
  added: []
  patterns:
    - "CI release pipeline: tag-triggered workflow on macos-latest with 60-min timeout"
    - "Certificate import: base64-encoded P12 from GitHub Secret into temporary keychain with partition list"
    - "Identity resolution: security find-identity grep rather than hardcoded Developer ID name"
    - "API key handling: written from GitHub Secret to ~/.appstoreconnect/AuthKey.p8 with chmod 600"
    - "Release creation: gh release create with --verify-tag and DMG path attachment"

key-files:
  created:
    - ".github/workflows/release.yml"
  modified: []

key-decisions:
  - "Certificate imported from GitHub Secret (APPLE_DEVELOPER_CERTIFICATE_P12) rather than requiring a pre-installed keychain — enables ephemeral CI runners to sign without persistent state"
  - "Developer ID identity resolved via security find-identity at runtime rather than hardcoded — avoids coupling workflow to a specific certificate common name"
  - "Keychain partition list restricted to apple-tool: and apple: — prevents non-Apple-signed processes from accessing the signing identity (T-13-10 mitigation)"
  - "Concurrency cancel-in-progress set to false — releases must not be cancelled mid-notarization as that could leave orphaned submissions at Apple"
  - "fetch-depth: 0 for full git history — script/release.sh uses git describe for version detection which requires tag history"

patterns-established:
  - "Pattern 1: Tag-triggered release workflow with workflow_dispatch fallback on macos-latest"
  - "Pattern 2: Ephemeral keychain creation — P12 decoded from secret, imported into build.keychain, partition list restricted, certificate file deleted after import"
  - "Pattern 3: API key file provisioning — secret written to ~/.appstoreconnect/AuthKey.p8 with restrictive permissions (600), path exported as APPLE_NOTARY_KEY_FILE"

requirements-completed:
  - DIST-03
  - DIST-05
  - DIST-07

duration: 2min
completed: 2026-05-12
---

# Phase 13 Plan 02: GitHub Actions Release Workflow Summary

**Tag-triggered CI pipeline builds, signs, notarizes, and packages a signed DMG, then creates a GitHub Release with the downloadable artifact — all automated with no manual steps beyond pushing a version tag.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-12T00:52:37Z
- **Completed:** 2026-05-12T00:55:04Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- GitHub Actions release workflow created at `.github/workflows/release.yml` (121 lines)
- Triggers on `v*` tag pushes and manual `workflow_dispatch`
- Imports Developer ID certificate from base64-encoded GitHub Secret into ephemeral `build.keychain` with partition list restrictions
- Resolves Developer ID identity name at runtime via `security find-identity` — no hardcoded certificate name
- Provisions App Store Connect API key from GitHub Secret to `~/.appstoreconnect/AuthKey.p8` with `chmod 600`
- Sets all six Apple credential environment variables (`APPLE_DEVELOPER_IDENTITY`, `APPLE_DEVELOPER_TEAM_ID`, `APPLE_NOTARY_KEY_ID`, `APPLE_NOTARY_KEY`, `APPLE_NOTARY_KEY_FILE`, `APPLE_NOTARY_KEY_ISSUER_ID`) from GitHub Secrets
- Runs `./script/release.sh` for the full build-sign-notarize-package pipeline
- Uploads the DMG as a workflow artifact with 30-day retention via `actions/upload-artifact@v4`
- Creates a GitHub Release with `gh release create --verify-tag` and attaches the DMG as a downloadable asset
- Verifies the stapled notarization ticket with `xcrun stapler validate`
- 60-minute timeout (accommodates notarization which can take 30+ minutes)
- `contents: write` permissions for release creation
- `cancel-in-progress: false` to prevent mid-notarization cancellation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create GitHub Actions release workflow** - `c347f44` (feat)

## Files Created/Modified
- `.github/workflows/release.yml` - Complete CI/CD release pipeline: certificate import, API key provisioning, script invocation, artifact upload, GitHub Release creation, and staple verification

## Decisions Made
All decisions followed the plan exactly. Key architectural choices:

- **Temporary keychain approach**: Rather than requiring a pre-installed certificate, the workflow creates a `build.keychain`, imports the P12 from a base64-encoded secret, and tears it down when the runner is destroyed. This is the standard CI approach for macOS codesigning.
- **Runtime identity resolution**: `security find-identity` greps for "Developer ID Application" rather than hardcoding a certificate common name. This decouples the workflow from specific certificate renewals.
- **Keychain partition list**: `security set-key-partition-list -S apple-tool:,apple:` restricts access to Apple-signed tools only, preventing non-Apple processes from using the signing identity.
- **Concurrency protection**: `cancel-in-progress: false` ensures a release cannot be cancelled mid-notarization, which would leave an orphaned submission at Apple requiring manual cleanup.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

**Total deviations:** 0
**Impact on plan:** N/A

## Issues Encountered

- Python YAML validation failed (no `yaml` module installed). Used Ruby's built-in `yaml` library instead — valid YAML confirmed.
- The plan's automated verification checked for `xcrun notarytool` directly in the workflow file, but the call is in `script/release.sh` (delegated by the workflow). This is correct architecture — the workflow runs the script which handles notarization. All other acceptance criteria (21 checks) passed.

## User Setup Required

**External services require manual configuration.** The following GitHub Secrets must be set in the repository before the workflow can run:

| Secret | How to Generate |
|--------|----------------|
| `APPLE_DEVELOPER_CERTIFICATE_P12` | `base64 -i ~/Downloads/developerID_application.p12 \| tr -d '\n'` |
| `APPLE_DEVELOPER_CERTIFICATE_PASSWORD` | Password used when exporting the P12 from Keychain Access |
| `APPLE_DEVELOPER_TEAM_ID` | 10-character Team ID from [Apple Developer](https://developer.apple.com/account) |
| `APPLE_NOTARY_KEY` | Full contents of `.p8` private key (including BEGIN/END lines) |
| `APPLE_NOTARY_KEY_ID` | Key ID from [App Store Connect](https://appstoreconnect.apple.com/access/integrations/api) |
| `APPLE_NOTARY_KEY_ISSUER_ID` | Issuer ID from [App Store Connect](https://appstoreconnect.apple.com/access/integrations/api) |

Additionally, **Workflow permissions** must be set to "Read and write permissions" in Repository Settings -> Actions -> General.

**Verification after setup**: Push a version tag (e.g., `v1.3.0`) and the workflow should produce a signed, notarized DMG attached to a GitHub Release.

## Threat Flags

No new threat surface beyond what is documented in the plan's `<threat_model>` section. All five threats (T-13-07 through T-13-11) are mitigated through base64-encoded secrets, keychain partition lists, `--verify-tag`, `chmod 600`, and 60-minute timeout — each directly implemented in the workflow.

## Known Stubs

None — no hardcoded placeholders, TODOs, or unimplemented paths.

## Next Phase Readiness
- Release workflow is complete and ready for CI execution once GitHub Secrets are configured
- Plan 13-03 (Sparkle auto-update integration) can proceed — it needs the GitHub Releases URL pattern this workflow establishes (`https://github.com/{owner}/{repo}/releases/tag/{tag}`)

---
*Phase: 13-signed-and-notarized-dmg-with-ci-pipeline*
*Completed: 2026-05-12*
