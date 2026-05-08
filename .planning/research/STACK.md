# Research: Stack Additions For v1.1

**Milestone:** v1.1 Open Source Readiness and Broad Inventory
**Date:** 2026-05-08

## Recommendation

Keep the shipped SwiftPM/macOS stack intact. v1.1 should use the existing native Swift, Foundation, SwiftUI, AppKit, shell-script, and GitHub Actions tooling without adding third-party Swift packages.

## Stack Notes

### Open Source Readiness

- Add repository-level community and governance files rather than new runtime dependencies: `LICENSE`, `SECURITY.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md`, improved `CONTRIBUTING.md`, issue templates, PR template, and README updates.
- GitHub recognizes community health files in the repository root, `.github/`, or `docs/`; issue templates live under `.github/ISSUE_TEMPLATE`.
- Add a privacy/sanitization checklist to documentation and CI so generated examples do not expose local usernames, home paths, bundle ids, hostnames, or real job output.
- GitHub public repositories receive secret scanning/push protection support, but the repo should still include local guidance and avoid committing generated personal scan output.

### CI And Workflows

- Continue using GitHub Actions on `macos-latest` for SwiftPM. GitHub's Swift guide confirms macOS hosted runners include dependencies for Swift packages.
- Keep `./script/ci.sh` as the one local and remote quality gate, and add workflow checks that verify documentation, package hygiene, and generated app assets where possible.
- Prefer explicit permissions, concurrency, and timeouts as already present in `.github/workflows/ci.yml`.

### Automation Discovery

- Keep scanner IO in `ActiveJobsCore` and keep views driven by presentation/store data.
- Add scanner adapters for deterministic scheduler sources before heuristic discovery:
  - launchd: current plist scanner plus optional system launchd paths when readable.
  - cron: user crontab, `/etc/crontab`, and known cron tab directories when readable.
  - Shortcuts: `shortcuts list` can inventory shortcut names and folders, but it does not prove a scheduled trigger.
  - Automator: workflow files can be discovered, but workflow existence is not the same as scheduled execution.
  - Manual entries: local user-supplied records for things the app cannot prove automatically.
- Add a candidate-file scanner for script-like files in common user locations, but label those as candidates with lower confidence rather than scheduled jobs.

### Visual Assets

- Use the `imagegen` skill to create source art for the app icon and any public-facing screenshots/graphics. Live generation requires `OPENAI_API_KEY`; it is currently missing in this session.
- For macOS packaging, plan for a real icon pipeline that generates `AppIcon`/`.icns` outputs from one high-resolution source image.
- Apple guidance frames app icons as distinct, recognizable identity assets; Xcode/asset catalogs expect multiple app icon sizes for macOS.

## Sources

- GitHub Docs: community health files — https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file
- GitHub Docs: secret scanning and push protection — https://docs.github.com/en/code-security/how-tos/secure-your-secrets/work-with-leak-prevention
- GitHub Docs: building and testing Swift — https://docs.github.com/en/actions/tutorials/build-and-test-code/swift
- Apple Developer: creating launch daemons and agents — https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
- Apple Developer: scheduling timed jobs — https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html
- Apple Support: Shortcuts command-line usage — https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac
- Apple Support: Automator user guide — https://support.apple.com/en-euro/guide/automator/welcome/mac
- Apple Developer: app icons — https://developer.apple.com/design/human-interface-guidelines/app-icons/
