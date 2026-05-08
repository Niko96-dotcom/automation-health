# Codebase Concerns

**Analysis Date:** 2026-05-08

## Tech Debt

**Executable self-test instead of SwiftPM tests:**
- Issue: The project verifies behavior through the executable target `ActiveJobsCoreSelfTest` instead of a SwiftPM `.testTarget`; `swift test` reports no tests.
- Files: `Package.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`, `script/test.sh`, `script/ci.sh`
- Impact: Standard Swift tooling, IDE test discovery, coverage reporting, and per-test reporting are unavailable; failures terminate with `fatalError` instead of structured test diagnostics.
- Fix approach: Add a `testTarget` in `Package.swift`, move assertions from `Sources/ActiveJobsCoreSelfTest/main.swift` into XCTest or Swift Testing files under `Tests/ActiveJobsCoreTests`, and make `script/test.sh` run `swift test`.

**All-or-nothing inventory refresh:**
- Issue: `JobInventory.refresh()` calls `try scanners.flatMap { try $0.scan() }`, so any scanner failure aborts the whole refresh.
- Files: `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`
- Impact: A malformed Hermes jobs file or unreadable launchd directory can suppress otherwise valid jobs from other sources and leave the UI with only a generic `error.localizedDescription`.
- Fix approach: Return a typed scan result per source, keep partial successes, and surface per-source diagnostics in `JobStore` while preserving the last successful list when only one source fails.

**Unchecked Sendable scanner implementations:**
- Issue: `LaunchAgentScanner` and `HermesCronScanner` use `@unchecked Sendable` while storing a `FileManager` instance and are executed from `Task.detached`.
- Files: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`
- Impact: The compiler is not proving scanner thread-safety, so future mutable scanner state or custom `FileManager` use can introduce data races without warnings.
- Fix approach: Avoid stored non-value collaborators where possible, inject lightweight filesystem protocols that are explicitly `Sendable`, or run scanning through a dedicated actor instead of relying on unchecked conformance.

**LaunchAgent relevance is hard-coded to personal keywords:**
- Issue: `shouldShowRunAtLoadJob` includes `RunAtLoad` and `KeepAlive` jobs only when label or command text matches a fixed keyword list.
- Files: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `docs/scheduled-job-sources.md`
- Impact: Valid personal automations can be hidden when they do not contain terms like `hermes`, `niko`, `python`, or `script`; unrelated jobs can appear if they match one keyword accidentally.
- Fix approach: Replace the keyword gate with configurable source filters, explicit include/exclude settings, or a broader classification rule that is documented and test-covered.

**CI toolchain is not pinned:**
- Issue: GitHub Actions uses `macos-latest` and prints whatever Swift version is present on the runner.
- Files: `.github/workflows/ci.yml`, `Package.swift`, `script/ci.sh`
- Impact: SwiftPM, Swift 6 diagnostics, and macOS SDK behavior can change as the hosted runner image changes, causing build drift outside repository control.
- Fix approach: Pin the GitHub Actions macOS image to a known version and record the expected Swift/Xcode version in `docs/development.md` or CI setup.

## Known Bugs

**CI gate fails on date-relative humanization:**
- Symptoms: `./script/ci.sh` builds successfully, then exits with `Trace/BPT trap: 5` from `ActiveJobsCoreSelfTest` with `Expectation failed: tomorrow next run`.
- Files: `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`, `script/test.sh`, `script/ci.sh`
- Trigger: `JobHumanizer.relativeRunDescription(for:relativeTo:)` accepts a `relativeTo` date but uses `Calendar.current.isDateInToday`, `isDateInTomorrow`, and `isDateInYesterday`, which compare against the actual system date before using the injected `now`.
- Workaround: Run the self-test only when the actual system date makes the fixture dates line up, or change `relativeRunDescription` to calculate today, tomorrow, and yesterday from the injected `relativeTo` value.

**Search can show details for a job hidden by the active filter:**
- Symptoms: The sidebar list is filtered by `searchText`, but the detail pane still renders `store.selectedJob` from the unfiltered full job list.
- Files: `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`
- Trigger: Select a job, enter a search query that excludes it, and the detail view can continue displaying the previously selected job even though it is absent from the visible sidebar results.
- Workaround: Clear or update `selectedJobID` when the filtered result set changes, or derive the detail selection from `filteredJobs`.

**Large UTF-8 log snippets can disappear when the byte offset splits a scalar:**
- Symptoms: `TextSnippetReader.read(url:)` returns `nil` when `String(data:encoding:)` cannot decode the last 24 KB slice.
- Files: `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`
- Trigger: A large log or markdown output file contains multibyte UTF-8 near the arbitrary tail offset, so the slice starts in the middle of a scalar.
- Workaround: Decode with a lossy or boundary-aware strategy, or advance the offset until a valid UTF-8 boundary is found before constructing `String`.

## Security Considerations

**Sensitive automation content is displayed without redaction:**
- Risk: Commands, plist paths, Hermes prompts, scripts, and latest output snippets may contain tokens, passwords, private paths, or personal data and are rendered selectable in the UI.
- Files: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`, `Sources/AutomationHealth/Views/DetailView.swift`
- Current mitigation: The app is local and read-only, and output snippets are capped at 24 KB by `TextSnippetReader`.
- Recommendations: Add redaction for common secret patterns before building `JobPresentation`, mark unredacted views clearly, and add tests for token-like strings in commands and logs.

