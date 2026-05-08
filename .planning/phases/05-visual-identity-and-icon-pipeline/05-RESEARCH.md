# Phase 5: Visual Identity And Icon Pipeline - Research

**Researched:** 2026-05-08
**Domain:** macOS app icon source art, deterministic iconset generation, SwiftPM local app bundle resources, public asset privacy
**Confidence:** HIGH

## User Constraints

### Icon Identity
- **D-01:** The primary metaphor is Pulse Calendar: scheduled automations plus health/status at a glance.
- **D-02:** The anchor shape is a calendar tile with one green pulse line, not a dashboard, graph, or clock-only symbol.
- **D-03:** Automation detail stays subtle through schedule cues such as a calendar grid or timing marks, not miniature job rows or connected-node diagrams.
- **D-04:** The health signal is a green pulse accent, not a checkmark badge or quiet status dot.
- **D-05:** The icon should feel like a native macOS utility: polished, restrained, and suitable for a local SwiftUI desktop app.
- **D-06:** Use cool graphite plus green: neutral utility base with a clear health accent.
- **D-07:** Use soft 3D depth with gentle highlights and shadows, not flat vector art or high-gloss decoration.
- **D-08:** No text, app initials, letters, calendar numbers, screenshots, terminal output, private data, job rows, graph nodes, or clutter.

### Prompt Workflow
- **D-09:** Provide one final copy-paste-ready ChatGPT image prompt, plus short rationale and negative constraints.
- **D-10:** The prompt asks ChatGPT to generate 4 variants with small composition/material differences.
- **D-11:** Commit the selected original source PNG at `Assets/AppIcon/automation-health-icon-source.png`.
- **D-12:** Documentation focuses on manual ChatGPT generation. Paid API/CLI generation can be mentioned only as optional and must not be required.
- **D-13:** Record short selection notes explaining chosen variant, small-size legibility, Pulse Calendar metaphor, and absence of text/private data.

### Asset Pipeline
- **D-14:** Generate deterministic app icon files under `Assets/AppIcon/AutomationHealth.iconset/`.
- **D-15:** Generate `Assets/AppIcon/AutomationHealth.icns` from the iconset.
- **D-16:** Add a local deterministic script named `script/generate_app_icon.sh`.
- **D-17:** `script/build_and_run.sh` copies `AutomationHealth.icns` into `Contents/Resources` and sets `CFBundleIconFile`.
- **D-18:** Regeneration runs from the repo root, requires no secrets or network access, and uses built-in macOS tools unless a later plan proves a dependency necessary.

### the agent's Discretion
The exact documentation placement, shell implementation details, and whether README links to a dedicated asset note are discretionary, provided the UI contract paths and Phase 5 requirements are honored.

## Summary

Phase 5 should split into two plans matching the roadmap:

1. Write and document the ChatGPT icon prompt, then require the maintainer to place the selected 1024x1024 source PNG at `Assets/AppIcon/automation-health-icon-source.png`.
2. Add the deterministic `sips`/`iconutil` pipeline, generate the committed iconset and `.icns`, copy the `.icns` into the local `.app` bundle, and document regeneration.

The phase should not redesign the app UI. The only SwiftPM bundle integration point is the existing script-generated app bundle in `script/build_and_run.sh`.

## Project Constraints

- Keep the app read-only with respect to real scheduler files and local automations.
- Keep scanner IO out of views; this phase should not touch scanner behavior.
- Avoid new third-party Swift packages and avoid new external image tooling dependencies.
- Use existing shell-first workflow patterns: `set -euo pipefail`, repo-root discovery via `ROOT_DIR`, and commands callable from repository root.
- Preserve unrelated dirty working-tree changes. Current unrelated source changes exist in `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`, and `Sources/AutomationHealth/Views/DetailView.swift`.

## Architecture Responsibility Map

| Capability | Primary File Or Directory | Rationale |
|------------|---------------------------|-----------|
| Prompt, negative constraints, selection notes | `Assets/AppIcon/README.md` | Keeps source art and source-art rationale together. |
| Selected source art | `Assets/AppIcon/automation-health-icon-source.png` | Locked by UI-SPEC and stable enough for deterministic regeneration. |
| Generated iconset | `Assets/AppIcon/AutomationHealth.iconset/` | Standard iconset input for `iconutil --convert icns`. |
| Generated ICNS | `Assets/AppIcon/AutomationHealth.icns` | Bundle-ready resource copied into `Contents/Resources`. |
| Generation script | `script/generate_app_icon.sh` | Matches repo script style and avoids Swift/package changes. |
| App bundle integration | `script/build_and_run.sh` | Existing local `.app` bundle builder already writes `Info.plist` and `dist/AutomationHealth.app`. |
| Regeneration docs | `docs/development.md`, optional README pointer | Existing developer command docs are the right home for local asset generation. |

## Standard Stack

| Tool Or Format | Purpose | Why It Fits |
|----------------|---------|-------------|
| PNG source art | Stable source art from manual ChatGPT generation | Easy to inspect and regenerate into macOS icon sizes. |
| `.iconset` directory | Intermediate icon assets | `iconutil` accepts iconset input and produces `.icns`. |
| `.icns` | macOS app icon bundle resource | macOS app bundles conventionally include app icon files in `Contents/Resources`. |
| `sips` | Resize source PNG into iconset PNGs | Built into macOS; available locally at `/usr/bin/sips`. |
| `iconutil` | Convert iconset to `.icns` | Built into macOS; available locally at `/usr/bin/iconutil`. |
| `CFBundleIconFile` | Info.plist bundle icon key | Apple documents that it identifies the bundle icon file in the main resources directory. |

