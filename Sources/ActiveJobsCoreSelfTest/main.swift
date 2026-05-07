import Foundation
import ActiveJobsCore

try testParsesEnabledHermesCronJobsWithLatestOutput()
try testParsesLaunchAgentCalendarSchedulesAndLogTail()
try testAggregatesAndSortsJobsByNextRunThenName()
try testHumanizesSchedulesAndRunTimes()
try testHealthSummaries()

print("ActiveJobsCoreSelfTest passed")

func testParsesEnabledHermesCronJobsWithLatestOutput() throws {
    let root = try TemporaryFixture()
    try root.write(
        relativePath: ".hermes/cron/jobs.json",
        contents: """
        {
          "jobs": [
            {
              "id": "aa8acee71842",
              "name": "daily-ft-bookmarks-to-eigenwiki",
              "prompt": "Run the daily Field Theory bookmark pipeline.",
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
        relativePath: ".hermes/cron/output/aa8acee71842/2026-05-06_09-10-37.md",
        contents: "old output"
    )
    try root.write(
        relativePath: ".hermes/cron/output/aa8acee71842/2026-05-07_09-19-34.md",
        contents: "latest run report"
    )

    let jobs = try HermesCronScanner(homeDirectory: root.url).scan()

    expect(jobs.map(\.name) == ["daily-ft-bookmarks-to-eigenwiki"], "Hermes enabled job names")
    expect(jobs.first?.schedule == "0 9 * * *", "Hermes schedule")
    expectDatesEqual(jobs.first?.lastRun, isoDate("2026-05-07T09:19:34.169510+02:00"), "Hermes last run")
    expectDatesEqual(jobs.first?.nextRun, isoDate("2026-05-08T09:00:00+02:00"), "Hermes next run")
    expect(jobs.first?.lastStatus == "ok", "Hermes status")
    expect(jobs.first?.definition == "Run the daily Field Theory bookmark pipeline.", "Hermes prompt definition")
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
            <string>/Users/niko/Scripts/downloads-cleanup.py</string>
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
    ).scan()

    expect(jobs.count == 1, "LaunchAgent count")
    expect(jobs[0].name == "com.user.downloads-cleanup", "LaunchAgent name")
    expect(jobs[0].command == "/usr/bin/python3 /Users/niko/Scripts/downloads-cleanup.py", "LaunchAgent command")
    expect(jobs[0].schedule == "01:00, 04:00", "LaunchAgent schedule")
    expect(jobs[0].definition.hasSuffix("/Library/LaunchAgents/com.user.downloads-cleanup.plist"), "LaunchAgent definition path")
    expect(jobs[0].lastRunDetails == "first line\nsecond line\nthird line", "LaunchAgent log")
    expect(jobs[0].source == .launchd, "LaunchAgent source")
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

    let jobs = try JobInventory(scanners: [scanner], homeDirectory: root.url).refresh()

    expect(jobs.map(\.name) == ["Alpha", "Zulu"], "Job sort order")
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
}

private struct StaticJobScanner: JobScanning {
    let jobs: [ScheduledJob]

    func scan() throws -> [ScheduledJob] {
        jobs
    }
}

private extension ScheduledJob {
    static func fixture(lastStatus: String?, lastRun: Date?, nextRun: Date?) -> ScheduledJob {
        ScheduledJob(
            id: UUID().uuidString,
            name: "Fixture",
            source: .hermesCron,
            schedule: "0 10 * * *",
            command: nil,
            state: "scheduled",
            lastStatus: lastStatus,
            lastRun: lastRun,
            nextRun: nextRun,
            definition: "",
            lastRunDetails: nil,
            detailPath: nil
        )
    }
}
