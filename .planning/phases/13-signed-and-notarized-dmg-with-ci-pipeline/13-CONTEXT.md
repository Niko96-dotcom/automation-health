# Phase 13: Signed and Notarized DMG with CI Pipeline - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

Users can download a Gatekeeper-compatible, signed and notarized DMG of Automation Health from GitHub Releases, built entirely by CI with no manual steps.

This phase covers: codesigning with Developer ID and hardened runtime entitlements, notarization via notarytool + stapler, DMG packaging, GitHub Release artifact publishing, release process documentation with placeholder identifiers, and CI-based notarization in GitHub Actions.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Use ROADMAP phase goal, success criteria, REQUIREMENTS.md (DIST-01 through DIST-07), and codebase conventions to guide decisions.

Key references:
- Build pipeline: `script/build_and_run.sh` already assembles `.app` bundle in `dist/`
- Bundle ID: `org.automationhealth.AutomationHealth` (from `script/build_and_run.sh`)
- CI: `.github/workflows/ci.yml` already runs `macos-latest` with SwiftPM build+test
- No existing codesigning, entitlements, notarization, or DMG tooling in the repo
- No third-party Swift dependencies — build/packaging tooling is shell scripts

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `script/build_and_run.sh` — existing `.app` bundle assembly (Info.plist generation, binary copy, icon copy)
- `script/ci.sh` — local CI gate (`swift build` + `./script/test.sh`)
- `.github/workflows/ci.yml` — GitHub Actions workflow on `macos-latest`
- `Package.swift` — SwiftPM manifest with macOS 14 target, no external dependencies

### Established Patterns
- Shell scripts for build/packaging (Bash, `set -euo pipefail`)
- Makefile aliases for common commands
- GitHub Actions for CI automation
- Script constants for bundle metadata (APP_NAME, BUNDLE_ID, etc.)

### Integration Points
- New release script(s) for codesign + notarize + DMG + GitHub Release
- New GitHub Actions workflow for the release pipeline
- `.gitignore` update for any new artifacts
- `Makefile` additions for release commands

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase. Refer to ROADMAP phase description, success criteria, and REQUIREMENTS.md DIST-01 through DIST-07.

</specifics>

<deferred>
## Deferred Ideas

None — infrastructure phase.

</deferred>
