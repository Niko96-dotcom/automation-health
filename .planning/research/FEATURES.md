# Feature Research — v1.3 Shippable Distribution

**Domain:** macOS app distribution — codesigning, notarization, DMG, GitHub Releases, Sparkle auto-update
**Researched:** 2026-05-12
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist when downloading a macOS app. Missing these = product feels broken or untrustworthy.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| App launches without Gatekeeper warning | macOS users expect downloaded apps to pass Gatekeeper. An unsigned app that triggers "cannot be opened because it is from an unidentified developer" is a trust failure. | MEDIUM | Requires Developer ID cert ($99/yr Apple Developer Program), `codesign --options runtime`, notarization, and stapling. |
| DMG with Applications alias | Standard macOS distribution UX. Users expect to drag the app icon to an Applications folder shortcut. | LOW | `create-dmg` handles this; raw `hdiutil` produces a bare DMG that confuses users. |
| Hardened runtime | Required for notarization since 2019, enforced strictly in 2025+. Apps without it fail notarization unconditionally. | LOW | `--options runtime` flag on `codesign`; entitlements plist with minimal exceptions. |
| Notarization ticket stapled | Without stapling, the first launch requires internet to verify the ticket. Stapling makes it work offline. | LOW | `xcrun stapler staple` after notarization completes. |
| Downloadable from GitHub Releases | Users expect a `.dmg` on the Releases page. Manual `git clone && swift build` is not distribution. | LOW | `softprops/action-gh-release@v2` in CI; tag-triggered workflow. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable for this project.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Sparkle auto-update from GitHub Releases | Users get notified of new versions and can update in-app without re-downloading from the website. Standard for well-maintained macOS indie apps. | MEDIUM | First external Swift dependency. ~15 lines of integration code. `SPUStandardUpdaterController` in App struct. `Check for Updates` menu item. |
| CI-based notarization (no manual steps) | Every release is automatically signed and notarized in GitHub Actions. No developer machine bottleneck. Reproducible, auditable. | MEDIUM | Temporary keychain in CI, cert + secrets from GitHub Secrets, `notarytool --wait` in release workflow. |
| EdDSA-signed Sparkle updates | Sparkle 2 uses EdDSA keys for update feed signing. Protects against update feed tampering. Standard for Sparkle 2. | LOW | `generate_keys` tool from Sparkle; public key in Info.plist, private key in CI secrets for `sign_update`. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Mac App Store distribution | "Reach more users" | MAS requires sandbox entitlement, which conflicts with read-only scanner access to system paths (launchd plists, cron tabs). Would require significant architectural changes and feature loss. | Direct distribution via GitHub Releases with Sparkle auto-update. |
| Sparkle delta updates | "Smaller downloads" | Requires maintaining binary diff tooling, increases release complexity, and provides marginal benefit for a <10 MB app. | Full binary updates only. App size is small enough that delta updates aren't worth the complexity. |
| Auto-update without user consent | "Seamless experience" | Violates user trust, especially for an app that inspects system automation. Users should know when their inspection tool changes. | Sparkle's standard "download and install on quit" or user-initiated update flow. |
| App Store Connect API key management in repo | "Simpler than certs" | Committing API keys is a security risk. Even encrypted, it adds attack surface. | GitHub Secrets for all credentials. Never commit keys, certs, or passwords. |
| Custom update server | "More control" | Requires running infrastructure, monitoring, TLS certs, and adds a point of failure. GitHub Releases already provides reliable hosting. | Use Sparkle's built-in GitHub Releases appcast support (appcast.xml hosted alongside the release). |

## Feature Dependencies

```
[DIST-01: Codesigning]
    └──requires──> [DIST-02: Hardened Runtime Entitlements]

[DIST-03: Notarization Recipe]
    └──requires──> [DIST-01: Codesigning]
    └──requires──> [DIST-02: Hardened Runtime Entitlements]

[DIST-04: Signed + Notarized DMG]
    └──requires──> [DIST-03: Notarization Recipe]
    └──requires──> [DIST-01: Codesigning]

[DIST-07: CI-Based Notarization]
    └──requires──> [DIST-03: Notarization Recipe]
    └──requires──> [DIST-04: DMG Pipeline]

[DIST-05: GitHub Release]
    └──requires──> [DIST-04: Signed + Notarized DMG]
    └──enhances──> [DIST-08: Sparkle Auto-Update]

[DIST-08: Sparkle Auto-Update]
    └──requires──> [DIST-01: Codesigning]
    └──requires──> [DIST-05: GitHub Release]
    └──enhances──> [DIST-05: GitHub Release]

[DIST-06: Release Documentation]
    └──documents──> [All DIST-01 through DIST-08]
```

### Dependency Notes

- **DIST-01 requires DIST-02:** Hardened runtime entitlements must be configured before signing; `codesign --options runtime` references the entitlements plist.
- **DIST-03 requires DIST-01 + DIST-02:** notarytool can only notarize signed apps with hardened runtime enabled.
- **DIST-04 requires DIST-03:** The DMG must be signed, then notarized, then stapled — in that order.
- **DIST-07 wraps DIST-03 + DIST-04:** CI notarization automates the same steps, not a separate capability.
- **DIST-08 requires DIST-01:** Sparkle's XPC service and update installation need a signed app bundle. Unsigned app can't use Sparkle's install flow.
- **DIST-08 enhances DIST-05:** Sparkle reads the GitHub Releases atom feed to discover updates. Without GitHub Releases, there's no feed for Sparkle to consume.

## Feature Categories for Scoping

### Category: Build & Sign (enabling)
- DIST-02: Hardened runtime entitlements
- DIST-01: Codesigning with Developer ID

### Category: Notarization & Packaging (artifact)
- DIST-03: Notarization recipe (notarytool + stapler)
- DIST-04: Signed + notarized DMG

### Category: CI & Release (automation)
- DIST-07: CI-based notarization via GitHub Actions
- DIST-05: GitHub Release with downloadable artifact

### Category: Auto-Update (runtime)
- DIST-08: Sparkle auto-update integration

### Category: Documentation (meta)
- DIST-06: Release process documentation
