# Automation Health

This macOS SwiftPM project was retired on 2026-09-30. See
[the retirement record](docs/retirement.md) for the closing evidence and limits.
Historical `.planning/` files are records, not an active orchestration workflow.
Do not start a new milestone, release, or maintenance cycle without a user request.

## Preserved architecture

- macOS 14 or newer, Swift 6, SwiftUI and AppKit.
- `ActiveJobsCore` owns scheduler IO, normalization, and app-owned manual records.
- `AutomationHealthCore` owns presentation, grouping, and navigation helpers.
- `AutomationHealth` owns views, observable stores, preferences, and updates.
- Sparkle 2.9.1 is the sole external Swift package, pinned exactly.
- The bundle identifier is `org.automationhealth.AutomationHealth`.
- Real scheduler jobs remain read-only. Manual records are app-owned metadata in
  Application Support; preferences use UserDefaults.

## Verification when explicitly resuming work

- Preserve unrelated dirty and untracked files; stage only requested changes.
- Use `./script/ci.sh` for builds, the 41-case scanner/presentation self-test,
  and app icon validation. Add focused coverage when behavior changes.
- Use `./script/build_and_run.sh --verify` for local bundle launch checks.
- Development bundles are ad-hoc signed and do not check for updates.
- Signed distribution uses `script/release.sh` and `.github/workflows/release.yml`.
  Verify the actual DMG, signing, notarization, appcast, and installed behavior
  separately from source tests. Never expose signing or notarization secrets.
- Documentation-only edits need structural and link checks, not a new release.
- Keep scanner IO out of views. Use injected paths and disposable fixtures.
- Follow `.editorconfig` and retain the public privacy boundaries in
  [the privacy checklist](docs/privacy-scrub-checklist.md).
