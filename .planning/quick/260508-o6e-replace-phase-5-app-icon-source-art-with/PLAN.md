---
id: 260508-o6e
slug: replace-phase-5-app-icon-source-art-with
status: in_progress
created: 2026-05-08
---

# Quick Task: Replace Phase 5 App Icon Source Art

Replace the current glossy/chunky app icon source art with a restrained icon closer to the user's dock reference: simple rounded-square app icon, mostly monochrome, minimal black/graphite glyph, low gloss, no text, no private data.

## Tasks

1. Generate a new source PNG in the reference style and copy it to `Assets/AppIcon/automation-health-icon-source.png`.
2. Update `Assets/AppIcon/README.md` selection notes to describe the restrained monochrome source art.
3. Regenerate `Assets/AppIcon/AutomationHealth.iconset/` and `Assets/AppIcon/AutomationHealth.icns`.
4. Verify source/icon dimensions and bundle icon integration.

## Verification

- `sips -g pixelWidth -g pixelHeight Assets/AppIcon/automation-health-icon-source.png`
- `./script/generate_app_icon.sh`
- `./script/build_and_run.sh --verify`
- `/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" dist/AutomationHealth.app/Contents/Info.plist`
