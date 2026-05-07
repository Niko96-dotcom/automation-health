# Contributing

Thanks for improving Automation Health. This project is a small SwiftPM macOS app, so the workflow is intentionally lightweight and scriptable.

## Requirements

- macOS 14 or newer.
- Xcode or Xcode Command Line Tools with Swift 6 support.
- Git.

## Local Workflow

Run the full local gate before opening a pull request:

```sh
./script/ci.sh
```

Useful shortcuts:

```sh
make build
make test
make run
make verify
```

`make test` runs the `ActiveJobsCoreSelfTest` executable. The self-test covers scanner parsing, inventory sorting, schedule humanization, and health summaries without requiring a full Xcode installation.

## Branches And Pull Requests

- Branch from `main`.
- Keep changes focused on one product concern.
- Update the self-test coverage for scanner, parser, presentation, or workflow behavior when the change affects behavior.
- Update `README.md` or `docs/` when commands, architecture, supported sources, or limitations change.
- Fill out the pull request template and include the local verification command you ran.

## Code Style

- Follow the existing Swift style: 4-space indentation, descriptive names, and small focused types.
- Keep `ActiveJobsCore` independent from SwiftUI so scanner behavior remains testable.
- Prefer dependency injection for filesystem paths and scanners; avoid direct reads from global paths in tests.
- Keep the app read-only unless a future product decision explicitly expands scope.

## CI

GitHub Actions runs `./script/ci.sh` on pushes to `main`, pull requests, and manual dispatch. Dependabot checks GitHub Actions updates weekly.
