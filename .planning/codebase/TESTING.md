# Testing Patterns

**Analysis Date:** 2026-05-08

## Test Framework

**Runner:**
- Custom Swift executable self-test: `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Test command wrapper: `script/test.sh`, which runs `swift run ActiveJobsCoreSelfTest`.
- Full local gate: `script/ci.sh`, which runs `swift build` and then `script/test.sh`.
- Not detected: no `.testTarget` exists in `Package.swift`; `Tests/ActiveJobsCoreTests` exists but contains no test files.

**Assertion Library:**
- Custom assertion helpers in `Sources/ActiveJobsCoreSelfTest/main.swift`: `expect(_:_:)`, `expectDatesEqual(_:_:_:)`, and `isoDate(_:)`.
- Assertions fail with `fatalError(...)` in `Sources/ActiveJobsCoreSelfTest/main.swift`; XCTest and Swift Testing assertions are not used.

**Run Commands:**
```bash
./script/test.sh                  # Run all implemented self-tests
make test                         # Makefile alias for ./script/test.sh
./script/ci.sh                    # Run swift build, then ./script/test.sh
swift run ActiveJobsCoreSelfTest  # Run the self-test executable directly
# Not detected: watch mode
# Not detected: coverage
```

**Current Command Behavior:**
- `swift test --list-tests` reports no tests because `Package.swift` has no test target and `Tests/ActiveJobsCoreTests` has no files.
- `./script/test.sh` builds `ActiveJobsCoreSelfTest` and exits with failure at `Sources/ActiveJobsCoreSelfTest/main.swift:195` with `Expectation failed: tomorrow next run`.
- The failing self-test path exercises `JobHumanizer.relativeRunDescription(for:relativeTo:)` from `Sources/ActiveJobsCore/Support/JobHumanizer.swift`.

## Test File Organization

**Location:**
- Implemented tests live in executable source at `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Placeholder SwiftPM test directory exists at `Tests/ActiveJobsCoreTests`, but no test files are present.
- No co-located `*.test.swift`, `*.spec.swift`, or `*Tests.swift` files were detected under `Sources` or `Tests`.

**Naming:**
- Test functions use `test` plus behavior description in lowerCamelCase, such as `testParsesEnabledHermesCronJobsWithLatestOutput`, `testLimitsLaunchAgentLogTailForUiResponsiveness`, and `testAggregatesAndSortsJobsByNextRunThenName` in `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Fixture helpers use descriptive type names, including `TemporaryFixture`, `StaticJobScanner`, and `ScheduledJob.fixture(...)` in `Sources/ActiveJobsCoreSelfTest/main.swift`.

**Structure:**
```
Sources/ActiveJobsCoreSelfTest/main.swift
├── top-level try test...() calls
├── test functions using temporary files and injected scanners
├── assertion/date helpers
├── TemporaryFixture
├── StaticJobScanner
└── ScheduledJob.fixture(...)
```

## Test Structure

**Suite Organization:**
```swift
try testParsesEnabledHermesCronJobsWithLatestOutput()
try testParsesLaunchAgentCalendarSchedulesAndLogTail()
try testLimitsLaunchAgentLogTailForUiResponsiveness()
try testAggregatesAndSortsJobsByNextRunThenName()
try testHumanizesSchedulesAndRunTimes()
try testHealthSummaries()

func testParsesEnabledHermesCronJobsWithLatestOutput() throws {
    let root = try TemporaryFixture()
    try root.write(relativePath: ".hermes/cron/jobs.json", contents: "...")
    let jobs = try HermesCronScanner(homeDirectory: root.url).scan()
    expect(jobs.map(\.name) == ["daily-ft-bookmarks-to-eigenwiki"], "Hermes enabled job names")
}
```

**Patterns:**
- Set up temporary filesystem fixtures with `TemporaryFixture` in `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Inject scanner roots through `HermesCronScanner(homeDirectory:)` and `LaunchAgentScanner(homeDirectory:launchAgentDirectories:)` instead of reading live user paths in tests.
- Assert normalized `ScheduledJob` fields directly with `expect(...)` in `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Keep tests synchronous and throwing; no XCTest lifecycle methods, `setUp`, or `tearDown` functions are used.

## Mocking

**Framework:** custom fakes and dependency injection

**Patterns:**
```swift
private struct StaticJobScanner: JobScanning {
    let jobs: [ScheduledJob]

    func scan() throws -> [ScheduledJob] {
        jobs
    }
}
```

**What to Mock:**
- Mock scanner dependencies through the `JobScanning` protocol in `Sources/ActiveJobsCore/Services/JobScanning.swift`.
- Use temporary directories and fixture files for filesystem-dependent scanner behavior in `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Use injected `homeDirectory`, `launchAgentDirectories`, and `fileManager` parameters in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift` and `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`.

**What NOT to Mock:**
- Do not mock `ScheduledJob` behavior when a small fixture factory in `Sources/ActiveJobsCoreSelfTest/main.swift` is enough.
- Do not read live user scheduler paths in tests; use injected paths rather than the defaults from `Sources/ActiveJobsCore/Services/JobScanning.swift`.
- UI views in `Sources/AutomationHealth/Views` are not covered by the current self-test runner, so view mocking patterns are not established.

## Fixtures and Factories

**Test Data:**
```swift
let root = try TemporaryFixture()
try root.write(
    relativePath: "Library/LaunchAgents/com.user.downloads-cleanup.plist",
    contents: """
    <plist version="1.0">
    ...
    </plist>
    """
)
```

**Location:**
- JSON, plist, and log fixtures are inline string literals inside `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Temporary files are written under `FileManager.default.temporaryDirectory` by `TemporaryFixture` in `Sources/ActiveJobsCoreSelfTest/main.swift`.
- `ScheduledJob.fixture(...)` lives in a private extension at the bottom of `Sources/ActiveJobsCoreSelfTest/main.swift`.

## Coverage

**Requirements:** None enforced. `CONTRIBUTING.md` requires updating self-test coverage when scanner, parser, presentation, or workflow behavior changes, but no numeric coverage target exists.

**View Coverage:**
```bash
Not detected
```

## Test Types

**Unit Tests:**
- Implemented as executable self-test functions in `Sources/ActiveJobsCoreSelfTest/main.swift`.
- Covered units include Hermes cron parsing, launchd plist parsing, log tail bounding, inventory sorting, schedule/run-time humanization, and health summaries.

**Integration Tests:**
- Lightweight filesystem integration patterns exist through temporary directories and real JSON/plist/log parsing in `Sources/ActiveJobsCoreSelfTest/main.swift`.
- `LaunchAgentScanner` tests avoid live LaunchAgent directories by passing `launchAgentDirectories` from the temporary fixture.

**E2E Tests:**
- Not used. No UI automation, XCUITest, or browser-style E2E framework is configured for `Sources/AutomationHealth`.

## Common Patterns

**Async Testing:**
```swift
Not detected
```

**Error Testing:**
```swift
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError("Expectation failed: \(message)")
    }
}
```

---

*Testing analysis: 2026-05-08*
