# Phase 9: Publication Verification And Docs Polish - Research

**Researched:** 2026-05-09
**Domain:** public release privacy scrub, sanitized documentation visuals, final local regression verification, requirement traceability
**Confidence:** HIGH

## Summary

Phase 9 should be a short publication-readiness phase that turns the already-built v1.1 work into a clean public handoff. It should not add scheduler behavior or new app capabilities. The plans should focus on two waves already named in the roadmap:

1. Refresh public docs/assets, remove privacy scrub findings, and make the publication scrub rerunnable and clean.
2. Run final CI/manual verification across the implemented scanners, manual records, sidebar grouping/collapse/focus behavior, and requirement traceability.

The current blocking findings are concrete:

- `find . -name .DS_Store -print` currently reports `.DS_Store` files under the repo root, `Sources/`, `.build/`, `dist/`, and `.git/`.
- `rg -n "niko|com\\.niko|/Users/niko" README.md CONTRIBUTING.md docs .github Sources script` currently reports intentional checklist mentions plus `Sources/ActiveJobsCore/Support/JobHumanizer.swift:21` stripping `com.niko.` from launchd labels.
- Phase 9 has no `CONTEXT.md` or `UI-SPEC.md` yet. Planning can use requirements, roadmap, audit, and research, but the UI safety gate should block final plan creation until `$gsd-ui-phase 9` runs or the user explicitly replans with `--skip-ui`.

## Phase Requirement Map

| Requirement | Meaning For Phase 9 | Planning Implication |
|-------------|---------------------|----------------------|
| `PRIV-01` | The maintainer can run or follow a publication privacy scrub covering docs, fixtures, screenshots, sample output, bundle identifiers, usernames, hostnames, and paths. | Include exact scrub commands, resolve unexpected hits, and document accepted false positives. |
| `VIS-04` | Public README/docs visuals use sanitized, aesthetically consistent screenshots or assets with no personal local automations. | Either update public visuals/assets or explicitly document that public visuals are abstract/sanitized assets rather than screenshots. Verify no private paths/output/text leaks into assets. |
| `QUAL-04` | Existing launchd, Hermes cron, search, selection, and refresh behavior continue to pass the local CI gate. | Run `./script/ci.sh`, app icon validation, app bundle verification, view-layer IO/mutation greps, and manual smoke checks where UI behavior cannot be fully automated. |

## Relevant Existing Artifacts

| Artifact | Role |
|----------|------|
| `.planning/v1.1-MILESTONE-AUDIT.md` | Source of the Phase 9 gap closure: privacy scrub still fails, sanitized public visuals are missing, and final regression signoff is absent. |
| `docs/privacy-scrub-checklist.md` | Existing rerunnable checklist and scrub command source. Plans should improve or validate this rather than inventing a separate process. |
| `README.md` | Primary public surface; currently links the privacy checklist and should carry only sanitized visual/public identity content. |
| `Assets/AppIcon/README.md` and `Assets/AppIcon/*` | Existing abstract Pulse Grid visual identity and local icon validation path. |
| `script/test_app_icon.sh` | Already verifies icon docs, generated icon sizes, bundle icon wiring, and rejects private-looking strings in the source PNG and ICNS. |
| `script/test.sh` | Runs `swift run ActiveJobsCoreSelfTest` and `./script/test_app_icon.sh`. |
| `script/ci.sh` | Runs `swift build` and `./script/test.sh`; this is the project quality gate for Phase 9. |
| `.planning/phases/07-candidate-discovery-and-manual-records/07-VERIFICATION.md` | Defines prior manual-record and broad inventory behavior that final smoke verification should mention. |
| `.planning/phases/08-sidebar-grouping-collapse-and-focus-polish/08-VERIFICATION.md` and `08-HUMAN-UAT.md` | Defines prior sidebar grouping/collapse/focus behavior and the human-approved focus result to preserve. |

## Recommended Plan Split

### 09-01: Refresh sanitized public docs/screenshots/assets and run the privacy scrub

Purpose: make `PRIV-01` and `VIS-04` true before final regression signoff.

Expected scope:

- Remove committed `.DS_Store` files from the working tree and ensure they remain ignored.
- Resolve `com.niko` in production/source identifiers so only intentional checklist references remain.
- Review README/docs public visuals and icon references for sanitized, aesthetically consistent content.
- Decide whether Phase 9 uses abstract app/icon assets only or adds screenshots. If screenshots are added, they must be synthetic and scrubbed. If no screenshots are added, README/docs should make public visuals rely on the sanitized app icon/assets rather than real local automation screenshots.
- Run and record:
  - `find . -name .DS_Store -print`
  - `rg -n "niko|com\\.niko|/Users/niko" README.md CONTRIBUTING.md docs .github Sources script`
  - `rg -n "token|secret|password|hostname|screenshot|scheduler output" README.md CONTRIBUTING.md docs .github Sources script`
  - `./script/test_app_icon.sh`

### 09-02: Run CI/manual verification and prepare publication notes

Purpose: make `QUAL-04` true and reconcile final traceability.

Expected scope:

