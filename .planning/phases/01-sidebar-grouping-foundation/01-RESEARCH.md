# Phase 1: Sidebar Grouping Foundation - Research

**Researched:** 2026-05-08
**Domain:** SwiftUI macOS sidebar presentation data and grouped list rendering
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

**CRITICAL:** These decisions are copied from `01-CONTEXT.md` and must be honored by the planner.

### Locked Decisions
- **D-01:** Source sections should use the known source order: Launchd first, Hermes cron second.
- **D-02:** Jobs within each source section should preserve the existing inventory order instead of introducing a new per-section sort. This keeps the current next-run-then-name behavior intact.
- **D-03:** Sources with zero visible jobs should not render section headers or placeholder rows.
- **D-04:** Each source header should show the human-readable source name plus the count of visible jobs in that section.
- **D-05:** Job row subtitles should remove the duplicated source name once rows are grouped under source headers. The subtitle should focus on timing or schedule text.
- **D-06:** When search is active, section header counts should reflect only visible filtered jobs.
- **D-07:** The top sidebar summary count should also reflect only visible filtered jobs, keeping the sidebar count language consistent under search.

### the agent's Discretion
- Exact source header typography, spacing, and count separator may be chosen during planning/implementation as long as the result stays compact, native-feeling, and clearly shows source name plus visible count.

### Deferred Ideas (OUT OF SCOPE)
- None from phase discussion.
- Existing project-level deferred items remain out of scope: health-based grouping, schedule-based grouping, persisted custom grouping modes, and collapsible groups.
</user_constraints>

<project_constraints>
## Project Constraints (from AGENTS.md)

- Keep scanner IO out of views; sidebar work should use presentation/store data, not direct filesystem reads. [VERIFIED: AGENTS.md]
- Preserve read-only behavior; this project is navigation and organization, not job management. [VERIFIED: AGENTS.md]
- Avoid new third-party packages unless necessary; this package currently has no external Swift dependencies. [VERIFIED: AGENTS.md]
- Use the existing `ActiveJobsCoreSelfTest` and `script/ci.sh` workflow; add focused coverage where non-UI behavior moves into presentation helpers. [VERIFIED: AGENTS.md]
- Use repository patterns, small focused types, and one primary Swift type per file. [VERIFIED: AGENTS.md]
- Keep comments rare and use descriptive names instead of explanatory noise. [VERIFIED: AGENTS.md]
- Do not create, rename, or switch git branches during plan-phase. [VERIFIED: plan-phase.md]
</project_constraints>

<architectural_responsibility_map>
## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Build source-grouped visible sidebar data | Presentation State Layer | SwiftUI App Layer | Grouping belongs beside `JobPresentation` because it transforms already-scanned `JobPresentation` values and avoids scanner IO in views. [VERIFIED: `Sources/AutomationHealth/Models/JobPresentation.swift`, `.planning/codebase/ARCHITECTURE.md`] |
| Apply search-filtered grouping and counts | SwiftUI App Layer | Presentation State Layer | `ContentView` currently owns search filtering, so grouping should happen after `filteredJobs` is computed. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`] |
| Render source headers and job rows | SwiftUI App Layer | Presentation State Layer | `SidebarView` already renders the sidebar header, rows, selection binding, health dot, and scan footer. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`] |
| Validate grouping behavior | Executable Self-Test Layer | Presentation State Layer | The project uses `ActiveJobsCoreSelfTest` for focused non-UI behavior checks instead of an XCTest target. [VERIFIED: `Package.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`, `.planning/codebase/STACK.md`] |
</architectural_responsibility_map>

<research_summary>
## Summary

Phase 1 should be planned as a presentation-boundary refactor followed by a sidebar rendering change and self-test coverage. The key implementation move is to introduce a grouped sidebar model in `Sources/AutomationHealth/Models/JobPresentation.swift` or a sibling app-target model, then have `ContentView` map `filteredJobs` into source sections before passing them to `SidebarView`. [VERIFIED: `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Views/ContentView.swift`, `01-CONTEXT.md`]

