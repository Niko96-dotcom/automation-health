---
phase: 14-sparkle-auto-update-integration
plan: 03
subsystem: infra
tags: [sparkle, appcast, eddsa, release-pipeline, ci, bash]

# Dependency graph
requires:
  - phase: 14-sparkle-auto-update-integration
    plan: 01
    provides: "Sparkle 2 SPM dependency, UpdateStore ObservableObject, SPUUpdater wiring"
provides:
  - "Sparkle appcast generation step in release.sh (Step 11), signed with EdDSA private key"
  - "Updated release-process.md with complete Sparkle setup documentation (key generation, public key embedding, private key export, CI secret, appcast upload)"
  - "dist/appcast.xml output from release pipeline, referencing GitHub Releases download URLs"
affects:
  - "Future CI release workflow (needs SPARKLE_EDDSA_PRIVATE_KEY secret and appcast.xml upload)"
  - "Developer onboarding (generate_sparkle_keys.sh + SUPublicEDKey in Info.plist)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "generate_appcast tool with -f flag for file-based EdDSA private key (not Keychain, for CI compatibility)"
    - "Base64-encoded SPARKLE_EDDSA_PRIVATE_KEY env var piped through base64 --decode for temporary signing"
    - "appcast.xml URL rewriting from local file:// to GitHub Releases download URLs via sed"
    - "Non-failing appcast generation — DMG is always produced; missing key/tool causes warning, not error"

key-files:
  modified:
    - script/release.sh
    - docs/release-process.md

key-decisions:
  - "Appcast generation is a non-failing step — missing credentials or tools warn but do not block the release"
  - "generate_appcast uses -f flag for file-based private key input rather than Keychain lookup, enabling CI usage"
  - "Temporary private key file deleted immediately after generate_appcast completes"
  - "appcast.xml enclosure URLs rewritten from file:// to GitHub Releases download URLs for Sparkle to find the DMG"

patterns-established:
  - "EdDSA private key: stored in Keychain locally, exported as base64 for GitHub Secret, decoded to temp file at runtime"
  - "Non-critical release steps: appcast generation skips gracefully, never blocks DMG production"

requirements-completed:
  - DIST-08

# Metrics
duration: 5min
completed: 2026-05-12
---

# Phase 14 Plan 03: Appcast Pipeline + Documentation Summary

**Release pipeline extended with Sparkle appcast generation and complete Sparkle setup documentation for the release process**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-12T08:50:01Z
- **Completed:** 2026-05-12T08:55:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Release pipeline (`script/release.sh`) now generates a signed `dist/appcast.xml` via `generate_appcast` with EdDSA private key signing
- Appcast generation gracefully handles three failure modes: dev version (skip), missing env var (warn), missing tool (warn) — DMG is always produced
- Appcast enclosure URLs are rewritten from local `file://` paths to GitHub Releases download URLs for Sparkle to find updates
- Release documentation (`docs/release-process.md`) now has a complete "Sparkle Auto-Update Setup" section covering key generation, public key embedding, private key export, CI secret setup, and appcast upload
- CI secrets table updated with `SPARKLE_EDDSA_PRIVATE_KEY` entry
- Architecture diagram updated with `generate_appcast` and `appcast.xml` in the flow
- Troubleshooting section covers Sparkle-specific failure modes (missing private key, missing public key in Info.plist)
- Key rotation guidance included with link to Sparkle's EdDSA migration documentation

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Sparkle appcast generation to release.sh** - `cc88adf` (feat)
2. **Task 2: Update release documentation with Sparkle setup** - `a660d46` (docs)

## Files Created/Modified
- `script/release.sh` - Added Step 11 (Generate Sparkle appcast) after notarization, renamed success summary to Step 12. Locates `generate_appcast` from `.sparkle-tools` cache or SPM checkouts, decodes EdDSA key from base64, generates signed appcast.xml, rewrites URLs to GitHub Releases, cleans up temp key file
- `docs/release-process.md` - Added "Sparkle Auto-Update Setup" H2 section (5 steps), updated prerequisites, CI secrets table, Architecture diagram, and Troubleshooting section with Sparkle entries

## Decisions Made

- Appcast generation is non-failing: only warns on missing credentials/tools, never blocks the DMG from being produced (plan specification followed)
- `generate_appcast` uses `-f` flag for file-based private key input (not Keychain lookup), enabling CI compatibility (plan specification followed)
- Temporary private key file is base64-decoded, used for signing, and immediately deleted afterward (plan specification + threat model mitigation T-14-11)
- `dist/appcast.xml` is the artifact to upload alongside the DMG in the GitHub Release (Step 12 references this)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. The documentation in `docs/release-process.md` covers all Sparkle setup steps for developers.

## Next Phase Readiness

- `script/release.sh` now produces `dist/appcast.xml` (alongside the DMG) for releases with `SPARKLE_EDDSA_PRIVATE_KEY` set
- Release documentation fully documents the Sparkle auto-update workflow
- Plan 14-04 or CI workflow modifications should wire the appcast into `.github/workflows/release.yml` (referenced as Step 5 in docs but not yet implemented in the workflow YAML)

---
*Phase: 14-sparkle-auto-update-integration*
*Completed: 2026-05-12*
