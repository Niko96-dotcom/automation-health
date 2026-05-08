# Requirements: Automation Health

**Defined:** 2026-05-08
**Core Value:** Users can quickly understand and navigate the health of their local scheduled automations without the app modifying those jobs.

## v1 Requirements

Requirements for the sidebar navigation and organization milestone.

### Keyboard Navigation

- [ ] **NAV-01**: User can use the Down arrow while the sidebar is active to select the next visible job.
- [ ] **NAV-02**: User can use the Up arrow while the sidebar is active to select the previous visible job.
- [ ] **NAV-03**: Keyboard navigation skips non-job UI such as section headers, the sidebar summary, and the scan footer.
- [ ] **NAV-04**: Keyboard navigation keeps the selected job row, detail view, and store selection id synchronized.
- [ ] **NAV-05**: Keyboard navigation scrolls the newly selected visible job row into view when it is outside the current viewport.
- [ ] **NAV-06**: Keyboard navigation behaves predictably at the first and last visible job without clearing the current selection.

### Sidebar Organization

- [ ] **ORG-01**: Sidebar jobs are grouped under clear section headers by job source.
- [ ] **ORG-02**: Each source section header shows a human-readable source name and visible job count.
- [ ] **ORG-03**: Source groups with zero visible jobs are hidden.
- [ ] **ORG-04**: Jobs keep their current display name, subtitle, health dot, and selection styling inside grouped sections.
- [ ] **ORG-05**: Grouping preserves a stable order for sections and jobs so refreshes do not visually shuffle unrelated rows.

### Search And Filtering

- [ ] **SRCH-01**: Sidebar search results remain grouped by source after filtering.
- [ ] **SRCH-02**: Up and Down arrow navigation traverses only jobs visible under the current search query.
- [ ] **SRCH-03**: When a search query produces no visible jobs, the sidebar communicates the empty state without a selectable placeholder row.
- [ ] **SRCH-04**: Clearing search restores grouped navigation over the full visible job list.

### Quality And Regression Safety

- [ ] **QUAL-01**: The change preserves existing scan refresh behavior, including retaining the selected job after refresh when it still exists.
- [ ] **QUAL-02**: The change preserves the read-only product boundary; sidebar interactions do not mutate scheduled jobs.
- [ ] **QUAL-03**: Focused coverage or equivalent compile-time validation protects any extracted grouping or navigation helpers.
- [ ] **QUAL-04**: The local CI gate builds successfully after the sidebar changes.

## v2 Requirements

Deferred to future release. Tracked but not in the current roadmap.

### Alternate Grouping

- **GRP-01**: User can group jobs by health state.
- **GRP-02**: User can group jobs by schedule or trigger type.
- **GRP-03**: User can persist a preferred grouping mode.
- **GRP-04**: User can collapse and expand sidebar sections.

### Broader Navigation

- **KEY-01**: User can use additional keyboard shortcuts for refresh, reveal output, and moving focus between sidebar and detail panes.
- **KEY-02**: User can type-ahead within the sidebar list independent of the search field.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Job editing controls | The app is intentionally read-only and this milestone is navigation-focused. |
| New scheduler scanners | The requested improvement applies to existing visible jobs. |
| Custom grouping preferences | Source-based grouping is the v1 decision and avoids settings work. |
| Collapsible sections | Useful later, but not required for clear headers and keyboard navigation. |
| Full UI redesign | The goal is to improve the existing sidebar, not replace the app shell. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| NAV-01 | TBD | Pending |
| NAV-02 | TBD | Pending |
| NAV-03 | TBD | Pending |
| NAV-04 | TBD | Pending |
| NAV-05 | TBD | Pending |
| NAV-06 | TBD | Pending |
| ORG-01 | TBD | Pending |
| ORG-02 | TBD | Pending |
| ORG-03 | TBD | Pending |
| ORG-04 | TBD | Pending |
| ORG-05 | TBD | Pending |
| SRCH-01 | TBD | Pending |
| SRCH-02 | TBD | Pending |
| SRCH-03 | TBD | Pending |
| SRCH-04 | TBD | Pending |
| QUAL-01 | TBD | Pending |
| QUAL-02 | TBD | Pending |
| QUAL-03 | TBD | Pending |
| QUAL-04 | TBD | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 0
- Unmapped: 19

---
*Requirements defined: 2026-05-08*
*Last updated: 2026-05-08 after initial definition*
