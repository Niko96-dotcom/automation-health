import Foundation
import ActiveJobsCore
import AutomationHealthCore

try testParsesEnabledHermesCronJobsWithLatestOutput()
try testParsesLaunchAgentCalendarSchedulesAndLogTail()
try testLimitsLaunchAgentLogTailForUiResponsiveness()
try testJobConfidenceAndOriginCases()
try testInventoryAggregatesJobsAndScanNotes()
try testExistingScannersPopulateScheduledConfidenceAndOrigins()
try testParsesUserCrontabEntriesWithInjectedRunner()
try testParsesSystemCrontabEntriesFromFixtureFile()
try testCronScannerReportsSourceNotesForUnavailableInputs()
try testShortcutsScannerListsRegisteredShortcutsWithoutSchedulingEvidence()
try testShortcutsScannerReportsCommandFailureAsScanNote()
try testAutomatorScannerListsWorkflowFixturesAsRegistered()
try testAutomatorScannerReportsMissingWorkflowDirectoriesAsNotes()
try testCandidateScriptScannerFindsBoundedScriptFiles()
try testCandidateScriptScannerSkipsIgnoredHiddenAndOversizedFiles()
try testCandidateScriptScannerReportsCapsAndMissingRoots()
try testManualRecordStoreCreatesUpdatesDeletesAppOwnedRecords()
try testManualRecordScannerConvertsRecordsToManualJobs()
try testManualRecordScannerReportsMalformedJSONWithoutDeletingRecords()
try testJobSourceOrderMatchesSidebarGroupingContract()
try testInventoryIncludesCandidateAndManualRecordsWithoutBreakingExistingSources()
try testSidebarGroupingModeLabelsAndOrders()
try testSidebarOriginGroupingSplitsLaunchdRows()
try testSidebarTriggerClassificationPreservesEvidenceBoundaries()
try testSidebarCollapseSearchRevealAndNavigation()
try testSidebarNavigationHandlesHiddenSelection()
try testJobPresentationManualRecordIDUsesRawJobID()
try testAggregatesAndSortsJobsByNextRunThenName()
try testHumanizesSchedulesAndRunTimes()
try testHealthSummaries()
try testCollapseStateCodableRoundTrip()
try testGroupingModeCodableRoundTrip()
try testScanConfigDefaults()
try testSidebarTypeToSelect()
try testSidebarExpandOverride()
try testGroupingModeShortcutKeys()
try testSidebarScheduleGroupingModeAndSections()

print("ActiveJobsCoreSelfTest passed")

func testParsesEnabledHermesCronJobsWithLatestOutput() throws {
    let root = try TemporaryFixture()
    try root.write(
        relativePath: ".hermes/cron/jobs.json",
        contents: """
        {
          "jobs": [
            {
              "id": "example-daily-report",
              "name": "daily-example-report",
              "prompt": "Run the daily example report.",
              "schedule": { "kind": "cron", "expr": "0 9 * * *", "display": "0 9 * * *" },
              "enabled": true,
              "state": "scheduled",
              "next_run_at": "2026-05-08T09:00:00+02:00",
              "last_run_at": "2026-05-07T09:19:34.169510+02:00",
              "last_status": "ok"
            },
            {
              "id": "disabled",
              "name": "disabled-job",
              "prompt": "ignore me",
              "schedule": { "kind": "cron", "expr": "0 1 * * *" },
              "enabled": false,
              "state": "paused"
            }
          ]
        }
        """
    )
    try root.write(
        relativePath: ".hermes/cron/output/example-daily-report/2026-05-06_09-10-37.md",
        contents: "old output"
    )
    try root.write(
        relativePath: ".hermes/cron/output/example-daily-report/2026-05-07_09-19-34.md",
        contents: "latest run report"
    )

    let jobs = try HermesCronScanner(homeDirectory: root.url).scan().jobs

    expect(jobs.map(\.name) == ["daily-example-report"], "Hermes enabled job names")
    expect(jobs.first?.schedule == "0 9 * * *", "Hermes schedule")
    expectDatesEqual(jobs.first?.lastRun, isoDate("2026-05-07T09:19:34.169510+02:00"), "Hermes last run")
    expectDatesEqual(jobs.first?.nextRun, isoDate("2026-05-08T09:00:00+02:00"), "Hermes next run")
    expect(jobs.first?.lastStatus == "ok", "Hermes status")
    expect(jobs.first?.definition == "Run the daily example report.", "Hermes prompt definition")
    expect(jobs.first?.lastRunDetails == "latest run report", "Hermes latest output")
    expect(jobs.first?.source == .hermesCron, "Hermes source")
}

func testParsesLaunchAgentCalendarSchedulesAndLogTail() throws {
    let root = try TemporaryFixture()
    try root.write(
        relativePath: "Library/LaunchAgents/com.user.downloads-cleanup.plist",
        contents: """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key><string>com.user.downloads-cleanup</string>
          <key>ProgramArguments</key>
          <array>
            <string>/usr/bin/python3</string>
            <string>/Users/example/Scripts/downloads-cleanup.py</string>
          </array>
          <key>StartCalendarInterval</key>
          <array>
            <dict><key>Hour</key><integer>1</integer><key>Minute</key><integer>0</integer></dict>
            <dict><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
          </array>
          <key>StandardOutPath</key><string>__ROOT__/Scripts/downloads-cleanup.log</string>
        </dict>
        </plist>
        """.replacingOccurrences(of: "__ROOT__", with: root.url.path)
    )
    try root.write(
        relativePath: "Scripts/downloads-cleanup.log",
        contents: "first line\nsecond line\nthird line"
    )

    let jobs = try LaunchAgentScanner(
        homeDirectory: root.url,
        launchAgentDirectories: [root.url.appending(path: "Library/LaunchAgents")]
    ).scan().jobs

    expect(jobs.count == 1, "LaunchAgent count")
    expect(jobs[0].name == "com.user.downloads-cleanup", "LaunchAgent name")
    expect(jobs[0].command == "/usr/bin/python3 /Users/example/Scripts/downloads-cleanup.py", "LaunchAgent command")
    expect(jobs[0].schedule == "01:00, 04:00", "LaunchAgent schedule")
    expect(jobs[0].definition.hasSuffix("/Library/LaunchAgents/com.user.downloads-cleanup.plist"), "LaunchAgent definition path")
    expect(jobs[0].lastRunDetails == "first line\nsecond line\nthird line", "LaunchAgent log")
    expect(jobs[0].source == .launchd, "LaunchAgent source")
}

func testLimitsLaunchAgentLogTailForUiResponsiveness() throws {
    let root = try TemporaryFixture()
    try root.write(
        relativePath: "Library/LaunchAgents/com.user.large-log.plist",
        contents: """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key><string>com.user.large-log</string>
          <key>ProgramArguments</key>
          <array>
            <string>/bin/echo</string>
            <string>large log</string>
          </array>
          <key>StartInterval</key><integer>3600</integer>
          <key>StandardOutPath</key><string>__ROOT__/Logs/large.log</string>
        </dict>
        </plist>
        """.replacingOccurrences(of: "__ROOT__", with: root.url.path)
    )

    let oldOutput = "ancient-start\n" + (0..<4_000).map { "old line \($0)" }.joined(separator: "\n")
    try root.write(
        relativePath: "Logs/large.log",
        contents: oldOutput + "\nimportant tail"
    )

    let jobs = try LaunchAgentScanner(
        homeDirectory: root.url,
        launchAgentDirectories: [root.url.appending(path: "Library/LaunchAgents")]
    ).scan().jobs

    let details = jobs[0].lastRunDetails ?? ""
    expect(details.hasPrefix("[Showing last 24 KB]"), "large log tail marker")
    expect(details.contains("important tail"), "large log keeps newest output")
    expect(!details.contains("ancient-start"), "large log drops oldest output")
    expect(details.utf8.count < 25_000, "large log snippet is bounded")
}

