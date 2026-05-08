# Research: Pitfalls For v1.1

**Milestone:** v1.1 Open Source Readiness and Broad Inventory
**Date:** 2026-05-08

## Privacy And Publication

- **Leaking personal data:** Screenshots, fixture names, output snippets, paths, bundle IDs, and logs can expose local user identity or private workflows.
  - Prevention: add an explicit privacy scrub checklist and CI/docs guidance; use synthetic fixtures and redacted screenshots.
- **Unclear license:** Publishing without a license makes reuse ambiguous.
  - Prevention: add `LICENSE` and state license in README.
- **Security reports in public issues:** Vulnerability reports should not require public disclosure.
  - Prevention: add `SECURITY.md` with private reporting instructions and supported versions.

## Discovery Claims

- **Overpromising “everything”:** No local macOS app can prove every automation, especially root-only, proprietary, cloud, app-internal, or manually invoked scripts.
  - Prevention: introduce confidence labels and phrase the product as broad inventory plus manual coverage.
- **Mistaking scripts for scheduled jobs:** A script on Desktop may be important, but it is not necessarily an automation.
  - Prevention: classify loose scripts as Candidate until linked to a scheduler or confirmed manually.
- **Root/system visibility gaps:** Some launchd, cron, and app metadata will be unreadable without privileges.
  - Prevention: report unreadable sources as scan notes, not fatal errors.

## UI And Navigation

- **Collapse breaks selection:** Collapsing the selected section can leave keyboard navigation and detail state feeling inconsistent.
  - Prevention: define hidden-selection behavior before implementation and test helper logic.
- **Too many grouping modes:** Adding every grouping option at once can bury the simple sidebar.
  - Prevention: start with a small grouping control and a reusable grouping model.
- **Focus styling regressions:** Removing the blue sidebar focus rectangle must not remove keyboard accessibility cues.
  - Prevention: replace it with an app-matched focus treatment and verify keyboard-only use.

## Technical Scope

- **Candidate scanning performance:** Recursive scans of common folders can hit huge directories, network mounts, or build outputs.
  - Prevention: add caps, ignore lists, shallow defaults, and visible scan notes.
- **Shell command variance:** `crontab`, `shortcuts`, and other tools can fail, hang, prompt, or behave differently by macOS version.
  - Prevention: run with timeouts where possible and treat failures as source-specific warnings.
- **Manual persistence creep:** Manual entries could quietly turn into job management.
  - Prevention: store app-only records and avoid writing scheduler files.
