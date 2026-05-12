---
phase: 13-signed-and-notarized-dmg-with-ci-pipeline
plan: 03
subsystem: documentation, distribution
tags: [docs, release-process, gitignore, readme, distribution]
results: pass
depends_on:
  - 13-01
key-decisions:
  - "Release process documentation covers both local (env vars) and CI (GitHub Secrets) workflows"
  - "Documentation uses placeholder identifiers only (YOURTEAMID, xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx, YOURKEYID, Your Name (XXXXXXXXXX))"
  - "README distribution section replaced with signed/notarized DMG availability from GitHub Releases"
  - ".release-staging/ excluded from version control for temporary release workspace"
tech-stack:
  patterns: [markdown-documentation, gitignore-exclusion, placeholder-credentials]
key-files:
  created:
    - docs/release-process.md — 178-line release process guide
  modified:
    - .gitignore — added .release-staging/ exclusion
    - README.md — updated distribution status section
affected:
  - docs/release-process.md — references script/release.sh and .github/workflows/release.yml
  - README.md — links to docs/release-process.md and GitHub Releases
duration_seconds: 0
completed_date: ""
---

# Phase 13 Plan 03: Release Documentation and Distribution Status Summary

**One-liner:** Created a complete 178-line release process guide with placeholder identifiers, excluded release staging artifacts from git, and updated README to reflect downloadable signed/notarized DMG distribution.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create release process documentation | `c910b13` | `docs/release-process.md` |
| 2 | Update .gitignore and README.md | `99b1cc5` | `.gitignore`, `README.md` |

## What Changed

### Task 1: Release process documentation (`docs/release-process.md`)

Created a comprehensive release process guide covering:

- **Prerequisites:** Apple Developer Program membership, Developer ID Application certificate, App Store Connect API key
- **Local release setup (4 steps):** export certificate, create API key, set environment variables, run `./script/release.sh`
- **CI release setup (4 steps):** encode certificate, add GitHub Secrets, enable workflow write permissions, create and push a version tag
- **Verification:** stapler validate, spctl Gatekeeper check, codesign verify on mounted DMG
- **Troubleshooting:** 4 common failure modes (certificate not found, authentication failure, unsigned binary, notarization rejection) with diagnostic commands
- **Certificate renewal:** 5-year expiration guidance with steps to update local and CI credentials
- **Architecture diagram:** ASCII flow diagram showing end-to-end `git tag -> release.yml -> release.sh -> GitHub Release` pipeline

All credentials use placeholder identifiers: `YOURTEAMID`, `YOURKEYID`, `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`, `Developer ID Application: Your Name (XXXXXXXXXX)`. No real credentials are committed.

### Task 2: .gitignore and README.md updates

**`.gitignore`:** Added `.release-staging/` exclusion after the existing `*.swp` entry. This directory is used by `script/release.sh` as a temporary workspace for app bundle assembly, DMG mounting, and notary submission results.

**`README.md`:** Replaced the "Current Distribution Status" section. The old section described the app as source-distributed only with unsigned/unsandboxed/not-notarized output and stated signed/notarized was "out of scope." The new section:

- Declares Automation Health ships as a signed and notarized DMG from GitHub Releases
- Links to the releases page (`nikomohr/AutomationHealth/releases`)
- Describes DMG properties (Developer ID, hardened runtime, Apple notarization, Gatekeeper compatibility)
- Links to `docs/release-process.md` for release-from-source instructions
- Preserves `./script/build_and_run.sh` instructions for local unsigned builds

All other README sections (Quick Start, Privacy, What It Scans, Build And Run, Known Limitations, Products, Contributing) remain unchanged.

## Verification

All automated checks passed:

| Check | Result |
|-------|--------|
| `docs/release-process.md` exists | PASS |
| `APPLE_DEVELOPER_IDENTITY` referenced | PASS (3 occurrences) |
| `script/release.sh` referenced | PASS (3 occurrences) |
| `release.yml` referenced | PASS (2 occurrences) |
| `notarytool submit` referenced | PASS |
| Placeholder identifiers used | PASS (15 lines) |
| H1 title is `# Release Process` | PASS |
| All 7 required H2 sections present | PASS |
| Line count >= 150 | PASS (178 lines) |
| `.release-staging/` in `.gitignore` | PASS |
| `signed and notarized DMG` in README | PASS |
| `docs/release-process.md` linked in README | PASS |
| `GitHub Releases` linked in README | PASS |
| `unsigned` and `out of scope` removed from distribution section | PASS |
| `build_and_run.sh` instructions preserved | PASS |
| All README sections intact | PASS |

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None. Documentation uses placeholder identifiers only (T-13-12 mitigated). `.release-staging/` excluded from git (T-13-13 mitigated). T-13-14 (repudiation) accepted per threat model.

## Self-Check

| Item | Status |
|------|--------|
| `docs/release-process.md` exists | PASS |
| `.gitignore` updated with `.release-staging/` | PASS |
| `README.md` updated with signed/notarized DMG | PASS |
| Commit `c910b13` exists | PASS |
| Commit `99b1cc5` exists | PASS |
