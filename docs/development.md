# Development

Run commands from the repo root.

## Common Commands

Run the scanner self-test:

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

## Package Layout

- `Package.swift`: SwiftPM manifest.
- `Sources/ActiveJobsCore`: scheduler scanners, shared models, and support helpers.
- `Sources/AutomationHealth`: SwiftUI app, views, store, and presentation model.
- `Sources/ActiveJobsCoreSelfTest`: executable self-test target.
- `script/build_and_run.sh`: local app bundle builder and launcher.
- `docs/`: architecture and source documentation.

## Notes

- The generated `.app` bundle is written to `dist/`, which is ignored by git.
- SwiftPM build output is written to `.build/`, which is ignored by git.
- The app bundle identifier is `com.niko.AutomationHealth`.
