# Pitfalls Research

**Domain:** macOS SwiftUI scanner app — persisted preferences, grouping modes, keyboard shortcuts, signed distribution
**Researched:** 2026-05-10
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: @AppStorage String-Key Fragility And Type Silently Falling Back

**What goes wrong:**
An `@AppStorage("groupingMode")` key with a typo (`"groupingMode"` in ContentView vs `"grouping_mode"` elsewhere) silently creates two separate UserDefaults entries. When the value type changes (e.g., `Bool` → `String` raw-enum), the existing stored value is discarded with no warning and reverts to the default. The UI appears to work but preferences don't persist across launches.

**Why it happens:**
`@AppStorage` uses string keys with no compile-time key validation. Each wrapper instance independently reads/writes UserDefaults. Type mismatches between wrapper declaration and stored value produce silent fallback to the default value — no diagnostic, no crash, no log. With `SidebarGroupingMode: RawRepresentable as String` and `SidebarCollapseState` needing custom Codable, the type-coercion gap is invisible at compile time.

**How to avoid:**
Define all preference keys as a single-source-of-truth `enum PreferenceKey: String` (or a static constant struct) used by every `@AppStorage` and UserDefaults access point. For non-trivial types like `SidebarCollapseState`, use a dedicated `Preferences` wrapper class with typed getters/setters that internally serialize to UserDefaults via `JSONEncoder`/`JSONDecoder`, rather than relying on `@AppStorage`'s limited RawRepresentable support. Write a self-test that writes a known value, reads it back through every access path, and verifies type fidelity.

**Warning signs:**
- Preferences reset to defaults after app restart with no error.
- `@AppStorage` key string appears differently in any file (grep `@AppStorage` across the project).
- Adding a new preference type (enum, Set, custom struct) to `@AppStorage` without testing round-trip persistence.
- `UserDefaults.standard.removePersistentDomain(forName:)` or `resetStandardUserDefaults()` used in test teardown without resetting wrapper state.

**Phase to address:**
Phase 10 (Preferences persistence) — define the preference keys and storage layer before wiring into views.

---

### Pitfall 2: Grouping Mode Staleness After Refresh — Stale Sections From Old Mode

**What goes wrong:**
After a scan refresh, the visible `SidebarJobSection` array is computed from `filteredJobs` using the current `sidebarGroupingMode`. If the grouping mode is changed during a scan (or between the scan completing and the UI updating), the sections array can reflect the old mode's sections while the menu shows the new mode's label. This produces sections that don't match the selected grouping mode until the next user interaction.

**Why it happens:**
`ContentView` derives `sidebarSections` synchronously from `filteredJobs` (which depends on `store.jobs` and `searchText`) plus `sidebarGroupingMode` and `sidebarCollapseState`. During the async refresh in `JobStore.refresh()`, the grouping mode is a separate `@State` that can be mutated independently. There's no transactional coupling between "the scan finished" and "the sections were recomputed for the current grouping mode."

**How to avoid:**
The grouping mode and collapse state should be co-located with the job data in `JobStore` or a dedicated `PreferencesStore` that publishes changes atomically. When `groupingMode` changes, force a synchronous section recomputation. If a scan is in flight when the mode changes, mark a `pendingSectionsRecomputation` flag and apply it when the scan completes. Write a self-test: change grouping mode while a simulated scan is in flight, verify sections match the mode after scan completes.

**Warning signs:**
- Section headers show "Source" categories but the grouping picker says "Health."
- Changing grouping mode during scan spinner produces visual flicker or empty sections briefly.
- `SidebarJobSection.sections(for:groupingMode:collapseState:hasSearchQuery:)` called with `groupingMode` that doesn't match the UI's displayed picker value.

**Phase to address:**
Phase 10 (Preferences persistence) — the persistence mechanism must co-own grouping mode alongside job data, not leave it as local `@State`.

---

### Pitfall 3: Evidence Boundary Violation When Schedule-Based Grouping Attributes Next-Run To Candidate/Manual Records

**What goes wrong:**
A new schedule-based grouping mode categorizes jobs by "runs daily," "runs weekly," "runs monthly," etc. Candidate scripts (discovered files with no proven scheduler) and Manual records (user-added with optional schedule description text) get classified into these buckets based on their `schedule` or `humanScheduleDescription` fields. This implies schedule evidence that doesn't exist — a Candidate record whose name happens to contain "daily" appears in the "Daily" group alongside real launchd jobs with cron schedules.

