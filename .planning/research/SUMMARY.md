# Project Research Summary

**Project:** Automation Health v1.2
**Domain:** macOS SwiftUI read-only automation scanner app — preferences, keyboard navigation, grouped sidebar, signed distribution
**Researched:** 2026-05-10
**Confidence:** HIGH

## Executive Summary

Automation Health v1.2 transforms the app from "buildable locally" to "downloadable and personalized" — all using built-in macOS/SwiftUI/Foundation technologies with zero new third-party dependencies. The research confirms that preferences persistence (`@AppStorage` + `UserDefaults`), keyboard shortcuts (SwiftUI `CommandMenu` + `onKeyPress`), and distribution (Apple's `codesign`, `notarytool`, `hdiutil`) are all fully supported by the platform's built-in toolchain on macOS 14+.

The recommended approach separates concerns cleanly: a new `PreferencesStore` (`@MainActor ObservableObject`) centralizes all persisted state (grouping mode, collapse state, scan config), keeping `JobStore` focused on scan data. Keyboard shortcuts are registered declaratively via SwiftUI `CommandMenu` entries, avoiding global `.onKeyPress` capture. The distribution pipeline follows Apple's recommended sequence — sign the `.app`, package into DMG, notarize the DMG, staple the ticket — with credentials stored in environment variables, never committed.

The primary risks are: (1) the codesigning/notarization pipeline requires an Apple Developer Program membership ($99/yr) and correct bundle structure, (2) schedule-based grouping must enforce confidence gates so Candidate/Manual records never imply schedule evidence they don't have, and (3) keyboard shortcuts must avoid conflicting with macOS system conventions. All risks are addressable through the phased approach and pitfall-specific self-tests documented in the research.

## Key Findings

### Recommended Stack

All v1.2 features use built-in macOS/SwiftUI/Foundation capabilities. No new Swift packages or external toolchains required.

**Core technologies:**
- **`@AppStorage` + `UserDefaults` standard**: Persist simple preferences (grouping mode, collapse state) — `@AppStorage` for SwiftUI views, direct `UserDefaults` access for non-view code like `JobStore`. Complex types serialize via `JSONEncoder`/`JSONDecoder` to `Data`.
- **SwiftUI `CommandMenu` + `.keyboardShortcut`**: Register global keyboard shortcuts declaratively. `FocusedValue` bridges context between focused views and menu commands. `@FocusState` handles programmatic focus (e.g., Cmd+Shift+F → search field).
- **`codesign`, `notarytool`, `stapler`, `hdiutil`**: Apple's built-in signing/notarization/DMG toolchain via Xcode Command Line Tools. No third-party alternatives needed. Sequence: sign `.app` → create DMG → sign DMG → notarize DMG → staple ticket.
- **MIT License**: Already committed in v1.1 Phase 4. Confirm presence in v1.2 release tag.

**What NOT to use:**
- `@SceneStorage` for app-wide preferences (per-scene only)
- `codesign --deep` (Apple DTS explicitly warns against it)
- `altool` for notarization (deprecated; use `notarytool`)
- Third-party DMG tools (`create-dmg`, `node-appdmg`) — add unnecessary toolchain dependencies
- `@AppStorage` in non-view code — use direct `UserDefaults` access
- Third-party preferences libraries (`Defaults`, `SwiftyUserDefaults`) — no benefit over `@AppStorage` + `UserDefaults`

### Expected Features

**Must have (table stakes) — P1:**
- Persisted grouping mode — `@AppStorage` on `SidebarGroupingMode` raw value; existing `@State` becomes persisted store
- Persisted collapse state — `SidebarCollapseState` made `Codable`; serialized to `UserDefaults` as JSON
- Keyboard shortcut: focus search field — Cmd+Shift+F (not Cmd+F, which conflicts with system Find)
- Keyboard shortcut: expand/collapse all — Shift+Cmd+RightArrow / Shift+Cmd+LeftArrow
- Keyboard shortcut: switch grouping mode — Cmd+1 through Cmd+N mapped to grouping modes
- LICENSE file — Verify present in repo root (already committed in v1.1 Phase 4)
- Codesigned `.app` bundle — `codesign` with Developer ID, hardened runtime, entitlements plist
- Notarization recipe — `script/notarize.sh` documenting `notarytool submit → staple → verify`
- GitHub Release with downloadable artifact — Signed/notarized `.dmg` via GitHub Releases
- Evidence boundary preservation — Candidate/Manual records never classified into schedule-based groups

**Should have (competitive) — P2:**
- Schedule-based grouping mode — New `SidebarGroupingMode.scheduleTimeOfDay`; classifies jobs by cadence (morning/afternoon/evening/night, daily/weekly/monthly, on-demand) with strict confidence-gating
- Keyboard shortcut: jump-to-letter — `onKeyPress` gated on sidebar `@FocusState`; matches `displayName` prefix
- Release process documentation — `docs/release.md` with placeholder identifiers, certificate setup, pipeline steps

**Defer to v2+ — P3:**
- Custom ordering mode — Drag-and-drop reordering; requires `OrderedSet`-like persistence; significant SwiftUI complexity
- Scan configuration in Settings scene — Candidate scan path config, ignore patterns; needs persistence model beyond simple `@AppStorage`
- Automated notarization in CI — GitHub Actions with Apple ID secrets; complex due to 2FA/keychain requirements

### Architecture Approach

A new `PreferencesStore` (`@MainActor ObservableObject`) centralizes all persisted preferences, bridging `UserDefaults` reads/writes to `@Published` properties. This keeps `JobStore` focused on scan/selection state (single responsibility). The `Settings` scene consumes the same `PreferencesStore`, eliminating duplicate key strings. New grouping modes (schedule-based) extend `SidebarGroupingMode` and `SidebarJobSection.groupDefinitions(for:)` with a dedicated `SidebarScheduleKind` classifier that gates on `JobConfidence.scheduled` to prevent evidence boundary violations. Distribution scripts (`sign.sh`, `notarize.sh`, `package.sh`) are fully additive — they run independently without modifying the existing `build_and_run.sh` baseline.

**Major components:**
1. **`PreferencesStore`** (NEW) — `@MainActor ObservableObject` owning grouping mode, collapse state, and scan-on-launch preferences; reads/writes `UserDefaults` with centralized keys
2. **`SidebarScheduleKind`** (NEW enum) — Schedule cadence classifier: morning/afternoon/evening/night, daily/weekly/monthly/on-demand; used by schedule-based grouping
3. **`SettingsView`** (NEW) — SwiftUI form consuming `PreferencesStore`; exposed via `Settings {}` scene in `AutomationHealthApp`
4. **`CommandMenu` entries** (MODIFIED) — View and Navigate menus with keyboard shortcuts for expand/collapse all, grouping mode switching, focus search
5. **Distribution scripts** (NEW) — `sign.sh`, `notarize.sh`, `package.sh`; `build_and_run.sh` Modified with optional `--sign` mode
6. **`entitlements.plist`** (NEW) — Minimal hardened runtime entitlements; no sandbox (app reads local scheduler files)

### Critical Pitfalls

1. **@AppStorage string-key fragility** — Typo'd key strings silently create separate UserDefaults entries; values revert to defaults with no warning. **Prevent:** Single-source-of-truth key constants; self-test that round-trips every key through all access paths.

2. **Grouping mode staleness after refresh** — Changing grouping mode during async scan can produce sections mismatched with the picker state. **Prevent:** Co-locate grouping mode with job data via `PreferencesStore` + force synchronous section recomputation on mode change.

3. **Evidence boundary violation in schedule-based grouping** — Candidate/Manual records classified into time-based buckets imply schedule evidence they don't have. **Prevent:** Gate all schedule classification on `job.confidence == .scheduled`; non-scheduled records fall into "No schedule evidence" bucket.

4. **Keyboard shortcut conflicts with system conventions** — Cmd+F, Cmd+[, Cmd+] conflict with macOS standard shortcuts (Find, Back/Forward). **Prevent:** Use Cmd+Shift+F, Shift+Cmd+Arrow for custom shortcuts; document all shortcuts; test against Apple HIG keyboard shortcut guidelines.

5. **DMG creation breaks code signature** — Finder `.DS_Store` or testing the signed app before DMG packaging dirties the signature. **Prevent:** Sign `.app` as last step before DMG creation; use clean `dist/signed/` directory; never open/test the signed app before packaging.

## Implications for Roadmap

Based on dependency analysis, recommended phase structure:

### Phase 1: Preferences Persistence

**Rationale:** All keyboard shortcuts and the Settings scene depend on a centralized, persisted preferences store. This phase builds the foundation that Phases 2-3 consume. No visual change to end users, but establishes the single source of truth for grouping mode and collapse state.

**Delivers:**
- `PreferencesStore` — `@MainActor ObservableObject` bridging UserDefaults ↔ @Published
- `SidebarCollapseState` + `SidebarSectionID` made `Codable`
- `ContentView` migrated from `@State` to `@ObservedObject preferences`
- Self-test: round-trip write/read for every preference key; mode change during simulated scan

**Avoids:** Pitfall 1 (string-key fragility), Pitfall 2 (grouping staleness), Anti-Pattern 1 (preferences in JobStore), Anti-Pattern 4 (duplicate @AppStorage keys)

**Implements:** Architecture Refactors 1, 2, 3

### Phase 2: Keyboard Navigation

**Rationale:** Keyboard shortcuts are the highest-value P1 feature with a hard dependency on `PreferencesStore` (grouping mode shortcuts, expand/collapse all). This phase makes the sidebar keyboard-operable without touching the mouse for common actions.

**Delivers:**
- `CommandMenu("View")` with expand/collapse all (Shift+Cmd+RightArrow/LeftArrow)
- `CommandMenu("View")` with grouping mode cycling (Cmd+1..Cmd+N)
- Cmd+Shift+F to focus search field (with focus restoration on Escape)
- Jump-to-letter navigation in sidebar (`onKeyPress` gated on `@FocusState`)
- Existing Up/Down arrow navigation preserved and verified

**Avoids:** Pitfall 4 (shortcut conflicts with system), UX pitfalls (search focus breaking arrow navigation, expand/collapse losing selection)

**Implements:** Integration Points 4, 6; Architecture Phase 4

### Phase 3: Schedule-Based Grouping

**Rationale:** The highest-value P2 differentiator. Depends on the persisted grouping mode from Phase 1 (needs `PreferencesStore.groupingMode` and `SidebarGroupingMode` enum to add the new case). Must enforce evidence boundaries from the start.

**Delivers:**
- `SidebarGroupingMode.scheduleTimeOfDay` case
- `SidebarScheduleKind` enum + classifier in `JobPresentation`
- `SidebarJobSection.groupDefinitions(for:)` updated with schedule-based buckets
- Confidence gate: Candidate/Manual/Registered records → "No schedule evidence"
- Self-test: Candidate record with "Daily at noon" text → NOT in "Daily" bucket

**Avoids:** Pitfall 3 (evidence boundary violation), Anti-Pattern 2 (scanner-specific branching in grouping logic)

**Implements:** Architecture Phase 3; Integration Point 5

### Phase 4: Shippable Distribution

**Rationale:** The distribution pipeline is independent of all UI features — it only requires the app to build and run correctly (which it does from the v1.1 baseline). Can run in parallel with Phases 1-3. This phase makes Automation Health downloadable and Gatekeeper-compliant.

**Delivers:**
- LICENSE file presence verified (already committed in v1.1)
- `entitlements.plist` with minimal hardened runtime config
- `script/sign.sh` — codesign `.app` with Developer ID (env-var-driven)
- `script/notarize.sh` — notarytool submit + wait + staple + verify
- `script/package.sh` — DMG creation from signed/stapled `.app`
- `script/build_and_run.sh` — modified with optional `--sign` mode
- `Makefile` — `make sign`, `make notarize`, `make release` targets
- `docs/release.md` — release process with placeholder identifiers, no real secrets
- GitHub Release with signed/notarized `.dmg` asset

**Avoids:** Pitfalls 5-10 (hardened runtime `launchctl` breakage, secret leakage, notarization failure from incomplete bundle, DMG signature breakage, GitHub upload timeout, copyright ambiguity)

**Implements:** Architecture Phase 5; Integration Points 7, 8

### Phase Ordering Rationale

- **Phase 1 → 2:** Keyboard shortcuts depend on `PreferencesStore` for grouping mode cycling and collapse state. Phase 1 must ship first or be merged into Phase 2.
- **Phase 1 → 3:** Schedule-based grouping depends on persisted grouping mode infrastructure and the `SidebarGroupingMode` enum. Phase 1 is prerequisite.
- **Phases 2 and 3:** Independent after Phase 1 — keyboard shortcuts don't depend on schedule grouping, and schedule grouping doesn't depend on shortcuts.
- **Phase 4:** Fully independent of Phases 1-3. Can run in parallel at any point. Only requires that `swift build` passes.
- **Merge opportunity:** Phases 1+2 could be combined into a single "Preferences + Keyboard Polish" phase since both are needed for a polished, keyboard-operable sidebar.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Schedule-Based Grouping):** Real-world schedule text variability may require iterative classifier refinement. Plan for a spike/adjustment cycle.
- **Phase 4 (Distribution Pipeline):** Notarization is sensitive to bundle structure and linking. First notarization attempt may reveal Info.plist gaps or dynamic linking surprises. Plan for troubleshooting iteration.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Preferences):** Well-documented `@AppStorage`/`UserDefaults`/`@MainActor ObservableObject` patterns from Apple docs and community.
- **Phase 2 (Keyboard Shortcuts):** Standard SwiftUI `CommandMenu` + `.keyboardShortcut` patterns verified against Apple HIG and competitor apps.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies are built-in macOS/SwiftUI/Foundation; verified via Apple docs (Context7), Developer Forums (Quinn "The Eskimo!"), and Scripting OS X tutorials. No third-party unknowns. |
| Features | HIGH | Competitor analysis verified against Apple's own apps (Finder, Mail, Music, Notes); feature prioritization based on codebase inspection of existing grouping mode/collapse state infrastructure. |
| Architecture | HIGH | Integration points verified against current source files (line-by-line reads of all Swift files in `Sources/`); refactor impact assessed against actual `@State` declarations and binding paths. |
| Pitfalls | HIGH | Rooted in known Apple platform behaviors (Quinn's DTS guidance on `codesign --deep`, Antoine van der Lee on `@AppStorage` fragility, Apple's notarization documentation); forensics from v1.1 commit hygiene issues incorporated. |

