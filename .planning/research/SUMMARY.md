# Research Summary: v1.1 Open Source Readiness and Broad Inventory

**Date:** 2026-05-08

## Stack Additions

- No third-party Swift dependencies are needed.
- Add repository health files, richer GitHub Actions/docs checks, and a deterministic icon asset pipeline.
- Use Codex-authored, copy-paste-ready prompts in the ChatGPT app for source visual assets. API/CLI generation can be documented as an optional paid reproducibility path, not the default.

## Feature Table Stakes

- Public README, license, security policy, contribution docs, support docs, issue/PR templates, and privacy scrub before GitHub publication.
- Broader scanner model with deterministic scheduler sources, manual entries, and bounded candidate-script discovery.
- Explicit confidence labels so candidates and manual records are not confused with proven scheduled jobs.
- Collapsible sidebar sections, improved focus styling, and grouping/sorting by better dimensions than raw scheduler source.
- App icon and public-facing visual assets generated and packaged without leaking personal context.

## Watch Outs

- Do not promise perfect discovery of every automation on every Mac. Use "Scheduled", "Registered", "Candidate", and "Manual" confidence states.
- Keep broad filesystem discovery bounded, transparent, and best-effort.
- Preserve read-only behavior: manual entries are app records, not edits to real jobs.
- Avoid personal data leaks in docs, screenshots, examples, fixture names, and generated assets.

## Recommended Phase Shape

1. Open-source repository hardening and privacy scrub.
2. Visual identity and icon asset pipeline.
3. Broad inventory domain model and deterministic scanner expansion.
4. Candidate/manual automation coverage.
5. Sidebar grouping, collapse, and focus polish.
6. Publication verification and docs refresh.

## Sources

- GitHub Docs: community health files — https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file
- GitHub Docs: leak prevention — https://docs.github.com/en/code-security/how-tos/secure-your-secrets/work-with-leak-prevention
- GitHub Docs: Swift CI — https://docs.github.com/en/actions/tutorials/build-and-test-code/swift
- Apple Developer: launchd jobs — https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
- Apple Developer: timed jobs — https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html
- Apple Support: Shortcuts command line — https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac
- Apple Support: Automator — https://support.apple.com/en-euro/guide/automator/welcome/mac
- Apple Developer: app icons — https://developer.apple.com/design/human-interface-guidelines/app-icons/