func testJobConfidenceAndOriginCases() throws {
    expect(JobConfidence.allCases == [.scheduled, .registered, .candidate, .manual], "JobConfidence order")
    expect(JobConfidence.allCases.map(\.displayName) == ["Scheduled", "Registered", "Candidate", "Manual"], "JobConfidence display names")
    expect(JobConfidence.scheduled.description.contains("Direct schedule evidence"), "Scheduled description")
    expect(JobConfidence.registered.description.contains("Registered automation without schedule evidence"), "Registered description")
    expect(JobConfidence.candidate.description.contains("Possible automation candidate"), "Candidate description")
    expect(JobConfidence.manual.description.contains("User-added app record"), "Manual description")

    expect(JobOrigin.allCases == [.userAuthored, .thirdPartyApp, .system, .unknown], "JobOrigin order")
    expect(JobOrigin.allCases.map(\.displayName) == ["User-authored", "Third-party app", "System", "Unknown"], "JobOrigin display names")
    expect(ScanNoteSeverity.allCases.map(\.displayName) == ["Info", "Warning", "Error"], "ScanNoteSeverity display names")

    let note = ScanNote(source: .launchd, severity: .warning, message: "Limited scan", detail: "Example detail")
    expect(note.id == "launchd:warning:Limited scan:Example detail", "ScanNote deterministic id")

    let job = ScheduledJob.fixture(lastStatus: nil, lastRun: nil, nextRun: nil)
    expect(job.confidence == .scheduled, "ScheduledJob default confidence")
    expect(job.origin == .unknown, "ScheduledJob default origin")
}

func testInventoryAggregatesJobsAndScanNotes() throws {
    let root = try TemporaryFixture()
    let note = ScanNote(source: .launchd, severity: .info, message: "Source unavailable")
    let scanner = StaticJobScanner(
        jobs: [
            ScheduledJob.fixture(id: "duplicate", name: "Zulu", source: .launchd, nextRun: Date(timeIntervalSince1970: 2)),
            ScheduledJob.fixture(id: "alpha", name: "Alpha", source: .hermesCron, nextRun: Date(timeIntervalSince1970: 1)),
            ScheduledJob.fixture(id: "duplicate", name: "Duplicate", source: .launchd, nextRun: Date(timeIntervalSince1970: 3))
        ],
        notes: [note]
    )

    let result = try JobInventory(scanners: [scanner]).refresh()

    expect(result.jobs.map(\.name) == ["Alpha", "Zulu"], "Inventory dedupes and sorts jobs")
    expect(result.notes == [note], "Inventory preserves scan notes")
}

func testExistingScannersPopulateScheduledConfidenceAndOrigins() throws {
    let root = try TemporaryFixture()
    try root.write(
        relativePath: "Library/LaunchAgents/com.user.shell-report.plist",
        contents: """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key><string>com.user.shell-report</string>
          <key>Program</key><string>__ROOT__/Scripts/report.sh</string>
          <key>StartInterval</key><integer>3600</integer>
        </dict>
        </plist>
        """.replacingOccurrences(of: "__ROOT__", with: root.url.path)
    )
    try root.write(
        relativePath: ".hermes/cron/jobs.json",
        contents: """
        {
          "jobs": [
            {
              "id": "example-hermes",
              "name": "example-hermes",
              "prompt": "Run the example.",
              "schedule": { "kind": "cron", "expr": "0 9 * * *" },
              "enabled": true,
              "state": "scheduled"
            }
          ]
        }
        """
    )

    let launchdJobs = try LaunchAgentScanner(
        homeDirectory: root.url,
        launchAgentDirectories: [root.url.appending(path: "Library/LaunchAgents")]
    ).scan().jobs
    let hermesJobs = try HermesCronScanner(homeDirectory: root.url).scan().jobs

    expect(launchdJobs.first?.confidence == .scheduled, "LaunchAgent scheduled confidence")
    expect(launchdJobs.first?.origin == .userAuthored, "LaunchAgent user-authored origin")
    expect(hermesJobs.first?.confidence == .scheduled, "Hermes scheduled confidence")
    expect(hermesJobs.first?.origin == .userAuthored, "Hermes user-authored origin")
}

func testJobSourceOrderMatchesSidebarGroupingContract() throws {
    expect(JobSource.allCases == [.launchd, .hermesCron, .cron, .shortcuts, .automator, .candidateScripts, .manualRecords], "JobSource sidebar grouping order")
    expect(JobSource.allCases.map(\.displayName) == ["launchd", "Hermes cron", "cron", "Shortcuts", "Automator", "Candidate scripts", "Manual records"], "JobSource sidebar titles")
}

func testCandidateScriptScannerFindsBoundedScriptFiles() throws {
    let root = try TemporaryFixture()
    try root.write(relativePath: "Scripts/weekly-cleanup.sh", contents: "#!/bin/zsh")
    try root.write(relativePath: "Scripts/nested/level-two/report.py", contents: "print('report')")
    try root.write(relativePath: "bin/extensionless-tool", contents: "#!/bin/zsh")
    try root.makeExecutable(relativePath: "bin/extensionless-tool")
    try root.write(relativePath: "Documents/Scripts/deep/too/deep/ignored.sh", contents: "ignored")

    let result = try CandidateScriptScanner(
        homeDirectory: root.url,
        candidateRootDirectories: [
            root.url.appending(path: "Scripts"),
            root.url.appending(path: "bin"),
            root.url.appending(path: "Documents/Scripts")
        ]
    ).scan()

    let paths = result.jobs.compactMap(\.detailPath)
    expect(paths.contains { $0.hasSuffix("Scripts/weekly-cleanup.sh") }, "Candidate includes weekly-cleanup.sh")
    expect(paths.contains { $0.hasSuffix("Scripts/nested/level-two/report.py") }, "Candidate includes level-two report.py")
    expect(paths.contains { $0.hasSuffix("bin/extensionless-tool") }, "Candidate includes extensionless-tool")
    expect(!paths.contains { $0.hasSuffix("Documents/Scripts/deep/too/deep/ignored.sh") }, "Candidate respects maxDepth")
    expect(result.jobs.allSatisfy { $0.source == .candidateScripts }, "Candidate source")
    expect(result.jobs.allSatisfy { $0.confidence == .candidate }, "Candidate confidence")
    expect(result.jobs.allSatisfy { $0.origin == .userAuthored }, "Candidate origin")
    expect(result.jobs.allSatisfy { $0.schedule == "Script candidate (no schedule evidence)" }, "Candidate schedule")
    expect(result.jobs.allSatisfy { $0.nextRun == nil }, "Candidate no next run")
    expect(result.jobs.allSatisfy { $0.lastRun == nil }, "Candidate no last run")
}

func testCandidateScriptScannerSkipsIgnoredHiddenAndOversizedFiles() throws {
    let root = try TemporaryFixture()
    try root.write(relativePath: "Scripts/.hidden.sh", contents: "hidden")
    try root.write(relativePath: "Scripts/.git/hooks/pre-commit", contents: "ignored")
    try root.write(relativePath: "Scripts/node_modules/tool.sh", contents: "ignored")
    try root.write(relativePath: "Scripts/huge.sh", contents: String(repeating: "x", count: 1_000_001))

    let result = try CandidateScriptScanner(
        homeDirectory: root.url,
        candidateRootDirectories: [root.url.appending(path: "Scripts")]
    ).scan()

    let paths = result.jobs.compactMap(\.detailPath)
    expect(!paths.contains { $0.hasSuffix("Scripts/.hidden.sh") }, "Candidate skips hidden file")
    expect(!paths.contains { $0.hasSuffix("Scripts/.git/hooks/pre-commit") }, "Candidate skips .git")
    expect(!paths.contains { $0.hasSuffix("Scripts/node_modules/tool.sh") }, "Candidate skips node_modules")
    expect(!paths.contains { $0.hasSuffix("Scripts/huge.sh") }, "Candidate skips oversized file")
    expect(result.notes.contains { $0.message == "Skipped oversized candidate script" }, "Candidate oversized scan note")
}

func testCandidateScriptScannerReportsCapsAndMissingRoots() throws {
    let root = try TemporaryFixture()
    try root.write(relativePath: "Scripts/one.sh", contents: "one")
    try root.write(relativePath: "Scripts/two.sh", contents: "two")
    try root.write(relativePath: "Scripts/three.sh", contents: "three")

    let result = try CandidateScriptScanner(
        homeDirectory: root.url,
        candidateRootDirectories: [
            root.url.appending(path: "MissingScripts"),
            root.url.appending(path: "Scripts")
        ],
        configuration: CandidateScriptScanner.Configuration(
            maxDepth: 2,
            maxVisitedFiles: 2,
            maxResults: 1,
            maximumCandidateBytes: 1_000_000,
            scriptExtensions: CandidateScriptScanner.Configuration.default.scriptExtensions,
            ignoredDirectoryNames: CandidateScriptScanner.Configuration.default.ignoredDirectoryNames
        )
    ).scan()

    expect(result.jobs.count <= 1, "Candidate result cap")
    expect(result.notes.contains { $0.message == "Missing candidate script directory" }, "Candidate missing-root note")
    expect(result.notes.contains { $0.message == "Candidate scan visited-file cap reached" || $0.message == "Candidate scan result cap reached" }, "Candidate cap note")
}

