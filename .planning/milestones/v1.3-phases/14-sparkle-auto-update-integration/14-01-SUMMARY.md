---
phase: 14-sparkle-auto-update-integration
plan: 01
subsystem: auto-update
tags: [sparkle, spm, auto-update, eddsa, updater, observable-object]
dependency_graph:
  requires: []
  provides:
    - Sparkle 2 SPM dependency (branch 2.x)
    - UpdateStore ObservableObject (KVO-to-Combine bridge)
    - EdDSA key generation script
  affects:
    - Package.swift
    - AutomationHealth target
    - .sparkle-tools cache
tech_stack:
  added:
    - Sparkle 2.9.1 (SPM binaryTarget, branch 2.x)
    - Combine (publisher(for:) KVO bridging)
  patterns:
    - @MainActor ObservableObject store (PreferencesStore, JobStore style)
    - set -euo pipefail shell scripts (release.sh style)
key_files:
  created:
    - Package.resolved (SPM resolution lockfile)
    - Sources/AutomationHealth/Stores/UpdateStore.swift (96 lines)
    - script/generate_sparkle_keys.sh (69 lines)
  modified:
    - Package.swift (added dependencies array, Sparkle to AutomationHealth target)
    - .gitignore (added .sparkle-tools/)
decisions:
  - Sparkle 2 added as branch-based SPM dependency (2.x) rather than version-based, since Sparkle 2's Package.swift lives on the 2.x branch not tagged releases
  - Only AutomationHealth executable target links Sparkle -- ActiveJobsCore and AutomationHealthCore remain framework-free per ARCHITECTURE.md
  - UpdateStore does NOT conform to SPUUpdaterDelegate -- a separate UpdateStoreDelegate class bridges delegate callbacks while UpdateStore observes KVO properties
  - SPUUpdater.automaticallyChecksForUpdates is read/written through the updater instance, not UserDefaults directly (following Sparkle docs recommendation)
  - EdDSA private key stored in login Keychain by generate_keys (not written to disk), public key printed for manual Info.plist embedding
metrics:
  started: "2026-05-12T08:35:00Z"
  completed: "2026-05-12T08:43:27Z"
  duration: "8 min"
  tasks: 3
  files_created: 3
  files_modified: 2
---

# Phase 14 Plan 01: Sparkle 2 SPM Dependency, UpdateStore, and EdDSA Key Generation Summary

**One-liner:** Added Sparkle 2 as the project's first external SPM dependency, created UpdateStore ObservableObject bridging Sparkle's KVO API to SwiftUI @Published state, and created an EdDSA key generation script for the release pipeline.

## Task Summary

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Add Sparkle 2 SPM dependency to Package.swift | 6322d24 | Package.swift, Package.resolved |
| 2 | Create UpdateStore ObservableObject | 136f97e | Sources/AutomationHealth/Stores/UpdateStore.swift |
| 3 | Create EdDSA key generation script | 649a349 | script/generate_sparkle_keys.sh, .gitignore |

## Verification Results

| Verification | Status | Detail |
|-------------|--------|--------|
| swift build exits 0 | PASS | Build complete (0.09s) |
| sparkle-project/Sparkle in Package.swift | PASS | 1 occurrence |
| UpdateStore.swift exists | PASS | 96 lines |
| generate_sparkle_keys.sh executable | PASS | chmod +x verified |
| generate_sparkle_keys.sh syntax valid | PASS | bash -n exits 0 |
| Sparkle checkout exists | PASS | .build/checkouts/Sparkle present |
| ActiveJobsCore has no Sparkle | PASS | Framework-free target preserved |
| AutomationHealthCore has no Sparkle | PASS | Framework-free target preserved |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] SPM argument ordering: products must precede dependencies**
- **Found during:** Task 1
- **Issue:** Swift Package Manager requires `products` argument before `dependencies` in Package init. Plan template placed `dependencies` first.
- **Fix:** Reordered Package initializer arguments to `products` before `dependencies`
- **Files modified:** Package.swift
- **Commit:** 6322d24

**2. [Rule 2 - Missing Critical Functionality] Added UpdateStoreDelegate bridge class**
- **Found during:** Task 2
- **Issue:** Without an SPUUpdaterDelegate, updateState would never transition to `.updateAvailable`, `.upToDate`, or `.error` from Sparkle callbacks. KVO alone covers only `canCheckForUpdates` and `sessionInProgress`.
- **Fix:** Added `UpdateStoreDelegate` as a file-private NSObject conforming to `SPUUpdaterDelegate`, bridging `didFindValidUpdate`, `updaterDidNotFindUpdate`, and `didAbortWithError` to `updateState` transitions
- **Files modified:** Sources/AutomationHealth/Stores/UpdateStore.swift (+30 lines)
- **Commit:** 136f97e
- **Note:** The plan's design decision #6 says delegate is "handled separately in plan 14-02", but the delegate class itself must exist before plan 14-02 can wire it. Plan 14-02 will instantiate and assign `UpdateStoreDelegate`.

## Threat Flags

None -- all threat model items covered or accepted per plan. T-14-01 (tampering/SPM checksum) is inherent accept. T-14-02 (generate_keys download) mitigated by HTTPS and pinned version. T-14-03 (private key) mitigated by Keychain storage. T-14-04 (EoP/signature verification) and T-14-05 (DoS/missing key) mitigated in design.

## Known Stubs

None -- all created code is functional and compiles. The UpdateStoreDelegate is ready for wiring in plan 14-02. The generate_sparkle_keys.sh script is complete and runnable (requires network access to download Sparkle tools).

## Self-Check: PASSED

- [x] Package.swift -- modified, commit 6322d24 verified
- [x] Package.resolved -- created, commit 6322d24 verified
- [x] Sources/AutomationHealth/Stores/UpdateStore.swift -- created, commit 136f97e verified
- [x] script/generate_sparkle_keys.sh -- created, commit 649a349 verified
- [x] .gitignore -- modified, commit 649a349 verified
- [x] swift build exits 0 -- confirmed