**Why it happens:**
The existing `SidebarTriggerClassifier` already has this problem with `beginsWithTimeDescription` matching against `humanScheduleDescription` for non-scheduled records (the `registeredOnly` guard exists but the time-description check runs before the confidence check in some paths). Schedule-based grouping amplifies this because the classifier must parse `schedule` and `humanScheduleDescription` for *all* records, including Candidate (`confidence == .candidate`) and Manual (`confidence == .manual`). The grouping logic doesn't gate on `job.confidence` before attempting schedule classification.

**How to avoid:**
For any new schedule-based grouping mode, explicitly gate classification on `job.confidence == .scheduled`. Candidate, Registered, and Manual records should fall into a single "No schedule evidence" group or be classified only by their declared confidence label. Add a self-test that verifies: a Candidate record with `schedule = "Daily at noon"` (user-entered notes) appears in the "No schedule evidence" bucket, not "Daily." Extend the existing `SidebarTriggerClassifier` to check confidence *before* any schedule-text parsing.

**Warning signs:**
- A Manual record's `scheduleDescription` field ("Every Friday morning") causes it to group with real cron jobs.
- The schedule-based grouping `groupDefinitions(for:)` doesn't include a `confidence` filter in any branch.
- A self-test passes when Candidate records group alongside Scheduled records in a time-based category.

**Phase to address:**
Phase 11 (Additional grouping modes) — the schedule-based mode must be built with confidence-gating from the start.

---

### Pitfall 4: Keyboard Shortcut Conflicts With System And Menu Shortcuts

**What goes wrong:**
Adding `Cmd-F` for "find/jump-to-letter" in the sidebar silently overrides the system-standard "Find" shortcut. Adding `Cmd-[` and `Cmd-]` for expand/collapse all conflicts with system-standard "Back/Forward" navigation. Adding `Cmd-1` through `Cmd-5` for switching grouping modes eats standard tab/sidebar switching shortcuts. The user's muscle memory is violated without any visible conflict warning.

**Why it happens:**
SwiftUI's `.keyboardShortcut()` on a `Button` in the `CommandMenu` or directly on a view registers global shortcuts that take priority over system behavior when the app is frontmost. There's no built-in shortcut conflict detection; SwiftUI silently overrides. The existing `Command-r` for Rescan in `AutomationHealthApp.swift` is already non-standard (system uses `Cmd-R` for refresh in some contexts).

**How to avoid:**
Use the macOS-standard shortcut conventions: `Cmd-Shift-F` for "focus search" (system Find uses `Cmd-F`), `Option-Command-[` for collapse all (not `Cmd-[`), `Cmd-Shift-G` or a `Picker` with `Cmd-1`..`Cmd-N` only if those numbers aren't used by `TabView` or system window management. Document every shortcut in a help section. Use `.keyboardShortcut()` only on `CommandMenu` items, not raw `onKeyPress` on unfocused views. Test with VoiceOver enabled and with system keyboard shortcuts active.

**Warning signs:**
- Any shortcut starting with `Cmd` + a single letter that matches a standard macOS shortcut (F, H, M, N, O, P, Q, W, comma, period, brackets).
- `.onKeyPress` modifiers on views without active `@FocusState` — these capture keystrokes globally when the window is frontmost.
- Shortcut help text that doesn't list all active shortcuts for discoverability.

**Phase to address:**
Phase 12 (Keyboard shortcuts) — design the shortcut map before implementing, verify against Apple's HIG keyboard shortcut guidelines.

---

### Pitfall 5: Hardened Runtime Entitlement Missing For launchctl Subprocess

**What goes wrong:**
After signing the app with `codesign -o runtime` (Hardened Runtime) and notarizing successfully, the app launches but `launchctl` subprocess calls in `LaunchAgentScanner` silently fail. The `Process` execution is blocked by the Hardened Runtime because the app doesn't declare the `com.apple.security.cs.disable-executable-page-protection` or necessary exceptions. Scan notes report "no runtime state" for every launchd job without an obvious error.

