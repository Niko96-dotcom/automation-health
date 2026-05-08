# Roadmap: Automation Health

## Overview

Milestone v1.1 makes Automation Health ready to publish as a clean open-source GitHub project while expanding the app from a machine-specific scheduler viewer into a broader, honest automation inventory. The roadmap keeps the read-only product boundary, distinguishes proven scheduled jobs from registered/candidate/manual records, and finishes with the sidebar grouping and focus polish requested from the screenshots.

## Milestones

- [x] **v1.0 Sidebar Navigation** - Phases 1-3 shipped 2026-05-08; 8 plans completed. Archives: [roadmap](milestones/v1.0-ROADMAP.md), [requirements](milestones/v1.0-REQUIREMENTS.md), [audit](milestones/v1.0-MILESTONE-AUDIT.md).
- [ ] **v1.1 Open Source Readiness and Broad Inventory** - Phases 4-9 planned.

## Phases

**Phase Numbering:**
- Integer phases (4, 5, 6): Planned milestone work continuing from v1.0.
- Decimal phases (6.1, 6.2): Urgent insertions if needed.

- [x] **Phase 4: Open Source Foundation And Privacy Scrub** - Prepare public repository materials, GitHub workflow hygiene, and privacy guardrails.
- [x] **Phase 5: Visual Identity And Icon Pipeline** - Prompt, generate, and package a polished app icon and deterministic visual asset workflow.
- [x] **Phase 6: Inventory Model And Deterministic Sources** - Add confidence/origin modeling and deterministic scanner expansion for scheduler-backed or registered automations.
- [x] **Phase 7: Candidate Discovery And Manual Records** - Add bounded script-candidate discovery plus app-only manual records for uncovered automations.
- [ ] **Phase 8: Sidebar Grouping, Collapse, And Focus Polish** - Add collapsible sections, better grouping modes, and screenshot-driven focus treatment.
- [ ] **Phase 9: Publication Verification And Docs Polish** - Verify CI, documentation, screenshots/assets, and public-ready release posture.

## Phase Details

### Phase 4: Open Source Foundation And Privacy Scrub
**Goal**: The repository is structurally ready for public GitHub publication and has explicit privacy guidance before any public-facing assets are produced.
**Depends on**: v1.0 completion
**Requirements**: [OSS-01, OSS-02, OSS-03, OSS-04, OSS-05, OSS-06, PRIV-02, PRIV-03, QUAL-05]
**UI hint**: no
**Success Criteria** (what must be TRUE):
  1. README, CONTRIBUTING, security/support/community files, issue templates, and PR template are public-ready.
  2. GitHub Actions still runs the local `./script/ci.sh` gate with explicit permissions and clear workflow naming.
  3. Docs explain scanner boundaries, local-only data handling, and broad best-effort discovery language.
  4. A publication privacy scrub checklist exists and covers personal paths, hostnames, bundle ids, screenshots, fixtures, and sample output.
  5. Scanner architecture docs explain how to add a source without view-layer IO.
**Plans**: 3 plans

Plans:
**Wave 1**
- [x] 04-01: Add public repository health files and update GitHub templates/workflow docs.

**Wave 2 *(blocked on Wave 1 completion)***
- [x] 04-02: Rewrite README and source docs around privacy, scanner limits, architecture, and open-source contribution flow.

**Wave 3 *(blocked on Wave 2 completion)***
- [x] 04-03: Add and apply the privacy scrub checklist to public docs, fixtures, and examples.

### Phase 5: Visual Identity And Icon Pipeline
**Goal**: The app has a polished generated icon and a repeatable asset path suitable for local builds and public docs.
**Depends on**: Phase 4
**Requirements**: [VIS-01, VIS-02, VIS-03]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. Codex produces a copy-paste-ready ChatGPT image prompt for the app icon, with API/CLI generation documented only as an optional paid/reproducible path.
  2. Final source art is committed in a stable project asset location.
  3. A deterministic script or build step generates app-ready icon assets from source art.
  4. The generated icon appears in the local `.app` bundle created by existing packaging scripts.
  5. Regeneration steps are documented without requiring secrets in the repo.
**Plans**: 2 plans

Plans:
**Wave 1**
- [x] 05-01: Write the ChatGPT app icon prompt, generate/select the source image, and document the prompt/assets.

**Wave 2 *(blocked on Wave 1 completion)***
- [x] 05-02: Add icon asset generation and integrate the icon into the app bundle.

Cross-cutting constraints:
- Selected source art remains the stable input at `Assets/AppIcon/automation-health-icon-source.png`.
- Manual ChatGPT source-art generation is the expected path; paid API/CLI generation, secrets, and network automation are not required.
- Selection notes and generated assets must remain free of text, private data, screenshots, local paths, terminal output, and real scheduler details.

