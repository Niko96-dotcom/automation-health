# Research Synthesis — v1.3 Shippable Distribution

**Domain:** macOS SwiftUI app — codesigning, notarization, DMG packaging, GitHub Actions release pipeline, Sparkle 2 auto-update
**Synthesized:** 2026-05-12
**Confidence:** MEDIUM

## Executive Summary

Automation Health is a brownfield macOS SwiftUI app built with pure SwiftPM (no Xcode project) that currently ships as an unsigned, manually-built `.app`. v1.3 adds the distribution pipeline: codesigning with a Developer ID certificate, hardened runtime entitlements, notarization via `notarytool`, polished DMG creation via `create-dmg`, GitHub Actions CI automation of the full signing-to-release pipeline, and Sparkle 2 auto-update against a GitHub Releases appcast.

The recommended approach is to build the pipeline in strict dependency order: static linking first (to prevent the most common notarization rejection), then local codesigning and notarization verification, then DMG packaging, and only then wire it into CI with GitHub Secrets. Sparkle integration should proceed after the signed DMG pipeline works, because Sparkle's end-to-end update flow requires a published release as its appcast source.

The highest risk items are (1) SwiftPM's default dynamic linking breaking notarization — fix with `-Xswiftc -static-executable`, (2) the Hardened Runtime potentially blocking the app's `Process`-based `launchctl` scanner — verify on a non-dev Mac early, and (3) the Sparkle framework bundling challenge inherent in a non-Xcode SwiftPM build — handle by downloading the pre-built framework and copying it manually into `Contents/Frameworks/`. The key architectural decision: keep the pure SwiftPM build. Do not adopt an Xcode project solely for Sparkle's copy-frameworks build phase.

## Key Findings

### From STACK.md — Technologies Selected

| Technology | Role | Rationale |
|------------|------|-----------|
| **Sparkle 2.x** (SwiftPM) | Auto-update framework | Standard for macOS indie apps; `SPUStandardUpdaterController` provides minimal-code integration |
| **`create-dmg`** (Homebrew) | Polished DMG | Produces drag-to-install UX with Applications alias; CI-only Brew dependency |
| **`codesign` + `notarytool` + `stapler`** | Signing/notarization | Apple's current toolchain; unchanged from v1.2 but now CI-automated |
| **GitHub Actions `macos-latest`** | CI runner | Pre-installed Xcode CLT, Homebrew, Swift; triggers on version tags |
| **`softprops/action-gh-release@v2`** | Release creation | Community standard; handles asset upload and release notes |
| **GitHub Releases atom feed** | Sparkle appcast | Zero-infrastructure; `https://github.com/{owner}/AutomationHealth/releases.atom` |

**Critical requirement:** Build with `-Xswiftc -static-executable` to avoid notarization rejection from dynamic Swift runtime linking.

### From FEATURES.md — What to Build

**Table stakes (MUST ship):** Gatekeeper-clean launch, DMG with Applications alias, hardened runtime, stapled notarization ticket, downloadable from GitHub Releases.

**Differentiators (SHOULD ship):** Sparkle auto-update, CI-based notarization (no manual steps), EdDSA-signed updates.

**Deferred:** Mac App Store (sandbox conflict), delta updates (unnecessary), custom update server (overkill), silent auto-update (trust violation).

**Dependency chain:** Entitlements → Codesigning → Notarization → DMG → CI Notarization → GitHub Release → Sparkle.

### From ARCHITECTURE.md — Component Boundaries

**New files:** `entitlements.plist`, `sign.sh`, `notarize.sh`, `package.sh`, `release.sh`, `.github/workflows/release.yml`.

**Modified files:** `Package.swift` (Sparkle dep), `AutomationHealthApp.swift` (SPUStandardUpdaterController), `SettingsView.swift` (Updates section), `Makefile` (release targets), `build_and_run.sh` (framework bundling, Info.plist keys).

**Key patterns:**
1. Inside-out signing order: Sparkle.framework → `.app` bundle → DMG. Never use `codesign --deep`.
2. Notarize the DMG, not the `.app` — Apple requires containers.
3. Ephemeral CI keychain for certificate management.

### From PITFALLS.md — Top 5 Critical Risks

| # | Pitfall | Prevention | Phase |
|---|---------|------------|-------|
| 1 | SwiftPM dynamic linking blocks notarization | `-Xswiftc -static-executable`; verify with `otool -L` | 13 |
| 2 | Hardened Runtime blocks `launchctl` subprocess | Test signed Release on non-dev Mac; add self-test | 13 |
| 3 | Incomplete Info.plist causes notarization rejection | Add all required keys; validate with `plutil -lint` | 13 |
| 4 | DMG creation destroys code signature | Fresh build, sign, immediately package — never open first | 13 |
| 5 | Developer ID secret leakage in CI logs | Ephemeral keychain, env vars only | 13 |

## Implications for Roadmap

### Suggested Phase Ordering

**Phase 13: Signed + Notarized DMG with CI Pipeline**
DIST-01 through DIST-07. Static linking → Info.plist hardening → Entitlements → Local codesigning → DMG → Local notarization + stapling → CI secrets → release.yml → Documentation.

**Phase 14: Sparkle Auto-Update Integration**
DIST-08. SPM dependency → Framework bundling → AppDelegate init → Info.plist keys → Settings UI → EdDSA keys → CI sign_update → End-to-end update test.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Signing/notarization: HIGH. Sparkle tooling: LOW (needs verification at implementation time). `create-dmg`: MEDIUM. |
| Features | HIGH | Dependencies and scoping are well-understood. |
| Architecture | MEDIUM-HIGH | Clear boundaries; framework bundling approach has implementation risk. |
| Pitfalls | HIGH | All validated against Apple docs and project codebase. |

## Sources

- `STACK.md` — Technology selection
- `FEATURES.md` — Feature categorization and dependency graph
- `ARCHITECTURE.md` — Component boundaries and build order
- `PITFALLS.md` — Critical pitfalls and prevention strategies