**Why it happens:**
The Hardened Runtime restricts process execution, memory mapping, and dynamic code loading. `LaunchAgentScanner` uses `Process` to invoke `/bin/launchctl` — this requires either the app to be unsandboxed with Hardened Runtime exceptions for process execution, or specific entitlements. The app currently has no entitlements file at all (no `AutomationHealth.entitlements` in the project). When `codesign -o runtime` is applied without an entitlements plist, the defaults are maximally restrictive.

**How to avoid:**
Create an `AutomationHealth.entitlements` file with the minimum required entitlements:
- `com.apple.security.cs.allow-jit` — if using any dynamic code (unlikely but safe to omit if not needed)
- For spawn/exec: Hardened Runtime doesn't block `NSTask`/`Process` by default on macOS, BUT if the app is sandboxed, it does. Since this app is NOT sandboxed (no `com.apple.security.app-sandbox`), `Process` to `/bin/launchctl` should work. Test explicitly.

The critical entitlement for this app: **none required for Process if unsandboxed**. However, **file access** entitlements are needed if the app is sandboxed. Since the app reads from `~/Library/LaunchAgents`, `/Library/LaunchDaemons`, and `~/.hermes/`, a sandboxed app would need `com.apple.security.temporary-exception.files.home-relative-path.read-write` or similar. The current architecture is **unsandboxed** — keep it that way for v1.2, but verify after signing that `launchctl` subprocesses still work by running the self-test on the signed binary.

**Warning signs:**
- Entitlements file missing from the signing step.
- `codesign -d --entitlements - AutomationHealth.app` shows empty/missing entitlements after signing.
- Self-test passes in debug build but launchctl-dependent tests fail on the signed Release binary.
- Notarization succeeds but Gatekeeper blocks launch with a vague "damaged" message (often means runtime crash from blocked syscall).

**Phase to address:**
Phase 14 (Codesigning and notarization) — create and test the entitlements file alongside the first signing attempt.

---

### Pitfall 6: Developer ID Secret Leakage In CI And Committed Scripts

**What goes wrong:**
The Developer ID certificate (`.p12`), its password, the Apple ID app-specific password for `notarytool`, and the Team ID are committed to the repository or logged in CI output. Anyone with read access to the repo can sign malware with the project's Developer ID. Apple revokes the certificate upon detecting misuse, breaking the distribution pipeline for legitimate releases.

**Why it happens:**
The natural instinct is to make the release script self-contained with credentials inline or in a `.env` file. `.gitignore` excludes `.env`, but script comments, CI workflow YAML logs, and `set -x` bash traces can leak values. The GitHub Actions macOS runner logs are semi-public (visible to anyone with repo read access). `notarytool store-credentials` stores the app-specific password in the login keychain, but the keychain password itself can be exposed if CI unlocks it on the runner.

**How to avoid:**
- Store the Developer ID certificate in a GitHub Actions secret (`DEVELOPER_ID_CERTIFICATE_BASE64`), import it into a temporary keychain during the CI job, and delete it after.
- Store the app-specific password in a GitHub Actions secret (`NOTARYTOOL_PASSWORD`).
- Use `notarytool` with `--apple-id`, `--team-id`, and `--password` from environment variables (never hardcoded).
- Never use `set -x` in release scripts that touch secrets.
- CI workflow step must have `echo "::add-mask::$SECRET"` for any secret that might appear in logs.
- The release script committed to the repo must use **placeholder values** (`$DEVELOPER_ID`, `$NOTARY_KEYCHAIN_PROFILE`) that are only resolved in CI from secrets.
- Document the keychain profile name (e.g., `automationhealth-release`) in `docs/release-process.md` but never the actual password.

**Warning signs:**
- Any script containing `--password` with a literal string value.
- CI workflow YAML that lacks `secrets: inherit` or explicit secret references for signing steps.
- `security import` or `security unlock-keychain` commands with passwords in clear text.
- GitHub Actions logs showing certificate common names or keychain entries.

**Phase to address:**
Phase 13 (Release process and docs) and Phase 14 (Codesigning/notarization) — these phases must be designed together; secrets handling is a cross-cutting CI concern.

---

### Pitfall 7: Notarization Failure From Incomplete Bundle Structure

