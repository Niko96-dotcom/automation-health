# Retirement Record

Automation Health development ended on 2026-09-30 at the owner's request.
No next milestone, maintenance releases after v1.3.2, or ongoing support are planned.
The MIT license, source history, tags, and release assets remain available for forks.

## Final Maintenance Release

[v1.3.2](https://github.com/Niko96-dotcom/automation-health/releases/tag/v1.3.2)
packages the updater fixes already committed on `main` after v1.3.1. The old
v1.3 and v1.3.1 binaries can fail Check for Updates with a missing-appcast-URL
error. Their source used a separate Sparkle delegate whose lifetime was not
retained by the application. The final source makes `UpdateStore` the retained
delegate, centralizes release eligibility in `UpdatePolicy`, and explains why
development builds do not check for updates. Install the final DMG directly
when upgrading from an affected old binary.

The final release uses the existing Developer ID, notarization, DMG, and signed
Sparkle appcast workflow. No new product features were added during retirement.

## Closing Verification

- The source checkout was clean before the sweep and was brought forward to the
  merged dependency updates on `main`.
- `./script/ci.sh` passed: SwiftPM build, 41 scanner/presentation self-test cases,
  and app icon validation.
- `./script/build_and_run.sh --verify` passed. The development bundle completed
  a local scan, displayed search results and the empty-search state, and showed
  the expected development-build update explanation in Settings.
- A candidate built from the final source with release-mode metadata completed a
  live Sparkle check and displayed “You're up to date.” This was an ad-hoc runtime
  check, separate from signed release artifact verification.
- No open pull requests or issues remained. PRs #2 and #3 were merged; PR #1 was
  closed as superseded. `main` was the only remaining remote branch.
- Contributor, support, security, development, architecture, and planning entry
  points now describe retirement and the current source layout. The stale
  next-milestone instructions and recurring Dependabot configuration were removed.

## Remaining Limits

Retirement records completion of development and the checks above. It is not an
exhaustive guarantee of every scheduler, macOS version, or runtime path.

- Discovery remains best-effort and health summaries are heuristic; see
  [source coverage](scheduled-job-sources.md).
- Search filters the sidebar but can leave the previously selected record in
  the detail pane when that record is excluded by the filter.
- A UTF-8 log tail can be omitted if the fixed byte boundary splits a multibyte
  character. The historical [concerns snapshot](../.planning/codebase/CONCERNS.md)
  describes this behavior.
- This sweep did not repeat every historical keyboard, grouping, preference,
  manual-record, or update-installation scenario on multiple Macs. Archived
  milestone reports retain their original verification limits.

## Archive And Recovery

The GitHub repository is preserved as an archive, including its existing releases
and tags. Retained build/release workflows document reproducibility for forks;
they are not an ongoing maintenance service. Local private records and recovery
material are kept separately and are not published with the public source.
