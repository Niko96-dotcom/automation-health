---
phase: 12-schedule-based-grouping
verified: 2026-05-11T12:00:00Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 0
overrides: []
human_verification:
  - test: "Open the app and check the sidebar grouping mode picker"
    expected: "'Schedule' appears as the 6th option in the Group Sidebar By dropdown"
    why_human: "Visual appearance of menu items can only be verified in the running app"
  - test: "Press Cmd+6 to switch to Schedule grouping mode"
    expected: "Sidebar re-renders with schedule-based sections (Morning, Afternoon, Evening, Night, Hourly, Daily, Weekly, Monthly, No schedule evidence)"
    why_human: "Keyboard shortcut behavior in the macOS menu system requires a running app"
  - test: "Select Schedule grouping and verify job classification"
    expected: "Scheduled jobs with known run times appear in correct time-of-day bucket; frequency-based jobs appear in correct frequency bucket"
    why_human: "Visual verification of correct section assignment with real scanner data"
  - test: "Verify 'No schedule evidence' section"
    expected: "Registered, Candidate, and Manual records all appear in 'No schedule evidence' section, which is the last section in the sidebar"
    why_human: "Visual confirmation that non-scheduled records are properly isolated"
  - test: "Verify existing grouping modes are unaffected"
    expected: "Cmd+1..5 still switch to Source, Origin, Health, Trigger, Confidence; existing section titles and job placement unchanged"
    why_human: "Regression check requires visual confirmation in the running app"
gaps: []
---

# Phase 12: Schedule-Based Grouping Verification Report

**Phase Goal:** Schedule-based grouping mode with confidence-gated classifier. Evidence boundary preservation for Registered, Candidate, and Manual records.

**Verified:** 2026-05-11
**Status:** human_needed — all automated checks pass; 5 items require visual confirmation in the running app
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | "Schedule" appears as a selectable grouping mode alongside existing five modes | ✓ VERIFIED | `SidebarGroupingMode` has `case schedule` (line 120, `JobPresentation.swift`), label `"Schedule"` (line 139). `SidebarView` auto-includes via `ForEach(SidebarGroupingMode.allCases)` (line 278, `SidebarView.swift`). Cmd+6 shortcut in `AutomationHealthApp.swift` (line 80-83). Codable round-trip verified by `testGroupingModeCodableRoundTrip`. |
| 2 | Jobs with schedule evidence are classified into time-of-day or frequency buckets | ✓ VERIFIED | `SidebarScheduleClassifier.kind(for:)` (lines 654-716) implements: (a) time-of-day via `Calendar.current.component(.hour, from: nextRun)` mapping to Morning (4-11), Afternoon (12-17), Evening (18-21), Night (0-3,22-23); (b) clock-time regex fallback `\b(\d{1,2}):(\d{2})\b` on raw schedule string; (c) frequency keyword detection on lowercased `scheduleText` for hourly/daily/weekly/monthly. Verified by `testScheduleClassifierTimeOfDay` and `testScheduleClassifierFrequency` self-tests. |
| 3 | Registered, Candidate, and Manual records appear in a "No schedule evidence" section | ✓ VERIFIED | Confidence gate at `SidebarScheduleClassifier` line 656: `guard job.job.confidence == .scheduled else { return .noScheduleEvidence }`. All non-scheduled confidence levels are excluded from time-of-day/frequency buckets. Verified by `testScheduleClassifierEvidenceBoundaries` which uses Set comparison to confirm all 4 boundary cases land in "No schedule evidence". |
| 4 | Non-scheduled confidence records never display fabricated run times or next-run dates | ✓ VERIFIED | `nextRunText` calls `humanNextRunDescription` → `JobHumanizer.relativeRunDescription(for: nextRun, ...)` which returns `"Not scheduled"` when `nextRun` is nil (line 94-96, `JobHumanizer.swift`). `SidebarJobSummary` detailText (line 247) uses `job.job.nextRun != nil ? job.nextRunText : job.scheduleText` — non-scheduled jobs show truthful schedule descriptions (e.g., "Script candidate (no schedule evidence)"). No fabrication code exists anywhere in the classification or rendering pipeline. |
| 5 | Existing grouping modes (Source, Origin, Health, Trigger, Confidence) are unaffected | ✓ VERIFIED | `.schedule` placed after `.confidence` (line 120) preserving Cmd+1..5 mapping. `groupDefinitions` branches for `.source/.origin/.health/.trigger/.confidence` (lines 484-529) are unchanged. `SidebarJobSummary` adds `.schedule` alongside `.origin, .health, .trigger` (line 251) without affecting existing subtitle logic. All existing self-tests pass unchanged via `swift run ActiveJobsCoreSelfTest`. |