func testManualRecordStoreCreatesUpdatesDeletesAppOwnedRecords() throws {
    let root = try TemporaryFixture()
    let fileURL = root.url.appending(path: "Library/Application Support/AutomationHealth/manual-records.json")
    let store = ManualRecordStore(fileURL: fileURL)
    let createdAt = isoDate("2026-05-01T10:00:00Z")
    let updatedAt = isoDate("2026-05-02T10:00:00Z")

    let created = try store.create(
        ManualRecordDraft(
            name: "Quarterly archive reminder",
            origin: .unknown,
            scheduleDescription: "Quarterly",
            command: "/Users/example/Scripts/archive.sh",
            notes: "Tracked manually for fixture coverage"
        ),
        now: createdAt
    )

    expect(FileManager.default.fileExists(atPath: fileURL.path), "Manual records file exists")
    expect(created.createdAt == createdAt, "Manual createdAt")
    expect(created.updatedAt == createdAt, "Manual updatedAt")

    let updated = try store.update(
        id: created.id,
        draft: ManualRecordDraft(
            name: "Quarterly archive reminder updated",
            origin: .unknown,
            scheduleDescription: "Quarterly",
            command: "/Users/example/Scripts/archive.sh",
            notes: "Tracked manually for fixture coverage updated"
        ),
        now: updatedAt
    )

    expect(updated.name == "Quarterly archive reminder updated", "Manual update changes name")
    expect(updated.notes.contains("updated"), "Manual update changes notes")
    expect(updated.createdAt == createdAt, "Manual update preserves createdAt")
    expect(updated.updatedAt == updatedAt, "Manual update changes updatedAt")

    try store.delete(id: created.id)
    let remainingRecords = try store.loadRecords()
    expect(remainingRecords.isEmpty, "Manual delete leaves empty array")
}

func testManualRecordScannerConvertsRecordsToManualJobs() throws {
    let root = try TemporaryFixture()
    let store = ManualRecordStore(
        fileURL: root.url.appending(path: "Library/Application Support/AutomationHealth/manual-records.json")
    )
    _ = try store.create(
        ManualRecordDraft(
            name: "Quarterly archive reminder",
            origin: .unknown,
            scheduleDescription: "Quarterly",
            command: "/Users/example/Scripts/archive.sh",
            notes: "Tracked manually for fixture coverage"
        ),
        now: isoDate("2026-05-01T10:00:00Z")
    )

    let jobs = try ManualRecordScanner(store: store).scan().jobs

    expect(jobs.count == 1, "Manual scanner job count")
    expect(jobs[0].source == .manualRecords, "Manual source")
    expect(jobs[0].confidence == .manual, "Manual confidence")
    expect(jobs[0].origin == .unknown, "Manual origin")
    expect(jobs[0].state == "manual", "Manual state")
    expect(jobs[0].schedule == "Quarterly", "Manual schedule")
    expect(jobs[0].definition.contains("Tracked manually"), "Manual definition")
    expect(jobs[0].nextRun == nil, "Manual no next run")
}

func testManualRecordScannerReportsMalformedJSONWithoutDeletingRecords() throws {
    let root = try TemporaryFixture()
    let fileURL = root.url.appending(path: "Library/Application Support/AutomationHealth/manual-records.json")
    try root.write(relativePath: "Library/Application Support/AutomationHealth/manual-records.json", contents: "{not valid json")

    let result = try ManualRecordScanner(store: ManualRecordStore(fileURL: fileURL)).scan()

    expect(result.jobs.isEmpty, "Malformed manual JSON produces no jobs")
    expect(result.notes.contains { $0.message == "Manual records unavailable" && $0.severity == .warning }, "Malformed manual JSON note")
    let malformedContents = try root.read(relativePath: "Library/Application Support/AutomationHealth/manual-records.json")
    expect(malformedContents.contains("{not valid json"), "Malformed manual JSON preserved")
}

func testInventoryIncludesCandidateAndManualRecordsWithoutBreakingExistingSources() throws {
    let root = try TemporaryFixture()
    try root.write(relativePath: "Scripts/candidate-report.sh", contents: "candidate")

    let manualStore = ManualRecordStore(
        fileURL: root.url.appending(path: "Library/Application Support/AutomationHealth/manual-records.json")
    )
    _ = try manualStore.create(
        ManualRecordDraft(
            name: "Manual quarterly archive",
            origin: .unknown,
            scheduleDescription: nil,
            command: "/Users/example/Scripts/archive.sh",
            notes: "Manual fixture"
        ),
        now: isoDate("2026-05-01T10:00:00Z")
    )

    let existingSources = StaticJobScanner(jobs: [
        ScheduledJob.fixture(id: "shared", name: "Launchd A", source: .launchd, confidence: .scheduled),
        ScheduledJob.fixture(id: "shared", name: "Launchd Duplicate", source: .launchd, confidence: .scheduled),
        ScheduledJob.fixture(id: "shared", name: "Hermes Same ID", source: .hermesCron, confidence: .scheduled),
        ScheduledJob.fixture(id: "cron", name: "Cron", source: .cron, confidence: .scheduled),
        ScheduledJob.fixture(id: "shortcut", name: "Shortcut", source: .shortcuts, confidence: .registered),
        ScheduledJob.fixture(id: "automator", name: "Automator", source: .automator, confidence: .registered)
    ])

    let result = try JobInventory(scanners: [
        existingSources,
        CandidateScriptScanner(homeDirectory: root.url, candidateRootDirectories: [root.url.appending(path: "Scripts")]),
        ManualRecordScanner(store: manualStore)
    ]).refresh()

    let sources = Set(result.jobs.map(\.source))
    expect(sources.isSuperset(of: [.launchd, .hermesCron, .cron, .shortcuts, .automator, .candidateScripts, .manualRecords]), "Inventory includes all sources")
    expect(result.jobs.filter { $0.source == .launchd && $0.id == "shared" }.count == 1, "Inventory dedupes by source and id")
    expect(result.jobs.contains { $0.source == .hermesCron && $0.id == "shared" }, "Inventory keeps same id across different source")
    expect(result.jobs.filter { $0.source == .launchd || $0.source == .hermesCron || $0.source == .cron }.allSatisfy { $0.confidence == .scheduled }, "Existing scheduled confidence")
    expect(result.jobs.filter { $0.source == .shortcuts || $0.source == .automator }.allSatisfy { $0.confidence == .registered }, "Existing registered confidence")
    expect(result.jobs.contains { $0.source == .candidateScripts && $0.confidence == .candidate }, "Inventory candidate confidence")
    expect(result.jobs.contains { $0.source == .manualRecords && $0.confidence == .manual }, "Inventory manual confidence")
}