**What goes wrong:**
The `.app` bundle created by `script/build_and_run.sh` is a minimal hand-assembled structure (binary + `Info.plist` + icon). When signed and submitted to `notarytool`, notarization fails with "The binary is not signed" or "invalid Info.plist" because the bundle lacks required metadata keys (`CFBundleVersion`, `CFBundleShortVersionString`, `NSHumanReadableCopyright`, `LSApplicationCategoryType`, executable hardening flags), or because the Swift runtime libraries aren't bundled (SwiftPM builds link dynamically by default).

**Why it happens:**
The hand-rolled `Info.plist` in `script/build_and_run.sh` has only the bare minimum keys. macOS notarization requires additional keys. More critically, a `swift build` binary links against the system Swift runtime libraries (in `/usr/lib/swift`), which is fine for development but notarization may flag unsigned dylib dependencies. Additionally, `CFBundleVersion` and `CFBundleShortVersionString` must be present and parseable as valid version strings.

**How to avoid:**
1. Add `CFBundleVersion`, `CFBundleShortVersionString`, `NSHumanReadableCopyright`, and `LSApplicationCategoryType` to the generated `Info.plist`.
2. Verify the binary links statically: check with `otool -L AutomationHealth.app/Contents/MacOS/AutomationHealth | grep swift` — if there are entries, the Swift runtime is dynamically linked and must be bundled or the build must use `-static-executable`.
3. For SwiftPM static linking: add `-Xswiftc -static-executable` to `swift build` flags, OR bundle the Swift runtime dylibs using `swift package --package-path ...` with appropriate flags.
4. Run `spctl --assess -vv --type execute AutomationHealth.app` locally before submitting to notarization.
5. Check `codesign --verify --deep --strict --verbose=2 AutomationHealth.app` passes.

**Warning signs:**
- `Info.plist` missing `CFBundleVersion` or `CFBundleShortVersionString`.
- `otool -L` shows `@rpath/libswift*.dylib` for the binary.
- `notarytool submit` returns "Invalid" with log mentioning "The binary is not signed" or "The signature is not valid."
- The app works when launched via `open` but fails Gatekeeper verification (`spctl -a`).

**Phase to address:**
Phase 14 (Codesigning and notarization) — must include `Info.plist` hardening and linking verification before signing.

---

### Pitfall 8: DMG Creation Breaks Code Signature

**What goes wrong:**
The signed `.app` bundle is placed into a DMG using `hdiutil create -srcfolder`, but the resulting DMG mount point is writable and the Finder modifies `.DS_Store` or resource fork data inside the `.app` bundle during DMG creation or testing. This invalidates the code signature. Users downloading the DMG see a "damaged" warning from Gatekeeper.

**Why it happens:**
DMG creation with `hdiutil` preserves the source folder contents, but if the source `.app` was previously mounted or opened by Finder, macOS may have written `.DS_Store`, extended attributes, or Spotlight metadata into the bundle. Even after signing, opening the app to "test" before DMG creation dirties the signature. The DMG itself must also be signed with a Developer ID Installer certificate for notarization.

**How to avoid:**
1. Sign the `.app` as the absolute last step before DMG creation — never open or test the signed app.
2. Use a clean build output directory (`dist/signed/`) that is created fresh each time.
3. Create the DMG using `hdiutil create -fs HFS+ -srcfolder dist/signed -volname "Automation Health" dist/AutomationHealth.dmg`.
4. Sign the DMG with `codesign -s "Developer ID Application: ..." dist/AutomationHealth.dmg`.
5. Notarize the DMG (not the .app) using `notarytool submit dist/AutomationHealth.dmg`.
6. Staple the notarization ticket to the DMG: `xcrun stapler staple dist/AutomationHealth.dmg`.
7. Verify with `spctl --assess -vv --type open dist/AutomationHealth.dmg`.

**Warning signs:**
- Testing the signed `.app` by double-clicking it before DMG packaging.
- `codesign -vvv dist/AutomationHealth.app` returning `code object is not signed at all` after DMG extraction.
- Finder `.DS_Store` files visible in `ls -la dist/AutomationHealth.app/Contents/`.
- DMG itself not signed or notarized — Gatekeeper flags unsigned disk images.

**Phase to address:**
Phase 14 (Codesigning and notarization) and Phase 13 (Release process) — DMG packaging must be part of the release script, not a manual step.

---

### Pitfall 9: GitHub Release Asset Upload Timeout For Large DMG

