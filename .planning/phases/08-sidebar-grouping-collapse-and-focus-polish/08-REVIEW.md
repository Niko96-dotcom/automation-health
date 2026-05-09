---
phase: 08-sidebar-grouping-collapse-and-focus-polish
reviewed: 2026-05-08T18:59:28Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - Package.swift
  - Sources/AutomationHealthCore/JobPresentation.swift
  - Sources/AutomationHealth/Views/ContentView.swift
  - Sources/AutomationHealth/Views/SidebarView.swift
  - Sources/AutomationHealth/Views/DetailView.swift
  - Sources/AutomationHealth/Stores/JobStore.swift
  - Sources/ActiveJobsCoreSelfTest/main.swift
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 08: Code Review Report

**Reviewed:** 2026-05-08T18:59:28Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** clean after triage and fixes

## Summary

Reviewed the Phase 08 source files for correctness, read-only boundary regressions, sidebar grouping/collapse behavior, accessibility state, and focused test coverage. The Swift package builds and `./script/test.sh` passes. Initial actionable findings were fixed or triaged as pre-existing Phase 7 scope.

## Post-Review Disposition

| ID | Original Severity | Disposition |
|----|-------------------|-------------|
| CR-01 | BLOCKER | Triaged as not Phase 8. Manual app-owned records and their write UI pre-existed this phase; Phase 8 did not add scheduler mutation behavior. |
| CR-02 | BLOCKER | Fixed by moving `manualRecordID` onto `JobPresentation` and parsing `ScheduledJob.id` instead of the source-prefixed selection ID. Covered by `testJobPresentationManualRecordIDUsesRawJobID()`. |
| WR-01 | WARNING | Fixed by adding `allJobs` to `SidebarJobSection` and using all filtered jobs for header counts/health summary while navigation still uses visible `jobs`. |
| WR-02 | WARNING | Fixed by preserving persistent and effective collapse state separately; disclosure labels/actions now use persistent state while search reveal uses effective state. |

## Resolved / Triaged Findings

### CR-01: BLOCKER - Phase 08 Adds Write-Side Manual Record Management

**File:** `Sources/AutomationHealth/Stores/JobStore.swift:49-82`
**Issue:** The project and Phase 08 scope are read-only navigation/sidebar polish, but these methods create, update, and delete manual records through `ManualRecordStore`. `ContentView` exposes those writes from the toolbar and detail actions (`Sources/AutomationHealth/Views/ContentView.swift:63-91`, `Sources/AutomationHealth/Views/ContentView.swift:97-111`), turning a scanner/navigation app into a local record management UI. This violates the stated read-only/scope constraint for the phase and expands the IO boundary beyond presenting scanned inventory.
**Fix:**
```swift
// Remove write-side manual record actions from Phase 08.
// Keep JobStore focused on read-only inventory refresh:
func refresh() {
    refresh(preferredSelectionID: nil)
}
```
If manual app-owned records are intended for a later phase, split them into a separately scoped phase with explicit product approval, persistence tests, and UX copy that distinguishes app-owned records from scanned scheduler state.

### CR-02: BLOCKER - Manual Record Edit And Remove Actions Cannot Resolve Their UUID

**File:** `Sources/AutomationHealth/Views/ContentView.swift:263-269`
**Issue:** `JobPresentation.id` is the selection id (`manualRecords:manual-<uuid>`), but `manualRecordID` removes only `"manual-"` and then tries to parse the remaining `"manualRecords:<uuid>"` as a `UUID`. The parse always fails, so `openManualRecordEditor(_:)` and `removeManualRecord(_:)` silently return without editing or removing the selected manual record.
**Fix:**
```swift
private extension JobPresentation {
    var manualRecordID: UUID? {
        guard job.source == .manualRecords,
              job.id.hasPrefix("manual-") else {
            return nil
        }

        let rawID = String(job.id.dropFirst("manual-".count))
        return UUID(uuidString: rawID)
    }
}
```
Add a self-test that creates a manual `ScheduledJob`, wraps it in `JobPresentation`, and verifies the UI helper can recover the original record UUID.

## Warnings

### WR-01: WARNING - Collapsing Sections Makes The Header Underreport Inventory Counts

**File:** `Sources/AutomationHealth/Views/SidebarView.swift:22-35`
**Issue:** `visibleJobs` is derived from `sections.flatMap(\.jobs)`, but collapsed sections intentionally set `jobs` to an empty array. The sidebar header then receives `visibleJobs.count` and a health summary computed only from expanded rows (`Sources/AutomationHealth/Views/SidebarView.swift:56-59`). Collapsing a section can make the header say `0 automation records` even when matching records still exist, which is a misleading navigation/status regression.
**Fix:** Compute header counts and health summary from all filtered jobs, not only expanded rows. For example, pass a separate `totalJobCount` and `allHealthKinds`, or store all summaries separately from displayed `jobs` on `SidebarJobSection`.

### WR-02: WARNING - Search-Revealed Collapsed Sections Announce The Wrong Collapse Action

**File:** `Sources/AutomationHealthCore/JobPresentation.swift:373-382`
**Issue:** `SidebarJobSection.isCollapsed` stores the effective collapsed state after search reveal, not the user's persisted collapse state. When search is active, a previously collapsed section is shown with `isCollapsed == false`; `SidebarSectionHeader` therefore displays a down chevron and announces `"Collapse"` (`Sources/AutomationHealth/Views/SidebarView.swift:262-274`). Clicking it actually removes the persisted collapsed state instead of collapsing the visible search result, so the accessibility label and action are misleading.
**Fix:** Preserve both states in the section model, for example `isPersistentlyCollapsed` and `isEffectivelyCollapsed`, then drive row visibility from the effective state and labels/actions from the persisted state. Alternatively, disable section toggles while search is revealing collapsed matches and announce that search is temporarily overriding collapse.

---

_Reviewed: 2026-05-08T18:59:28Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