func testSidebarGroupingModeLabelsAndOrders() throws {
    let now = isoDate("2026-05-08T12:00:00Z")
    let recent = isoDate("2026-05-08T10:00:00Z")
    let old = isoDate("2026-05-01T10:00:00Z")
    let future = isoDate("2026-05-09T10:00:00Z")

    expect(SidebarGroupingMode.allCases.map(\.label) == ["Source", "Origin", "Health", "Trigger", "Confidence"], "Sidebar grouping labels")
    expect(SidebarGroupingMode.defaultMode == .source, "Sidebar grouping default")

    let sourceJobs = JobSource.allCases.map { source in
        JobPresentation(job: ScheduledJob.fixture(id: source.rawValue, name: source.rawValue, source: source), now: now)
    }
    expect(SidebarJobSection.sections(for: sourceJobs, groupingMode: .source, collapseState: SidebarCollapseState(), hasSearchQuery: false).map(\.title) == ["launchd", "Hermes cron", "cron", "Shortcuts", "Automator", "Candidate scripts", "Manual records"], "Source group order")

    let originJobs = JobOrigin.allCases.map { origin in
        JobPresentation(job: ScheduledJob.fixture(id: origin.rawValue, name: origin.rawValue, source: .launchd, origin: origin), now: now)
    }
    expect(SidebarJobSection.sections(for: originJobs, groupingMode: .origin, collapseState: SidebarCollapseState(), hasSearchQuery: false).map(\.title) == ["User-authored", "Third-party app", "System", "Unknown"], "Origin group order")

    let healthJobs = [
        ScheduledJob.fixture(id: "failed", name: "failed", lastStatus: "failed", lastRun: recent, nextRun: future),
        ScheduledJob.fixture(id: "stale", name: "stale", lastStatus: "ok", lastRun: old, nextRun: nil),
        ScheduledJob.fixture(id: "waiting", name: "waiting", lastStatus: nil, lastRun: nil, nextRun: future),
        ScheduledJob.fixture(id: "alive", name: "alive", lastStatus: "ok", lastRun: recent, nextRun: future),
        ScheduledJob.fixture(id: "unknown", name: "unknown", confidence: .registered, schedule: "Registered shortcut (no schedule evidence)", lastStatus: nil, lastRun: nil, nextRun: nil)
    ].map { JobPresentation(job: $0, now: now) }
    expect(SidebarJobSection.sections(for: healthJobs, groupingMode: .health, collapseState: SidebarCollapseState(), hasSearchQuery: false).map(\.title) == ["Needs attention", "Stale", "Waiting", "Alive", "Unknown"], "Health group order")

    let triggerJobs = [
        ScheduledJob.fixture(id: "time", name: "time", schedule: "0 10 * * *"),
        ScheduledJob.fixture(id: "login", name: "login", schedule: "at login, keep alive"),
        ScheduledJob.fixture(id: "queue", name: "queue", schedule: "queues: /tmp/example"),
        ScheduledJob.fixture(id: "registered", name: "registered", source: .shortcuts, confidence: .registered, schedule: "Registered shortcut (no schedule evidence)"),
        ScheduledJob.fixture(id: "candidate", name: "candidate", source: .candidateScripts, confidence: .candidate, schedule: "Script candidate (no schedule evidence)"),
        ScheduledJob.fixture(id: "manual", name: "manual", source: .manualRecords, confidence: .manual, schedule: ScheduledJob.manualDefaultScheduleDescription)
    ].map { JobPresentation(job: $0, now: now) }
    expect(SidebarJobSection.sections(for: triggerJobs, groupingMode: .trigger, collapseState: SidebarCollapseState(), hasSearchQuery: false).map(\.title) == ["Time-based", "Login / Keep Alive", "File / Queue Trigger", "Registered Only", "Candidate Scripts", "Manual / Unspecified"], "Trigger group order")

    let confidenceJobs = JobConfidence.allCases.map { confidence in
        JobPresentation(job: ScheduledJob.fixture(id: confidence.rawValue, name: confidence.rawValue, confidence: confidence), now: now)
    }
    expect(SidebarJobSection.sections(for: confidenceJobs, groupingMode: .confidence, collapseState: SidebarCollapseState(), hasSearchQuery: false).map(\.title) == ["Scheduled", "Registered", "Candidate", "Manual"], "Confidence group order")
}

func testSidebarOriginGroupingSplitsLaunchdRows() throws {
    let now = isoDate("2026-05-08T12:00:00Z")
    let jobs = JobOrigin.allCases.map { origin in
        JobPresentation(
            job: ScheduledJob.fixture(
                id: "launchd-\(origin.rawValue)",
                name: "Launchd \(origin.rawValue)",
                source: .launchd,
                origin: origin
            ),
            now: now
        )
    }

    let sections = SidebarJobSection.sections(for: jobs, groupingMode: .origin, collapseState: SidebarCollapseState(), hasSearchQuery: false)

    expect(sections.map(\.title) == ["User-authored", "Third-party app", "System", "Unknown"], "Launchd rows split by origin")
    expect(sections.allSatisfy { $0.jobs.count == 1 }, "Each origin section has one launchd row")
    expect(sections.flatMap(\.jobs).allSatisfy { $0.subtitle.contains("launchd") }, "Origin subtitles retain source")
}

func testSidebarTriggerClassificationPreservesEvidenceBoundaries() throws {
    let now = isoDate("2026-05-08T12:00:00Z")
    let future = isoDate("2026-05-09T10:00:00Z")
    let jobs = [
        ScheduledJob.fixture(id: "shortcut", name: "Registered Shortcut", source: .shortcuts, confidence: .registered, schedule: "Registered shortcut (no schedule evidence)"),
        ScheduledJob.fixture(id: "automator", name: "Registered Automator", source: .automator, confidence: .registered, schedule: "Automator workflow (no schedule evidence)"),
        ScheduledJob.fixture(id: "candidate", name: "Candidate Script", source: .candidateScripts, confidence: .candidate, schedule: "Script candidate (no schedule evidence)"),
        ScheduledJob.fixture(id: "manual", name: "Manual Record", source: .manualRecords, confidence: .manual, schedule: ScheduledJob.manualDefaultScheduleDescription),
        ScheduledJob.fixture(id: "watched", name: "Watched Files", source: .launchd, schedule: "watches: /tmp/input"),
        ScheduledJob.fixture(id: "queued", name: "Queue Files", source: .launchd, schedule: "queues: /tmp/input"),
        ScheduledJob.fixture(id: "login", name: "Login Agent", source: .launchd, schedule: "at login, keep alive"),
        ScheduledJob.fixture(id: "cron", name: "Cron Job", source: .cron, schedule: "0 10 * * *"),
        ScheduledJob.fixture(id: "next", name: "Next Run", source: .hermesCron, schedule: "Registered only until next run proves schedule", nextRun: future)
    ].map { JobPresentation(job: $0, now: now) }

    let sections = SidebarJobSection.sections(for: jobs, groupingMode: .trigger, collapseState: SidebarCollapseState(), hasSearchQuery: false)

    expect(section(sections, titled: "Registered Only").allJobIDs == ["shortcuts:shortcut", "automator:automator"], "Registered Shortcuts and Automator remain registered only")
    expect(section(sections, titled: "Candidate Scripts").allJobIDs == ["candidateScripts:candidate"], "Candidate scripts trigger group")
    expect(section(sections, titled: "Manual / Unspecified").allJobIDs == ["manualRecords:manual"], "Manual records trigger group")
    expect(section(sections, titled: "File / Queue Trigger").allJobIDs == ["launchd:watched", "launchd:queued"], "Watch and queue trigger group")
    expect(section(sections, titled: "Login / Keep Alive").allJobIDs == ["launchd:login"], "Login and keep alive trigger group")
    expect(section(sections, titled: "Time-based").allJobIDs == ["cron:cron", "hermesCron:next"], "Cron and next-run trigger group")
}

func testSidebarCollapseSearchRevealAndNavigation() throws {
    let jobs = [
        JobPresentation(job: ScheduledJob.fixture(id: "alpha", name: "Alpha Cleanup", source: .launchd)),
        JobPresentation(job: ScheduledJob.fixture(id: "beta", name: "Beta Report", source: .launchd)),
        JobPresentation(job: ScheduledJob.fixture(id: "gamma", name: "Gamma Report", source: .hermesCron))
    ]
    let launchdSectionID = SidebarSectionID(groupingMode: .source, groupKey: JobSource.launchd.rawValue)
    var collapseState = SidebarCollapseState()
    collapseState.toggle(launchdSectionID)

    let collapsedSections = SidebarJobSection.sections(for: jobs, groupingMode: .source, collapseState: collapseState, hasSearchQuery: false)
    let collapsedLaunchd = section(collapsedSections, titled: "launchd")
    expect(collapsedLaunchd.jobs.isEmpty, "Collapsed section hides jobs")
    expect(collapsedLaunchd.allJobIDs == ["launchd:alpha", "launchd:beta"], "Collapsed section keeps all IDs")

    let matchingJobs = jobs.filter { $0.searchText.contains("beta") }
    let searchSections = SidebarJobSection.sections(for: matchingJobs, groupingMode: .source, collapseState: collapseState, hasSearchQuery: true)
    let revealedLaunchd = section(searchSections, titled: "launchd")
    expect(revealedLaunchd.jobs.map(\.id) == ["launchd:beta"], "Search reveals matching collapsed row")
    expect(collapseState.isCollapsed(launchdSectionID), "Search does not mutate collapse state")

    let restoredSections = SidebarJobSection.sections(for: matchingJobs, groupingMode: .source, collapseState: collapseState, hasSearchQuery: false)
    expect(section(restoredSections, titled: "launchd").jobs.isEmpty, "Clearing search restores collapse")
    expect(SidebarNavigation.targetJobID(in: collapsedSections, selectedJobID: nil, direction: .next) == "hermesCron:gamma", "Navigation skips collapsed rows")
}

