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
- The [v1.3.2 release workflow](https://github.com/Niko96-dotcom/automation-health/actions/runs/36695876414)
  completed successfully from tag commit `6d489c0`. Both published assets matched
  GitHub's SHA-256 digests and sizes. The DMG's notarization staple, nested code
  signatures, and Gatekeeper assessment passed. The appcast's version, enclosure
  URL, length, and Ed25519 signature verified against the embedded public key,
  which matches the previous installation.
- The published DMG was installed directly over the old v1.3 app with a recovery
  copy retained. The installed v1.3.2 app launched, completed a scan, showed the
  correct version in Settings, and completed a live Check for Updates with
  “You're up to date.” This proves direct installation and update checking;
  Sparkle's update-download/install/relaunch flow was not exercised.
- A README formatting change initially broke the icon check's exact-text
  requirement after the release tag was pushed. The original wording was restored
  on `main` and the focused icon check passed. This correction changes documentation
  only; the published app's source code is unchanged.
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

## Final Artifact Digests

| Published asset | SHA-256 |
| --- | --- |
| `AutomationHealth-1.3.2.dmg` | `b529228132033c3d583526edaa3d7df4dc7718bdccddef279d3461d830430a60` |
| `appcast.xml` | `1fc8242403549f7c8eed2e97e7c5070408870571944f2c1f071434d6e34e0eb5` |