The current code already has the right inputs: each `JobPresentation` exposes `sourceName`, `job.source`, health, timing strings, and `searchText`; each `SidebarJobSummary` exposes row fields consumed by `SidebarJobRow`. The plan should preserve that split, changing row subtitles so grouped rows no longer repeat the source name and adding a section model that can carry `JobSource`, display name, visible count, and row summaries. [VERIFIED: `Sources/AutomationHealth/Models/JobPresentation.swift`]

**Primary recommendation:** Create a deterministic `SidebarJobSection` presentation helper that groups filtered `JobPresentation` values by `JobSource.allCases`, preserves the incoming job order inside each source, omits empty groups, and produces source-free `SidebarJobSummary` subtitles for grouped rows. [VERIFIED: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`]
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Swift | Swift 6 through SwiftPM | App and presentation model implementation | Existing project language and package manager. [VERIFIED: `Package.swift`, `.planning/codebase/STACK.md`] |
| SwiftUI | macOS 14 target | Sidebar rendering with `NavigationSplitView`, `ScrollView`, `LazyVStack`, buttons, and native materials | Existing app UI framework. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`] |
| ActiveJobsCore | Internal SwiftPM library | Supplies `ScheduledJob`, `JobSource`, and health humanization | Existing scanner/domain boundary; app target already imports it. [VERIFIED: `Sources/AutomationHealth/Models/JobPresentation.swift`] |
| ActiveJobsCoreSelfTest | Internal executable target | Focused regression checks without XCTest | Existing local self-test workflow. [VERIFIED: `Sources/ActiveJobsCoreSelfTest/main.swift`, `script/test.sh`] |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `./script/ci.sh` | Build and self-test gate | Final verification for planning/execution. [VERIFIED: `script/ci.sh`] |
| `swift run ActiveJobsCoreSelfTest` | Focused self-test command | Validate presentation helper behavior after grouping code moves out of views. [VERIFIED: `script/test.sh`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| App-target presentation helper | Scanner-layer grouping in `ActiveJobsCore` | Wrong boundary: grouping visible filtered UI rows depends on presentation/search state, not source scanning. [VERIFIED: `.planning/codebase/ARCHITECTURE.md`, `01-CONTEXT.md`] |
| `List` with `Section` | Current `ScrollView` plus `LazyVStack` sections | `List` would be a larger UI behavior change; the current row selection and material styling are already custom and should be preserved for Phase 1. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`] |
| New XCTest target | Extend `ActiveJobsCoreSelfTest` | Existing project has no declared test target, and docs route validation through the self-test executable. [VERIFIED: `Package.swift`, `.planning/codebase/STACK.md`] |
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### System Architecture Diagram

```text
JobStore.jobs
    |
    v
ContentView.filteredJobs(searchText)
    |
    v
Sidebar section builder
    |-- iterate JobSource.allCases in stable source order
    |-- filter visible jobs for each source
    |-- preserve incoming job order
    |-- omit empty groups
    v
[SidebarJobSection]
    |
    v
SidebarView
    |-- SidebarHeader uses visible row count
    |-- Section headers show source display name + visible count
    |-- SidebarJobRow buttons remain the only selectable elements
    v
selectedJobID binding -> DetailView selected job
```

### Recommended Project Structure

```text
Sources/AutomationHealth/
├── Models/
│   └── JobPresentation.swift        # Add grouped sidebar presentation values or same-file helper
├── Views/
│   ├── ContentView.swift            # Group filtered visible jobs before rendering
│   └── SidebarView.swift            # Render sections, headers, rows, footer
└── Stores/
    └── JobStore.swift               # No Phase 1 changes expected

Sources/ActiveJobsCoreSelfTest/
└── main.swift                       # Add grouping behavior tests if helper is non-UI and testable
```

### Pattern 1: Group After Filtering
**What:** Keep search filtering in `ContentView`, then build grouped sections from the filtered visible jobs. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`, `01-CONTEXT.md`]
**When to use:** Required for D-06 and D-07 so group counts and top summary counts describe the same visible set. [VERIFIED: `01-CONTEXT.md`]
**Planning implication:** Plan 01-01 should make the section builder accept `[JobPresentation]`, not raw `ScheduledJob` and not a search query.

