# Phase 10: Preferences Persistence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-10
**Phase:** 10-preferences-persistence
**Areas discussed:** Preferences Store Architecture, Scan Config Knobs, Settings Scene Scope, LICENSE

---

## Preferences Store Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Separate PreferencesStore (Recommended) | New file in AutomationHealth/Stores — owns groupingMode, collapseState, scan config. JobStore stays focused on scanner state. Two @StateObjects in AutomationHealthApp. | ✓ |
| Merge into JobStore | Add @Published groupingMode/collapseState/scanConfig to existing JobStore. Simpler but conflates scanner lifecycle with persistent preferences. | |

**User's choice:** Separate PreferencesStore
**Notes:** Research recommendation accepted. JobStore is already handling scan orchestration, selection, and manual record CRUD.

---

## Scan Configuration Knobs

| Option | Description | Selected |
|--------|-------------|----------|
| Key knobs only (Recommended) | maxDepth slider (0-5), maxResults slider (10-500), "Scan on launch" toggle. Script extensions and ignored dirs stay at compile-time defaults. | ✓ |
| Full config surface | All 6 fields exposed: depth, visited file cap, result cap, size cap, script extensions, ignored dirs. | |
| Minimal — just on/off | Only a scan-on-launch toggle. Deeper config stays at compile-time defaults. | |

**User's choice:** Depth + results + on/off toggle
**Notes:** Script extensions (11 types) and ignored directory names (10 patterns) are too niche for Settings. Advanced users can change compile-time defaults.

---

## Settings Scene Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Default grouping mode + scan (Recommended) | Settings shows: default grouping mode picker, candidate scan toggle. | ✓ |

**User's choice:** Default grouping mode + scan config (depth, results, toggle). No keyboard shortcut reference.

---

## LICENSE

| Option | Description | Selected |
|--------|-------------|----------|
| Copyright Niko, 2026 | MIT license: Copyright (c) 2026 Niko | ✓ |
| Use placeholder | Placeholder for later fill-in | |

**User's choice:** Copyright (c) 2026 Niko
**Notes:** Standard MIT license text with the specified copyright line.

---

## Agent's Discretion

- Collapse state serialization: JSON-encode `Set<SidebarSectionID>` to `Data` for UserDefaults. `SidebarSectionID` and `SidebarCollapseState` need `Codable`.
- UserDefaults key naming convention
- Settings view layout details (standard SwiftUI Form with grouped sections)
- How PreferencesStore initializes defaults and syncs with UserDefaults

## Deferred Ideas

None — discussion stayed within phase scope.
