# Phase 4: Open Source Foundation And Privacy Scrub - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 04-open-source-foundation-and-privacy-scrub
**Areas discussed:** Public Docs Voice, Privacy Scrub Strictness, Contribution Intake, Scanner Extension Guide

---

## Public Docs Voice

### Public README feel

| Option | Description | Selected |
|--------|-------------|----------|
| Balanced utility | Clear for users, with enough scanner architecture context for contributors. | Yes |
| User-first app | Lead with installation, limitations, privacy, and what the Mac app does. | |
| Developer project | Frame it mainly as an extensible scanner architecture, with the app as the current frontend. | |

**User's choice:** Balanced utility
**Notes:** README should be approachable to users and still useful to scanner contributors.

### README opening order

| Option | Description | Selected |
|--------|-------------|----------|
| What it does -> privacy -> quick start | Makes the local/read-only promise visible before commands. | Yes |
| Quick start -> what it scans -> limitations | Fastest for developers who just want to run it. | |
| Problem story -> screenshots/assets -> quick start | More product-like, probably better after Phase 5/9 visuals exist. | |

**User's choice:** What it does -> privacy -> quick start
**Notes:** Opening should make the read-only privacy promise visible early.

### Limitations prominence

| Option | Description | Selected |
|--------|-------------|----------|
| Prominent and plain | Users see early that discovery is best-effort and local-only. | Yes |
| Detailed but lower down | Keep the top concise, put limitations in dedicated sections. | |
| Minimal in README | Keep README inviting; move nuance into source docs. | |

**User's choice:** Prominent and plain
**Notes:** Best-effort and not-supported-yet language should be visible, not hidden.

### Distribution status

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit local-build status | State it is unsigned/local-build for now, with signing/notarization out of scope. | Yes |
| Soft mention only | Say "build locally" but avoid emphasizing unsigned status. | |
| Full install/release section placeholder | Create a future-facing release section even before signed artifacts exist. | |

**User's choice:** Explicit local-build status
**Notes:** Public docs should be honest that signing/notarization is out of scope for v1.1.

---

## Privacy Scrub Strictness

### Sanitization strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Strict public scrub | Remove accidental files and replace personal examples/IDs with neutral project examples where practical. | Yes |
| Docs-only scrub | Sanitize public docs/templates, but leave source/test fixture names alone unless they leak real secrets. | |
| Checklist-first | Write the checklist now, but defer most actual sanitization to Phase 9 publication verification. | |

**User's choice:** Strict public scrub
**Notes:** Phase 4 should do actual cleanup, not only create guidance.

### Bundle identifier

| Option | Description | Selected |
|--------|-------------|----------|
| Neutralize now | Switch docs/scripts to a non-personal placeholder-style bundle id suitable for public source. | Yes |
| Document as local default | Keep it for now, but call out that local builders may customize it. | |
| Defer to icon/release phase | Leave bundle identity untouched until asset packaging work. | |

**User's choice:** Neutralize now
**Notes:** Applies to public-facing docs/scripts.

### Test and example data

| Option | Description | Selected |
|--------|-------------|----------|
| Synthetic examples everywhere | Use neutral fake names/paths/output in fixtures and docs, even when harmless. | Yes |
| Only remove real personal data | Synthetic where clearly personal, but leave quirky/domain-specific sample names if useful. | |
| Docs synthetic, tests pragmatic | Public docs get neutral examples; test fixtures can stay as long as they are not secrets. | |

**User's choice:** Synthetic examples everywhere
**Notes:** Prefer boring neutral fixtures over personally flavored examples.

### Checklist location

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone checklist | Create a dedicated publication/privacy checklist that can be rerun before GitHub publication. | Yes |
| CONTRIBUTING section | Put it where maintainers already look before PR/publication work. | |
| README + docs split | Mention it in README, detailed checks in source docs. | |

**User's choice:** Standalone checklist
**Notes:** Checklist should be rerunnable.

---

## Contribution Intake

### Logs and screenshots

