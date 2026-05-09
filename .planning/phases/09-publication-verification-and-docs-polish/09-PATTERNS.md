# Phase 09: Publication Verification And Docs Polish - Patterns

**Mapped:** 2026-05-09
**Source:** Phase 09 research, UI spec, validation strategy, roadmap, and existing publication docs

## Scope Map

| Planned Area | Files | Closest Existing Analog | Pattern To Reuse |
|--------------|-------|-------------------------|------------------|
| Publication scrub cleanup | `.gitignore`, repository `.DS_Store` files, `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `docs/privacy-scrub-checklist.md` | `docs/privacy-scrub-checklist.md`, `script/test_app_icon.sh` | Use explicit shell commands, distinguish unexpected findings from documented false positives, and keep cleanup outside app behavior. |
| Public visuals and docs polish | `README.md`, `Assets/AppIcon/README.md`, `docs/development.md`, `docs/privacy-scrub-checklist.md` | `Assets/AppIcon/README.md`, `README.md` | Prefer the committed abstract Pulse Grid icon assets or explicitly synthetic screenshots. Avoid real local automation data, raw terminal images, usernames, hostnames, paths, and scheduler output. |
| Icon/public visual verification | `script/test_app_icon.sh`, `Assets/AppIcon/*` | `script/test_app_icon.sh` | Validate source art, generated iconset sizes, ICNS presence, bundle icon wiring, and private-looking strings in PNG/ICNS assets. |
| Final regression gate | `script/ci.sh`, `script/test.sh`, `script/build_and_run.sh`, `Sources/ActiveJobsCoreSelfTest/main.swift` | Phase 07/08 verification reports | Pair automated CI/app-bundle verification with manual smoke coverage for behavior that is local-machine or SwiftUI-visual dependent. |
| Traceability and publication evidence | `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/phases/09-publication-verification-and-docs-polish/*-SUMMARY.md`, future `09-VERIFICATION.md` | `.planning/phases/07-candidate-discovery-and-manual-records/07-VERIFICATION.md`, `.planning/phases/08-sidebar-grouping-collapse-and-focus-polish/08-VERIFICATION.md` | Name requirement IDs, commands run, expected false positives, manual checks, and read-only signoff directly in summary/verification artifacts. |

## Concrete Existing Patterns

### Privacy Scrub Checklist

`docs/privacy-scrub-checklist.md` already defines the publication scrub surface. Plans should reuse these exact commands instead of creating a parallel checklist:

```sh
find . -name .DS_Store -print
rg -n "niko|com\\.niko|/Users/niko" README.md CONTRIBUTING.md docs .github Sources script
rg -n "token|secret|password|hostname|screenshot|scheduler output" README.md CONTRIBUTING.md docs .github Sources script
```

The existing checklist also defines expected false positives: security/support/contribution guidance and the checklist itself may intentionally mention sensitive categories as things not to publish.

### App Icon Validation

`script/test_app_icon.sh` is the existing public visual validation pattern. It requires:

- `Assets/AppIcon/README.md` includes the Pulse Grid prompt and privacy constraints.
- `Assets/AppIcon/automation-health-icon-source.png` is square and at least 1024 px.
- generated iconset PNGs exist at required macOS sizes.
- `Assets/AppIcon/AutomationHealth.icns` exists and contains no private-looking strings.
- `script/build_and_run.sh` copies and declares `AutomationHealth.icns`.
- `README.md` references local icon regeneration through `docs/development.md`.

### Phase Verification Reports

Phase 07 and Phase 08 verification files use concise tables with requirement IDs, exact command evidence, and residual risk. Phase 09 should follow that shape for publication evidence:

- `07-VERIFICATION.md` records manual record add/edit/remove checks and explicitly states real scheduler files are not modified.
- `08-VERIFICATION.md` records automated checks, a human UAT artifact, and which behavior needed manual visual approval.
- `08-HUMAN-UAT.md` is the existing pattern for compact human signoff when automation cannot prove the UI state.

## File-Level Guidance

| File | Guidance |
|------|----------|
| `README.md` | Keep public copy practical and local-first. If adding visuals, use abstract icon/assets or synthetic screenshots only. Do not add marketing-style hero sections or real scheduler output. |
| `docs/privacy-scrub-checklist.md` | Update only if the publication scrub needs clearer accepted false positives or exact remediation steps. Keep commands rerunnable. |
| `Sources/ActiveJobsCore/Support/JobHumanizer.swift` | Replace the personal namespace scrub rule with a generic/private-neutral approach that still removes common bundle prefixes from display names. Do not introduce scanner IO or behavior changes outside display-name normalization. |
| `.gitignore` | `.DS_Store` is already ignored. Execution should remove accidental local `.DS_Store` files and confirm they are not staged/committed. |
| `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` | Update traceability only after evidence exists. Plans should not mark `PRIV-01`, `VIS-04`, or `QUAL-04` complete during execution until checks/manual signoff pass. |

## Guardrails

- Do not add scheduler mutation controls or write behavior for real automations.
- Do not add screenshots from the maintainer's real machine unless every visible value is synthetic.
- Do not treat checklist guidance matches as failed privacy leaks; document expected false positives separately from unexpected findings.
- Do not let CI alone satisfy `QUAL-04`; the final smoke check must cover launchd, Hermes cron, search, selection, refresh, manual records, grouping/collapse, focus styling, and read-only posture.
- Do not introduce third-party dependencies, web design systems, or non-native UI patterns.