### Phase 6: Inventory Model And Deterministic Sources
**Goal**: Broader inventory has source-independent confidence and ownership modeling, plus additional deterministic or registered scanner sources.
**Depends on**: Phase 4
**Requirements**: [DISC-01, DISC-02, DISC-03, DISC-04, DISC-05, DISC-07, QUAL-01, QUAL-02]
**UI hint**: no
**Success Criteria** (what must be TRUE):
  1. Scheduled, Registered, Candidate, and Manual confidence states exist below the view layer.
  2. User-authored, third-party app, system, and unknown origin classifications are derived separately from scanner source.
  3. Cron scanner coverage reads supported readable cron locations or reports source-specific scan notes.
  4. Shortcuts and Automator inventory paths are best-effort and do not claim scheduling evidence they do not have.
  5. New scanners are tested with injected fixtures/command runners and do not mutate scheduler files.
**Plans**: 3 plans

Plans:
**Wave 1**
- [x] 06-01: Extend core models and presentation adapters with confidence, origin, and scan-note concepts.

**Wave 2 *(blocked on Wave 1 completion)***
- [x] 06-02: Add cron scanner coverage with fixture-driven self-tests.

**Wave 3 *(blocked on Wave 2 completion)***
- [x] 06-03: Add Shortcuts and Automator inventory scanners with best-effort failure handling.

Cross-cutting constraints:
- Inventory scanners remain read-only: no edit, remove, install, run, view, sign, or execute commands are introduced for cron, Shortcuts, or Automator sources.
- Source-specific scan notes report missing tools, permission limits, unreadable paths, and confidence limits without failing the whole inventory refresh.
- New scanner behavior must be covered with injected command runners or fixture paths, not live local machine automation state.
- Confidence and origin labels are evidence-based and source-independent; registered sources do not claim schedule evidence unless a scanner proves it.

### Phase 7: Candidate Discovery And Manual Records
**Goal**: Users can account for automations that are not proven scheduler jobs through bounded candidates and local manual records.
**Depends on**: Phase 6
**Requirements**: [DISC-06, DISC-08, MAN-01, MAN-02, MAN-03, QUAL-03]
**Gap Closure**: Closes v1.1 audit gaps for missing candidate discovery, manual records, broader inventory search/detail integration, and candidate discovery performance bounds.
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. Candidate script discovery scans only documented bounded locations and labels results as Candidate.
  2. Candidate scan limits, ignore rules, and failure cases are documented and tested.
  3. Users can add, edit, and remove app-only manual records without touching real scheduled jobs or files.
  4. Manual records persist locally and appear in sidebar search/detail flows with clear Manual confidence.
  5. Existing launchd and Hermes cron records still render through the same inventory presentation path.
**Plans**: 3 plans

Plans:
**Wave 1**
- [x] 07-01: Add bounded candidate script discovery and tests for limits/ignore behavior.

**Wave 2 *(blocked on Wave 1 completion)***
- [x] 07-02: Add local manual record storage and app-only create/edit/remove flows.

**Wave 3 *(blocked on Wave 2 completion)***
- [x] 07-03: Integrate candidates and manual records into search, selection, and detail presentation.

Cross-cutting constraints:
- Candidate and Manual records must preserve the read-only boundary for real scheduler jobs, scripts, Shortcuts, Automator workflows, cron entries, launchd plists, and Hermes metadata.
- SwiftUI views must consume `JobStore`, `JobPresentation`, and normalized `ScheduledJob` values; scanner IO and manual JSON persistence stay below the view layer.
- Existing launchd, Hermes cron, cron, Shortcuts, and Automator records must continue through the shared inventory, search, selection, sidebar, detail, scan-note, and CI paths.
- Sidebar grouping modes, collapsible sections, persisted grouping preferences, and custom focus treatment remain Phase 8 scope.

### Phase 8: Sidebar Grouping, Collapse, And Focus Polish
**Goal**: The sidebar becomes a richer navigation surface with collapsible categories, better grouping modes, and app-matched keyboard focus styling.
**Depends on**: Phase 7
**Requirements**: [SIDE-01, SIDE-02, SIDE-03, SIDE-04, SIDE-05, SIDE-06, SIDE-07]
**Gap Closure**: Closes v1.1 audit gaps for collapsible sidebar sections, hidden-row keyboard navigation, grouping modes, stable grouped browsing, launchd origin separation, and accessible custom focus treatment.
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. Users can collapse and expand groups while the selected detail remains coherent.
  2. Keyboard navigation ignores hidden collapsed rows and respects search filtering.
  3. Grouping modes include source, origin/ownership, health, trigger type, and confidence.
  4. launchd jobs can be visually separated by user-authored, third-party app, system, or unknown origin.
  5. The focused sidebar no longer shows the oversized default blue rectangle and still has a visible accessible focus cue.
