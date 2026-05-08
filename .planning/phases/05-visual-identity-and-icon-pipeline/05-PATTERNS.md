# Phase 5: Visual Identity And Icon Pipeline - Patterns

**Mapped:** 2026-05-08
**Scope:** App icon prompt/source art, deterministic icon generation, local `.app` bundle integration, and regeneration docs

## Summary

Phase 5 should reuse the repository's existing shell-first local build style and plain Markdown documentation style. The only app-bundle integration point should be `script/build_and_run.sh`, which already assembles `dist/AutomationHealth.app`, writes `Info.plist`, and launches or verifies the app.

No Swift source changes are needed for this phase. No scanner behavior changes are needed.

## File Classification

| File | Role | Closest Existing Analog | Pattern To Reuse |
|------|------|-------------------------|------------------|
| `Assets/AppIcon/README.md` | Prompt, negative constraints, asset selection notes | `docs/privacy-scrub-checklist.md`, `docs/development.md` | Plain Markdown, concrete commands/paths, privacy-safe public language. |
| `Assets/AppIcon/automation-health-icon-source.png` | Selected source art | No direct committed asset analog | Stable source input committed under an explicit asset directory. |
| `Assets/AppIcon/AutomationHealth.iconset/` | Generated iconset PNGs | `dist/AutomationHealth.app` structure from `script/build_and_run.sh` | Deterministic generated files from committed source art; file names follow macOS iconset conventions. |
| `Assets/AppIcon/AutomationHealth.icns` | Bundle-ready app icon | `script/build_and_run.sh` generated app bundle resources | Copy into `Contents/Resources` during local bundle assembly. |
| `script/generate_app_icon.sh` | Local deterministic asset generator | `script/ci.sh`, `script/test.sh`, `script/build_and_run.sh` | Bash with `set -euo pipefail`, repo-root discovery, no external dependencies. |
| `script/build_and_run.sh` | Bundle icon integration | Existing app bundle builder | Add resource directory creation, copy icon, and add `CFBundleIconFile` to generated plist. |
| `docs/development.md` | Regeneration documentation | Existing Common Commands and Local App Bundle Status sections | Command-oriented docs from repo root. |
| `README.md` | Optional public pointer | Existing Quick Start and Build And Run sections | Keep concise; link to deeper development docs if needed. |

## Shared Patterns

- Use repository-relative paths in docs and scripts.
- Keep local scripts callable from the repo root.
- Put script constants near the top before execution.
- Keep generated `dist/` output uncommitted.
- Use `./script/ci.sh` and `./script/build_and_run.sh --verify` as final gates where bundle behavior changes.
- Keep public docs and assets free of local paths, hostnames, scheduler output, screenshots, and job details.

## Existing Script Pattern

From `script/build_and_run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="AutomationHealth"
DISPLAY_NAME="Automation Health"
BUNDLE_ID="org.automationhealth.AutomationHealth"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
```

Phase 5 should extend this with icon constants such as:

```bash
APP_RESOURCES="$APP_CONTENTS/Resources"
ICON_NAME="AutomationHealth"
ICON_FILE="$ROOT_DIR/Assets/AppIcon/$ICON_NAME.icns"
```

and should create/copy resources after the bundle directory is recreated.

## Documentation Pattern

From `docs/development.md`, command docs use short headings and fenced shell snippets:

````markdown
Build a local app bundle and open it:

```sh
./script/build_and_run.sh
```
````

Phase 5 regeneration docs should follow that same direct style:

- Tell maintainers to place source art at `Assets/AppIcon/automation-health-icon-source.png`.
- Show `./script/generate_app_icon.sh`.
- Show `./script/build_and_run.sh --verify`.
- State that no API key, network access, signing, or notarization is required.

## No Analog Found

| File | Why No Direct Analog | Research Pattern |
|------|----------------------|------------------|
| `Assets/AppIcon/automation-health-icon-source.png` | The repo currently has no committed visual asset directory. | Create a small, explicit `Assets/AppIcon/` tree with source art, generated iconset, `.icns`, and a README. |
| `Assets/AppIcon/AutomationHealth.iconset/` | The repo currently has no committed generated image assets. | Use standard macOS iconset names and generate from the source PNG with `sips`. |

## Suggested Plan Boundaries

### Plan 05-01

Owns:

- `Assets/AppIcon/README.md`
- `Assets/AppIcon/automation-health-icon-source.png`

This plan is intentionally not fully autonomous because the expected path is manual ChatGPT generation and maintainer selection. It should end only after the source PNG exists and selection notes are written.

### Plan 05-02

Owns:

- `script/generate_app_icon.sh`
- `Assets/AppIcon/AutomationHealth.iconset/`
- `Assets/AppIcon/AutomationHealth.icns`
- `script/build_and_run.sh`
- `docs/development.md`
- optional `README.md` pointer

This plan can be autonomous once Plan 05-01 provides the source PNG.