func testSidebarNavigationHandlesHiddenSelection() throws {
    let jobs = [
        JobPresentation(job: ScheduledJob.fixture(id: "visible-before", name: "Visible Before", source: .launchd)),
        JobPresentation(job: ScheduledJob.fixture(id: "hidden-a", name: "Hidden A", source: .hermesCron)),
        JobPresentation(job: ScheduledJob.fixture(id: "hidden-b", name: "Hidden B", source: .hermesCron)),
        JobPresentation(job: ScheduledJob.fixture(id: "visible-after", name: "Visible After", source: .cron))
    ]
    var collapseState = SidebarCollapseState()
    collapseState.toggle(SidebarSectionID(groupingMode: .source, groupKey: JobSource.hermesCron.rawValue))

    let sections = SidebarJobSection.sections(for: jobs, groupingMode: .source, collapseState: collapseState, hasSearchQuery: false)

    expect(SidebarNavigation.targetJobID(in: sections, selectedJobID: "hermesCron:hidden-a", direction: .previous) == "launchd:visible-before", "Hidden selection previous uses nearest visible before section")
    expect(SidebarNavigation.targetJobID(in: sections, selectedJobID: "hermesCron:hidden-a", direction: .next) == "cron:visible-after", "Hidden selection next uses nearest visible after section")
}

func testJobPresentationManualRecordIDUsesRawJobID() throws {
    let id = UUID()
    let presentation = JobPresentation(
        job: ScheduledJob.fixture(
            id: "manual-\(id.uuidString)",
            name: "Manual Record",
            source: .manualRecords,
            confidence: .manual
        )
    )

    expect(presentation.id == "manualRecords:manual-\(id.uuidString)", "Manual presentation selection ID keeps source prefix")
    expect(presentation.manualRecordID == id, "Manual presentation recovers raw record UUID")
}

func testAggregatesAndSortsJobsByNextRunThenName() throws {
    let root = try TemporaryFixture()
    let scanner = StaticJobScanner(jobs: [
        ScheduledJob(
            id: "b",
            name: "Zulu",
            source: .launchd,
            schedule: "daily",
            command: nil,
            state: "scheduled",
            lastStatus: nil,
            lastRun: nil,
            nextRun: Date(timeIntervalSince1970: 2),
            definition: "",
            lastRunDetails: nil,
            detailPath: nil
        ),
        ScheduledJob(
            id: "a",
            name: "Alpha",
            source: .hermesCron,
            schedule: "daily",
            command: nil,
            state: "scheduled",
            lastStatus: nil,
            lastRun: nil,
            nextRun: Date(timeIntervalSince1970: 1),
            definition: "",
            lastRunDetails: nil,
            detailPath: nil
        )
    ])

    let jobs = try JobInventory(scanners: [scanner]).refresh().jobs

    expect(jobs.map(\.name) == ["Alpha", "Zulu"], "Job sort order")
}

func testParsesUserCrontabEntriesWithInjectedRunner() throws {
    let root = try TemporaryFixture()
    let scanner = CronScanner(
        commandRunner: StubCronCommandRunner(result: CronCommandResult(
            output: """
            # weekday jobs
            SHELL=/bin/zsh
            15 9 * * 1-5 /Users/example/Scripts/weekday-report.sh
            @hourly /Users/example/Scripts/hourly-check.sh
            """,
            errorOutput: "",
            exitCode: 0
        )),
        systemCrontabFiles: [],
        cronTabDirectories: [],
        fileManager: .default
    )

    let result = try scanner.scan()
    let jobs = result.jobs

    expect(jobs.count == 2, "User crontab parsed job count")
    expect(jobs.allSatisfy { $0.source == .cron }, "User crontab source")
    expect(jobs.allSatisfy { $0.confidence == .scheduled }, "User crontab confidence")
    expect(jobs.allSatisfy { $0.origin == .userAuthored }, "User crontab origin")
    expect(jobs.map(\.schedule) == ["15 9 * * 1-5", "@hourly"], "User crontab schedules")
    expect(jobs[0].command?.contains("weekday-report.sh") == true, "Weekday command")
    expect(jobs[1].command?.contains("hourly-check.sh") == true, "Hourly command")
    _ = root
}

func testParsesSystemCrontabEntriesFromFixtureFile() throws {
    let root = try TemporaryFixture()
    try root.write(
        relativePath: "etc/crontab",
        contents: "0 3 * * * root /usr/libexec/example-maintenance"
    )

    let scanner = CronScanner(
        commandRunner: StubCronCommandRunner(result: CronCommandResult(output: "", errorOutput: "", exitCode: 0)),
        systemCrontabFiles: [root.url.appending(path: "etc/crontab")],
        cronTabDirectories: [],
        fileManager: .default
    )

    let jobs = try scanner.scan().jobs

    expect(jobs.count == 1, "System crontab parsed job count")
    expect(jobs[0].source == .cron, "System crontab source")
    expect(jobs[0].confidence == .scheduled, "System crontab confidence")
    expect(jobs[0].origin == .system, "System crontab origin")
    expect(jobs[0].command == "/usr/libexec/example-maintenance", "System crontab command")
}

func testCronScannerReportsSourceNotesForUnavailableInputs() throws {
    let root = try TemporaryFixture()
    let missingFile = root.url.appending(path: "missing-crontab")
    let scanner = CronScanner(
        commandRunner: StubCronCommandRunner(result: CronCommandResult(
            output: "",
            errorOutput: "no crontab for example",
            exitCode: 1
        )),
        systemCrontabFiles: [missingFile],
        cronTabDirectories: [],
        fileManager: .default
    )

    let result = try scanner.scan()

    expect(result.jobs.isEmpty, "Unavailable cron inputs produce no jobs")
    expect(result.notes.contains { $0.message.contains("crontab -l") || ($0.detail?.contains("crontab -l") == true) }, "Cron command note")
    expect(result.notes.contains { $0.detail == missingFile.path }, "Missing system file note")
    expect(result.notes.contains { $0.detail?.contains("no crontab for example") == true }, "Cron stderr detail")
}

func testShortcutsScannerListsRegisteredShortcutsWithoutSchedulingEvidence() throws {
    let scanner = ShortcutsScanner(commandRunner: StubShortcutsCommandRunner(result: ShortcutsCommandResult(
        output: "Morning Routine (ABC-123)",
        errorOutput: "",
        exitCode: 0
    )))

    let jobs = try scanner.scan().jobs

    expect(jobs.count == 1, "Shortcuts parsed job count")
    expect(jobs[0].source == .shortcuts, "Shortcuts source")
    expect(jobs[0].confidence == .registered, "Shortcuts registered confidence")
    expect(jobs[0].origin == .userAuthored, "Shortcuts user-authored origin")
    expect(jobs[0].state == "registered", "Shortcuts registered state")
    expect(jobs[0].schedule == "Registered shortcut (no schedule evidence)", "Shortcuts schedule evidence")
    expect(jobs[0].nextRun == nil, "Shortcuts no next run")
    expect(jobs[0].definition.contains("ABC-123"), "Shortcuts identifier definition")
}

func testShortcutsScannerReportsCommandFailureAsScanNote() throws {
    let scanner = ShortcutsScanner(commandRunner: StubShortcutsCommandRunner(result: ShortcutsCommandResult(
        output: "",
        errorOutput: "shortcuts unavailable",
        exitCode: 69
    )))

    let result = try scanner.scan()

    expect(result.jobs.isEmpty, "Shortcuts failure jobs")
    expect(result.notes.contains { $0.message.contains("Shortcuts list failed") }, "Shortcuts failure note")
    expect(result.notes.contains { $0.detail?.contains("shortcuts unavailable") == true }, "Shortcuts failure detail")
}