**Plans**: 3 plans

Plans:
**Wave 1**
- [ ] 08-01: Build reusable grouping/collapse state and navigation behavior over visible inventory rows.

**Wave 2 *(blocked on Wave 1 completion)***
- [ ] 08-02: Add grouping controls, collapsible section rendering, and stable ordering.

**Wave 3 *(blocked on Wave 2 completion)***
- [ ] 08-03: Replace the sidebar focus treatment and verify keyboard accessibility against the screenshots.

### Phase 9: Publication Verification And Docs Polish
**Goal**: The milestone is verified as public-ready with a clean privacy scrub, sanitized visuals, passing CI, and updated traceability.
**Depends on**: Phase 8
**Requirements**: [PRIV-01, VIS-04, QUAL-04]
**Gap Closure**: Closes v1.1 audit gaps for publication privacy scrub failures, sanitized public visuals, final CI/manual regression verification, and PRIV-01 traceability reconciliation.
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. README/docs visuals are sanitized and aesthetically consistent with the new icon/app identity.
  2. The publication privacy scrub runs clean, including no personal namespace matches or local `.DS_Store` artifacts.
  3. `./script/ci.sh` passes with open-source docs, scanners, icon packaging, manual records, and sidebar changes.
  4. Manual verification covers privacy scrub, broad inventory source notes, manual records, collapsible groups, grouping modes, and focus styling.
  5. Requirements traceability is complete and the app remains read-only for real scheduled jobs.
**Plans**: 2 plans

Plans:
**Wave 1**
- [ ] 09-01: Refresh sanitized public docs/screenshots/assets and run the privacy scrub.

**Wave 2 *(blocked on Wave 1 completion)***
- [ ] 09-02: Run CI/manual verification and prepare publication notes.

## Progress

**Execution Order:**
Phases execute in numeric order: 4 -> 5 -> 6 -> 7 -> 8 -> 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 4. Open Source Foundation And Privacy Scrub | 3/3 | Complete | 2026-05-08 |
| 5. Visual Identity And Icon Pipeline | 2/2 | Complete | 2026-05-08 |
| 6. Inventory Model And Deterministic Sources | 3/3 | Complete | 2026-05-08 |
| 7. Candidate Discovery And Manual Records | 3/3 | Complete | 2026-05-08 |
| 8. Sidebar Grouping, Collapse, And Focus Polish | 0/3 | Pending | — |
| 9. Publication Verification And Docs Polish | 0/2 | Pending | — |

## Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| OSS-01 | Phase 4 | Complete |
| OSS-02 | Phase 4 | Complete |
| OSS-03 | Phase 4 | Complete |
| OSS-04 | Phase 4 | Complete |
| OSS-05 | Phase 4 | Complete |
| OSS-06 | Phase 4 | Complete |
| PRIV-01 | Phase 9 | Pending |
| PRIV-02 | Phase 4 | Complete |
| PRIV-03 | Phase 4 | Complete |
| VIS-01 | Phase 5 | Complete |
| VIS-02 | Phase 5 | Complete |
| VIS-03 | Phase 5 | Complete |
| VIS-04 | Phase 9 | Pending |
| DISC-01 | Phase 6 | Complete |
| DISC-02 | Phase 6 | Complete |
| DISC-03 | Phase 6 | Complete |
| DISC-04 | Phase 6 | Complete |
| DISC-05 | Phase 6 | Complete |
| DISC-06 | Phase 7 | Complete |
| DISC-07 | Phase 6 | Complete |
| DISC-08 | Phase 7 | Complete |
| MAN-01 | Phase 7 | Complete |
| MAN-02 | Phase 7 | Complete |
| MAN-03 | Phase 7 | Complete |
| SIDE-01 | Phase 8 | Pending |
| SIDE-02 | Phase 8 | Pending |
| SIDE-03 | Phase 8 | Pending |
| SIDE-04 | Phase 8 | Pending |
| SIDE-05 | Phase 8 | Pending |
| SIDE-06 | Phase 8 | Pending |
| SIDE-07 | Phase 8 | Pending |
| QUAL-01 | Phase 6 | Complete |
| QUAL-02 | Phase 6 | Complete |
| QUAL-03 | Phase 7 | Complete |
| QUAL-04 | Phase 9 | Pending |
| QUAL-05 | Phase 4 | Complete |

**Coverage:**
- v1.1 requirements: 36 total
- Mapped to phases: 36
- Unmapped: 0