**Development app bundle is unsigned and unsandboxed:**
- Risk: `script/build_and_run.sh` creates a local `.app` bundle manually with no signing, hardened runtime, sandbox entitlement review, or notarization path.
- Files: `script/build_and_run.sh`, `Package.swift`, `docs/development.md`
- Current mitigation: Documentation presents the bundle as a local development artifact under ignored `dist/`.
- Recommendations: Before distribution, add a release packaging path with code signing, notarization, entitlement review, and explicit privacy notes for scanned local files.

**System command execution depends on labels from local plists:**
- Risk: The launchd scanner invokes `/bin/launchctl print` for labels read from plist files; a future change that switches from `Process.arguments` to shell execution would create command-injection risk.
- Files: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`
- Current mitigation: The current implementation uses `Process.executableURL` plus an argument array and does not invoke a shell.
- Recommendations: Keep launchctl invocation shell-free, add tests around unusual labels, and isolate the status reader behind a small interface.

**Secret files are ignored but not otherwise managed:**
- Risk: Local `.env` files are ignored by git, but the codebase has no redaction policy for automation outputs that may contain equivalent secrets.
- Files: `.gitignore`, `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`, `Sources/AutomationHealth/Views/DetailView.swift`
- Current mitigation: `.gitignore` excludes `.env`, `.env.*`, logs, `.build/`, and `dist/`.
- Recommendations: Treat scanned job output as sensitive input and redact before UI rendering, screenshots, logs, or future export features.

## Performance Bottlenecks

**Launchd scanning starts a synchronous subprocess per plist:**
- Problem: Each parsed launchd job calls `LaunchctlStatusReader.status`, which can run two blocking `launchctl print` subprocesses and waits without a timeout.
- Files: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`
- Cause: Parsing and status lookup are coupled, and `Process.waitUntilExit()` is called for each label during refresh.
- Improvement path: Batch status collection where possible, add a timeout, cache recent status results, and make runtime status optional so plist parsing can complete even when launchctl is slow.

**Hermes output lookup scans every markdown file for each job:**
- Problem: `latestOutput(for:)` lists all files in a job output directory, reads metadata for each markdown file, and picks the newest by modification date.
- Files: `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`
- Cause: There is no index or filename-based shortcut for latest output selection.
- Improvement path: Use Hermes metadata if available, rely on timestamped filenames when trustworthy, or cap the number of files inspected in very large output directories.

**DateFormatter allocation occurs during presentation for every job:**
- Problem: `JobHumanizer` creates new `DateFormatter` instances in `timeString`, `weekdayString`, and `dateString` while `JobPresentation` computes display fields for every scanned job.
- Files: `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`
- Cause: Formatter construction is inside helper functions instead of cached static formatter configuration.
- Improvement path: Reuse static formatters or `FormatStyle` values and keep timezone/locale behavior explicit.

## Fragile Areas