- Run `./script/ci.sh` after the privacy/docs/assets pass.
- Run `./script/build_and_run.sh --verify`.
- Manually smoke-check with synthetic or privacy-safe local data:
  - launchd and Hermes cron records still render where available.
  - broader inventory records from Phase 7 remain searchable/selectable.
  - manual records can still be added/edited/removed without modifying real scheduler files.
  - sidebar grouping modes, collapse/search reveal, and Up/Down focus navigation still behave as Phase 8 describes.
  - read-only posture is visible and no real scheduled job mutation controls are introduced.
- Update requirement traceability so `PRIV-01`, `VIS-04`, and `QUAL-04` are satisfied by Phase 9 evidence.
- Prepare a concise Phase 9 summary and publication notes that state which scrub hits are expected false positives and which checks passed.

## Validation Architecture

Phase 9 can be validated mostly with existing local commands and a small manual smoke checklist. No new XCTest target or third-party dependency is needed.

| Validation Dimension | Automated Command Or Evidence | Manual Evidence |
|----------------------|--------------------------------|-----------------|
| Privacy metadata cleanup | `find . -name .DS_Store -print` returns no publishable-tree hits; `.build/`, `dist/`, and `.git/` findings should be handled by cleaning ignored/local artifacts before publication. | N/A |
| Personal namespace scrub | `rg -n "niko|com\\.niko|/Users/niko" README.md CONTRIBUTING.md docs .github Sources script` has only intentional checklist false positives or no output. | N/A |
| Sensitive category scan | `rg -n "token|secret|password|hostname|screenshot|scheduler output" README.md CONTRIBUTING.md docs .github Sources script` shows only intentional guidance in privacy/security docs/templates. | N/A |
| Public visual safety | `./script/test_app_icon.sh` passes and README/docs contain only sanitized abstract icon/assets or explicitly synthetic screenshots. | Human review confirms visuals do not expose local automations, paths, output, hostnames, or private commands. |
| Regression safety | `./script/ci.sh` and `./script/build_and_run.sh --verify` pass. | Manual smoke checks cover launchd, Hermes cron, search, selection, refresh, manual records, grouping/collapse, and focus styling. |
| Traceability | `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and Phase 9 summary/verification name `PRIV-01`, `VIS-04`, and `QUAL-04`. | N/A |

## Security Threat Model

Security enforcement is applicable because Phase 9 prepares public-facing docs/assets and verifies no private local automation details are published.

| Threat ID | Category | Asset | Mitigation |
|-----------|----------|-------|------------|
| `T-09-01` | Information Disclosure | README/docs/screenshots/sample output | Require sanitized visuals or abstract assets only; reject paths, hostnames, job names, raw scheduler output, tokens, and private commands. |
| `T-09-02` | Information Disclosure | Source code and bundle identifiers | Remove personal namespace strings from source behavior unless explicitly documented as checklist false positives. |
| `T-09-03` | Information Disclosure | Local repository metadata | Remove `.DS_Store` and other accidental local metadata before publication. |
| `T-09-04` | Repudiation | Release/publication readiness evidence | Record exact commands and manual checks in Phase 9 summary/verification so publication readiness is auditable. |
| `T-09-05` | Tampering | Real scheduled jobs | Preserve the read-only boundary; manual verification must confirm no real scheduler files, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata are modified. |

## Common Pitfalls

| Pitfall | Why It Matters | Guardrail |
|---------|----------------|-----------|
| Treating checklist text as a failed scrub | The checklist intentionally contains sensitive category names and the scrub regex itself. | Plans must distinguish expected false positives from unexpected source/docs hits. |
| Only deleting `.DS_Store` under source-controlled paths | Publication packaging can still pick up ignored local artifacts if `dist/` or `.build/` are copied. | Clean ignored build/output artifacts before publication and verify the working tree publish surface. |
| Adding real screenshots from the maintainer's machine | Screenshots can leak job names, paths, outputs, hostnames, and UI state. | Prefer abstract app/icon assets; if screenshots are needed, use synthetic data only. |
| Marking `QUAL-04` from CI alone | The requirement names launchd, Hermes cron, search, selection, and refresh behavior. | Pair `./script/ci.sh` with app bundle verification and targeted manual smoke checks. |
| Updating traceability before evidence exists | Phase 9 exists to close audit gaps with proof. | Only mark requirements complete after scrub, visual review, CI, and manual verification evidence exists. |

## Sources

- Repository files verified locally: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/v1.1-MILESTONE-AUDIT.md`, `docs/privacy-scrub-checklist.md`, `script/test_app_icon.sh`, `script/test.sh`, `script/ci.sh`, `.planning/phases/07-candidate-discovery-and-manual-records/07-VERIFICATION.md`, `.planning/phases/08-sidebar-grouping-collapse-and-focus-polish/08-VERIFICATION.md`, `.planning/phases/08-sidebar-grouping-collapse-and-focus-polish/08-HUMAN-UAT.md`.
- Local checks run during research: `find . -name .DS_Store -print`; `rg -n "niko|com\\.niko|/Users/niko" README.md CONTRIBUTING.md docs .github Sources script`.
