---
phase: 09
slug: publication-verification-and-docs-polish
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-10
---

# Phase 09 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Local repository metadata -> public source tree | Accidental Finder metadata must not enter the publishable source surface. | Local macOS metadata, ignored files |
| Local scheduler identity -> README/docs/assets | Public docs and visuals must not reveal real local automations, paths, hostnames, output, private commands, tokens, or secrets. | Scheduler names, paths, output snippets, public assets |
| Display-name cleanup -> scanner behavior | Removing a personal namespace literal must preserve read-only scanner behavior and avoid adding IO or mutation. | Launchd labels, scanner presentation strings |
| Automated regression output -> public evidence | Evidence records command names and outcomes without publishing private terminal logs. | CI/build outcomes, scrub outcomes |
| Manual smoke checks -> real automations | Verification inspects read-only behavior without modifying real scheduler sources. | Live scheduler posture, synthetic fixture evidence |
| Traceability updates -> requirement status | Requirements may only be marked complete after scrub, visual, CI, bundle, and manual evidence exists. | Requirement and roadmap status |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-09-01 | Information Disclosure | README/docs/screenshots/sample output and verification artifacts | mitigate | README privacy guidance requires sanitized summaries and abstract/synthetic visuals; final scrub commands were rerun and found no unexpected public-surface privacy issues. Evidence: `README.md:38`, `README.md:40`, `09-02-SUMMARY.md:77-88`, fresh `find`/`rg` audit on 2026-05-10. | closed |
| T-09-02 | Information Disclosure | Source code namespace strings | mitigate | `JobHumanizer` now drops generic bundle-prefix components instead of a personal namespace literal, with self-test coverage for generic and placeholder launchd labels. Evidence: `Sources/ActiveJobsCore/Support/JobHumanizer.swift:36-42`, `Sources/ActiveJobsCoreSelfTest/main.swift:820-821`, fresh `rg` audit on 2026-05-10. | closed |
| T-09-03 | Information Disclosure | Local repository metadata | mitigate | `.DS_Store` remains ignored and the current metadata scrub returned no `.DS_Store` files. Evidence: `.gitignore:1`, fresh `find . -name .DS_Store -print` audit on 2026-05-10. | closed |
| T-09-04 | Repudiation | Publication scrub and readiness evidence | mitigate | Phase summaries and verification record exact command names, pass results, expected false positives, icon validation, manual checklist, and requirement coverage. Evidence: `09-02-SUMMARY.md:72-92`, `09-VERIFICATION.md:31-41`, fresh `./script/test_app_icon.sh` and `./script/test.sh` runs on 2026-05-10. | closed |
| T-09-05 | Tampering | Real scheduled jobs | avoid | Phase evidence uses repository scripts, synthetic fixtures, and app-owned manual-record coverage; it explicitly records no real scheduler files, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, or Hermes metadata were modified. Evidence: `09-HUMAN-UAT.md:71-75`, `09-VERIFICATION.md:43-55`. | closed |
| T-09-06 | Spoofing | Requirement traceability | mitigate | Traceability for `PRIV-01`, `VIS-04`, and `QUAL-04` is checked complete only after evidence files exist. Evidence: `.planning/REQUIREMENTS.md:22`, `.planning/REQUIREMENTS.md:31`, `.planning/REQUIREMENTS.md:65`, `.planning/ROADMAP.md:165-184`, `09-VERIFICATION.md:23-29`. | closed |
| T-09-07 | Denial of Service | Final verification workflow | mitigate | Final verification is limited to existing bounded local scripts and documented outcomes: `./script/ci.sh`, `./script/test.sh`, `./script/test_app_icon.sh`, and `./script/build_and_run.sh --verify`. Evidence: `script/ci.sh:1-9`, `script/test.sh:1-9`, `script/build_and_run.sh:76-80`, `09-VERIFICATION.md:38-41`. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party) - avoid (scope excludes the risky behavior)*

---

## Accepted Risks Log

No accepted risks.

---

## Unregistered Flags

No `## Threat Flags` section was present in `09-01-SUMMARY.md` or `09-02-SUMMARY.md`, and no unregistered implementation security flag was identified during this mitigation audit.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-10 | 7 | 7 | 0 | Codex |

Fresh audit checks run:

- `find . -name .DS_Store -print` - passed with no output.
- `rg -n "niko|com\\.niko|/Users/niko" README.md CONTRIBUTING.md docs .github Sources script` - expected checklist-only matches in `docs/privacy-scrub-checklist.md`.
- `rg -n "token|secret|password|hostname|screenshot|scheduler output" README.md CONTRIBUTING.md docs .github Sources script` - expected guidance/template matches only.
- `./script/test_app_icon.sh` - passed.
- `./script/test.sh` - passed.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer / avoid)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-10