**Overall confidence:** HIGH — RESEARCH COMPLETE. All technologies are platform-built-in, integration points are verified against the current codebase, and pitfalls are documented with concrete prevention strategies.

### Gaps to Address

- **Dynamic vs static Swift linking:** `otool -L` verification needed during Phase 4 planning to confirm whether `swift build` produces a statically-linked binary or requires runtime library bundling. Not a blocker — just a verification step.
- **Apple Developer Program membership:** Required for codesigning. An external dependency the code can't resolve — must be obtained before Phase 4 execution. Scripts use placeholder/ENV vars to handle this gracefully.
- **Schedule classifier accuracy boundary:** Real-world schedule text is unpredictable. The classifier should be designed as a best-effort bucket with a clear "Uncategorized" fallback, not an exhaustive parser. Acceptance criteria should reflect this.
- **Custom ordering paths:** Research was clear this is v2+ material. The `SidebarGroupingMode.custom` case and `CustomOrderStore` should be stubbed but not implemented in v1.2 to avoid scope creep.

## Sources

### Primary (HIGH confidence)
- **Context7** `/websites/developer_apple_swiftui` — `@AppStorage`, `@SceneStorage`, `Settings` scene, `keyboardShortcut`, `CommandMenu`, `FocusState`, `FocusedValue`, `NavigationSplitView`
- **Apple Developer Forums** — Quinn "The Eskimo!" on codesign ordering, `--deep` danger, entitlements, Developer ID requirements (Mar 2022, updated Feb 2024)
- **Scripting OS X** (scriptingosx.com) — `notarytool` workflow, store-credentials, stapler (Jul 2021); SwiftPM-specific signing and notarization (Aug 2023)
- **Apple Developer Documentation** — `notarytool` man page, `codesign` man page, Hardened Runtime, Notarization Guide, Customizing the Notarization Workflow
- **Apple Support** — macOS keyboard shortcuts reference (support.apple.com/en-us/102650)
- **GitHub Docs** — Licensing a repository, GitHub Releases REST API, community health files
- **Project codebase** — Direct line-level reads of all Swift source files in `Sources/`; verified `@State` declarations, existing `SidebarGroupingMode`/`SidebarCollapseState`, `CommandMenu` rescan shortcut, `build_and_run.sh` bundle structure

### Secondary (MEDIUM confidence)
- **Open-source macOS app distribution** — Rectangle, Maccy, IINA all use GitHub Releases + signed `.dmg`/`.zip` (observed ecosystem pattern)
- **`@AppStorage` Explained** (avanderlee.com) — String-key fragility, no compile-time validation, limited type support

### Tertiary (LOW confidence)
- None. All findings verified against primary sources or the project codebase.

---

*Research completed: 2026-05-10*
*Ready for roadmap: yes*
