# Phase 4: Open Source Foundation And Privacy Scrub - Research

**Researched:** 2026-05-08
**Domain:** Open-source repository readiness, privacy-safe public documentation, GitHub repository hygiene
**Confidence:** HIGH

## User Constraints

### Public Docs Voice
- **D-01:** Public docs should use a balanced utility voice: approachable for users while still useful to scanner contributors.
- **D-02:** The README opening should be ordered around what the app does, the privacy/read-only posture, then quick start commands.
- **D-03:** Best-effort discovery and "not supported yet" limitations should be prominent and plain, not hidden deep in the docs.
- **D-04:** Distribution status should be explicit: this is currently an unsigned/local-build app; signing and notarization remain out of scope for v1.1.

### Privacy Scrub Strictness
- **D-05:** Phase 4 should perform a strict public scrub, not merely document the risk.
- **D-06:** The current personal bundle identifier should be neutralized now in public-facing docs/scripts.
- **D-07:** Tests, fixtures, examples, docs, and sample output should use synthetic automation names, paths, and output everywhere practical.
- **D-08:** The publication privacy scrub should be a standalone rerunnable checklist.

### Contribution Intake
- **D-09:** Issue templates should warn before users share logs, screenshots, scheduler output, paths, hostnames, job names, or secrets; ask for summaries or sanitized snippets.
- **D-10:** Add the full standard GitHub health file set: `LICENSE`, `SECURITY.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md`, improved `CONTRIBUTING.md`, PR template, and issue templates.
- **D-11:** Use the MIT license.
- **D-12:** PR verification should require the local `./script/ci.sh` gate plus an explicit privacy check for public docs, examples, screenshots, and fixtures.

### Scanner Extension Guide
- **D-13:** Scanner contributor docs should provide an adapter recipe: add scanner type, update `JobSource`, compose it in `JobInventory`, add fixture/self-test coverage, and update docs.
- **D-14:** Source docs should use honest source notes: what each scanner reads, what it cannot see, what errors mean, and whether available evidence proves scheduling.
- **D-15:** Phase 4 may prepare language for broader v1.1 inventory, but must not document confidence/origin fields or UX as if they already exist.
- **D-16:** Scanner-extension guidance should live in a dedicated docs page, linked from README, CONTRIBUTING, architecture docs, and scheduled-source docs.

### the agent's Discretion
No major implementation choices were delegated to the agent. Downstream agents can decide exact wording, section headings, file ordering, and Markdown formatting as long as the decisions above are honored.

## Summary

Phase 4 is documentation, repository hygiene, and privacy hardening work. It should not add scanner behavior or app features; the implementation path is to make public-facing files explicit, privacy-preserving, and contributor-friendly while keeping the app's read-only local inspection boundary central. [VERIFIED: `.planning/ROADMAP.md`, `.planning/phases/04-open-source-foundation-and-privacy-scrub/04-CONTEXT.md`]

The best planning split is the three-wave roadmap shape already present: repository health and templates first, public README/source/architecture docs second, then strict privacy scrub artifacts plus targeted neutralization of known personal identifiers and sample data. This keeps PR/community files available before docs link to them, and keeps the final scrub after public text is updated. [VERIFIED: `.planning/ROADMAP.md`]

Primary recommendation: create three executable plans with concrete grep-verifiable acceptance criteria, include `./script/ci.sh` as the final automated gate where code or scripts change, and make the privacy checklist a real artifact under `docs/` instead of a note buried in README. [VERIFIED: `script/ci.sh`, `docs/`, `.planning/phases/04-open-source-foundation-and-privacy-scrub/04-CONTEXT.md`]

## Project Constraints (from AGENTS.md)

