# Research: Architecture For v1.1

**Milestone:** v1.1 Open Source Readiness and Broad Inventory
**Date:** 2026-05-08

## Existing Architecture To Preserve

- `ActiveJobsCore` owns IO and source adapters.
- `JobStore` bridges scan refreshes into main-actor UI state.
- `JobPresentation` turns domain jobs into display/search/grouping data.
- SwiftUI views render presentation state and do not read scheduler files.
- The app is read-only.

## New Domain Concepts

### Discovery Confidence

Add a source-independent confidence model so broad discovery remains honest:

- **Scheduled**: a scheduler source directly defines a job trigger.
- **Registered**: a platform tool lists an automation, but schedule/trigger is not proven.
- **Candidate**: a file looks automation-like, but no scheduler link is known.
- **Manual**: user added the record for tracking.

This belongs in the core/presentation boundary, not as view-only strings.

### Origin And Ownership

Add ownership classification separate from scheduler source:

- **User-authored**: user home paths, labels or executables that look local/custom.
- **Third-party app**: app/vendor bundle identifiers, `/Applications` paths, labels such as Dropbox/Google.
- **System**: Apple/system paths.
- **Unknown**: insufficient evidence.

This enables better grouping than the current launchd/Hermes split, where closed-source app updaters and user scripts share the same source.

### Manual Records

Manual entries should be local app data, not modifications to real scheduled jobs. A small JSON file in app support or another explicit local data path can store records with:

- id
- display name
- command/path
- notes
- confidence = Manual
- optional source link/path
- created/updated timestamps

This is the first likely need for lightweight persistence; keep it isolated from scanner output and documented.

## Scanner Additions

### Deterministic Scanner Expansion

Add scanners behind `JobScanning`:

- `CronScanner`: reads user crontab via `crontab -l` and readable system cron files.
- `ShortcutsScanner`: shells out to `shortcuts list` for registered shortcut inventory, labeled as Registered unless a scheduler is proven.
- `AutomatorScanner`: discovers workflows in known user-visible workflow locations, labeled Registered or Candidate depending on evidence.
- Optional launchd expansion: include system launchd paths when readable, with source filtering and ownership classification.

### Candidate Script Discovery

Add bounded candidate discovery for common user locations:

- Desktop, Documents, Downloads, and selected project/script folders.
- File extensions and shebangs such as `.sh`, `.zsh`, `.bash`, `.py`, `.rb`, `.js`, `.applescript`, `.scpt`, `.workflow`, `.shortcut`.
- Hard limits on depth, file count, size, ignored directories, and hidden/vendor cache locations.

Candidate discovery should be opt-in or clearly scoped in UI copy because it inspects broad filesystem areas.

## UI Integration

- Replace source-only sections with a grouping model that can group by source, ownership/origin, health, trigger type, and confidence.
- Collapsed sections should keep selection sane: if the selected row is hidden by collapse, detail can remain selected, but keyboard traversal should skip hidden rows.
- Sidebar focus treatment should be a local visual state that matches the existing search focus ring, not the default oversized focus rectangle around the whole sidebar.
- Use existing presentation helpers for counts and visible row lists so search, collapse, and keyboard navigation share one model.

## Build And Publication

- Keep CI script-first: `./script/ci.sh` remains the single gate.
- Add documentation checks as scripts if needed, keeping dependencies low.
- Add app icon generation/packaging in `script/build_and_run.sh` or a dedicated asset script only if it stays deterministic after the source image is committed.

## Risk Areas

- Broad file scanning can become slow or invasive without strict bounds.
- Running shell commands like `crontab` and `shortcuts` must be best-effort and failure-tolerant.
- Manual persistence is a new product capability; keep it read-only with respect to real jobs.
- Ownership classification will be heuristic; UI must make uncertainty visible.