**Health classification depends on display text:**
- Files: `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`
- Why fragile: `staleThreshold` checks substrings in `humanScheduleDescription`, so changing user-facing schedule wording can change health behavior.
- Safe modification: Split schedule parsing into a structured schedule type and derive both display text and stale thresholds from that type.
- Test coverage: The self-test covers a small set of health summaries in `Sources/ActiveJobsCoreSelfTest/main.swift`; it does not cover wording changes, weekly schedules, monthly schedules, or unusual launchd calendar dictionaries.

**Launchctl output parsing is regex-based against command text:**
- Files: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`
- Why fragile: `LaunchctlStatusReader.firstMatch` expects strings like `state = ...` and `last exit code = ...`; output format changes or localization can silently convert status into `nil`.
- Safe modification: Keep launchctl parsing isolated, add sample-output fixtures, and treat runtime status as best-effort metadata separate from parsed job definitions.
- Test coverage: No self-test covers `LaunchctlStatusReader` because live process execution is embedded in `LaunchAgentScanner`.

**SwiftUI detail view mixes UI layout, AppKit bridge, and file reveal behavior:**
- Files: `Sources/AutomationHealth/Views/DetailView.swift`
- Why fragile: `DetailView.swift` is the largest source file and contains status cards, text rendering, `NSViewRepresentable` log display, health pill, technical details, and `NSWorkspace` file reveal behavior.
- Safe modification: Extract the AppKit log viewer and technical details controls into focused files before adding editing, export, or redaction behavior.
- Test coverage: No UI tests or view-model tests cover `ReadOnlyLogTextView`, accessibility labels, or reveal-path behavior.

**Refresh task cannot be cancelled from the UI:**
- Files: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`
- Why fragile: `JobStore.refresh()` stores no task handle and disables refresh while scanning; a hung launchctl subprocess keeps `isScanning` true until the detached task returns.
- Safe modification: Store the refresh task, add cancellation, and pass timeout/cancellation checks into scanner operations.
- Test coverage: No tests cover concurrent refresh requests, cancellation, scanner hangs, or UI recovery after a failed refresh.

## Scaling Limits

**Launchd capacity is bounded by local plist count and subprocess latency:**
- Current capacity: The scanner walks `~/Library/LaunchAgents`, `/Library/LaunchAgents`, and `/Library/LaunchDaemons` in-process.
- Limit: Refresh latency grows with plist count and can approach two `launchctl` invocations per parsed job.
- Scaling path: Separate definition scanning from runtime status enrichment, cap or parallelize status lookups carefully, and display partial results as they arrive.
- Files: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/JobScanning.swift`

**Hermes output capacity is bounded by per-job output directory size:**
- Current capacity: The scanner lists one output directory per Hermes job and inspects markdown file metadata.
- Limit: Jobs with many historical markdown outputs cause repeated filesystem metadata reads on each refresh.
- Scaling path: Use job metadata for latest output, persist a small cache keyed by job id and directory modification date, or limit historical file inspection.
- Files: `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`

**UI state is a single in-memory list:**
- Current capacity: `JobStore` publishes the full `[JobPresentation]` array and `ContentView` filters it synchronously for search.
- Limit: Very large job lists can make refresh and search recompute all presentation fields and `searchText` strings at once.
- Scaling path: Keep the current approach for small local inventories, but move to incremental updates or indexed search before adding high-volume sources.
- Files: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`

## Dependencies at Risk