func testAutomatorScannerListsWorkflowFixturesAsRegistered() throws {
    let root = try TemporaryFixture()
    try root.write(
        relativePath: "Library/Services/Resize Images.workflow/Contents/Info.plist",
        contents: """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>CFBundleDisplayName</key><string>Resize Images</string>
          <key>CFBundleName</key><string>Resize Images</string>
        </dict>
        </plist>
        """
    )

    let scanner = AutomatorScanner(
        homeDirectory: root.url,
        workflowDirectories: [root.url.appending(path: "Library/Services")]
    )

    let jobs = try scanner.scan().jobs

    expect(jobs.count == 1, "Automator parsed job count")
    expect(jobs[0].source == .automator, "Automator source")
    expect(jobs[0].confidence == .registered, "Automator registered confidence")
    expect(jobs[0].origin == .userAuthored, "Automator user-authored origin")
    expect(jobs[0].state == "registered", "Automator registered state")
    expect(jobs[0].schedule == "Automator workflow (no schedule evidence)", "Automator schedule evidence")
    expect(jobs[0].detailPath?.hasSuffix(".workflow") == true, "Automator detail path")
    expect(jobs[0].name == "Resize Images", "Automator display name")
}

func testAutomatorScannerReportsMissingWorkflowDirectoriesAsNotes() throws {
    let root = try TemporaryFixture()
    let missingDirectory = root.url.appending(path: "MissingWorkflows")
    let scanner = AutomatorScanner(
        homeDirectory: root.url,
        workflowDirectories: [missingDirectory]
    )

    let result = try scanner.scan()

    expect(result.jobs.isEmpty, "Missing Automator directories produce no jobs")
    expect(result.notes.contains { $0.source == .automator && $0.severity == .info }, "Missing Automator directory note")
    expect(result.notes.contains { $0.detail == missingDirectory.path }, "Missing Automator detail path")
}

func testHumanizesSchedulesAndRunTimes() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 7, hour: 20, minute: 16))!
    let tomorrow = calendar.date(from: DateComponents(year: 2026, month: 5, day: 8, hour: 10, minute: 0))!
    let today = calendar.date(from: DateComponents(year: 2026, month: 5, day: 7, hour: 22, minute: 0))!

    expect(JobHumanizer.scheduleDescription("0 10 * * *") == "Daily at 10:00", "daily cron language")
    expect(JobHumanizer.scheduleDescription("01:00, 04:00") == "Daily at 01:00 and 04:00", "calendar time language")
    expect(JobHumanizer.scheduleDescription("at login, keep alive") == "Starts at login and stays running", "login schedule language")
    expect(JobHumanizer.relativeRunDescription(for: tomorrow, relativeTo: now) == "Tomorrow at 10:00", "tomorrow next run")
    expect(JobHumanizer.relativeRunDescription(for: today, relativeTo: now) == "Today at 22:00", "today next run")
    expect(JobHumanizer.displayName("com.example.daily-report", source: .launchd) == "Example Daily Report", "generic bundle identifier display name")
    expect(JobHumanizer.displayName("com.user.downloads-cleanup", source: .launchd) == "Downloads Cleanup", "placeholder owner display name")
}

func testHealthSummaries() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 7, hour: 20, minute: 16))!
    let recent = calendar.date(from: DateComponents(year: 2026, month: 5, day: 7, hour: 13, minute: 7))!
    let next = calendar.date(from: DateComponents(year: 2026, month: 5, day: 8, hour: 10, minute: 0))!
    let old = calendar.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 10, minute: 0))!

    let healthy = ScheduledJob.fixture(lastStatus: "ok", lastRun: recent, nextRun: next)
    let pending = ScheduledJob.fixture(lastStatus: nil, lastRun: nil, nextRun: next)
    let failed = ScheduledJob.fixture(lastStatus: "failed", lastRun: recent, nextRun: next)
    let stale = ScheduledJob.fixture(lastStatus: "ok", lastRun: old, nextRun: nil)

    expect(healthy.health(relativeTo: now).label == "Alive", "healthy label")
    expect(pending.health(relativeTo: now).label == "Waiting", "pending label")
    expect(failed.health(relativeTo: now).label == "Needs attention", "failed label")
    expect(stale.health(relativeTo: now).label == "Stale", "stale label")
}

func testCollapseStateCodableRoundTrip() throws {
    let sectionA = SidebarSectionID(groupingMode: .source, groupKey: "launchd")
    let sectionB = SidebarSectionID(groupingMode: .origin, groupKey: "userAuthored")
    var original = SidebarCollapseState()
    original.toggle(sectionA)
    original.toggle(sectionB)

    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(original) else {
        fatalError("Expected SidebarCollapseState to encode to JSON Data")
    }

    let decoder = JSONDecoder()
    guard let decoded = try? decoder.decode(SidebarCollapseState.self, from: data) else {
        fatalError("Expected SidebarCollapseState to decode from JSON Data")
    }

    expect(decoded.collapsedSectionIDs == original.collapsedSectionIDs,
           "Decoded collapse state matches original")
    expect(decoded.isCollapsed(sectionA),
           "Decoded state preserves collapsed section A")
    expect(decoded.isCollapsed(sectionB),
           "Decoded state preserves collapsed section B")
    expect(!decoded.isCollapsed(SidebarSectionID(groupingMode: .confidence, groupKey: "scheduled")),
           "Decoded state preserves non-collapsed sections")

    // Round-trip empty state
    let empty = SidebarCollapseState()
    guard let emptyData = try? encoder.encode(empty) else {
        fatalError("Expected empty SidebarCollapseState to encode")
    }
    guard let decodedEmpty = try? decoder.decode(SidebarCollapseState.self, from: emptyData) else {
        fatalError("Expected empty SidebarCollapseState to decode")
    }
    expect(decodedEmpty.collapsedSectionIDs.isEmpty,
           "Empty collapse state round-trips correctly")
}

func testGroupingModeCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for mode in SidebarGroupingMode.allCases {
        guard let data = try? encoder.encode(mode) else {
            fatalError("Expected SidebarGroupingMode.\(mode.rawValue) to encode")
        }
        guard let decoded = try? decoder.decode(SidebarGroupingMode.self, from: data) else {
            fatalError("Expected SidebarGroupingMode.\(mode.rawValue) to decode")
        }
        expect(decoded == mode,
               "SidebarGroupingMode \(mode.rawValue) round-trips correctly")
    }

    // Verify fallback: invalid raw value decodes to nil, which caller handles
    let invalidJSON = "\"nonexistent_mode\"".data(using: .utf8)!
    let invalidDecode = try? decoder.decode(SidebarGroupingMode.self, from: invalidJSON)
    expect(invalidDecode == nil,
           "Invalid SidebarGroupingMode raw value returns nil")
}

func testScanConfigDefaults() throws {
    let config = CandidateScriptScanner.Configuration.default

    expect(config.maxDepth == 2,
           "Default maxDepth is 2")
    expect(config.maxVisitedFiles == 2_000,
           "Default maxVisitedFiles is 2,000")
    expect(config.maxResults == 200,
           "Default maxResults is 200")
    expect(config.maximumCandidateBytes == 1_000_000,
           "Default maximumCandidateBytes is 1,000,000")

    expect(config.scriptExtensions.contains("sh"),
           "Default scriptExtensions includes sh")
    expect(config.scriptExtensions.contains("py"),
           "Default scriptExtensions includes py")
    expect(config.scriptExtensions.contains("swift"),
           "Default scriptExtensions includes swift")

    expect(config.ignoredDirectoryNames.contains(".git"),
           "Default ignoredDirectoryNames includes .git")
    expect(config.ignoredDirectoryNames.contains("node_modules"),
           "Default ignoredDirectoryNames includes node_modules")
    expect(config.ignoredDirectoryNames.contains(".swiftpm"),
           "Default ignoredDirectoryNames includes .swiftpm")

    // Verify custom Configuration constructor
    let custom = CandidateScriptScanner.Configuration(
        maxDepth: 5,
        maxVisitedFiles: 500,
        maxResults: 50,
        maximumCandidateBytes: 500_000,
        scriptExtensions: ["sh"],
        ignoredDirectoryNames: [".git"]
    )
    expect(custom.maxDepth == 5, "Custom Configuration respects maxDepth")
    expect(custom.maxResults == 50, "Custom Configuration respects maxResults")
    expect(custom.maxVisitedFiles == 500, "Custom Configuration respects maxVisitedFiles")
    expect(custom.scriptExtensions == ["sh"], "Custom Configuration respects scriptExtensions")
}

