# Requirements — v1.3 Shippable Distribution

**Milestone:** v1.3 Shippable Distribution
**Goal:** Ship a signed, notarized, auto-updating downloadable release of Automation Health.
**Defined:** 2026-05-12

## Active Requirements

### Build & Sign (enabling)

- [x] **DIST-01**: The `.app` bundle is codesigned with a Developer ID from the build pipeline.
- [x] **DIST-02**: Hardened runtime entitlements are configured for the signed app.

### Notarization & Packaging (artifact)

- [x] **DIST-03**: A notarization recipe (notarytool + stapler) is documented and reproducible.
- [x] **DIST-04**: A signed and notarized DMG is produced by the release pipeline.

### CI & Release (automation)

- [x] **DIST-05**: A GitHub Release delivers a downloadable artifact.
- [x] **DIST-06**: Release process documentation covers signing and notarization with placeholder identifiers.
- [x] **DIST-07**: CI-based notarization runs in GitHub Actions as part of the release pipeline.

### Auto-Update (runtime)

- [ ] **DIST-08**: Sparkle auto-update checks GitHub Releases and presents update UI to the user.

## Out of Scope

- Mac App Store distribution — sandbox entitlement conflicts with read-only scanner access to system paths.
- Sparkle delta updates — marginal benefit for a small app; adds binary diff complexity.
- Custom Sparkle update server — GitHub Releases provides reliable hosting without infrastructure burden.
- Silent auto-update without user consent — trust violation for an inspection tool.
- Universal binary (arm64 + x86_64) — arm64-only is sufficient; users on Intel Macs can build from source.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DIST-01 | Phase 13 | Complete |
| DIST-02 | Phase 13 | Complete |
| DIST-03 | Phase 13 | Complete |
| DIST-04 | Phase 13 | Complete |
| DIST-05 | Phase 13 | Complete |
| DIST-06 | Phase 13 | Complete |
| DIST-07 | Phase 13 | Complete |
| DIST-08 | Phase 14 | Pending |

*Traceability updated 2026-05-12 by roadmap.*
