# Requirements: Automation Health

**Defined:** 2026-05-08
**Milestone:** v1.1 Open Source Readiness and Broad Inventory
**Core Value:** Users can quickly understand and navigate the health of their local scheduled automations without the app modifying those jobs.

## v1.1 Requirements

Requirements for making Automation Health publishable as an open-source project while broadening local automation inventory and polishing the sidebar.

### Open Source Readiness

- [x] **OSS-01**: User can read a public-ready README that explains what Automation Health does, what it scans, known limitations, privacy expectations, build steps, and contribution entry points.
- [x] **OSS-02**: Contributor can find license, security, support, code of conduct, and contribution guidance in standard GitHub-recognized locations.
- [x] **OSS-03**: Contributor can use issue and pull request templates that ask for relevant macOS, scanner, verification, and privacy information without requesting sensitive local output.
- [x] **OSS-04**: Maintainer can rely on GitHub Actions to run the same local `./script/ci.sh` gate used before pull requests.
- [x] **OSS-05**: Contributor can understand the scanner architecture and add a new scanner without reading SwiftUI view code.
- [x] **OSS-06**: User can understand the current unsigned/local distribution status and any release/build limitations before installing or running the app.

### Privacy And Publication Safety

- [ ] **PRIV-01**: Maintainer can run or follow a publication privacy scrub that checks docs, fixtures, screenshots, sample output, bundle identifiers, usernames, hostnames, and paths for personal data.
- [x] **PRIV-02**: Public examples and tests use synthetic automation names, paths, and output instead of real local job details.
- [x] **PRIV-03**: User can see clear documentation of what each scanner reads, whether it shells out, and what data remains local.

### Visual Identity

- [x] **VIS-01**: Maintainer can use a Codex-authored, copy-paste-ready ChatGPT image prompt to generate at least one polished app icon source image; API/CLI generation remains optional for paid reproducible runs.
- [x] **VIS-02**: User sees the generated icon integrated into the local macOS app bundle instead of the default/blank app identity.
- [x] **VIS-03**: Maintainer can regenerate app icon assets deterministically from committed source art using a documented local script or build step.
- [ ] **VIS-04**: Public README/docs visuals use sanitized, aesthetically consistent screenshots or assets that do not expose personal local automations.

### Broad Automation Inventory

- [ ] **DISC-01**: User can distinguish Scheduled, Registered, Candidate, and Manual automation records through a source-independent confidence model.
- [ ] **DISC-02**: User can distinguish user-authored, third-party app, system, and unknown automation origins independently from scheduler source.
- [ ] **DISC-03**: User can see local cron jobs where readable, including per-user crontab entries and supported readable system cron files.
- [ ] **DISC-04**: User can see registered Shortcuts inventory where the `shortcuts` command is available, without treating listed shortcuts as proven scheduled jobs.
- [ ] **DISC-05**: User can see Automator workflows or app-visible workflow files where readable, labeled by confidence according to available evidence.
- [ ] **DISC-06**: User can see bounded candidate script discoveries from common user locations, labeled as candidates rather than scheduled jobs.
- [ ] **DISC-07**: User can see source-specific scan notes when permissions, missing tools, unreadable files, or confidence limits prevent complete discovery.
- [ ] **DISC-08**: User can search and inspect broader inventory records through the same sidebar/detail flow as existing launchd and Hermes cron jobs.

### Manual Records

- [ ] **MAN-01**: User can add a manual automation record for an automation the scanner cannot discover automatically.
- [ ] **MAN-02**: User can edit or remove app-only manual records without modifying real scheduled jobs or script files.
- [ ] **MAN-03**: Manual records persist locally and are clearly identified as user-added app records in search, grouping, and detail views.

### Sidebar Organization And Focus