**What goes wrong:**
The notarized + stapled DMG is uploaded to a GitHub Release via `gh release upload`, but the upload fails with a timeout or 422 error because the DMG exceeds GitHub's file size limits or the upload connection is terminated mid-transfer.

**Why it happens:**
GitHub Release assets have a **2 GB per-file limit**. A DMG containing a SwiftPM-built app with bundled Swift runtime libraries can reach 50-200 MB, which is well under 2 GB. More commonly, the issue is upload timeout: `gh release upload` uses the HTTP endpoint which can time out on slow connections. The 422 error occurs when the `upload_url` hypermedia token from the Release creation expires (tokens are short-lived).

**How to avoid:**
1. Use `gh release create` with the `--generate-notes` flag and attach the asset in the same command: `gh release create v1.2.0 dist/AutomationHealth.dmg --title "Automation Health v1.2" --generate-notes`.
2. Verify DMG size is under 2 GB (for this project it's <100 MB — not a concern).
3. If using the API directly (not `gh` CLI), GET the `upload_url` from the Release creation response and POST the asset immediately — the token expires quickly.
4. Add a `--verify` step: after upload, `gh release view v1.2.0` and confirm the asset is listed with correct size and download URL.

**Warning signs:**
- `gh release upload` returning 422 with "Problems parsing JSON" (expired token).
- Upload succeeds but the download URL returns 404 (asset not fully processed).
- DMG size shown as 0 bytes on the release page (corrupted upload).

**Phase to address:**
Phase 13 (Release process) — the release script must atomically create the release + upload assets + verify.

---

### Pitfall 10: MIT LICENSE Already Exists — But Copyright Attribution Is Generic

**What goes wrong:**
The existing `LICENSE` file says `Copyright (c) 2026 Automation Health contributors` — this is legally ambiguous. "Automation Health contributors" is not a legal entity. In a dispute, it's unclear who holds copyright. For an OSS project accepting external contributions, this is acceptable if a CLA or DCO is in place, but `CONTRIBUTING.md` should reference it.

**Why it happens:**
The MIT License template was filled in with the project name placeholder during Phase 4. This was correct for v1.1 when no individual copyright holder was identified. For a signed/notarized release with a real Developer ID tied to an individual or organization, the copyright holder should be explicit.

**How to avoid:**
This is a **LOW severity** item for v1.2. The LICENSE as-is is valid and the MIT terms are clear. If a specific legal entity (individual or LLC) holds the Developer ID, consider updating the copyright line to that entity. Otherwise, the current wording is standard for community OSS projects. The real requirement is that `LICENSE` is committed (it already is) and referenced in `README.md` (it already is).

**Warning signs:**
- None critical for v1.2. This was already done in v1.1 Phase 4.
- If the Developer ID certificate is held by an LLC, update `Copyright (c) 2026 [LLC Name]`.

**Phase to address:**
Already addressed in Phase 4. No new LICENSE work needed beyond verifying it's present in the v1.2 release commit.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using `@AppStorage` directly in every View instead of a single `PreferencesStore` | Faster to wire up, no new class needed | String-key drift across files, no compile-time key validation, hard to add migration logic, impossible to test without running the app | Never for >3 preferences; fine for a single-view prototype |
| Putting `SidebarGroupingMode.defaultMode` as a raw enum string in `@AppStorage` without a migration path | One-line persistence | Adding a new mode renumbers/reorders the enum; old persisted values silently map to wrong modes or nil | Only if you're certain the enum will never change — not the case here |
| Using `onKeyPress(.characters)` to capture letters for jump-to-letter | Simple implementation | Captures all keystrokes globally when the view is focused, including text entry in search field; eats standard type-to-select in List | Never in a view that coexists with a search field |
| Using `codesign --deep` to sign the entire .app bundle | One command instead of signing nested items individually | Applies same entitlements to every code item; signs code in unexpected locations; Apple explicitly warns against this (see Quinn's DevForums post) | Acceptable only if the app has zero nested code and zero entitlements |
| Creating DMG from the same .app used for testing | Avoids a clean-rebuild step | Finder `.DS_Store` and extended attributes invalidate the code signature | Never — always build fresh for release |
| Hardcoding the Developer ID certificate name in the release script | Simple, works on the dev machine | Script breaks on CI, on a different Mac, or when the certificate is renewed | Never — use CI secrets + `security find-identity` to discover it dynamically |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `UserDefaults` (direct or via `@AppStorage`) | Using `UserDefaults.standard` in both the main app and a self-test executable target — they share the same domain and tests pollute real preferences | Use `UserDefaults(suiteName:)` in the app with a unique suite name (e.g., `UserDefaults(suiteName: "org.automationhealth.preferences")`); tests use a different suite or `UserDefaults.standard` with teardown |
| `notarytool` | Submitting the `.app` directly — Apple requires a `.pkg`, `.dmg`, or `.zip` container for notarization | Package the signed `.app` into a `.dmg` or `.zip`, then submit the container |
| `gh release` CLI | Using `gh release create` without `--generate-notes` produces an empty release body; using `gh release upload` separately can fail if the release creation token expired | Use `gh release create TAG ASSET --generate-notes --title "..."` as a single atomic command |
| `Process` (launchctl invocation) | Assuming `/bin/launchctl` exists at the same path on all macOS versions — it moved in some betas | Use `/usr/bin/env launchctl` or resolve via `ProcessInfo.processInfo.environment["PATH"]` |
| `codesign` | Using `--deep` flag — applies same signing options to nested code incorrectly | Sign each nested executable/framework individually from the inside out (leaf → parent) |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Computing `SidebarJobSection.sections(for:groupingMode:collapseState:hasSearchQuery:)` on every `body` invocation | UI stutter when switching grouping mode with 500+ jobs; scrolling lag because sections recomputed on hover state changes | Memoize sections using `@State` or compute in `JobStore` and publish as `@Published`; only recompute when `jobs`, `searchText`, `groupingMode`, or `collapseState` change | ~200 jobs |
| `SidebarJobSummary` subtitle format in `groupDefinitions` does `joined(separator:)` on every row | Slow scroll on large inventories | Precompute all subtitles once per grouping mode change and store in the summary | ~500 jobs visible |
| `SidebarTriggerClassifier.kind(for:)` does string lowercasing and contains-checks for every row on every grouping change | Grouping mode switch pauses UI | Cache trigger kind in `JobPresentation` on creation, not recomputed on grouping change | ~300 jobs |
| `UserDefaults.synchronize()` (legacy) or frequent writes | Unnecessary disk I/O, especially in tight loops during scan | Use `@AppStorage` setter (doesn't call synchronize); batch writes in a `PreferencesStore.setBatch()` method | Already avoided by using `@AppStorage` which doesn't call `synchronize()` |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Committing `.p12` certificate file to repository | Anyone with repo access can sign malware with project's Developer ID; certificate revocation destroys release pipeline | Store in CI secrets, import ephemerally in workflow, delete temporary keychain after signing |
| Logging `notarytool --password` in CI output | Apple ID app-specific password exposed in public CI logs | Use `echo "::add-mask::$NOTARY_PASSWORD"` in GitHub Actions; pass via `--password` stdin or environment variable |
| Shipping the app with `com.apple.security.get-task-allow` entitlement in a distribution build | Allows any process to attach a debugger to the distributed app, bypassing code integrity | Only include `get-task-allow` in Debug builds; strip from Release/notarized builds |
| Not verifying code signature after DMG extraction | Users download a DMG that mounts a "damaged" app with broken signature | Add `spctl --assess -vv` verification step to CI after DMG creation and extraction |
| Persisting `SidebarCollapseState` to UserDefaults without encryption | Collapse state is non-sensitive — this is fine | Document that preferences are stored plaintext in `~/Library/Preferences/` and are non-sensitive |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Keyboard shortcuts not discoverable — no menu items or help text showing available shortcuts | Users don't know shortcuts exist, feel the app is mouse-only | Add each shortcut action to the `CommandMenu` (automatically shows the shortcut beside the menu item); list shortcuts in the app's Help menu |
| Focus search (`Cmd-Shift-F`) moves focus to the search field but the sidebar loses `@FocusState` and arrow key navigation silently stops working | User types search, wants to arrow-down through results, nothing happens — confused | After setting focus to search field, on `Escape` or `Tab`, restore focus to `.jobList`; test the focus → search → navigate → focus cycle |
| Expand/collapse all changes the currently selected job's position, causing the detail view to jump to a different automation | User collapses groups to declutter, but loses their place | After expand/collapse all, preserve `selectedJobID` and scroll to it; if it's now hidden (in a collapsed group), auto-expand that group |
| Grouping mode switch resets collapse state | User carefully collapses sections in "Source" mode, switches to "Health" to check something, switches back — all sections re-expanded | Associate collapse state with `SidebarSectionID(groupingMode:, groupKey:)` — which the existing `SidebarCollapseState` already does correctly. Verify this works across mode switches. |
| Preference reset (e.g., via `defaults delete`) silently resets grouping to `.source` but doesn't notify the user | User's custom grouping disappears after system maintenance or accidental defaults reset | `defaultMode` is `.source`, which is a safe fallback. No notification needed for a scanner tool. |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Persistence:** Grouping mode stored in UserDefaults — but verify the key is the same string in ALL files that read/write it (grep `@AppStorage("grouping`).
- [ ] **Persistence:** Collapse state stored — but verify `SidebarCollapseState` round-trips through `JSONEncoder`/`JSONDecoder` correctly (custom Codable conformance for `Set<SidebarSectionID>`).
- [ ] **Grouping modes:** Schedule-based mode works — but verify Candidate and Manual records don't appear in schedule buckets (confidence gate exists).
- [ ] **Keyboard shortcuts:** Arrow keys navigate — but verify they still work after focus moves to search field and back (focus restoration).
- [ ] **Keyboard shortcuts:** Jump-to-letter works — but verify it doesn't capture letters when the search field is active (`.onKeyPress` gated on `focusedTarget == .jobList`).
- [ ] **Codesigning:** Binary is signed — but verify `otool -L` shows no dynamic Swift runtime dependencies and `codesign --verify --deep --strict` passes.
- [ ] **Notarization:** `notarytool submit` returns "Accepted" — but verify the stapler ran and `spctl --assess` passes on the DMG.
- [ ] **DMG:** DMG mounts and app launches — but verify code signature is intact after extraction (`codesign -vvv` on the extracted app).
- [ ] **Release:** GitHub Release created with DMG asset — but verify the download URL works and the DMG downloads as the correct size.
- [ ] **Privacy:** No real paths in public docs — but verify `docs/release-process.md` uses placeholder identifiers like `$DEVELOPER_ID` and `$TEAM_ID`.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| @AppStorage key collision or silent type fallback | LOW | `defaults delete org.automationhealth.AutomationHealth` then restart app; preferences reset to defaults — acceptable for this app's scope |
| Grouping mode staleness after refresh | LOW | User switches grouping mode again (menu is still responsive); next scan fix |
| Evidence boundary violation in schedule-based grouping | MEDIUM | Fix the confidence gate, rebuild, rinse and repeat — no data corruption, only misleading display |
| Keyboard shortcut conflict with system | LOW | Remove the conflicting shortcut, update docs — low impact for a developer tool |
| Hardened Runtime blocks launchctl | MEDIUM | Add entitlement, re-sign, re-notarize — same bundle, no user data loss |
| Secret leaked in CI log | HIGH | Revoke certificates, rotate Apple ID password, generate new app-specific password, update CI secrets, re-sign and re-notarize release |
| Notarization failure from incomplete bundle structure | MEDIUM | Fix Info.plist, re-build, re-sign, re-submit — no downstream impact since release wasn't published yet |
| DMG code signature breakage | LOW | Recreate DMG from signed .app, re-sign DMG, re-staple — < 5 minutes if the signed .app is preserved |
| GitHub Release asset upload timeout | LOW | Re-run `gh release upload` or re-create the release — idempotent, no data loss |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| @AppStorage string-key fragility | Phase 10 (Preferences) | Self-test: round-trip write/read for every preference key |
| Grouping mode staleness | Phase 10 (Preferences) | Self-test: change mode during simulated scan, verify sections match |
| Evidence boundary violation | Phase 11 (Grouping modes) | Self-test: Candidate/Manual records always in "No evidence" bucket |
| Keyboard shortcut conflicts | Phase 12 (Keyboards shortcuts) | Manual: test every shortcut against Apple HIG list |
| Hardened Runtime entitlement missing | Phase 14 (Codesigning) | Verification: `launchctl` scan works on signed Release binary |
| Developer ID secret leakage | Phase 13 (Release process) | CI: verify no secrets in workflow logs after release run |
| Notarization failure — bundle structure | Phase 14 (Codesigning) | CI: `spctl --assess` and `notarytool submit --wait` in release pipeline |
| DMG breaks code signature | Phase 14 (Codesigning) | CI: extract DMG, verify app signature, run self-test |
| GitHub Release upload timeout | Phase 13 (Release process) | Manual: verify asset on release page after creation |
| MIT LICENSE copyright ambiguity | Already addressed | Verify LICENSE exists in v1.2 tag |

## Sources

### Official Apple Documentation
- [AppStorage Property Wrapper](https://developer.apple.com/documentation/swiftui/appstorage) — String-key based, no compile-time validation, limited type support. HIGH confidence.
- [onKeyPress and keyboardShortcut](https://developer.apple.com/documentation/swiftui/view-input-and-events) — Focus-gated key handling; global shortcuts via CommandMenu. HIGH confidence.
- [Creating Distribution-Signed Code for macOS](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac) — Replaces Quinn's DevForums post; inside-out signing order, `--deep` danger, entitlements. HIGH confidence.
- [Notarizing macOS Software Before Distribution](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution) — `notarytool` workflow, stapler, common notarization issues. HIGH confidence.
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime) — Entitlement requirements, default restrictions. HIGH confidence.

### Apple Developer Forums
- [Creating Distribution-Signed Code for Mac](https://developer.apple.com/forums/thread/701514) — Quinn's definitive guide: `--deep` is harmful, signing order matters, entitlements per-executable. HIGH confidence.
- [Resolving Common Notarization Issues](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/resolving_common_notarization_issues) — `get-task-allow` in distribution builds, invalid Info.plists, missing secure timestamps. HIGH confidence.

### Community and Third-Party Sources
- [@AppStorage Explained and Replicated for a Better Alternative](https://www.avanderlee.com/swift/appstorage-explained/) — Antoine van der Lee: string-key fragility, no key discovery, no compile-time validation. HIGH confidence.
- [Notarize a Command Line Tool with notarytool](https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/) — Scripting OS X: practical `notarytool` + `stapler` + `spctl` workflow for SPM tools. MEDIUM confidence (2021, but `notarytool` API is stable).
- [GitHub REST API: Releases](https://docs.github.com/en/rest/releases/releases) — Asset upload limits, release creation endpoints. HIGH confidence.

### Project Codebase Evidence
- `Sources/AutomationHealthCore/JobPresentation.swift` — Existing `SidebarGroupingMode` (5 modes), `SidebarCollapseState`, `SidebarTriggerClassifier`, `SidebarNavigation`. Confidence/HIGH.
- `Sources/AutomationHealth/Views/ContentView.swift` — `@State private var sidebarGroupingMode` and `sidebarCollapseState` — no persistence. Confidence/HIGH.
- `Sources/AutomationHealth/Views/SidebarView.swift` — `.onKeyPress(.downArrow)` / `.onKeyPress(.upArrow)`, `@FocusState` for jobList. Confidence/HIGH.
- `Sources/AutomationHealth/App/AutomationHealthApp.swift` — `Command-r` shortcut via `CommandMenu`. Confidence/HIGH.
- `script/build_and_run.sh` — Minimal `Info.plist`, no signing, no entitlements, no DMG. Confidence/HIGH.
- `LICENSE` — MIT License with "Automation Health contributors" copyright. Confidence/HIGH.
- `.planning/RETROSPECTIVE.md` — v1.1 commit hygiene lessons: atomic per-phase commits, `git status --porcelain` clean gate. Confidence/HIGH.

### Forensics and Retrospective
- `.planning/forensics/report-20260510-214900.md` — v1.1 suffered 11 uncommitted plans due to pre-existing dirty tree bypassing auto-commit. The "clean git status gate" is critical for v1.2 release quality. Confidence/HIGH.
- `.planning/codebase/CONCERNS.md` — Development app bundle is unsigned and unsandboxed; launchctl parsing is regex-based and fragile; DateFormatter allocation on every JobPresentation. Confidence/HIGH.

---
*Pitfalls research for: Automation Health v1.2 — preferences, grouping, shortcuts, distribution*
*Researched: 2026-05-10*
