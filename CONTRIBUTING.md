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
- Run `./script/ci.sh` before opening or updating a pull request.
- Complete a privacy check before changing public docs, examples, screenshots, fixtures, or sample output.
- Fill out the pull request template and include the local verification command you ran.

## Privacy And Public Examples

Automation Health inspects local scheduled jobs, so public examples need extra care. Before posting issues, pull requests, screenshots, fixtures, or sample logs, sanitize paths, hostnames, job names, scheduler output, screenshots, tokens, secrets, and any private command output.

Use synthetic values such as `/Users/example`, `example-daily-report`, and shortened summaries instead of raw local output. For repeatable publication checks, see `docs/privacy-scrub-checklist.md`.

## Scanner Contributions

Scanner behavior belongs in `Sources/ActiveJobsCore`. Add or update scanner types there, use injected paths or command runners where practical, and keep scanner IO out of SwiftUI views.

When scanner behavior changes, update `ActiveJobsCoreSelfTest` with fixture-driven coverage and update the relevant documentation in `README.md` or `docs/`. Use the sanitized issue templates in `.github/ISSUE_TEMPLATE` when reporting bugs or source ideas.

## Code Style

- Follow the existing Swift style: 4-space indentation, descriptive names, and small focused types.
- Keep `ActiveJobsCore` independent from SwiftUI so scanner behavior remains testable.
- Prefer dependency injection for filesystem paths and scanners; avoid direct reads from global paths in tests.
- Keep the app read-only unless a future product decision explicitly expands scope.

## CI

GitHub Actions runs `./script/ci.sh` on pushes to `main`, pull requests, and manual dispatch. Dependabot checks GitHub Actions updates weekly.