- Preserve read-only behavior; Phase 4 must not introduce job management or mutation controls. [VERIFIED: `AGENTS.md`]
- Keep scanner IO out of SwiftUI views; scanner architecture docs should reinforce the `ActiveJobsCore` boundary. [VERIFIED: `AGENTS.md`]
- Avoid new third-party Swift dependencies; repository-health docs do not need packages. [VERIFIED: `Package.swift`, `AGENTS.md`]
- Use `ActiveJobsCoreSelfTest` and `./script/ci.sh` as the existing verification workflow. [VERIFIED: `AGENTS.md`, `script/ci.sh`]
- Preserve unrelated dirty working-tree changes. Current source modifications exist in `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`, and `Sources/AutomationHealth/Views/DetailView.swift`; executors must read current files before editing and avoid reverting unrelated changes. [VERIFIED: `git status --short` on 2026-05-08]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public repository health files | Root and `.github/` documentation tier | GitHub issue/PR template metadata | GitHub discovers standard community files from root or `.github/` locations; no app code should own this. |
| CI gate documentation | `.github/workflows/ci.yml`, `docs/development.md`, PR template | `script/ci.sh` | The workflow should continue delegating to the local script so local and CI verification stay identical. |
| Scanner-source explanations | `docs/scheduled-job-sources.md` | README summary | Source docs own detailed scan boundaries and limitations; README should link without duplicating every edge case. |
| Scanner-extension recipe | New `docs/scanner-extension-guide.md` | `docs/architecture.md`, CONTRIBUTING, README | A dedicated guide keeps contributor implementation steps out of SwiftUI view docs and links to core contracts. |
| Privacy scrub procedure | New `docs/privacy-scrub-checklist.md` | PR template, CONTRIBUTING, README | The scrub needs to be rerunnable and referenceable from contribution/release flow. |
| Synthetic fixtures and identifiers | `Sources/ActiveJobsCoreSelfTest/main.swift`, `script/build_and_run.sh`, docs | Privacy checklist | Known public-facing examples should use neutral names and identifiers before screenshots/assets are produced. |

## Standard Stack

### Core

| Tool or Format | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Markdown | Repository-native | README, contribution, security, support, architecture, scanner docs | Existing project docs are Markdown and GitHub renders them directly. |
| GitHub issue forms YAML | GitHub-hosted schema | Bug/feature intake with labels, descriptions, and text areas | Existing issue templates already use YAML forms; GitHub documents issue forms under `.github/ISSUE_TEMPLATE`. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| GitHub Actions workflow YAML | GitHub-hosted schema | CI build/test gate | Existing workflow already runs `./script/ci.sh`; GitHub supports explicit `permissions` for least-privilege `GITHUB_TOKEN` access. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |
| SwiftPM scripts | Swift tools 6.0 package | Local build/test/app bundle verification | Current repo quality gate is `swift build` plus `swift run ActiveJobsCoreSelfTest`. [VERIFIED: `Package.swift`, `script/ci.sh`, `script/test.sh`] |

### Supporting

