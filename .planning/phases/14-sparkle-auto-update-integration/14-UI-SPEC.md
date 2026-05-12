# Phase 14: Sparkle Auto-Update Integration — UI Design Contract

**Phase:** 14 — sparkle-auto-update-integration
**Type:** Native SwiftUI macOS Settings extension + menu item + standard Sparkle alert
**Status:** Approved
**Design System:** Native macOS SwiftUI (Form/.grouped, Picker, Toggle, Button, .caption/.secondary)

## Visual Inventory

### New Components

| Component | Location | Type |
|-----------|----------|------|
| Updates Section | SettingsView | Section with version label, toggle, button |
| Check for Updates menu item | App menu (CommandGroup after .appInfo) | Menu button |
| Sparkle Update Alert | Sparkle framework (standard) | Native window with release notes, download progress |
| Sparkle Status Window | Sparkle framework (standard) | "You're up to date" dialog |

### Modified Components

| Component | File | Change |
|-----------|------|--------|
| SettingsView | Sources/AutomationHealth/Views/SettingsView.swift | Add Updates section after Candidate Scanning section |
| AutomationHealthApp | Sources/AutomationHealth/App/AutomationHealthApp.swift | Create UpdateStore, register check-for-updates command |

## Interaction Contracts

### Updates Section (SettingsView)

**Purpose:** Display current app version, allow manual update check, toggle auto-check.

**Layout (within existing grouped Form):**

```
SettingsView > Form
├── Section("Default View")
│   └── Picker ... (existing)
├── Section("Candidate Scanning")  
│   ├── Toggle ... (existing)
│   ├── Slider ... (existing)
│   └── Slider ... (existing)
└── Section("Updates")                                          ← NEW
    ├── LabeledContent("Current Version")                        ← NEW
    │   └── Text("1.3.0")                                       ← NEW
    ├── Toggle("Automatically check for updates", isOn:)         ← NEW
    └── Button("Check for Updates")                              ← NEW
```

**States:**

| State | Version Label | Auto-Check Toggle | Check Button | Description |
|-------|---------------|-------------------|--------------|-------------|
| Normal | Shows CFBundleShortVersionString | Interactive (bound to SPUUpdater) | Enabled | Default state |
| Checking | Shows version + spinner | Interactive | Disabled, label: "Checking..." | During Sparkle update check |
| Error | "Update checking is unavailable" | Disabled | Disabled | EdDSA key missing or Sparkle init failure |

**Error state secondary text:** "The EdDSA signature verification key was not found in the app bundle."

**Spacing:** Same vertical spacing as existing Sections in the Form (system-default Form spacing). No custom padding or insets needed.

**Typoography:** System default — version uses `.body` weight, secondary text uses `.font(.caption).foregroundStyle(.secondary)` (matching existing SettingsView conventions).

**Color:** System default — no custom colors. Button uses standard accent color. Version label uses primary text color. Secondary text uses `.secondary` foreground style.

### Check for Updates Menu Item

**Placement:** CommandGroup(after: .appInfo) — follows standard macOS convention of placing "Check for Updates..." under the application menu.

**Label:** "Check for Updates…" (with ellipsis per macOS HIG for commands that open a panel/dialog)

**Keyboard shortcut:** None (standard — Sparkle handles this).

### Sparkle Update Alert (Standard)

**States:**

| State | Title | Content | Buttons |
|-------|-------|---------|---------|
| Update Available | "A new version of Automation Health is available" | Release notes (from appcast), version number | "Install Update", "Remind Me Later", "Skip This Version" |
| Up to Date | "Automation Health is up to date" | "You're running the latest version (1.3.0)" | "OK" |
| Downloading | "Downloading update…" | Progress bar | None (system-managed) |
| Ready to Install | "Update ready to install" | "Automation Health will restart to complete the installation" | "Install and Relaunch" |

All alert states use Sparkle's standard `SPUStandardUpdaterController` or `SPUStandardUserDriver` — no custom alert UI needed.

## Copywriting

### Settings Section

| Element | Copy |
|---------|------|
| Section header | "Updates" |
| Version label | "Current Version" |
| Version value | `CFBundleShortVersionString` from Bundle.main (e.g., "1.3.0") |
| Auto-check toggle | "Automatically check for updates" |
| Check button | "Check for Updates" |

### Menu

| Element | Copy |
|---------|------|
| Menu item | "Check for Updates…" |

### Error

| Context | Copy |
|---------|------|
| Missing key (primary) | "Update checking is unavailable" |
| Missing key (secondary) | "The EdDSA signature verification key was not found in the app bundle." |

All copy follows existing SettingsView pattern: concise, no terminal punctuation on labels, sentence case for secondary text.

## Design Constraints

- Native SwiftUI Form with `.formStyle(.grouped)` — same as existing SettingsView
- Frame width: 480pt (existing SettingsView constraint preserved)
- No custom fonts, colors, or spacing — use system defaults
- Sparkle alert windows use the framework's standard UI (not SwiftUI custom)
- All copy must be in US English
- The Updates section must render correctly when Sparkle is not initialized (error state)
- The Updates section must gracefully degrade if Bundle.main CFBundleShortVersionString is missing

## Non-Goals (Out of Scope)

- Custom update alert UI (Sparkle's standard alerts are the design)
- Custom update progress UI (Sparkle's download progress is standard)
- Preferences beyond auto-check toggle (no custom check intervals)
- Settings for update channel selection (single channel: GitHub Releases)
- Localization of Settings copy (US English only, consistent with existing app)
- Dark/light mode variants (system SwiftUI handles this automatically)