### Pattern 2: Presentation Model Owns Row Text
**What:** Keep subtitle construction in `SidebarJobSummary` or a nearby presentation helper. [VERIFIED: `Sources/AutomationHealth/Models/JobPresentation.swift`]
**When to use:** Required to remove duplicate source names from grouped rows without making `SidebarView` understand job scheduling details. [VERIFIED: `01-CONTEXT.md`]
**Planning implication:** Plan 01-01 should specify exact subtitle behavior: `nextRunText` when `job.job.nextRun != nil`, otherwise `scheduleText`, with no `sourceName` prefix.

### Pattern 3: Non-Selectable Structure In The View
**What:** Section headers should be plain SwiftUI text/layout, while job rows remain buttons bound to `selectedJobID`. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`, `01-CONTEXT.md`]
**When to use:** Required for Phase 1 grouping and sets up Phase 2 keyboard navigation to skip headers. [VERIFIED: `.planning/ROADMAP.md`, `01-CONTEXT.md`]
**Planning implication:** Plan 01-02 should not introduce selection state or click handlers for source headers.

### Anti-Patterns to Avoid
- **Direct filesystem or scanner calls in views:** Violates the app architecture and read-only scanner boundary. [VERIFIED: AGENTS.md, `.planning/codebase/ARCHITECTURE.md`]
- **Sorting jobs separately inside each group:** Violates D-02 and can visually reshuffle jobs relative to the inventory order. [VERIFIED: `01-CONTEXT.md`]
- **Rendering empty source headers:** Violates D-03 and ORG-03. [VERIFIED: `01-CONTEXT.md`, `.planning/REQUIREMENTS.md`]
- **Keeping source names in grouped row subtitles:** Violates D-05 and preserves the visual duplication this phase is meant to remove. [VERIFIED: `01-CONTEXT.md`]
- **Adding collapsible groups or grouping controls:** Explicitly deferred/out of scope. [VERIFIED: `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`] 
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Source ordering | Custom string sort or hard-coded display-name comparison | `JobSource.allCases` order | `JobSource` already encodes known source order as `.launchd`, then `.hermesCron`. [VERIFIED: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`] |
| Row health colors | New health indicator logic | Existing `HealthDot` | Phase 1 should preserve current health visual semantics. [VERIFIED: `Sources/AutomationHealth/Views/SidebarView.swift`, `01-CONTEXT.md`] |
| Test harness | New testing framework | Existing `ActiveJobsCoreSelfTest` | Project docs and scripts already run this self-test executable. [VERIFIED: `script/test.sh`, `.planning/codebase/STACK.md`] |
| Source display names | Duplicate display-name mapping in the view | `job.source.displayName` / `JobPresentation.sourceName` | Avoids drift between detail/sidebar source naming. [VERIFIED: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`] |
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Grouping Before Search
**What goes wrong:** Section counts include hidden jobs or empty headers remain after filtering. [VERIFIED: `01-CONTEXT.md`]
**Why it happens:** The builder groups `store.jobs` instead of `filteredJobs`.
**How to avoid:** Make the section builder consume only the visible jobs array created after search filtering.
**Warning signs:** Searching for a Hermes-only job still shows a Launchd header, or top count differs from section count totals.

### Pitfall 2: Re-Sorting Within Sections
**What goes wrong:** Job rows shift order after grouping, breaking ORG-05. [VERIFIED: `.planning/REQUIREMENTS.md`, `01-CONTEXT.md`]
**Why it happens:** Sorting each source group by display name or source-local schedule after `JobInventory` already sorted globally.
**How to avoid:** Preserve the incoming array order when collecting rows for each source.
**Warning signs:** A test fixture with interleaved sources changes relative order inside launchd or Hermes sections.

### Pitfall 3: View-Centric Formatting Logic
**What goes wrong:** `SidebarView` starts branching on `ScheduledJob` or duplicating subtitle rules. [VERIFIED: `.planning/codebase/ARCHITECTURE.md`]
**Why it happens:** The plan treats grouping as only a visual loop change.
**How to avoid:** Keep row and section values in presentation models and pass render-ready data into the view.
**Warning signs:** `SidebarView` references `nextRunText`, `scheduleText`, or `JobSource` directly beyond displaying section metadata.

### Pitfall 4: Test Target Visibility
**What goes wrong:** The self-test target cannot instantiate internal app-target presentation types. [VERIFIED: `Package.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`]
**Why it happens:** `ActiveJobsCoreSelfTest` depends on `ActiveJobsCore`, not the `AutomationHealth` executable target.
**How to avoid:** During planning, either use compile-time validation through `swift build` for app-target helpers or plan a testable helper only if the target dependency structure supports it without an architecture detour.
**Warning signs:** A plan says to import `AutomationHealth` into `ActiveJobsCoreSelfTest`; SwiftPM executable targets are not currently arranged that way.
</common_pitfalls>

<code_examples>
## Code Examples

### Existing Source Order
```swift
// Source: Sources/ActiveJobsCore/Models/ScheduledJob.swift
public enum JobSource: String, CaseIterable, Identifiable, Sendable {
    case launchd
    case hermesCron
}
```

Use `JobSource.allCases` as the source-section order. [VERIFIED: `Sources/ActiveJobsCore/Models/ScheduledJob.swift`]

### Existing Search Filter Location
```swift
// Source: Sources/AutomationHealth/Views/ContentView.swift
private var filteredJobs: [JobPresentation] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !query.isEmpty else {
        return store.jobs
    }

    return store.jobs.filter { $0.searchText.contains(query) }
}
```

Build grouped sections from `filteredJobs`, not from `store.jobs`. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`]