**Score:** 5/5 truths verified

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| GROUP-01 | 12-01 | Schedule-based grouping mode available in the grouping mode selector | ✓ SATISFIED | `.schedule` case in `SidebarGroupingMode`, label "Schedule", auto-included in `SidebarView` picker via `allCases`, Cmd+6 shortcut |
| GROUP-02 | 12-01, 12-02 | Schedule-based grouping classifies jobs into time-of-day or frequency buckets | ✓ SATISFIED | `SidebarScheduleClassifier` with time-of-day (hour ranges), clock-time regex fallback, frequency keyword detection; verified by 4 self-tests |
| GROUP-03 | 12-01, 12-02 | Non-scheduled records appear in "No schedule evidence" bucket | ✓ SATISFIED | Confidence gate returns `.noScheduleEvidence` for non-`.scheduled`; verified by `testScheduleClassifierEvidenceBoundaries` |
| GROUP-04 | 12-01, 12-02 | Evidence boundaries are preserved | ✓ SATISFIED | Airtight `guard confidence == .scheduled` gate before any classification; Pitfall 3 explicitly tested (candidate with cron → No schedule evidence, not Daily) |
| GROUP-05 | — | Custom ordering grouping mode | ⏸ DEFERRED | Explicitly deferred per REQUIREMENTS.md — not in phase scope |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Sources/AutomationHealthCore/JobPresentation.swift` | SidebarScheduleKind, SidebarScheduleClassifier, .schedule case, groupDefinitions branch, subtitle case | ✓ VERIFIED | 717 lines. `SidebarScheduleKind` (lines 172-198): 9 cases with titles. `SidebarScheduleClassifier` (lines 654-717): confidence gate → time-of-day → clock-time regex → frequency keywords → fallthrough. `.schedule` in enum (line 120), label switch (line 139), groupDefinitions (lines 530-537), subtitle switch (line 251). |
| `Sources/AutomationHealth/App/AutomationHealthApp.swift` | Cmd+6 "Group by Schedule" shortcut | ✓ VERIFIED | "Group by Schedule" button with `.keyboardShortcut("6", modifiers: [.command])` at lines 80-83. Total 10 keyboard shortcuts (3 navigation + 6 grouping + 1 rescan). |
| `Sources/ActiveJobsCoreSelfTest/main.swift` | Updated shortcut test + 4 new classifier tests | ✓ VERIFIED | `testGroupingModeShortcutKeys` updated for 6 modes (lines 1087-1111). `testSidebarGroupingModeLabelsAndOrders` updated with "Schedule" label. Four new tests: `testScheduleClassifierTimeOfDay` (line 1156), `testScheduleClassifierFrequency` (line 1192), `testScheduleClassifierEvidenceBoundaries` (line 1211), `testScheduleGroupingIntegration` (line 1240). Plus `testSidebarScheduleGroupingModeAndSections` from Plan 01 (line 1113). All 41 tests pass. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `SidebarScheduleClassifier.kind(for:)` | `job.job.confidence` | `guard confidence == .scheduled` | ✓ WIRED | Line 656: first line of `kind(for:)` gates all classification on `.scheduled` confidence |
| `SidebarScheduleClassifier.kind(for:)` | `job.job.nextRun` | `Calendar.current.component(.hour)` | ✓ WIRED | Line 661: extracts hour from `nextRun` for primary time-of-day classification |
| `groupDefinitions(for: .schedule)` | `SidebarScheduleClassifier.kind(for:)` | closure matching SidebarScheduleKind case | ✓ WIRED | Line 535: `matches: { SidebarScheduleClassifier.kind(for: $0) == kind }` |
| `SidebarView` grouping picker | `SidebarGroupingMode.allCases` | ForEach auto-includes `.schedule` | ✓ WIRED | `SidebarView.swift` line 278: `ForEach(SidebarGroupingMode.allCases)` — no manual wiring needed |
| `Cmd+6` shortcut | `preferences.groupingMode = .schedule` | Button action | ✓ WIRED | `AutomationHealthApp.swift` line 80-83: button sets `.schedule` on `preferences.groupingMode` |
| `PreferencesStore` persistence | `SidebarGroupingMode(rawValue:)` | Codable round-trip via rawValue | ✓ WIRED | `PreferencesStore.swift`: `@AppStorage` persists `"schedule"` raw value; init decodes via `SidebarGroupingMode(rawValue:)` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `SidebarScheduleClassifier.kind(for:)` | `job.job.confidence` | `ScheduledJob.confidence` (set by scanners) | ✓ FLOWING | Confidence values come from scanner IO (launchd plist, Hermes JSON, etc.) — real classification data |
| `SidebarScheduleClassifier.kind(for:)` | `job.job.nextRun` | `ScheduledJob.nextRun` (parsed from scanner data) | ✓ FLOWING | `nextRun` populated by scanners from real schedule data (ISO8601 timestamps, cron calculations) |
| `SidebarJobSummary.subtitle` | `detailText` | `job.nextRunText ?? job.scheduleText` | ✓ FLOWING | `nextRunText` from `humanNextRunDescription` (real date formatting), `scheduleText` from `humanScheduleDescription` (real schedule parsing) |
| `SidebarJobSection.sections()` | `SidebarScheduleKind.title` | `SidebarScheduleKind.title` computed property | ✓ FLOWING | 9 hardcoded but semantically correct titles — these are labels, not data |
| `groupDefinitions(for: .schedule)` | sections via `compactMap` | `visibleJobs.filter { definition.matches($0) }` | ✓ FLOWING | Jobs flow from scanner → JobPresentation → classifier → group definitions → sections — full pipeline proven by integration tests |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Project compiles with schedule grouping additions | `swift build` | Exit code 0, build complete (0.10s) | ✓ PASS |
| All self-tests pass including schedule classifier tests | `swift run ActiveJobsCoreSelfTest` | "ActiveJobsCoreSelfTest passed" | ✓ PASS |
| testGroupingModeShortcutKeys expects 6 modes | `grep "Exactly 6 grouping modes" Sources/ActiveJobsCoreSelfTest/main.swift` | 1 match at line 1091 | ✓ PASS |
| testScheduleClassifierEvidenceBoundaries verifies Pitfall 3 | `grep "Pitfall 3" Sources/ActiveJobsCoreSelfTest/main.swift` | Match at line 1237 | ✓ PASS |
| testScheduleGroupingIntegration verifies section ordering | `grep "Section order: time-of-day" Sources/ActiveJobsCoreSelfTest/main.swift` | Match at line 1256 | ✓ PASS |

### Anti-Patterns Found

| File | Issue | Severity |
|------|-------|----------|
| None | No TODOs, FIXMEs, placeholders, empty implementations, or hardcoded empty data found in schedule grouping code | — |

The `return nil` matches in `JobPresentation.swift` (lines 57, 272, 372, 395, 460, 702, 709, 713) are all legitimate Swift patterns: guard-else returns, optional compactMap filtering, and regex match failures — none are stubs.

### Human Verification Required

1. **Sidebar grouping mode picker shows "Schedule"**
   - **Test:** Open AutomationHealth.app. Click the "Group Sidebar By" menu in the sidebar footer. Verify "Schedule" appears as the 6th option in the dropdown, after "Confidence".
   - **Expected:** "Schedule" is selectable; selecting it re-renders the sidebar with schedule-based sections.
   - **Why human:** Visual menu rendering can only be verified in the running app.

2. **Cmd+6 keyboard shortcut switches to Schedule grouping**
   - **Test:** In the running app, press Cmd+6.
   - **Expected:** Sidebar re-renders showing schedule-based sections (Morning, Afternoon, Evening, Night, Hourly, Daily, Weekly, Monthly, No schedule evidence). The "View" menu shows ⌘6 next to "Group by Schedule".
   - **Why human:** macOS keyboard shortcut dispatch requires the running app with an active menu system.

3. **Job classification with real scanner data**
   - **Test:** With real jobs on the system, select Schedule grouping mode.
   - **Expected:** Launchd agents with `StartCalendarInterval` appear in the correct time-of-day bucket (e.g., a 01:00 agent → Night). Hermes cron jobs with known next-run times appear in correct bucket. Cron jobs without next-run but with frequency schedules (e.g., "0 * * * *" → Hourly, "0 10 * * *" → Daily) appear in correct frequency bucket.
   - **Why human:** Requires real scanner data on the host system.

4. **"No schedule evidence" section is last and contains non-scheduled records**
   - **Test:** In Schedule grouping mode, scroll to the bottom of the sidebar.
   - **Expected:** "No schedule evidence" is the last section. It contains Shortcuts (registered), Automator workflows (registered), Candidate scripts (candidate), and Manual records (manual). A Candidate with a cron-like schedule in its schedule text must NOT appear in a Daily/Hourly/etc. bucket.
   - **Why human:** Visual confirmation of section ordering and proper evidence boundary enforcement with real data.

5. **Existing grouping modes unaffected**
   - **Test:** Press Cmd+1 through Cmd+5 and verify each switches to the expected grouping mode (Source, Origin, Health, Trigger, Confidence).
   - **Expected:** All existing modes render with their original sections, titles, and job placement. No regressions.
   - **Why human:** Regression testing requires visual comparison against pre-phase behavior.

### Gaps Summary

No gaps found. All 5 success criteria are verified through code inspection and self-test validation. All 4 requirements (GROUP-01 through GROUP-04) are satisfied. The phase delivers exactly what was planned: a working `.schedule` grouping mode with a confidence-gated classifier, keyboard shortcut, and comprehensive test coverage.

Phase is ready for human verification of visual behavior in the running app.

---

_Verified: 2026-05-11_
_Verifier: the agent (gsd-verifier)_
