# Phase 12: Schedule-Based Grouping - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a "Schedule" grouping mode to the sidebar that classifies jobs by time-of-day and frequency, gated on `.scheduled` confidence. Non-scheduled jobs (Registered, Candidate, Manual) appear in a "No schedule evidence" section. Existing five grouping modes (Source, Origin, Health, Trigger, Confidence) remain unchanged.

**In scope:**
- New `SidebarGroupingMode.schedule` enum case
- Schedule classifier with time-of-day (Morning/Afternoon/Evening/Night) and frequency (Hourly/Daily/Weekly/Monthly) buckets
- "No schedule evidence" section for non-scheduled jobs
- Classification heuristics using `nextRun` hour + schedule string clock-time parsing + humanized schedule keyword matching
- Self-test coverage for classifier logic
- Existing grouping modes unaffected

**Out of scope:**
- Code signing, notarization, packaging (Phase 13)
- Drag-to-reorder grouping
- Custom time-of-day ranges
- Cron expression editor
</domain>

<decisions>
## Implementation Decisions

### Classification Categories
- **D-01:** Time-of-day buckets: Morning (04:00-11:59), Afternoon (12:00-17:59), Evening (18:00-21:59), Night (22:00-03:59). Standard macOS day-part intervals.
- **D-02:** Frequency buckets: Hourly, Daily, Weekly, Monthly. For non-clock-based recurring schedules.
- **D-03:** "No schedule evidence" section collects all non-`.scheduled` confidence jobs (Registered, Candidate, Manual) plus `.scheduled` jobs with unclassifiable schedule text.
- **D-04:** "No schedule evidence" section always appears last, consistent with existing pattern where "Unknown" types are at the bottom.

### Classification Heuristics
- **D-05:** Time-of-day classification uses `nextRun` Date's hour component in local timezone (Calendar.current). Primary and most reliable source.
- **D-06:** Fallback: parse HH:MM clock times from raw schedule string (regex `\b\d{1,2}:\d{2}\b`). Use earliest matched time for bucket assignment.
- **D-07:** Frequency classification scans `scheduleDescription` humanized output for keywords (hourly/daily/"every day"/weekly/"every week"/monthly/"every month"). Also checks `nextRun` gap calculation: if two consecutive nextRun values are ~1h apart → Hourly, ~24h → Daily, ~168h → Weekly.
- **D-08:** Only `.scheduled` confidence jobs are eligible for time-of-day or frequency classification. Per ROADMAP criterion 4: non-scheduled records never display fabricated run times.
- **D-09:** Time-of-day classification wins over frequency. If both are detectable, time-of-day takes priority (more specific and useful).
- **D-10:** Empty sections are not rendered — existing `SidebarJobSection.sections()` already skips groups with zero matching jobs.

### Implementation
- **D-11:** New `SidebarScheduleClassifier` private enum (similar pattern to existing `SidebarTriggerClassifier` in JobPresentation.swift) tucked in the same file.
- **D-12:** Add `case schedule` to `SidebarGroupingMode` enum with label "Schedule".
- **D-13:** Add `case .schedule:` branch in `groupDefinitions(for:)` returning schedule-based `SidebarGroupDefinition` array.
- **D-14:** Self-tests cover: clock time parsing, time-of-day bucket assignment, frequency detection, confidence gating, empty section handling.

### the agent's Discretion
- Exact regex pattern for clock time extraction
- Whether frequency detection uses scheduleDescription text or direct schedule string analysis
- Specific implementation of frequency heuristics (keyword list, gap tolerance)
- Self-test fixture schedule strings
</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SidebarGroupingMode` enum with 5 cases — ready for a 6th `.schedule` case
- `groupDefinitions(for:)` switch dispatcher — ready for `.case schedule:` branch
- `SidebarTriggerClassifier` private enum — existing pattern for classification in JobPresentation.swift
- `SidebarJobSection.sections()` — already handles empty section filtering, collapse state, search filtering
- `JobHumanizer.scheduleDescription()` — already humanizes cron, clock times, login/watch patterns
- `JobHumanizer.relativeRunDescription()` — relative date formatting
- `SidebarSectionID(groupingMode: SidebarGroupingMode, groupKey: String)` — collapse state auto-isolated per mode

### Established Patterns
- Classification enums are file-private in JobPresentation.swift (SidebarTriggerClassifier)
- Group definitions use `@Sendable (JobPresentation) -> Bool` closures
- Section IDs use `SidebarSectionID(groupingMode:groupKey:)` for collapse persistence
- Health classifier uses `JobHumanizer.health()` extension on ScheduledJob

### Integration Points
- `JobPresentation.swift` lines 114-138 — SidebarGroupingMode enum
- `JobPresentation.swift` lines 420-500 — groupDefinitions(for:) switch
- `JobPresentation.swift` lines 509-612 — SidebarTriggerClassifier (pattern reference)
- `SidebarView.swift` — groupingMode picker renders all modes
- `PreferencesStore.swift` — groupingMode persists via UserDefaults
- `ActiveJobsCoreSelfTest/main.swift` — self-test fixture schedule strings
</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond ROADMAP success criteria and grey area decisions captured above.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.
</deferred>