### Existing Row Subtitle Rule To Refine
```swift
// Source: Sources/AutomationHealth/Models/JobPresentation.swift
if job.job.nextRun != nil {
    subtitle = "\(job.sourceName) • \(job.nextRunText)"
} else {
    subtitle = "\(job.sourceName) • \(job.scheduleText)"
}
```

For grouped rows, remove `job.sourceName` and the separator from the subtitle. [VERIFIED: `Sources/AutomationHealth/Models/JobPresentation.swift`, `01-CONTEXT.md`]
</code_examples>

<sota_updates>
## State of the Art

No external ecosystem changes are relevant for this phase. This is a local SwiftUI presentation change inside a dependency-free SwiftPM app, and no new third-party package or current framework lookup is needed. [VERIFIED: `Package.swift`, `.planning/codebase/STACK.md`]

**Deprecated/outdated:**
- None found for the planned scope. [VERIFIED: local codebase review]
</sota_updates>

<assumptions_log>
## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Section header typography can be implemented with native SwiftUI text styles without a separate design token system. [ASSUMED] | Architecture Patterns | Low; the UI-SPEC gate will provide the final visual contract before planning continues. |
</assumptions_log>

<open_questions>
## Open Questions

1. **Should grouping helpers be directly self-tested or compile-validated only?**
   - What we know: `QUAL-03` allows "focused coverage or equivalent compile-time validation." [VERIFIED: `.planning/REQUIREMENTS.md`]
   - What's unclear: `ActiveJobsCoreSelfTest` does not currently depend on the app executable target where `JobPresentation` lives. [VERIFIED: `Package.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`]
   - Recommendation: Prefer a focused app-target helper plus `swift build` compile validation unless implementation naturally creates a core-independent pure helper that can be tested without violating module boundaries.

2. **What exact section header styling should be used?**
   - What we know: The context delegates exact typography, spacing, and count separator to the agent as long as it stays compact and native-feeling. [VERIFIED: `01-CONTEXT.md`]
   - What's unclear: Final visual contract is missing because no `UI-SPEC.md` exists yet.
   - Recommendation: Run `$gsd-ui-phase 1` before final planning, per the plan-phase UI safety gate.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- `AGENTS.md` - Project constraints, workflow enforcement, architecture boundaries.
