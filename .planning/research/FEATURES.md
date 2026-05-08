# Research: Feature Shape For v1.1

**Milestone:** v1.1 Open Source Readiness and Broad Inventory
**Date:** 2026-05-08

## Public Open Source Project

**Table stakes**

- Clear README that explains what the app does, what it scans, what it does not scan, how privacy works, how to build, and how to contribute.
- License file, security policy, support policy, code of conduct, contribution guide, issue templates, and pull request template.
- GitHub Actions CI that matches local `./script/ci.sh`.
- Release/build documentation that describes the local `.app` packaging flow and any unsigned/notarized limitations.
- Privacy scrub of docs, screenshots, fixtures, sample output, bundle identifiers, usernames, hostnames, personal paths, and generated artifacts before publishing.

**Differentiators**

- A public "scanner confidence" model that makes limitations honest instead of hiding them.
- Contributor docs that explain how to add a scanner without touching SwiftUI views.
- A source/privacy matrix listing what each scanner reads and whether it shells out.

## Broad Automation Inventory

**Table stakes**

- Expand deterministic sources beyond launchd and Hermes cron to include at least local cron data where readable.
- Add manual entries so users can record automations that cannot be discovered automatically.
- Introduce confidence labels such as Scheduled, Registered, Candidate, and Manual.
- Show candidates for script-like files in common locations only as possible automations, not as proven scheduled jobs.
- Document permission limits, root-only files, and macOS privacy restrictions.

**Differentiators**

- Group and sort by origin/ownership: user-authored, third-party app, system, unknown.
- Detect likely app/vendor ownership from bundle identifiers, plist paths, executable paths, and labels.
- Allow users to mark candidates as automation, ignore them, or turn them into manual records without mutating the underlying jobs.

## Sidebar Organization

**Table stakes**

- Collapsible sections with keyboard-safe behavior.
- Focus ring styling that matches the dark sidebar and search focus treatment instead of the current oversized blue outline.
- Grouping modes beyond source, starting with ownership/origin and health.
- Stable ordering within groups and under search.

**Differentiators**

- Grouping modes for source, owner/origin, health, trigger type, confidence, and schedule cadence.
- Counts per collapsed group and clear empty states.
- Persisted UI preferences only after the core grouping model is stable.

## Visual Polish

**Table stakes**

- Generate at least one polished app icon concept through `imagegen`.
- Convert final source art into app-ready icon assets and use it in the local app bundle.
- Refresh README and docs visuals after privacy scrub.

**Differentiators**

- Small visual identity kit for open-source publication: icon, README hero/screenshot treatment, and consistent accent color usage.

## Anti-Features

- Do not promise "all automations" with perfect accuracy. The product should say what it can prove, what it can infer, and what the user added manually.
- Do not scan arbitrary file contents broadly without clear user-facing scope and performance bounds.
- Do not add job management actions such as enabling, disabling, deleting, or editing jobs.
- Do not commit real local scan output, usernames, hostnames, or private paths in public-facing docs.