- [ ] **SIDE-01**: User can collapse and expand sidebar sections without losing the selected job detail.
- [ ] **SIDE-02**: Keyboard navigation skips collapsed or hidden rows and remains predictable under search filtering.
- [ ] **SIDE-03**: User can group sidebar records by source, origin/ownership, health, trigger type, and confidence.
- [ ] **SIDE-04**: User can sort or browse grouped records in a stable order that avoids visually shuffling unrelated rows after refresh.
- [ ] **SIDE-05**: User can understand why closed-source app jobs and user-authored jobs are separated even when both come from launchd.
- [ ] **SIDE-06**: Sidebar focus styling matches the existing dark navigation surface and search focus treatment instead of showing an oversized default blue rectangle.
- [ ] **SIDE-07**: Focus styling still gives keyboard users a visible, accessible focus cue.

### Quality And Regression Safety

- [ ] **QUAL-01**: The app remains read-only with respect to real scheduled jobs, scheduler files, scripts, and third-party automation systems.
- [ ] **QUAL-02**: Scanner additions are covered by focused self-tests with injected paths or command runners rather than live machine state.
- [ ] **QUAL-03**: Broad candidate discovery has documented performance bounds, ignore rules, and failure behavior.
- [ ] **QUAL-04**: Existing launchd, Hermes cron, search, selection, and refresh behavior continue to pass the local CI gate.
- [x] **QUAL-05**: Public documentation explains that Automation Health provides broad best-effort inventory, not a guarantee that every automation on every Mac has been found.

## Future Requirements

Deferred to future releases. Tracked but not in the current roadmap.

### Additional Sources

- **SRC-01**: User can inspect Homebrew services metadata beyond launchd plists.
- **SRC-02**: User can inspect Calendar alarms or Reminders automations when a reliable local read-only source is identified.
- **SRC-03**: User can inspect third-party scheduler databases through opt-in adapters.
- **SRC-04**: User can inspect cloud-hosted automations connected to local tools.

### Preferences And Distribution

- **PREF-01**: User can persist preferred grouping and collapsed-section state.
- **PREF-02**: User can configure candidate-scan folders and ignore rules through settings.
- **DIST-01**: User can install a signed/notarized release artifact.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Editing real scheduled jobs | The product remains a read-only inspector; manual records are app-only metadata. |
| Perfect detection of every automation | Root-only, app-internal, cloud, manually invoked, and proprietary automations may be unknowable locally. |
| Unbounded home-directory indexing | Broad candidate discovery must stay transparent, bounded, and performant. |
| Uploading scan data | The app is local-first and public docs must not expose private automation details. |
| Signed/notarized distribution | Valuable later, but v1.1 focuses on source publication and local build/run paths. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

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
| DISC-01 | Phase 6 | Pending |
| DISC-02 | Phase 6 | Pending |
| DISC-03 | Phase 6 | Pending |
| DISC-04 | Phase 6 | Pending |
| DISC-05 | Phase 6 | Pending |
| DISC-06 | Phase 7 | Pending |
| DISC-07 | Phase 6 | Pending |
| DISC-08 | Phase 7 | Pending |
| MAN-01 | Phase 7 | Pending |
| MAN-02 | Phase 7 | Pending |
| MAN-03 | Phase 7 | Pending |
| SIDE-01 | Phase 8 | Pending |
| SIDE-02 | Phase 8 | Pending |
| SIDE-03 | Phase 8 | Pending |
| SIDE-04 | Phase 8 | Pending |
| SIDE-05 | Phase 8 | Pending |
| SIDE-06 | Phase 8 | Pending |
| SIDE-07 | Phase 8 | Pending |
| QUAL-01 | Phase 6 | Pending |
| QUAL-02 | Phase 6 | Pending |
| QUAL-03 | Phase 7 | Pending |
| QUAL-04 | Phase 9 | Pending |
| QUAL-05 | Phase 4 | Complete |

**Coverage:**
- v1.1 requirements: 36 total
- Satisfied: 12
- Pending: 24
- Mapped to phases: 36
- Unmapped: 0

---
*Requirements defined: 2026-05-08*
*Last updated: 2026-05-08 after milestone gap planning*
