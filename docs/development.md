# Development

Run commands from the repo root.

## Common Commands

Show available developer targets:

```sh
make
```

Run the full local CI gate:

```sh
./script/ci.sh
```

Run the scanner self-test:

```sh
./script/test.sh
```

Run the self-test executable directly:

```sh
swift run ActiveJobsCoreSelfTest
```

Build all package products:

```sh
swift build
```

Build a local app bundle and open it:

```sh
./script/build_and_run.sh
```

Build, open, and verify that the app process starts:

```sh
./script/build_and_run.sh --verify
```

## App Icon Assets

The selected source PNG lives at `Assets/AppIcon/automation-health-icon-source.png`.

Regenerate the local app icon assets from committed source art:

```sh
./script/generate_app_icon.sh
```

The generated icon files are `Assets/AppIcon/AutomationHealth.iconset/` and `Assets/AppIcon/AutomationHealth.icns`.

Regeneration uses built-in macOS tools and requires no API key, secret, network access, signing, or notarization.

Verify that the generated local app bundle contains and declares the icon:

```sh
./script/build_and_run.sh --verify
```

## Package Layout

- `Package.swift`: SwiftPM manifest.
- `Makefile`: short aliases for build, test, CI, app launch, logs, and cleanup.
- `Sources/ActiveJobsCore`: scheduler scanners, shared models, and support helpers.
- `Sources/AutomationHealth`: SwiftUI app, views, store, and presentation model.
- `Sources/ActiveJobsCoreSelfTest`: executable self-test target.
- `script/ci.sh`: local and CI quality gate.
- `script/test.sh`: test runner used by the CI gate.
- `script/build_and_run.sh`: local app bundle builder and launcher.
- `.github/workflows/ci.yml`: GitHub Actions build and test workflow.
- `docs/`: architecture and source documentation.

## Pull Request Checklist

- Keep the branch focused on one product or workflow concern.
- Run `./script/ci.sh` before opening or updating a pull request.
- Add or update self-test coverage when scanner, parsing, presentation, or workflow behavior changes.
- Update `README.md` or `docs/` when commands, architecture, supported sources, or limitations change.

## Local App Bundle Status

`script/build_and_run.sh` generates `dist/AutomationHealth.app` for local development. The generated bundle is unsigned, unsandboxed, and not notarized.

Signed and notarized distribution remains out of scope for this milestone.

## Notes

- The generated `.app` bundle is written to `dist/`, which is ignored by git.
- SwiftPM build output is written to `.build/`, which is ignored by git.
- The app bundle identifier is `org.automationhealth.AutomationHealth`.