| Option | Description | Selected |
|--------|-------------|----------|
| Warn before sharing | Ask for summaries/sanitized snippets, with explicit reminders to remove paths, hostnames, job names, and output secrets. | Yes |
| Structured fields only | Avoid freeform log fields and ask users to classify source, symptom, and verification instead. | |
| Allow logs but mark optional | Keep current-style log box, just add a light privacy note. | |

**User's choice:** Warn before sharing
**Notes:** Templates should still allow useful debugging detail, but with strong privacy prompts.

### GitHub health files

| Option | Description | Selected |
|--------|-------------|----------|
| Full standard set | `LICENSE`, `SECURITY.md`, `SUPPORT.md`, `CODE_OF_CONDUCT.md`, stronger `CONTRIBUTING.md`, PR template, issue templates. | Yes |
| Minimal public set | `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, PR/issue templates. | |
| Maintainer-light set | Avoid community/process docs beyond license/security/support until there is a real contributor base. | |

**User's choice:** Full standard set
**Notes:** Phase 4 should make the repo feel properly public-ready.

### License

| Option | Description | Selected |
|--------|-------------|----------|
| MIT | Simple permissive license, common for small open-source tools, easy for contributors/users to understand. | Yes |
| Apache 2.0 | Permissive too, with explicit patent language and a slightly heavier feel. | |
| Decide during planning | Leave the exact license flexible, but require a standard OSI-approved license. | |

**User's choice:** MIT
**Notes:** Downstream planning can assume MIT.

### PR verification

| Option | Description | Selected |
|--------|-------------|----------|
| Local CI plus privacy check | Require `./script/ci.sh` and ask whether public docs/examples/screenshots were privacy-scrubbed. | Yes |
| CI only | Keep PR friction low with just `./script/ci.sh`. | |
| Detailed checklist | Require CI, manual app verify, docs review, source-doc updates, and privacy scrub every time. | |

**User's choice:** Local CI plus privacy check
**Notes:** Keep contributor flow light but privacy-aware.

---

## Scanner Extension Guide

### Prescriptiveness

| Option | Description | Selected |
|--------|-------------|----------|
| Adapter recipe | Step-by-step: add scanner type, update `JobSource`, compose in `JobInventory`, add fixtures/self-tests, update docs. | Yes |
| Architecture overview | Explain the layer boundary and let contributors infer the steps from existing scanners. | |
| Strict source contract | Formal checklist of required model fields, failure handling, privacy language, and test expectations. | |

**User's choice:** Adapter recipe
**Notes:** The dedicated guide should be concrete.

### Limitations and confidence

| Option | Description | Selected |
|--------|-------------|----------|
| Honest source notes | Every source doc should say what it reads, what it cannot see, what errors mean, and whether evidence proves scheduling. | Yes |
| Short limitation bullets | Keep docs compact with a limitations section per source. | |
| Confidence model preview | Lean into Phase 6 terminology now: Scheduled, Registered, Candidate, Manual. | |

**User's choice:** Honest source notes
**Notes:** Current docs should stay truthful about present behavior.

### Guide location

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated docs page | Add something like `docs/adding-scanner-sources.md`, linked from README/CONTRIBUTING/source docs. | Yes |
| Inside architecture docs | Expand `docs/architecture.md` with a scanner contributor section. | |
| Inside scheduled source docs | Append contributor guidance to `docs/scheduled-job-sources.md`. | |

**User's choice:** Dedicated docs page
**Notes:** Link it from the existing public docs.

### Future inventory concepts

| Option | Description | Selected |
|--------|-------------|----------|
| Prepare language, no model claims | Mention future broad inventory carefully, but do not document fields/UX that do not exist yet. | Yes |
| Preview v1.1 direction | Describe Scheduled/Registered/Candidate/Manual as planned concepts so contributors see where scanner work is headed. | |
| Avoid future concepts | Keep Phase 4 docs strictly to current launchd/Hermes behavior. | |

**User's choice:** Prepare language, no model claims
**Notes:** Avoid making Phase 6 concepts sound shipped.

## the agent's Discretion

No areas were explicitly delegated to the agent beyond exact wording, section headings, and Markdown formatting.

## Deferred Ideas

None.
