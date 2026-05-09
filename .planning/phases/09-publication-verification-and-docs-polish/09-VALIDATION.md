---
phase: 09
slug: publication-verification-and-docs-polish
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-09
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for publication verification and docs polish.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SwiftPM executable self-test plus Bash verification scripts |
| **Config file** | `Package.swift`, `script/ci.sh`, `script/test.sh`, `script/test_app_icon.sh` |
| **Quick run command** | `./script/test.sh` |
| **Full suite command** | `./script/ci.sh` |
| **Estimated runtime** | ~60-180 seconds |

## Sampling Rate

- **After every task commit:** Run the narrow command named by that task.
- **After every plan wave:** Run `./script/ci.sh`.
- **Before `$gsd-verify-work`:** `./script/ci.sh`, `./script/build_and_run.sh --verify`, and the Phase 9 privacy scrub commands must pass or have documented expected false positives.
- **Max feedback latency:** 180 seconds for automated checks, excluding manual smoke verification.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | PRIV-01 | T-09-03 | Publishable tree has no accidental `.DS_Store` metadata. | shell | `find . -name .DS_Store -print` | yes | pending |
| 09-01-02 | 01 | 1 | PRIV-01 | T-09-02 | Personal namespace hits are removed or explicitly documented as checklist-only false positives. | shell | `rg -n "niko|com\\.niko|/Users/niko" README.md CONTRIBUTING.md docs .github Sources script` | yes | pending |
| 09-01-03 | 01 | 1 | PRIV-01, VIS-04 | T-09-01 | Public docs/assets do not expose local automation data or sensitive categories outside intentional guidance. | shell | `rg -n "token|secret|password|hostname|screenshot|scheduler output" README.md CONTRIBUTING.md docs .github Sources script` | yes | pending |
| 09-01-04 | 01 | 1 | VIS-04 | T-09-01 | Icon/public visual assets are sanitized and bundle-ready. | shell | `./script/test_app_icon.sh` | yes | pending |
| 09-02-01 | 02 | 2 | QUAL-04 | T-09-04 | Core launchd, Hermes cron, search, selection, and refresh behavior still passes the local gate. | shell | `./script/ci.sh` | yes | pending |
| 09-02-02 | 02 | 2 | QUAL-04 | T-09-04 | Local app bundle still builds and verifies. | shell | `./script/build_and_run.sh --verify` | yes | pending |
| 09-02-03 | 02 | 2 | PRIV-01, VIS-04, QUAL-04 | T-09-04 | Traceability records Phase 9 evidence for all assigned requirements. | grep | `rg -n "PRIV-01|VIS-04|QUAL-04" .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/phases/09-publication-verification-and-docs-polish` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `script/ci.sh` runs `swift build` and `./script/test.sh`.
- `script/test.sh` runs `swift run ActiveJobsCoreSelfTest` and `./script/test_app_icon.sh`.
- `script/test_app_icon.sh` verifies public icon docs/assets and rejects private-looking strings in icon assets.
- `docs/privacy-scrub-checklist.md` already defines rerunnable publication scrub commands.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Public visuals are aesthetically consistent and sanitized | VIS-04 | The project has no screenshot assertion workflow or visual diff target. | Review README/docs visuals and assets. Confirm they use abstract/synthetic content only and expose no local automations, paths, hostnames, scheduler output, or private command text. |
| Broad inventory and sidebar smoke verification | QUAL-04 | Local machine scheduler availability and SwiftUI focus appearance cannot be fully proven by the executable self-test. | Launch the app with synthetic or privacy-safe local inventory. Confirm launchd/Hermes records render where available, search/selection/refresh work, manual records still use app-owned mutation only, grouping modes/collapse behavior still work, and the Phase 8 custom focus cue remains visible. |
| Read-only publication signoff | PRIV-01, QUAL-04 | Human signoff is needed before publication because docs/screenshots can leak local context outside code paths. | Record in Phase 9 summary/verification that no real scheduler files, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata were modified. |

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit manual verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 180 seconds for automated checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending execution evidence