**`/bin/launchctl` output format is an implicit dependency:**
- Risk: Runtime state and last exit code depend on parsing command output text, not a stable Swift API.
- Impact: State can silently fall back to `loaded`, and last exit code can disappear without scan failure.
- Migration plan: Encapsulate the status reader behind an injectable protocol, add fixture tests for known output variants, and keep UI copy honest that status is best-effort.
- Files: `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `docs/scheduled-job-sources.md`

**GitHub Actions image updates can change Swift behavior:**
- Risk: `macos-latest` changes over time and can alter the Swift compiler, SDK, and default macOS behavior used by CI.
- Impact: Builds or self-tests can fail without a source change in `Sources/` or `Tests/`.
- Migration plan: Pin the runner image or install a specific Xcode toolchain in `.github/workflows/ci.yml`.
- Files: `.github/workflows/ci.yml`, `Package.swift`, `script/ci.sh`

**Third-party package dependency risk is minimal:**
- Risk: No external Swift package dependencies are declared, so there is no Swift package supply-chain surface.
- Impact: Dependabot only checks GitHub Actions; dependency drift risk is concentrated in hosted CI images and system tools.
- Migration plan: If packages are added, commit `Package.resolved`, add Dependabot Swift package updates, and document dependency review expectations.
- Files: `Package.swift`, `.github/dependabot.yml`

## Missing Critical Features

**Unsupported scheduler sources leave blind spots:**
- Problem: The app does not scan Shortcuts personal automations, Calendar alarms, Reminders, user or root crontabs outside Hermes, `at` jobs, rich Homebrew services metadata, third-party scheduler databases, or cloud schedulers.
- Blocks: The app cannot serve as a complete automation health dashboard for users whose scheduled work lives outside launchd and Hermes cron.
- Files: `docs/scheduled-job-sources.md`, `README.md`, `Sources/ActiveJobsCore/Services/JobScanning.swift`

**No partial diagnostics model:**
- Problem: Scanner errors are reduced to one `errorMessage` string in `JobStore`.
- Blocks: The UI cannot show that launchd succeeded while Hermes failed, cannot list skipped unreadable files, and cannot explain parse failures per job source.
- Files: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/ActiveJobsCore/Services/JobScanning.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`

**No timeout or cancellation controls:**
- Problem: Long-running filesystem reads and launchctl calls have no user-facing cancel path and no scanner-level timeout.
- Blocks: The refresh button can remain disabled during a stalled scan.
- Files: `Sources/AutomationHealth/Stores/JobStore.swift`, `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`

**No privacy mode or redacted export path:**
- Problem: The app displays local commands, file paths, prompts, and output text but has no mode for hiding sensitive fields.
- Blocks: Safe screenshots, support reports, or future export/share features.
- Files: `Sources/AutomationHealth/Views/DetailView.swift`, `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`

## Test Coverage Gaps

**No SwiftPM test target:**
- What's not tested: `swift test` cannot discover or run tests because `Package.swift` declares no `.testTarget`, and `Tests/ActiveJobsCoreTests` contains no test files.
- Files: `Package.swift`, `Tests/ActiveJobsCoreTests`, `Sources/ActiveJobsCoreSelfTest/main.swift`, `script/test.sh`
- Risk: CI depends on an executable self-test with unstructured `fatalError` assertions, and standard coverage tooling is unavailable.
- Priority: High

**Date and timezone behavior is under-specified:**
- What's not tested: Relative date descriptions against injected `now` values across actual system dates, time zones, daylight saving transitions, and calendar boundaries.
- Files: `Sources/ActiveJobsCore/Support/JobHumanizer.swift`, `Sources/ActiveJobsCoreSelfTest/main.swift`, `script/test.sh`
- Risk: User-facing labels and health summaries can change based on the machine date rather than fixture or scan time.
- Priority: High

**Scanner failure paths are not covered:**
- What's not tested: Malformed Hermes JSON, unreadable launchd directories, unreadable plists, invalid plist schemas, failed `launchctl`, slow `launchctl`, and partial source failures.
- Files: `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/JobScanning.swift`
- Risk: One bad file or system command behavior can break refresh in ways that CI does not catch.
- Priority: High

**UI and store behavior are not tested:**
- What's not tested: Search/selection interaction, refresh state transitions, error message display, accessibility labels, log text rendering, and file reveal behavior.
- Files: `Sources/AutomationHealth/Views/ContentView.swift`, `Sources/AutomationHealth/Views/SidebarView.swift`, `Sources/AutomationHealth/Views/DetailView.swift`, `Sources/AutomationHealth/Stores/JobStore.swift`
- Risk: Regressions in the macOS UI can ship even when scanner self-tests pass.
- Priority: Medium

**Sensitive-output handling is not tested:**
- What's not tested: Redaction or safe rendering for token-like strings in commands, definitions, prompts, and log snippets.
- Files: `Sources/AutomationHealth/Models/JobPresentation.swift`, `Sources/AutomationHealth/Views/DetailView.swift`, `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`
- Risk: Future screenshots, exports, or logs can expose secrets pulled from local automation output.
- Priority: Medium

---

*Concerns audit: 2026-05-08*
