# Feature Research: v1.2 Preferences, Polish, and Shippable Distribution

**Domain:** macOS SwiftUI app — persisted preferences, grouping/navigation, keyboard shortcuts, distribution
**Researched:** 2026-05-10
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Grouping mode persists across launches | macOS apps remember sidebar settings; closing and reopening should not reset view preferences | LOW | `@AppStorage` with `SidebarGroupingMode` raw value; existing `@State` becomes `@AppStorage` in `ContentView` |
| Section collapse state persists across launches | If user collapses "Candidate Scripts" section, it should stay collapsed next launch | MEDIUM | `SidebarCollapseState` needs `Codable`/`RawRepresentable` or stored as `Set<String>` in `@AppStorage`; encoding `Set<SidebarSectionID>` requires a serialization bridge |
| Candidate scan preferences persist | User-configured scan paths and ignore rules should survive app relaunch | MEDIUM | New `ScanConfiguration` model in `ActiveJobsCore`; `@AppStorage` for simple settings or JSON file at `~/Library/Application Support/AutomationHealth/` for complex config |
| Keyboard shortcut: focus search field | Standard macOS convention — `Command-F` in Finder, Mail, Safari, Notes | LOW | `.keyboardShortcut("f")` on sidebar search field; or `CommandMenu` with `focused` binding |
| Keyboard shortcut: find/jump-to-letter | Typing a letter in a macOS list/sidebar jumps to first item starting with that letter (Finder, Mail, Music) | MEDIUM | Requires `onKeyPress` handler at ScrollView level; character-match against `SidebarJobSummary.displayName` prefix; NSTableView has this built-in but SwiftUI List does not |
| LICENSE file at repo root | GitHub projects without a license are legally ambiguous; users expect it | LOW | Single file commit; MIT most common for open-source macOS tools |
| `.app` bundle is codesigned | macOS Gatekeeper blocks unsigned apps; users expect "open anyway" to not be necessary | MEDIUM | Requires Developer ID Application certificate ($99/yr Apple Developer Program); `codesign --timestamp --options runtime`; Hardened Runtime entitlement |
| Notarization recipe is documented | Without notarization docs, the build pipeline is incomplete for distribution | MEDIUM | `xcrun notarytool submit`, `xcrun stapler staple`; documentation + script with placeholder IDs; NOT fully automated (requires Apple ID credentials) |
| GitHub Release with downloadable artifact | Open-source macOS apps typically distribute via GitHub Releases (`.app.zip` or `.dmg`) | MEDIUM | Build script creates `.zip` via `ditto`; `gh release create` or manual upload; `.app.zip` simpler than `.dmg` for first distribution |
| Release process documentation | Contributors and maintainers need to know how to ship | LOW | `docs/release.md` covering signing prerequisites, notarization steps, GitHub Release creation |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Schedule-based grouping | Group jobs by their schedule pattern — "Every 5 min", "Daily", "Weekly", "On login", "Manual" — makes it easy to spot what runs when | MEDIUM | New `SidebarGroupingMode.schedule` case; classify schedule text into buckets using existing `JobHumanizer` patterns; unify with trigger classifier where overlap exists |
| Custom ordering mode | Let users drag sections or jobs into preferred order; presets for "most recently run", "alphabetical", "custom" | HIGH | Requires `OrderedSet`-like storage, drag-and-drop in SwiftUI List, persistence of custom order; complex interaction with section grouping |
| Expand/collapse all with keyboard | `Option-click` on disclosure triangle expands all in Finder; keyboard equivalent saves mouse trips | LOW | Add keyboard shortcut handler on section headers; `onKeyPress(.leftArrow)` / `.rightArrow` with Option modifier |
| Switch grouping mode via keyboard shortcut | Power users cycle through grouping modes without touching the menu | LOW | `Command-1` through `Command-{N}` or cycle with `Command-Shift-G`; register in `CommandMenu` |
| Zero-config persistence | Preferences persist automatically without a save button — macOS convention | LOW | `@AppStorage` auto-syncs to UserDefaults; no save button needed; immediate on change |
| Evidence boundary enforcement | Grouping/sorting never implies schedule for registered/candidate/manual records | MEDIUM | Schedule-based grouping must exclude or separate records with `confidence != .scheduled`; lint rule in `SidebarJobSection.sections()` prevents registered/candidate/manual from appearing in time-based schedule groups |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Settings window for everything | Users expect a Settings scene for preferences | Splits preferences between the sidebar grouping menu AND a separate Settings window → confusion about where to change what | Grouping mode: keep in sidebar menu (it's a view control, not a preference). Scan config: use Settings scene. Collapse state: implicit via interaction, no UI needed |
| Cloud-synced preferences | User wants settings on multiple Macs | Introduces iCloud dependency, network errors, sync conflicts; violates "local only" constraint | No cloud sync; document in README that preferences are local |
| In-app notarization | Automate the full distribution pipeline | Notarization requires Apple ID, keychain access, 2FA — cannot be fully automated without secrets; security risk | Document the notarization recipe; keep it a manual/reviewed step outside the app |
| Auto-update / Sparkle | Users want latest version automatically | Adds framework dependency; Sparkle requires appcast hosting, DSA signing, additional notarization complexity; violates "no new dependencies" constraint | Rely on GitHub Releases + manual download; add "Check for Updates" button that opens Releases page |
| Nested sub-grouping (source→origin→health) | Users want hierarchical sections | SwiftUI List/outline complexity explodes; section count balloons with combinatorial growth; keyboard navigation becomes unpredictable | Flat grouping with single dimension is sufficient for the number of records; richer multi-axis grouping can be a later milestone |
| Drag-and-drop reordering within groups | Users want to arrange jobs manually | SwiftUI drag-and-drop with sections is fragile on macOS 14; reordering conflicts with selection; custom ordering persistence requires all jobs to have stable IDs for order storage | Custom ordering as a dedicated mode (not mixed with drag-to-reorder), with sort presets (alphabetical, last run, next run) as stepping stones |
| Per-job preference overrides | Users want to customize individual job display | Every job override is a data point that can drift as the job changes; complicates the preferences model significantly | Keep preferences at the app/section level; individual job notes already served by Manual Records |

## Feature Dependencies

```
PersistedGroupingMode ──requires──> @AppStorage migration for SidebarGroupingMode
PersistedCollapseState ──requires──> Serializable SidebarCollapseState
ScheduleGrouping ──requires──> Schedule classification logic (new or extended from JobHumanizer)
ScheduleGrouping ──enhances──> Evidence boundary enforcement
CustomOrdering ──requires──> Persisted ordering model + drag-and-drop in SwiftUI List
JumpToLetter ──enhances──> Existing keyboard navigation (SidebarNavigation)
ExpandCollapseAll ──enhances──> Existing collapse state (SidebarCollapseState)
SwitchGroupingShortcut ──enhances──> Existing SidebarGroupingMode
Codesigning ──requires──> Developer ID certificate (external dependency)
Notarization ──requires──> Codesigning (prerequisite)
GitHubRelease ──requires──> Codesigning + Notarization + LICENSE
FocusSearchField ──requires──> @FocusState (already present for .jobList)
```

### Dependency Notes

- **ScheduleGrouping requires Schedule classification:** The existing `SidebarTriggerClassifier` already categorizes by trigger type (time-based, login, file queue). Schedule grouping extends this: it clusters jobs by *when* they run — "Hourly", "Daily", "Weekly", "Monthly", "On Login", "No Schedule" — rather than *what* triggers them. A new schedule classifier is needed that parses schedule text into normalized cadence buckets.
- **CustomOrdering requires Persisted ordering model:** Custom ordering needs to store a `[String]` (job IDs) per grouping mode, persisted in `@AppStorage` or Application Support JSON. This is a significant data model change — it cannot be done incrementally.
- **CollapseState persistence requires serialization:** `SidebarCollapseState` wraps `Set<SidebarSectionID>` which contains a `SidebarGroupingMode` and `String`. This needs a `Codable` conformance or a manual bridge to store as a `[String]` in UserDefaults.
- **Codesigning requires Developer ID:** This is an external dependency — requires a paid Apple Developer Program membership ($99/yr). The code and scripts should use placeholder/variable identity names so contributors can sign with their own certificates.
- **Notarization requires Codesigning:** The notary service rejects unsigned binaries. Signing must work before notarization can be tested.
- **GitHub Release requires all three:** A release without signing is unsigned (Gatekeeper blocked). A release without LICENSE is legally ambiguous. The sequence must be: LICENSE → Codesigning → Notarization → GitHub Release.

## MVP Definition

### Launch With (v1.2 must-have)

Minimum viable product — what's needed to ship a downloadable, personalized app.

- [ ] **Persisted grouping mode** — `@AppStorage("sidebarGroupingMode")` in `ContentView`; migrate from `@State` to `@AppStorage` for `SidebarGroupingMode` (already `RawRepresentable` as `String`)
- [ ] **Persisted collapse state** — `@AppStorage` for collapsed section IDs as a `Set<String>`; bridge from `SidebarCollapseState` through a computed property
- [ ] **Keyboard shortcut: focus search field** — `Command-F` or `Command-L` to focus the sidebar search; implement via `CommandMenu` button or `focused()` modifier
- [ ] **Keyboard shortcut: expand/collapse all** — `Shift-Command-RightArrow` to expand all sections, `Shift-Command-LeftArrow` to collapse all; `CommandMenu` buttons or `onKeyPress` in sidebar
- [ ] **Keyboard shortcut: switch grouping mode** — `Command-1` through `Command-5` (existing 5 modes), `Command-6` for schedule-based (when added); `CommandMenu` with `.keyboardShortcut`
- [ ] **LICENSE file** — MIT license committed to repo root; referenced in README
- [ ] **Codesigned `.app` bundle** — `codesign` step in `script/build_and_run.sh` with environment variable for identity; Hardened Runtime entitlement plist
- [ ] **Notarization recipe** — `script/notarize.sh` that zips, submits, staples; documented in `docs/release.md` with placeholder identity instructions
- [ ] **GitHub Release with `.app.zip`** — Release workflow doc; `.app.zip` created via `ditto -c -k --keepParent` after signing and notarization
- [ ] **Evidence boundary preservation** — Schedule-based grouping or custom ordering must not imply schedule for registered/candidate/manual records; lint assertion in `SidebarJobSection.sections()`

### Add After Validation (v1.2.x)

Features to add once core is working.

- [ ] **Schedule-based grouping mode** — New `SidebarGroupingMode.schedule` case; schedule classifier that buckets into "Every few minutes", "Hourly", "Daily", "Weekly", "Monthly", "On login/startup", "No schedule"; may need refinement after real-world schedule variety
- [ ] **Keyboard shortcut: jump-to-letter** — `onKeyPress` at ScrollView level intercepts single letter keys (a-z, 0-9) when sidebar has focus; scrolls to and selects first visible job whose `displayName` starts with that letter; repeat to cycle through matches
- [ ] **Release process documentation** — `docs/release.md` covering Apple Developer Program enrollment, certificate creation, keychain setup, environment variables, signing, notarization, GitHub Release creation

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Custom ordering mode** — User-defined section and job ordering with drag-and-drop; stored ordering per grouping mode; requires significant SwiftUI complexity and testing
- [ ] **Scan configuration in Settings scene** — Dedicated `Settings` scene with candidate scan path configuration, ignore patterns, scan depth limits; requires a persistence model beyond simple `@AppStorage`
- [ ] **Automated notarization in CI** — GitHub Actions workflow for codesigning and notarization using Apple ID credentials stored as repository secrets; complex due to 2FA and keychain requirements

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Persisted grouping mode | HIGH | LOW | P1 |
| Persisted collapse state | HIGH | MEDIUM | P1 |
| LICENSE file | HIGH (legal requirement) | LOW | P1 |
| Keyboard shortcut: focus search | HIGH | LOW | P1 |
| Keyboard shortcut: expand/collapse all | MEDIUM | LOW | P1 |
| Keyboard shortcut: switch grouping mode | MEDIUM | LOW | P1 |
| Codesigned `.app` bundle | HIGH | MEDIUM | P1 |
| Notarization recipe documented | HIGH | MEDIUM | P1 |
| GitHub Release with `.app.zip` | HIGH | MEDIUM | P1 |
| Evidence boundary preservation | HIGH | MEDIUM | P1 |
| Schedule-based grouping mode | MEDIUM | MEDIUM | P2 |
| Keyboard shortcut: jump-to-letter | MEDIUM | MEDIUM | P2 |
| Release process documentation | MEDIUM | LOW | P2 |
| Custom ordering mode | LOW | HIGH | P3 |
| Scan configuration in Settings | MEDIUM | MEDIUM | P3 |
| Automated notarization in CI | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for v1.2 launch (shippable, personalized app)
- P2: Should have, add in v1.2 if time or in v1.2.x patch
- P3: Nice to have, defer to v2+ milestone

## Competitor Feature Analysis

| Feature | Finder | Mail.app | Music.app | Notes.app | Our Approach |
|---------|--------|----------|-----------|-----------|-------------|
| Sidebar grouping | View menu (icons/list/columns/gallery) | Sort by date/sender/flags/attachments | Sort by artist/album/genre | Sort by date/title | Menu-based grouping picker in sidebar header; 5 modes + schedule-based |
| Persisted view state | Remembers view mode, sidebar width, sort column | Remembers sort, selected mailbox, sidebar width | Remembers sort, playlist selection | Remembers sort, folder selection | `@AppStorage` for grouping mode and collapse state; UserDefaults for scan config |
| Find/jump | Type letter to jump in list view | Type letter jumps in message list | Type letter jumps in song list | Type letter jumps in note list | `onKeyPress` character-match against first visible job name |
| Switch view mode | `Command-1/2/3/4` | None (sort via menu) | `Command-1/2/3/4` for view modes | None | `Command-1` through `Command-N` for grouping modes |
| Expand/collapse | `Option-click` disclosure triangle expands all; `Left/Right Arrow` in list view | `Option-click` in mailbox list | None (flat list) | None (flat list) | `Shift-Command-RightArrow` / `Shift-Command-LeftArrow`; `Option-click` on section header |
| Focus search | `Command-F` or `Option-Command-F` | `Command-Option-F` (mailbox search) | `Command-F` (Filter field) | `Command-F` | `Command-F` focuses sidebar search field |
| Settings | `Command-J` (View Options) | `Command-Comma` (Preferences) | `Command-Comma` | `Command-Comma` | `Command-Comma` for Settings scene (scan config); grouping mode stays in sidebar header |
| Distribution | Built-in (OS) | Built-in (OS) | Built-in (OS) | Built-in (OS) | GitHub Release via signed/notarized `.app.zip` |

## Existing Code Integration Points

### Already Exists (Do Not Rebuild)
- `SidebarGroupingMode` enum (source, origin, health, trigger, confidence) — extend, don't replace
- `SidebarCollapseState` struct — make serializable, don't redesign
- `SidebarNavigation` type — existing Up/Down arrow handling; extend, don't replace
- `SidebarJobSection.sections(for:groupingMode:collapseState:hasSearchQuery:)` — current section builder
- `JobHumanizer` — existing schedule description humanization
- `SidebarTriggerClassifier` — existing trigger classification
- `JobConfidence` enum — existing Scheduled/Registered/Candidate/Manual distinction
- `Command-R` keyboard shortcut for rescan — already registered in `AutomationHealthApp`
- `build_and_run.sh` — existing `.app` bundle creation; add signing step, don't rewrite
- `Package.swift` — no external dependencies; maintain this constraint

### Needs Creation
- `@AppStorage` property for grouping mode in `ContentView` — replaces `@State private var sidebarGroupingMode`
- `@AppStorage` bridge for collapse state — serializes `Set<SidebarSectionID>` as `Set<String>` or `[String]`
- Hardened Runtime entitlement plist — `Resources/AutomationHealth.entitlements`
- `script/notarize.sh` — notarization submission and stapling script
- `docs/release.md` — release process documentation
- Schedule classifier — new type in `AutomationHealthCore` for schedule cadence bucketing
- Jump-to-letter key handler — extension to `SidebarView` or new modifier

### Needs Modification
- `SidebarView` — add `onKeyPress` handlers for jump-to-letter, expand/collapse all
- `ContentView` — migrate grouping mode and collapse state to `@AppStorage`
- `AutomationHealthApp` — add `Settings` scene (if scan config moves to Settings), add more `CommandMenu` shortcuts
- `build_and_run.sh` — add `codesign` step, add `--sign` mode, add `--notarize` mode
- `Makefile` — add `make sign`, `make notarize`, `make release` targets

## Sources

### Apple Official Documentation
- SwiftUI `@AppStorage` — https://developer.apple.com/documentation/swiftui/appstorage (HIGH confidence, Context7)
- SwiftUI `@SceneStorage` — https://developer.apple.com/documentation/swiftui/scenestorage (HIGH confidence, Context7)
- SwiftUI `Settings` scene — https://developer.apple.com/documentation/swiftui/settings (HIGH confidence, Context7)
- SwiftUI `keyboardShortcut` — https://developer.apple.com/documentation/swiftui/view/keyboardshortcut(_:modifiers:) (HIGH confidence, Context7)
- SwiftUI `CommandMenu` — https://developer.apple.com/documentation/swiftui/commandmenu (HIGH confidence, Context7)
- SwiftUI `FocusState` — https://developer.apple.com/documentation/swiftui/focusstate (HIGH confidence, Context7)
- Apple Notarization Guide — https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution (HIGH confidence, Context7)
- `notarytool` CLI — https://developer.apple.com/documentation/security/customizing-the-notarization-workflow (HIGH confidence, Context7)
- macOS keyboard shortcuts reference — https://support.apple.com/en-us/102650 (HIGH confidence, Apple Support page, retrieved 2026-05-10)
- SwiftUI NavigationSplitView with List selection — https://developer.apple.com/documentation/swiftui/navigationsplitview (HIGH confidence, Context7)

### GitHub Documentation
- GitHub Releases — https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases (HIGH confidence, GitHub Docs)

### Community Patterns
- macOS sidebar conventions: Finder uses Command-1/2/3/4 for view modes, Option-click on disclosure triangle to expand all, typing letter to jump — verified via Apple Support keyboard shortcuts page (HIGH confidence)
- Notarization workflow: `codesign` → `ditto` zip → `notarytool submit` → `stapler staple` — verified via Apple Developer documentation (HIGH confidence)
- Open-source macOS app distribution: GitHub Releases + signed `.app.zip` or `.dmg` — community standard; common examples include Rectangle, Maccy, IINA (MEDIUM confidence, observed ecosystem pattern)

### Codebase Analysis
- Existing `SidebarGroupingMode` already includes `.health` — confirmed via `Sources/AutomationHealthCore/JobPresentation.swift` (HIGH confidence, codebase inspection)
- Existing `SidebarCollapseState` is a `Hashable`, `Sendable` struct with `Set<SidebarSectionID>` — confirmed via `Sources/AutomationHealthCore/JobPresentation.swift` (HIGH confidence)
- Current grouping mode is `@State`, not persisted — confirmed via `Sources/AutomationHealth/Views/ContentView.swift:8` (HIGH confidence)
- Current collapse state is `@State`, not persisted — confirmed via `Sources/AutomationHealth/Views/ContentView.swift:9` (HIGH confidence)
- `SidebarGroupingMode` is `RawRepresentable` as `String` — makes `@AppStorage` migration straightforward (HIGH confidence)
- `Package.swift` has zero external dependencies; `build_and_run.sh` creates unsigned `.app` bundle with `BUNDLE_ID="org.automationhealth.AutomationHealth"` (HIGH confidence)

---
*Feature research for: v1.2 Preferences, Polish, and Shippable Distribution*
*Researched: 2026-05-10*
