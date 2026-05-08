---
phase: 05
slug: visual-identity-and-icon-pipeline
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-08
---

# Phase 05 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| ChatGPT generated image -> public repository asset | Generated image output could accidentally include fake text, logos, screenshots, terminal output, job details, paths, or private-looking data. | Abstract generated source art. |
| Maintainer manual selection -> committed source art | The chosen variant becomes the source of truth for all generated bundle icons. | Selected PNG committed under `Assets/AppIcon/`. |
| Public docs -> future regeneration workflow | Documentation must not imply API keys, paid generation, or upload of private scheduler data is required. | Developer-facing regeneration instructions. |
| Committed source PNG -> generated icon assets | Local scripts transform source art into multiple committed PNG sizes and an `.icns` resource. | Local image assets generated from committed source art. |
| Repository assets -> generated app bundle | `script/build_and_run.sh` copies the committed `.icns` into `dist/AutomationHealth.app/Contents/Resources`. | Bundle resource file and plist metadata. |
| Developer docs -> maintainer regeneration workflow | Docs must describe local deterministic regeneration without secrets, network requirements, signing, or notarization claims. | Local build and verification commands. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-05-01-01 | Information Disclosure | Generated source PNG | mitigate | Prompt, negative constraints, selection notes, and privacy check reject text, screenshots, terminal output, local paths, private data, and real scheduler details. | closed |
| T-05-01-02 | Spoofing | App icon metaphor | mitigate | Source-art contract and selection notes require the Pulse Calendar metaphor and reject unrelated dashboards, graphs, logos, and clock-only symbols. | closed |
| T-05-01-03 | Repudiation | Manual image selection | mitigate | `Assets/AppIcon/README.md` records the selected variant, small-size legibility, metaphor check, and privacy check. | closed |
| T-05-01-04 | Elevation of Privilege | Image generation workflow | avoid | Source-art workflow is manual and documentation-first; no API keys, CLI generators, secrets, or automated network image generation are required. | closed |
| T-05-02-01 | Tampering | `script/generate_app_icon.sh` | mitigate | Generator uses explicit repository-local source/output paths, fails on missing or non-square source art, and uses built-in `sips` and `iconutil` only. | closed |
| T-05-02-02 | Denial of Service | Local bundle build | mitigate | Bundle builder regenerates the icon only when source, script, or `.icns` timestamps require it and lets the generator fail clearly on missing source art. | closed |
| T-05-02-03 | Information Disclosure | Generated assets and docs | mitigate | Generated assets derive only from the selected abstract source art; docs and README reinforce no screenshots, private data, paths, terminal output, or scheduler details. | closed |
| T-05-02-04 | Spoofing | App bundle identity | mitigate | `AutomationHealth.icns` is copied into `Contents/Resources` and `Info.plist` declares `CFBundleIconFile` as `AutomationHealth.icns`. | closed |
| T-05-02-05 | Elevation of Privilege | Regeneration workflow | avoid | Regeneration uses built-in macOS tooling and docs require no secrets, API keys, network calls, installers, signing, notarization, or new dependencies. | closed |

---

## Evidence Notes

| Threat ID | Evidence |
|-----------|----------|
| T-05-01-01 | `Assets/AppIcon/README.md` includes negative constraints for no text, no terminal output, and no private data; the final privacy check says no text, private data, screenshots, local paths, terminal output, or real scheduler details. The source PNG is a 1254 by 1254 abstract image with no visible text or private-looking content. |
| T-05-01-02 | `Assets/AppIcon/README.md` documents the Pulse Calendar prompt and a metaphor check for a compact schedule/grid mark crossed by one pulse-like stroke. The source image visually matches an abstract grid/pulse mark rather than a logo, dashboard, graph, or clock-only symbol. |
| T-05-01-03 | `Assets/AppIcon/README.md` records `Selected variant: Dock-reference replacement`, a small-size legibility note, a metaphor check, and the required privacy sentence. |
| T-05-01-04 | `Assets/AppIcon/README.md` states the workflow must not require API keys, paid API generation, network automation, or CLI image generation. |
| T-05-02-01 | `script/generate_app_icon.sh` defines explicit source, iconset, and `.icns` paths; checks source existence and square dimensions; recreates the iconset; and calls `sips` plus `iconutil`. |
| T-05-02-02 | `script/build_and_run.sh` invokes `script/generate_app_icon.sh` only when the source, script, or `.icns` state requires regeneration before assembling the app bundle. |
| T-05-02-03 | `docs/development.md` says regeneration requires no API key, secret, network access, signing, or notarization; README points to the local source-art regeneration docs. |
| T-05-02-04 | `./script/build_and_run.sh --verify` passed; `dist/AutomationHealth.app/Contents/Resources/AutomationHealth.icns` exists; `PlistBuddy` prints `AutomationHealth.icns` for `CFBundleIconFile`. |
| T-05-02-05 | `script/generate_app_icon.sh` uses only built-in macOS tools and `docs/development.md` documents a local-only workflow with no secrets, network access, signing, or notarization. |

No additional `## Threat Flags` sections were present in `05-01-SUMMARY.md` or `05-02-SUMMARY.md`.

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-08 | 9 | 9 | 0 | Codex |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-08