| Tool or Format | Purpose | When to Use |
|----------------|---------|-------------|
| `rg` | Privacy scrub and acceptance checks | Use for deterministic searches over usernames, hostnames, bundle ids, sample paths, and sensitive keywords. |
| MIT license text | Project license artifact | Use because D-11 locks the license choice. |
| Root community files | GitHub repository health | Use standard root files for `LICENSE`, `SECURITY.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md`, and `CONTRIBUTING.md`; GitHub documents community-health files as a standard contribution path. [CITED: https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Root `CODE_OF_CONDUCT.md` and `SECURITY.md` | `.github/` community-health files | Root files are more visible in a small repo and match D-10's "standard health file set" without adding indirection. |
| Existing executable self-test | New XCTest target | Out of scope for Phase 4; current constraint requires the existing `ActiveJobsCoreSelfTest` and `script/ci.sh` workflow. |
| Heavy legal/security policy templates | Lightweight project-specific language | A local scanner app benefits from clear intake boundaries and privacy warnings; heavyweight policy machinery can overpromise support expectations. |

## Architecture Patterns

### Phase Implementation Flow

```text
Repository health files and templates
  -> README, contribution, scanner architecture, and source docs
  -> Standalone privacy scrub checklist
  -> Targeted neutralization of bundle id, fixtures, and known personal keywords
  -> ./script/ci.sh verification
```

### Public Documentation Pattern

- README should start with product purpose, local/read-only privacy posture, supported sources, quick start, limitations, and contribution links in that order per D-02. [VERIFIED: `04-CONTEXT.md`]
- Detailed scanner truth belongs in `docs/scheduled-job-sources.md`, including "reads", "cannot see", "shells out", "evidence strength", and "failure meaning" sections per D-14. [VERIFIED: `04-CONTEXT.md`]
- Scanner extension steps belong in `docs/scanner-extension-guide.md` with concrete references to `ScheduledJob`, `JobSource`, `JobScanning`, `JobInventory`, fixtures in `ActiveJobsCoreSelfTest`, and docs updates per D-13/D-16. [VERIFIED: `Sources/ActiveJobsCore`, `04-CONTEXT.md`]

### Privacy Scrub Pattern

- Treat job names, local paths, hostnames, usernames, bundle identifiers, screenshots, sample output, and scheduler snippets as sensitive by default. [VERIFIED: `04-CONTEXT.md`, `.planning/REQUIREMENTS.md`]
- Use both artifact-level instructions and runnable `rg` commands. The checklist should say what each command is looking for and what to do with expected false positives, not merely list "check privacy". [ASSUMED: local repository practice]
- Known current scrub targets are `.github/.DS_Store`, `script/build_and_run.sh` bundle id, `docs/development.md` bundle id mention, personal fixture paths/job names in `Sources/ActiveJobsCoreSelfTest/main.swift`, and personal/domain-specific `interestingTerms` in `LaunchAgentScanner`. [VERIFIED: `04-CONTEXT.md`, inspected files]

## Don't Hand-Roll

- Do not invent a new CI entrypoint; preserve `./script/ci.sh` as the local and GitHub Actions gate. [VERIFIED: `script/ci.sh`, `.github/workflows/ci.yml`]
- Do not add Swift packages, linters, formatters, or generated docs tooling for this phase. The scope is publishable repository materials, not tooling expansion. [VERIFIED: `Package.swift`, `AGENTS.md`]
- Do not implement future confidence/origin UX or data fields in docs as shipped behavior. Mention future broad inventory only as planned or best-effort language per D-15. [VERIFIED: `04-CONTEXT.md`]
- Do not move scanner IO into SwiftUI views or suggest source-specific UI branching. The extension guide must route scanner additions through `ActiveJobsCore`. [VERIFIED: `docs/architecture.md`, `AGENTS.md`]

## Common Pitfalls

| Pitfall | Why It Matters | Plan Guardrail |
|---------|----------------|----------------|
| Templates invite raw logs/screenshots | Users can paste private scheduler output, paths, secrets, or hostnames. | Issue templates and PR template must explicitly ask for sanitized summaries/snippets. |
| README overclaims inventory completeness | Current scanners cover launchd and Hermes cron only. | README and source docs must say best-effort and not supported yet near the top. |
| Privacy checklist is non-runnable prose | Future screenshot/publication work needs repeatable checks. | Add `docs/privacy-scrub-checklist.md` with concrete `rg` commands and checklist categories. |
| Bundle id remains personal | Public scripts/docs should not carry a personal namespace. | Replace `com.niko.AutomationHealth` with `org.automationhealth.AutomationHealth` in public-facing script/docs. |
| Fixture changes break existing self-tests | Plan 3 touches test fixtures while preserving behavior. | Keep expected scanner output updated with the exact synthetic values and run `./script/ci.sh`. |
| CI workflow permissions drift | Public repos should minimize `GITHUB_TOKEN` permissions. | Preserve explicit `permissions: contents: read` and document that unspecified permissions become none when a permission map is specified. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |

## Code Examples

### Neutral Bundle Identifier Target

```bash
BUNDLE_ID="org.automationhealth.AutomationHealth"
```

Use the same string in `script/build_and_run.sh` and docs that mention the generated local app bundle.

### Privacy Scrub Commands

```bash
rg -n "niko|com\\.niko|/Users/niko|hostname|token|secret|password" README.md CONTRIBUTING.md docs .github Sources script
find . -name .DS_Store -print
```

Plans should require executors to resolve intentional hits or document why a hit is safe.

## Security Domain

Security enforcement is applicable because Phase 4 shapes public intake and privacy posture. The dominant threat is information disclosure: users or maintainers can accidentally publish local automation names, paths, command output, hostnames, bundle identifiers, or secrets. Secondary threats are tampering/misconfiguration of CI workflow permissions and overclaiming support/security guarantees in repository health files. Mitigations should be textual and procedural: sanitized templates, least-privilege workflow permissions, explicit local-only scanner descriptions, and rerunnable scrub commands.

## Open Questions (RESOLVED)

1. **Should Phase 4 require UI-SPEC?** RESOLVED: No. The roadmap explicitly says `UI hint: no`; any "view-layer IO" wording is architectural documentation, not frontend UI work.
2. **Should Phase 4 add new tests?** RESOLVED: Only if source fixtures or scanner heuristics change. Plan 3 changes fixtures/heuristics and must run the existing `./script/ci.sh` gate.
3. **Should signing/notarization be planned here?** RESOLVED: No. D-04 says signing and notarization remain out of scope for v1.1; docs should state local unsigned distribution.

## Sources

- GitHub Docs, "Syntax for issue forms": https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms
- GitHub Docs, "Workflow syntax for GitHub Actions": https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- GitHub Docs, "Creating a default community health file": https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file
- Repository files verified locally: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `04-CONTEXT.md`, `README.md`, `CONTRIBUTING.md`, `docs/*.md`, `.github/*`, `script/build_and_run.sh`, `Sources/ActiveJobsCoreSelfTest/main.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`