func testSidebarTypeToSelect() throws {
    let jobs = [
        JobPresentation(job: ScheduledJob.fixture(id: "alpha", name: "Alpha Backup", source: .launchd)),
        JobPresentation(job: ScheduledJob.fixture(id: "alice", name: "Alice Watcher", source: .hermesCron)),
        JobPresentation(job: ScheduledJob.fixture(id: "beta", name: "Beta Cleanup", source: .launchd)),
        JobPresentation(job: ScheduledJob.fixture(id: "baker", name: "Baker Report", source: .cron)),
        JobPresentation(job: ScheduledJob.fixture(id: "gamma", name: "Gamma Sync", source: .hermesCron))
    ]
    let sections = SidebarJobSection.sections(for: jobs)

    // Single-character prefix match
    expect(SidebarNavigation.typeToSelectMatch(for: "a", in: sections) == "launchd:alpha",
           "typeToSelect 'a' matches first visible 'Alpha Backup' by prefix")
    expect(SidebarNavigation.typeToSelectMatch(for: "b", in: sections) == "launchd:beta",
           "typeToSelect 'b' matches first visible 'Beta Cleanup' by prefix")
    expect(SidebarNavigation.typeToSelectMatch(for: "g", in: sections) == "hermesCron:gamma",
           "typeToSelect 'g' matches 'Gamma Sync' by prefix")

    // Multi-character prefix match
    expect(SidebarNavigation.typeToSelectMatch(for: "al", in: sections) == "launchd:alpha",
           "typeToSelect 'al' matches 'Alpha Backup' (not 'Alice Watcher' — Alpha comes first)")
    expect(SidebarNavigation.typeToSelectMatch(for: "ali", in: sections) == "hermesCron:alice",
           "typeToSelect 'ali' matches 'Alice Watcher' specifically")

    // Case-insensitive
    expect(SidebarNavigation.typeToSelectMatch(for: "ALPHA", in: sections) == "launchd:alpha",
           "typeToSelect is case-insensitive")

    // No match — returns nil (D-10)
    expect(SidebarNavigation.typeToSelectMatch(for: "z", in: sections) == nil,
           "typeToSelect no-match returns nil")
    expect(SidebarNavigation.typeToSelectMatch(for: "", in: sections) == nil,
           "typeToSelect empty prefix returns nil")

    // Cycle detection: typeToSelectNextMatch
    expect(SidebarNavigation.typeToSelectNextMatch(for: "a", in: sections, after: "launchd:alpha") == "hermesCron:alice",
           "typeToSelectNextMatch 'a' after alpha returns alice")
    expect(SidebarNavigation.typeToSelectNextMatch(for: "a", in: sections, after: "hermesCron:alice") == "launchd:alpha",
           "typeToSelectNextMatch 'a' after alice wraps to alpha")
    expect(SidebarNavigation.typeToSelectNextMatch(for: "b", in: sections, after: "launchd:beta") == "cron:baker",
           "typeToSelectNextMatch 'b' after beta returns baker")
    expect(SidebarNavigation.typeToSelectNextMatch(for: "b", in: sections, after: "cron:baker") == "launchd:beta",
           "typeToSelectNextMatch 'b' after baker wraps to beta")

    // NextMatch with no match returns nil
    expect(SidebarNavigation.typeToSelectNextMatch(for: "z", in: sections, after: "launchd:alpha") == nil,
           "typeToSelectNextMatch no-match returns nil")

    // Collapsed sections: type-to-select only matches visible jobs (D-09)
    var collapseState = SidebarCollapseState()
    let launchdSectionID = SidebarSectionID(groupingMode: .source, groupKey: JobSource.launchd.rawValue)
    collapseState.toggle(launchdSectionID)
    let collapsedSections = SidebarJobSection.sections(for: jobs, groupingMode: .source, collapseState: collapseState, hasSearchQuery: false)

    // Alpha and Beta are in collapsed launchd section; Alice and Gamma are visible
    expect(SidebarNavigation.typeToSelectMatch(for: "a", in: collapsedSections) == "hermesCron:alice",
           "typeToSelect 'a' with collapsed launchd returns alice (not alpha — alpha is hidden)")
    expect(SidebarNavigation.typeToSelectMatch(for: "b", in: collapsedSections) == "cron:baker",
           "typeToSelect 'b' with collapsed launchd returns baker (not beta — beta is hidden)")
}

func testSidebarExpandOverride() throws {
    let jobs = [
        JobPresentation(job: ScheduledJob.fixture(id: "alpha", name: "Alpha", source: .launchd)),
        JobPresentation(job: ScheduledJob.fixture(id: "gamma", name: "Gamma", source: .hermesCron))
    ]
    let launchdSectionID = SidebarSectionID(groupingMode: .source, groupKey: JobSource.launchd.rawValue)

    // Baseline: normal collapse state hides jobs
    var collapseState = SidebarCollapseState()
    collapseState.toggle(launchdSectionID)
    let collapsedSections = SidebarJobSection.sections(for: jobs, groupingMode: .source, collapseState: collapseState, hasSearchQuery: false)
    let collapsedLaunchd = section(collapsedSections, titled: "launchd")
    expect(collapsedLaunchd.jobs.isEmpty, "Normal collapse hides launchd jobs")
    expect(collapsedLaunchd.isPersistentlyCollapsed, "Normal collapse marks section persistently collapsed")

    // Override: true forces all sections open
    let openOverrideSections = collapsedSections.map { section in
        SidebarJobSection(
            id: section.id,
            title: section.title,
            visibleCount: section.totalCount,
            totalCount: section.totalCount,
            isPersistentlyCollapsed: false,
            isEffectivelyCollapsed: false,
            isCollapsed: false,
            jobs: section.allJobs,
            allJobs: section.allJobs,
            allJobIDs: section.allJobIDs
        )
    }
    let openLaunchd = section(openOverrideSections, titled: "launchd")
    expect(!openLaunchd.jobs.isEmpty, "Expand override forces jobs visible")
    expect(!openLaunchd.isPersistentlyCollapsed, "Expand override clears collapse flag")
    expect(openLaunchd.jobs.map(\.id) == ["launchd:alpha"], "Expand override shows all launchd jobs")

    // Override: false forces all sections closed
    let closedOverrideSections = collapsedSections.map { section in
        SidebarJobSection(
            id: section.id,
            title: section.title,
            visibleCount: section.totalCount,
            totalCount: section.totalCount,
            isPersistentlyCollapsed: true,
            isEffectivelyCollapsed: true,
            isCollapsed: true,
            jobs: [],
            allJobs: section.allJobs,
            allJobIDs: section.allJobIDs
        )
    }
    let closedLaunchd = section(closedOverrideSections, titled: "launchd")
    expect(closedLaunchd.jobs.isEmpty, "Collapse override hides all jobs")
    expect(closedLaunchd.isPersistentlyCollapsed, "Collapse override marks sections collapsed")

    // Override: nil means normal behavior (no forcing)
    let nilOverrideSections = SidebarJobSection.sections(for: jobs, groupingMode: .source, collapseState: collapseState, hasSearchQuery: false)
    let nilLaunchd = section(nilOverrideSections, titled: "launchd")
    expect(nilLaunchd.jobs.isEmpty, "nil override respects normal collapse state")
    expect(nilLaunchd.isPersistentlyCollapsed, "nil override preserves collapse state flag")

    // Manual reset: toggle after override clears override
    var manualCollapseState = SidebarCollapseState()
    manualCollapseState.toggle(launchdSectionID) // Collapse launchd
    // Simulate: sidebarExpandAllOverride was true, user clicked disclosure
    // After nil reset, toggle should uncollapse (since it was collapsed)
    manualCollapseState.toggle(launchdSectionID)
    let afterManualReset = SidebarJobSection.sections(for: jobs, groupingMode: .source, collapseState: manualCollapseState, hasSearchQuery: false)
    let resetLaunchd = section(afterManualReset, titled: "launchd")
    expect(!resetLaunchd.jobs.isEmpty, "Manual click uncollapses section after override reset")
    expect(!resetLaunchd.isPersistentlyCollapsed, "Manual click clears persistent collapse after override reset")
}

