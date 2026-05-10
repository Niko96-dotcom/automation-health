import Foundation

public struct HermesCronScanner: JobScanning, @unchecked Sendable {
    private let homeDirectory: URL
    private let fileManager: FileManager

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) {
        self.homeDirectory = homeDirectory
        self.fileManager = fileManager
    }

    public func scan() throws -> JobScanResult {
        let jobsURL = homeDirectory.appending(path: ".hermes/cron/jobs.json")
        guard fileManager.fileExists(atPath: jobsURL.path) else {
            return JobScanResult()
        }

        let data = try Data(contentsOf: jobsURL)
        let decoded = try JSONDecoder().decode(HermesJobsFile.self, from: data)

        let jobs: [ScheduledJob] = decoded.jobs.compactMap { job in
            guard job.enabled == true, job.state != "paused" else {
                return nil
            }

            let latestOutput = latestOutput(for: job.id)
            let command = job.script ?? commandFromPrompt(job.prompt)

            return ScheduledJob(
                id: job.id,
                name: job.name,
                source: .hermesCron,
                confidence: .scheduled,
                origin: .userAuthored,
                schedule: job.scheduleDisplay ?? job.schedule?.display ?? job.schedule?.expr ?? "Unknown",
                command: command,
                state: job.state ?? "scheduled",
                lastStatus: job.lastStatus,
                lastRun: FlexibleDateParser.parse(job.lastRunAt),
                nextRun: FlexibleDateParser.parse(job.nextRunAt),
                definition: job.script ?? job.prompt ?? "",
                lastRunDetails: latestOutput.contents,
                detailPath: latestOutput.path
            )
        }

        return JobScanResult(jobs: jobs, notes: [])
    }

    private func latestOutput(for id: String) -> (contents: String?, path: String?) {
        let outputDirectory = homeDirectory.appending(path: ".hermes/cron/output/\(id)")
        guard let files = try? fileManager.contentsOfDirectory(
            at: outputDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (nil, nil)
        }

        let markdownFiles = files.filter { $0.pathExtension == "md" }
        let latest = markdownFiles.max { lhs, rhs in
            let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            return (leftDate ?? .distantPast) < (rightDate ?? .distantPast)
        }

        guard let latest else {
            return (nil, nil)
        }

        return (TextSnippetReader.read(url: latest), latest.path)
    }

    private func commandFromPrompt(_ prompt: String?) -> String? {
        guard let prompt else {
            return nil
        }

        let lines = prompt.components(separatedBy: .newlines)
        return lines.first { line in
            line.contains("/Users/") || line.contains("python") || line.contains("swift") || line.contains("node")
        }?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct HermesJobsFile: Decodable {
    let jobs: [HermesJob]
}

private struct HermesJob: Decodable {
    let id: String
    let name: String
    let prompt: String?
    let script: String?
    let schedule: HermesSchedule?
    let scheduleDisplay: String?
    let enabled: Bool?
    let state: String?
    let nextRunAt: String?
    let lastRunAt: String?
    let lastStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case prompt
        case script
        case schedule
        case scheduleDisplay = "schedule_display"
        case enabled
        case state
        case nextRunAt = "next_run_at"
        case lastRunAt = "last_run_at"
        case lastStatus = "last_status"
    }
}

private struct HermesSchedule: Decodable {
    let kind: String?
    let expr: String?
    let display: String?
}