- `.planning/ROADMAP.md` - Phase 1 goal, requirements, success criteria, plan breakdown.
- `.planning/REQUIREMENTS.md` - ORG-01, ORG-02, ORG-03, ORG-05, SRCH-01, QUAL-03.
- `.planning/phases/01-sidebar-grouping-foundation/01-CONTEXT.md` - Locked phase decisions D-01 through D-07.
- `.planning/codebase/ARCHITECTURE.md` - Layer ownership and IO boundary.
- `.planning/codebase/STRUCTURE.md` - Where to place presentation, view, and self-test work.
- `.planning/codebase/STACK.md` - SwiftPM, macOS, SwiftUI, no external dependencies, test workflow.
- `Sources/AutomationHealth/Models/JobPresentation.swift` - Current presentation model and row summary behavior.
- `Sources/AutomationHealth/Views/ContentView.swift` - Current filtering and sidebar data flow.
- `Sources/AutomationHealth/Views/SidebarView.swift` - Current sidebar rendering and row selection structure.
- `Sources/ActiveJobsCore/Models/ScheduledJob.swift` - `JobSource` ordering and display names.
- `Sources/ActiveJobsCoreSelfTest/main.swift` - Current self-test style and fixture patterns.

### Secondary (MEDIUM confidence)
- None needed.

### Tertiary (LOW confidence - needs validation)
- None.
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: SwiftUI macOS sidebar rendering and app-target presentation models.
- Ecosystem: Existing SwiftPM targets and internal `ActiveJobsCore` / `AutomationHealth` boundaries.
- Patterns: Filter-then-group, render-ready presentation models, non-selectable section headers, executable self-test validation.
- Pitfalls: Wrong grouping order, duplicate source subtitle text, empty headers, accidental scanner IO in views, impossible test target imports.

**Confidence breakdown:**
- Standard stack: HIGH - verified from `Package.swift`, codebase maps, and local source files.
- Architecture: HIGH - verified from current source ownership and context decisions.
- Pitfalls: HIGH - derived directly from locked decisions and existing code boundaries.
- Code examples: HIGH - copied from local source files.
</metadata>

<security_domain>
## Security Domain

Security enforcement is enabled by default in `.planning/config.json`; this phase is low-risk because it changes local presentation of already-scanned data and does not add mutation, network access, persistence, authentication, or external dependencies. [VERIFIED: `.planning/config.json`, `.planning/PROJECT.md`, `01-CONTEXT.md`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication surface in scope. [VERIFIED: `.planning/PROJECT.md`] |
| V3 Session Management | no | No sessions in scope. [VERIFIED: `.planning/codebase/STACK.md`] |
| V4 Access Control | no | App remains local and read-only; no job mutation controls in scope. [VERIFIED: AGENTS.md, `.planning/PROJECT.md`] |
| V5 Input Validation | yes | Search text remains local UI filtering over `JobPresentation.searchText`; do not interpret it as a command or filesystem path. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`] |
| V6 Cryptography | no | No cryptographic behavior in scope. [VERIFIED: `.planning/ROADMAP.md`] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental scheduler mutation through sidebar actions | Tampering | Keep section headers and rows read-only selection/navigation surfaces only; do not add enable/disable/delete/edit controls. [VERIFIED: AGENTS.md, `.planning/PROJECT.md`] |
| Unbounded or unsafe input interpretation from search | Tampering | Keep `searchText` as in-memory string filtering; do not use it for paths, shell commands, or scanner queries. [VERIFIED: `Sources/AutomationHealth/Views/ContentView.swift`] |
| Data leakage through new logs | Information Disclosure | Do not add logging of job definitions, output snippets, or filesystem paths in Phase 1. [VERIFIED: local source review] |
</security_domain>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ORG-01 | Sidebar jobs are grouped under clear section headers by job source. | Use `SidebarJobSection` built from `JobSource.allCases` and visible rows. |
| ORG-02 | Each source section header shows a human-readable source name and visible job count. | Use `JobSource.displayName` or `JobPresentation.sourceName` plus `jobs.count` for each non-empty section. |
| ORG-03 | Source groups with zero visible jobs are hidden. | Builder omits empty groups after filtering. |
| ORG-05 | Grouping preserves stable order for sections and jobs. | Section order follows `JobSource.allCases`; row order preserves incoming `filteredJobs` order. |
| SRCH-01 | Sidebar search results remain grouped by source after filtering. | `ContentView` filters first, then builds groups. |
| QUAL-03 | Focused coverage or equivalent compile-time validation protects extracted grouping/navigation helpers. | Prefer self-test only if target visibility supports it; otherwise require `swift build` and `./script/ci.sh` compile/self-test gate. |
</phase_requirements>

## RESEARCH COMPLETE
