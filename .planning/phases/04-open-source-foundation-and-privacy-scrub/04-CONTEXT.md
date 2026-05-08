# Phase 4: Open Source Foundation And Privacy Scrub - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 prepares Automation Health for public GitHub publication before public-facing assets are produced. It covers public repository health files, README/docs updates, GitHub workflow/template hygiene, explicit privacy guidance, a rerunnable publication scrub checklist, and scanner architecture documentation. It does not add new scanner behavior, app features, icons, screenshots, signed releases, or job-management capabilities.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Defines Phase 4 goal, success criteria, planned waves, and phase boundary.
- `.planning/REQUIREMENTS.md` - Defines Phase 4 requirements: `OSS-01` through `OSS-06`, `PRIV-01` through `PRIV-03`, and `QUAL-05`.
- `.planning/PROJECT.md` - Captures project value, current milestone focus, constraints, and open-source/privacy key decisions.
- `.planning/STATE.md` - Current GSD state and warning about preserving unrelated working-tree changes.

### Public Documentation
- `README.md` - Primary public landing page to rewrite with balanced utility voice, privacy posture, quick start, limitations, and local-build status.
- `CONTRIBUTING.md` - Contributor workflow and style guidance to expand with privacy and scanner contribution expectations.
- `docs/development.md` - Developer commands, PR checklist, and local build/run details.
- `docs/architecture.md` - Existing scanner/presentation/app layer explanation; should link to the dedicated scanner-extension guide.
- `docs/scheduled-job-sources.md` - Existing source documentation; should gain honest source notes and link to scanner-extension guidance.

### GitHub Repository Hygiene
- `.github/workflows/ci.yml` - Existing CI workflow; should keep running `./script/ci.sh` with explicit permissions and clear naming.
- `.github/pull_request_template.md` - Existing PR template; should add local CI plus privacy-check expectations.
- `.github/ISSUE_TEMPLATE/bug_report.yml` - Existing bug report template; should warn about sanitized logs/screenshots/output.
- `.github/ISSUE_TEMPLATE/feature_request.yml` - Existing feature template; should avoid requesting sensitive local output.
- `.github/.DS_Store` - Accidental local metadata file detected during scout; should be removed as part of the public scrub.

### Privacy-Sensitive Code And Fixtures
- `script/build_and_run.sh` - Contains current bundle identifier and generated app metadata; neutralize personal bundle ID.
- `docs/development.md` - Mentions the current bundle identifier; update with neutralized identity.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Contains fixture paths and sample names that should become synthetic.
- `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` - Contains personal/domain-specific launchd heuristic terms that should be reviewed under the strict scrub.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `README.md`, `CONTRIBUTING.md`, `docs/development.md`, `docs/architecture.md`, and `docs/scheduled-job-sources.md` already provide the document skeletons Phase 4 should revise rather than replacing wholesale.
- `.github/workflows/ci.yml` already runs `./script/ci.sh`, sets explicit `contents: read` permissions, and uses concurrency. The work is hygiene/refinement, not a new CI system.
- `.github/ISSUE_TEMPLATE/*.yml` and `.github/pull_request_template.md` already exist and can be tightened around privacy instead of created from scratch.
- `script/build_and_run.sh` centralizes local app bundle metadata, including the bundle ID that needs neutralization.

### Established Patterns
- The repo uses SwiftPM, Bash scripts, Markdown docs, YAML GitHub templates, and no third-party Swift dependencies.
- Scanner IO lives in `Sources/ActiveJobsCore`; SwiftUI views consume presentation/store data. Public docs should reinforce this boundary.
- The local quality gate is `./script/ci.sh`, which runs `swift build` and `./script/test.sh`; PR docs and templates should keep pointing contributors there.
- Existing docs are concise and plain; Phase 4 should preserve that tone while making privacy and limitations more explicit.

### Integration Points
- Public docs connect through `README.md` and should link to `CONTRIBUTING.md`, `docs/development.md`, `docs/architecture.md`, `docs/scheduled-job-sources.md`, the new privacy checklist, and the new scanner-extension guide.
- Repository health files should be placed in GitHub-recognized root locations unless a standard file belongs under `.github/`.
- Scanner-extension docs should tie directly to `ScheduledJob`, `JobSource`, `JobScanning`, `JobInventory`, scanner fixtures in `Sources/ActiveJobsCoreSelfTest/main.swift`, and source documentation updates.

</code_context>

<specifics>
## Specific Ideas

- Use a neutral, synthetic bundle identifier in public-facing scripts/docs instead of `com.niko.AutomationHealth`.
- Replace `/Users/niko`-style fixture paths with synthetic paths such as `/Users/example/...` or fixture-root-relative paths.
- Replace personal or domain-specific sample automation names/output with neutral examples.
- Keep future broad inventory language careful: it can say the project is moving toward broader best-effort inventory, but it should not present confidence/origin model fields as shipped behavior.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 4 scope.

</deferred>

---

*Phase: 04-open-source-foundation-and-privacy-scrub*
*Context gathered: 2026-05-08*
