# Phase 3: Sidebar Polish And Verification - Pattern Map

**Mapped:** 2026-05-08
**Phase:** 03 - Sidebar Polish And Verification

## Summary

Phase 3 should refine the existing grouped sidebar instead of introducing new data flows. The implementation should stay in `ContentView` and `SidebarView`: `ContentView` derives whether the current empty list is caused by search, while `SidebarView` renders a compact header treatment, preserves row structure, optionally adds a quiet hover state, and shows a non-selectable filtered empty state.

## Files In Scope

| Planned file | Role | Closest existing analog | Pattern to preserve |
|--------------|------|-------------------------|---------------------|
| `Sources/AutomationHealth/Views/ContentView.swift` | Search-empty derivation and sidebar handoff | Existing `filteredJobs` and `sidebarSections` computed properties | Search ownership stays here; derive a boolean from trimmed `searchText` and visible results. |
| `Sources/AutomationHealth/Views/SidebarView.swift` | Header polish, row hover/spacing polish, filtered empty state | Current `SidebarHeader`, `SourceSectionHeader`, `SidebarJobRow`, keyboard handling, and scan footer | Keep rows as plain buttons, headers and empty state non-selectable, and navigation based on `visibleJobs`. |
| `Sources/AutomationHealth/Models/JobPresentation.swift` | Existing grouped data and navigation helpers | `SidebarJobSection.sections(for:)` and `SidebarNavigation.targetJobID` | No Phase 3 change expected unless implementation needs a tiny presentation helper. |
| `script/ci.sh` | Final automated gate | Existing local CI wrapper | Run, do not replace. It remains the Phase 3 verification command. |

## ContentView Pattern

Current search flow:

```swift
private var filteredJobs: [JobPresentation] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !query.isEmpty else {
        return store.jobs
    }

    return store.jobs.filter { $0.searchText.contains(query) }
}

private var sidebarSections: [SidebarJobSection] {
    SidebarJobSection.sections(for: filteredJobs)
}
```

Add derived state near these computed properties. Recommended names:

```swift
private var hasSearchQuery: Bool {
    !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

private var showsFilteredEmptyState: Bool {
    hasSearchQuery && filteredJobs.isEmpty
}
```

Then pass `showsFilteredEmptyState` to `SidebarView`.

## Sidebar Header Pattern

Current section header renders parenthetical counts:

```swift
Text("\(section.title) (\(section.visibleCount))")
```

Phase 3 should replace that with a compact layout:

```swift
VStack(alignment: .leading, spacing: 4) {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(section.title)
        Spacer(minLength: 8)
        Text("\(section.visibleCount)")
            .monospacedDigit()
    }
    Divider().opacity(0.35)
}
```

Preserve `section.title`, `section.visibleCount`, and the source order established by `SidebarJobSection.sections(for:)`.

## Sidebar Row Pattern

Keep `SidebarJobRow` as the only selectable item in the grouped list:

```swift
Button(action: select) {
    HStack(spacing: 10) {
        HealthDot(kind: job.healthKind)
        VStack(alignment: .leading, spacing: 2) {
            Text(job.displayName)
            Text(job.subtitle)
        }
        Spacer(minLength: 0)
    }
}
.buttonStyle(.plain)
```

Optional hover polish should be local:

```swift
@State private var isHovered = false

.background(rowBackground, in: RoundedRectangle(cornerRadius: 6))
.onHover { isHovered = $0 }
```

The selected background must remain stronger than hover:

```swift
private var rowBackground: Color {
    if isSelected { return Color.accentColor.opacity(0.18) }
    return isHovered ? Color.primary.opacity(0.06) : .clear
}
```

## Filtered Empty State Pattern

Render a private view only when a non-empty search query has no visible jobs:

```swift
if showsFilteredEmptyState {
    FilteredSidebarEmptyState()
}
```

The empty state should contain exactly:

- `No matching automations`
- `Try a different search.`

It must not be a `Button`, must not be included in `visibleJobs`, and must not receive `.id(...)` for keyboard navigation. With no visible jobs, existing Up/Down handling returns `.ignored` because `SidebarNavigation.targetJobID` returns nil.

## Verification Pattern

Use the existing gates and checks:

- `swift build`
- `./script/ci.sh`
- Source checks for no scanner IO in `SidebarView`
- Manual check recorded in `03-02-SUMMARY.md`

Do not add a new UI automation harness, checklist document, or verification script in Phase 3.

## Pitfalls To Avoid

- Do not render `launchd (3)` after header polish; use separate label and count.
- Do not add count badges or accent-colored section decoration.
- Do not reintroduce source names into grouped row subtitles.
- Do not add empty rows to `SidebarJobSection.jobs`.
- Do not attach key handling to the empty state.
- Do not edit scanner services, scheduler files, launchd state, Hermes cron metadata, or output files.
