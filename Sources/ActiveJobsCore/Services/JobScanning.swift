import Foundation

public struct JobScanResult: Hashable, Sendable {
    public let jobs: [ScheduledJob]
    public let notes: [ScanNote]

    public init(jobs: [ScheduledJob] = [], notes: [ScanNote] = []) {
        self.jobs = jobs
        self.notes = notes
    }
}

public protocol JobScanning: Sendable {
    func scan() throws -> JobScanResult
}

public struct JobInventory: Sendable {
    private let scanners: [JobScanning]

    public init(scanners: [JobScanning], homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.scanners = scanners
    }

    public static func live(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        manualRecordStore: ManualRecordStore? = nil
    ) -> JobInventory {
        let manualRecordStore = manualRecordStore ?? ManualRecordStore.live(homeDirectory: homeDirectory)

        return JobInventory(
            scanners: [
                LaunchAgentScanner(homeDirectory: homeDirectory),
                HermesCronScanner(homeDirectory: homeDirectory),
                CronScanner(),
                ShortcutsScanner(),
                AutomatorScanner(homeDirectory: homeDirectory),
                CandidateScriptScanner(homeDirectory: homeDirectory),
                ManualRecordScanner(store: manualRecordStore)
            ],
            homeDirectory: homeDirectory
        )
    }

    public func refresh() throws -> JobScanResult {
        let results = try scanners.map { try $0.scan() }
        let jobs = results.flatMap(\.jobs)
        var seen = Set<String>()
        let uniqueJobs = jobs.filter { job in
            let inserted = seen.insert("\(job.source.rawValue):\(job.id)").inserted
            return inserted
        }

        let uniqueSortedJobs = uniqueJobs.sorted { lhs, rhs in
            switch (lhs.nextRun, rhs.nextRun) {
            case let (left?, right?) where left != right:
                return left < right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }

        return JobScanResult(jobs: uniqueSortedJobs, notes: results.flatMap(\.notes))
    }
}
