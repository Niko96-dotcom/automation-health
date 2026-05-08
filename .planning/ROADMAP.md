# Roadmap: Automation Health

## Overview

This milestone improves the existing Automation Health sidebar without changing the scanner layer or the read-only product boundary. The work starts by shaping grouped sidebar data from the current presentation model, then adds Finder-like keyboard navigation over visible jobs, and finishes with visual polish, empty states, and the local CI gate.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work.
- Decimal phases (2.1, 2.2): Urgent insertions if needed.

- [ ] **Phase 1: Sidebar Grouping Foundation** - Represent and render source-grouped visible jobs in the sidebar.
- [ ] **Phase 2: Keyboard Navigation** - Add Up/Down selection movement across visible jobs and keep scrolling/detail state synchronized.
- [ ] **Phase 3: Sidebar Polish And Verification** - Refine the grouped UI, empty state, and regression checks.

## Phase Details

### Phase 1: Sidebar Grouping Foundation
**Goal**: Visible sidebar jobs are grouped by source with stable section structure that works under search filtering.
**Depends on**: Nothing (first phase)
**Requirements**: [ORG-01, ORG-02, ORG-03, ORG-05, SRCH-01, QUAL-03]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User sees visible jobs grouped under source section headers.
  2. Source headers show readable source names and visible counts.
  3. Source sections with no visible jobs do not render.
  4. Search results keep the same source-grouped structure.
  5. Grouping logic is protected by focused coverage or an extracted helper that compiles cleanly.
**Plans**: 3 plans

Plans:
**Wave 1**
- [x] 01-01: Create grouped sidebar presentation data from visible `JobPresentation` values.

**Wave 2 *(blocked on Wave 1 completion)***
- [x] 01-02: Render source section headers and grouped rows in `SidebarView`.

**Wave 3 *(blocked on Wave 2 completion)***
- [x] 01-03: Add focused validation for grouping behavior and stable ordering.

Cross-cutting constraints:
- D-01: Source sections use `JobSource.allCases`, preserving launchd before Hermes cron.
- D-02: Jobs inside each section preserve the incoming visible job order; no per-section sort.
- D-03: Sources with zero visible jobs do not render headers or placeholder rows.
- D-04: Source headers show a human-readable source name and visible count.
- D-05: Grouped row subtitles omit the duplicated source name and focus on timing or schedule text.
- D-06: Search filtering happens before grouping, so section counts reflect only visible filtered jobs.
- D-07: The top sidebar summary count is derived from the same visible grouped data.

### Phase 2: Keyboard Navigation
**Goal**: Up and Down arrows move selection through the visible sidebar jobs and keep the detail pane and scroll position aligned.
**Depends on**: Phase 1
**Requirements**: [NAV-01, NAV-02, NAV-03, NAV-04, NAV-05, NAV-06, SRCH-02, SRCH-04, QUAL-01, QUAL-02]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User can press Down to select the next visible job.
  2. User can press Up to select the previous visible job.
  3. Headers, summary text, empty states, and footer controls are skipped by keyboard navigation.
  4. The detail view updates to the job selected by keyboard navigation.
  5. Keyboard-selected rows scroll into view and boundary presses do not clear selection.
**Plans**: 3 plans

Plans:
- [ ] 02-01: Define visible-job navigation behavior for previous, next, and boundary cases.
- [ ] 02-02: Wire sidebar focus and keyboard handling into the existing selection binding.
- [ ] 02-03: Add scroll-to-selection behavior and verify search/refresh interactions.

### Phase 3: Sidebar Polish And Verification
**Goal**: The grouped sidebar looks clean, handles empty filtered results, and passes the local build/test gate.
**Depends on**: Phase 2
**Requirements**: [ORG-04, SRCH-03, QUAL-04]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User still sees each job row with its display name, subtitle, health dot, and selected styling.
  2. User sees a clear sidebar empty state when search returns no visible jobs.
  3. The sidebar remains compact and native-feeling at the current split-view width.
  4. The repository local CI gate completes successfully.
**Plans**: 2 plans

Plans:
- [ ] 03-01: Polish section header, row, and empty-state presentation.
- [ ] 03-02: Run the local CI gate and perform a manual sidebar behavior check.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Sidebar Grouping Foundation | 0/3 | Not started | - |
| 2. Keyboard Navigation | 0/3 | Not started | - |
| 3. Sidebar Polish And Verification | 0/2 | Not started | - |