Apple notes that a Mac app bundle has a `Contents/Resources` directory for nonlocalized resources and that the application icon file conventionally lives there with an `.icns` extension. Apple also documents `CFBundleIconFile` as the bundle icon filename; the extension may be included or omitted, and the system looks in the main resources directory.

## Implementation Flow

```text
Write prompt and asset notes
  -> Maintainer generates 4 ChatGPT variants
  -> Maintainer selects one source PNG
  -> Commit source PNG under Assets/AppIcon
  -> Add generator script using sips + iconutil
  -> Generate iconset and AutomationHealth.icns
  -> Build script copies ICNS into Contents/Resources
  -> Info.plist declares CFBundleIconFile
  -> Document regeneration and verify bundle
```

## Recommended Iconset Sizes

Use the conventional macOS iconset filenames and pixel sizes:

| File | Pixel Size |
|------|------------|
| `icon_16x16.png` | 16 |
| `icon_16x16@2x.png` | 32 |
| `icon_32x32.png` | 32 |
| `icon_32x32@2x.png` | 64 |
| `icon_128x128.png` | 128 |
| `icon_128x128@2x.png` | 256 |
| `icon_256x256.png` | 256 |
| `icon_256x256@2x.png` | 512 |
| `icon_512x512.png` | 512 |
| `icon_512x512@2x.png` | 1024 |

The script should fail early if `Assets/AppIcon/automation-health-icon-source.png` is missing or not square. The source should ideally be 1024x1024; if it is larger but square, the script can still resample deterministically.

## Verification Strategy

- Check prompt docs:
  - `Assets/AppIcon/README.md` contains `Create 4 polished macOS app icon variants`.
  - The same file contains `Pulse Calendar`, `no text`, and `automation-health-icon-source.png`.
- Check source art:
  - `test -f Assets/AppIcon/automation-health-icon-source.png`
  - `sips -g pixelWidth -g pixelHeight Assets/AppIcon/automation-health-icon-source.png`
- Check generator:
  - `test -x script/generate_app_icon.sh`
  - `./script/generate_app_icon.sh`
  - `test -f Assets/AppIcon/AutomationHealth.icns`
  - `test -f Assets/AppIcon/AutomationHealth.iconset/icon_512x512@2x.png`
- Check bundle integration:
  - `./script/build_and_run.sh --verify`
  - `test -f dist/AutomationHealth.app/Contents/Resources/AutomationHealth.icns`
  - `/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" dist/AutomationHealth.app/Contents/Info.plist`

## Security Domain

Security enforcement is applicable because this phase creates public visual assets and docs. The dominant threat is information disclosure: generated assets or documentation could accidentally include screenshots, terminal output, local paths, job names, hostnames, or other private scheduler details. A secondary threat is build-script tampering that causes local bundle generation to require network access, secrets, or new dependencies.

Mitigations should be concrete:

- Keep icon art generated from an abstract prompt only.
- Forbid text, screenshots, terminal output, private data, paths, hostnames, and job rows in the prompt and selection notes.
- Use only local macOS tools in `script/generate_app_icon.sh`.
- Keep generated `dist/` output ignored and copy only committed `AutomationHealth.icns` into the bundle.
- Run the privacy scrub search commands before public docs/assets are treated as release-ready.

## Common Pitfalls

| Pitfall | Why It Matters | Plan Guardrail |
|---------|----------------|----------------|
| Planning API/CLI generation as required | It adds cost/secrets/network requirements and violates D-12. | Manual ChatGPT generation is the expected path; no API key or CLI is required. |
| Source PNG lacks small-size legibility | Dock/Finder icons can collapse into noise. | Selection notes must explicitly check 16px, 32px, 128px, and 1024px readability. |
| Text or numbers appear in source art | Generated image models often add fake text or dates. | Prompt negative constraints and selection notes must reject text, initials, and numbers. |
| Build script references an icon not copied into the bundle | Finder/Dock may show the default app icon. | Copy `AutomationHealth.icns` into `Contents/Resources` and set `CFBundleIconFile`. |
| Generator creates untracked or ignored source-of-truth assets only | Future builds cannot reproduce the icon. | Commit source PNG, iconset, `.icns`, and script. Keep only `dist/` uncommitted. |
| Generated assets leak metadata or local details | Public assets must be safe to publish. | Use abstract source art, run privacy scrub commands, and avoid screenshots/local output. |

## Sources

- Repository files verified locally: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/phases/05-visual-identity-and-icon-pipeline/05-CONTEXT.md`, `.planning/phases/05-visual-identity-and-icon-pipeline/05-UI-SPEC.md`, `script/build_and_run.sh`, `docs/development.md`, `README.md`, `docs/privacy-scrub-checklist.md`.
- Local tool checks: `/usr/bin/sips`, `/usr/bin/iconutil`, `xcrun iconutil --help`, `sips --help`.
- Apple Developer Documentation, "Core Foundation Keys - CFBundleIconFile": https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
- Apple Developer Documentation, "Bundle Structures": https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html