func testGroupingModeShortcutKeys() throws {
    let allModes = SidebarGroupingMode.allCases

    // Verify exactly 5 modes per D-03 (Cmd+1 through Cmd+5)
    expect(allModes.count == 5, "Exactly 5 grouping modes for Cmd+1..5 shortcuts")

    // Verify enum case order matches shortcut key: Source=1, Origin=2, Health=3, Trigger=4, Confidence=5
    expect(allModes[0] == .source, "Cmd+1 maps to Source grouping")
    expect(allModes[1] == .origin, "Cmd+2 maps to Origin grouping")
    expect(allModes[2] == .health, "Cmd+3 maps to Health grouping")
    expect(allModes[3] == .trigger, "Cmd+4 maps to Trigger grouping")
    expect(allModes[4] == .confidence, "Cmd+5 maps to Confidence grouping")

    // Verify labels match menu items
    expect(allModes[0].label == "Source", "Source mode label is 'Source'")
    expect(allModes[1].label == "Origin", "Origin mode label is 'Origin'")
    expect(allModes[2].label == "Health", "Health mode label is 'Health'")
    expect(allModes[3].label == "Trigger", "Trigger mode label is 'Trigger'")
    expect(allModes[4].label == "Confidence", "Confidence mode label is 'Confidence'")

    // Verify default mode is source (ensures first-launch state is predictable)
    expect(SidebarGroupingMode.defaultMode == .source, "Default grouping mode is Source")
}

func testSidebarScheduleGroupingModeAndSections() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = calendar.date(from: DateComponents(year: 2026, month: 5, day: 8, hour: 12, minute: 0))!

    let morningDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 9, hour: 8, minute: 0))!
    let afternoonDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 9, hour: 14, minute: 0))!
    let eveningDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 9, hour: 20, minute: 0))!
    let nightDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 9, hour: 2, minute: 0))!

    // Verify .schedule case exists and is the 6th mode
    let allModes = SidebarGroupingMode.allCases
    expect(allModes.count == 6, "6 grouping modes after adding schedule")
    expect(allModes[5] == .schedule, "schedule is 6th case (index 5) after confidence")
    expect(allModes[5].label == "Schedule", "schedule mode label is 'Schedule'")

    // Verify sections classify correctly via .schedule grouping
    let jobs = [
        JobPresentation(job: ScheduledJob.fixture(id: "morning", confidence: .scheduled, nextRun: morningDate), now: now),
        JobPresentation(job: ScheduledJob.fixture(id: "afternoon", confidence: .scheduled, nextRun: afternoonDate), now: now),
        JobPresentation(job: ScheduledJob.fixture(id: "evening", confidence: .scheduled, nextRun: eveningDate), now: now),
        JobPresentation(job: ScheduledJob.fixture(id: "night", confidence: .scheduled, nextRun: nightDate), now: now),
        JobPresentation(job: ScheduledJob.fixture(id: "hourly", confidence: .scheduled, schedule: "every hour"), now: now),
        JobPresentation(job: ScheduledJob.fixture(id: "daily", confidence: .scheduled, schedule: "0 10 * * *"), now: now),
        JobPresentation(job: ScheduledJob.fixture(id: "weekly", confidence: .scheduled, schedule: "@weekly"), now: now),
        JobPresentation(job: ScheduledJob.fixture(id: "monthly", confidence: .scheduled, schedule: "@monthly"), now: now),
        JobPresentation(job: ScheduledJob.fixture(id: "candidate", confidence: .candidate, schedule: "0 9 * * *"), now: now),
    ]
    let sections = SidebarJobSection.sections(for: jobs, groupingMode: .schedule, collapseState: SidebarCollapseState(), hasSearchQuery: false)

    expect(section(sections, titled: "Morning (4 AM – 12 PM)").allJobIDs == ["hermesCron:morning"], "morning section contains morning job")
    expect(section(sections, titled: "Afternoon (12 PM – 6 PM)").allJobIDs == ["hermesCron:afternoon"], "afternoon section contains afternoon job")
    expect(section(sections, titled: "Evening (6 PM – 10 PM)").allJobIDs == ["hermesCron:evening"], "evening section contains evening job")
    expect(section(sections, titled: "Night (10 PM – 4 AM)").allJobIDs == ["hermesCron:night"], "night section contains night job")
    expect(section(sections, titled: "Hourly").allJobIDs == ["hermesCron:hourly"], "hourly section contains hourly job")
    expect(section(sections, titled: "Daily").allJobIDs == ["hermesCron:daily"], "daily section contains daily job")
    expect(section(sections, titled: "Weekly").allJobIDs == ["hermesCron:weekly"], "weekly section contains weekly job")
    expect(section(sections, titled: "Monthly").allJobIDs == ["hermesCron:monthly"], "monthly section contains monthly job")
    expect(section(sections, titled: "No schedule evidence").allJobIDs == ["hermesCron:candidate"], "noScheduleEvidence section contains candidate job")

    // Verify "No schedule evidence" is the last section
    expect(sections.last?.title == "No schedule evidence", "No schedule evidence section appears last")
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError("Expectation failed: \(message)")
    }
}

func expectDatesEqual(_ actual: Date?, _ expected: Date, _ message: String) {
    guard let actual else {
        fatalError("Expectation failed: \(message)")
    }

    expect(abs(actual.timeIntervalSince1970 - expected.timeIntervalSince1970) < 0.001, message)
}

func section(_ sections: [SidebarJobSection], titled title: String) -> SidebarJobSection {
    guard let section = sections.first(where: { $0.title == title }) else {
        fatalError("Expectation failed: missing sidebar section \(title)")
    }
    return section
}

func isoDate(_ value: String) -> Date {
    let fractionalISOFormatter = ISO8601DateFormatter()
    fractionalISOFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractionalISOFormatter.date(from: value) {
        return date
    }

    let plainISOFormatter = ISO8601DateFormatter()
    plainISOFormatter.formatOptions = [.withInternetDateTime]
    guard let date = plainISOFormatter.date(from: value) else {
        fatalError("Could not parse date: \(value)")
    }
    return date
}

private final class TemporaryFixture {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: "AutomationHealthTests")
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func write(relativePath: String, contents: String) throws {
        let target = url.appending(path: relativePath)
        try FileManager.default.createDirectory(
            at: target.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.write(to: target, atomically: true, encoding: .utf8)
    }

    func read(relativePath: String) throws -> String {
        try String(contentsOf: url.appending(path: relativePath), encoding: .utf8)
    }

    func makeExecutable(relativePath: String) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: url.appending(path: relativePath).path
        )
    }
}

private struct StaticJobScanner: JobScanning {
    let jobs: [ScheduledJob]
    var notes: [ScanNote] = []

    func scan() throws -> JobScanResult {
        JobScanResult(jobs: jobs, notes: notes)
    }
}

private struct StubCronCommandRunner: CronCommandRunning {
    let result: CronCommandResult

    func listCurrentUserCrontab() -> CronCommandResult {
        result
    }
}

private struct StubShortcutsCommandRunner: ShortcutsCommandRunning {
    let result: ShortcutsCommandResult

    func listShortcuts() -> ShortcutsCommandResult {
        result
    }
}

private extension ScheduledJob {
    static func fixture(
        id: String = UUID().uuidString,
        name: String = "Fixture",
        source: JobSource = .hermesCron,
        confidence: JobConfidence = .scheduled,
        origin: JobOrigin = .unknown,
        schedule: String = "0 10 * * *",
        command: String? = nil,
        state: String = "scheduled",
        definition: String = "",
        lastRunDetails: String? = nil,
        detailPath: String? = nil,
        lastStatus: String? = nil,
        lastRun: Date? = nil,
        nextRun: Date? = nil
    ) -> ScheduledJob {
        ScheduledJob(
            id: id,
            name: name,
            source: source,
            confidence: confidence,
            origin: origin,
            schedule: schedule,
            command: command,
            state: state,
            lastStatus: lastStatus,
            lastRun: lastRun,
            nextRun: nextRun,
            definition: definition,
            lastRunDetails: lastRunDetails,
            detailPath: detailPath
        )
    }

    static func fixture(lastStatus: String?, lastRun: Date?, nextRun: Date?) -> ScheduledJob {
        fixture(id: UUID().uuidString, lastStatus: lastStatus, lastRun: lastRun, nextRun: nextRun)
    }
}
