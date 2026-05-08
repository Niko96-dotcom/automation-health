# Phase 4: Open Source Foundation And Privacy Scrub - Patterns

**Mapped:** 2026-05-08
**Scope:** Public repository docs, GitHub templates, privacy scrub artifacts, and targeted public-data neutralization

## Summary

Phase 4 should reuse the repository's existing plain Markdown and script-first conventions. There is no need for new tooling or dependencies. New files should be short, GitHub-recognized, and easy to verify with `rg` plus `./script/ci.sh`.

## File Classification

| File | Role | Closest Existing Analog | Pattern To Reuse |
|------|------|-------------------------|------------------|
| `LICENSE` | Root repository license | `README.md` root Markdown placement | Root-level standard GitHub file, plain text/Markdown-compatible, no custom tooling. |
| `SECURITY.md` | Security reporting and privacy intake policy | `CONTRIBUTING.md` | Short sections, explicit local-only privacy warning, clear supported contact path placeholder. |
| `SUPPORT.md` | Support expectations | `CONTRIBUTING.md` | Lightweight support boundaries and links to issue templates/docs. |
| `CODE_OF_CONDUCT.md` | Community health | `CONTRIBUTING.md` | Standard contributor-facing language in root. |
| `CONTRIBUTING.md` | Contributor workflow | Existing `CONTRIBUTING.md` | Keep requirements/local workflow/style sections; add privacy, scanner contribution, PR checklist links. |
| `.github/pull_request_template.md` | PR checklist | Existing PR template | Checkbox list plus summary/risk sections; add `./script/ci.sh` and privacy scrub checkboxes. |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Bug intake form | Existing bug report issue form | YAML form with textareas, labels, descriptions, and privacy warning text. |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Feature intake form | Existing feature request issue form | YAML form with problem/proposal/notes fields; steer away from raw local output. |
| `.github/workflows/ci.yml` | CI workflow | Existing workflow | Preserve `permissions: contents: read`, `./script/ci.sh`, `TZ`, checkout, Swift toolchain display. |
| `README.md` | Public landing page | Existing `README.md` | Purpose, read-only/privacy posture, supported sources, build/run commands, limitations, docs links. |
| `docs/development.md` | Developer commands and bundle status | Existing `docs/development.md` | Command list plus PR checklist and packaging notes. |
| `docs/architecture.md` | Layering and scanner boundary | Existing `docs/architecture.md` | Core/presentation/app layer sections with explicit no view-layer IO boundary. |
| `docs/scheduled-job-sources.md` | Source-specific scanner truth | Existing `docs/scheduled-job-sources.md` | Per-source reads/extracts/limitations structure; add evidence and failure semantics. |
| `docs/scanner-extension-guide.md` | New scanner adapter recipe | `docs/architecture.md`, `docs/scheduled-job-sources.md` | Markdown guide with file path references and ordered implementation steps. |
| `docs/privacy-scrub-checklist.md` | Rerunnable publication scrub | `docs/development.md` checklist style | Checkbox sections plus exact `rg`/`find` commands. |
| `script/build_and_run.sh` | Local app metadata | Existing script constants | Keep constants at top; change only `BUNDLE_ID` value. |
| `Sources/ActiveJobsCoreSelfTest/main.swift` | Synthetic scanner fixtures | Existing self-test fixture pattern | Keep inline fixtures and `TemporaryFixture`; replace personal names/paths with synthetic examples and update expectations. |
| `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` | LaunchAgent relevance heuristic | Existing `shouldShowRunAtLoadJob` | Preserve read-only scanner behavior; remove personal/domain-specific keywords from `interestingTerms`. |

## No Analog Found

| File | Why No Direct Analog | Research Pattern |
|------|----------------------|------------------|
| `docs/privacy-scrub-checklist.md` | No existing privacy checklist artifact exists. | Use concrete categories from D-05 through D-08 and grep-verifiable commands from `04-RESEARCH.md`. |
| `docs/scanner-extension-guide.md` | Existing architecture/source docs describe current behavior but not an adapter recipe. | Use the `ActiveJobsCore` responsibility map and ordered recipe from D-13/D-16. |

## Shared Patterns

- Keep docs concise, plain, and command-oriented; avoid marketing copy.
- Use exact repository-relative file paths inside docs and plans.
- Keep `./script/ci.sh` as the single full local gate in PR and CI copy.
- Make privacy guidance explicit anywhere users might paste logs, screenshots, command output, scheduler definitions, or paths.
- Treat future broad inventory fields as future/planned language only; do not document them as shipped behavior.
- Before editing `Sources/ActiveJobsCoreSelfTest/main.swift`, read the current file because it already has unrelated working-tree changes.

## Pattern Excerpts

From `.github/workflows/ci.yml`:

```yaml
permissions:
  contents: read
...
      - name: Build and test
        run: ./script/ci.sh
```

From `script/build_and_run.sh`:

```bash
APP_NAME="AutomationHealth"
DISPLAY_NAME="Automation Health"
BUNDLE_ID="com.niko.AutomationHealth"
MIN_SYSTEM_VERSION="14.0"
```

From `docs/architecture.md`:

```markdown
This layer is read-only and has no dependency on SwiftUI.
```

From `Sources/ActiveJobsCoreSelfTest/main.swift`:

```swift
let jobs = try LaunchAgentScanner(
    homeDirectory: root.url,
    launchAgentDirectories: [root.url.appending(path: "Library/LaunchAgents")]
).scan()
```

