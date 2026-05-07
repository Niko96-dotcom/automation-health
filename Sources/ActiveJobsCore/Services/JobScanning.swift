import Foundation

public protocol JobScanning: Sendable {
    func scan() throws -> [ScheduledJob]
}

public struct JobInventory: Sendable {
    private let scanners: [JobScanning]

    public init(scanners: [JobScanning], homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.scanners = scanners
    }

    public static func live(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> JobInventory {
        JobInventory(
            scanners: [
                LaunchAgentScanner(homeDirectory: homeDirectory),
                HermesCronScanner(homeDirectory: homeDirectory)
            ],
            homeDirectory: homeDirectory
        )
    }

    public func refresh() throws -> [ScheduledJob] {
        let jobs = try scanners.flatMap { try $0.scan() }
        var seen = Set<String>()
        let uniqueJobs = jobs.filter { job in
            let inserted = seen.insert("\(job.source.rawValue):\(job.id)").inserted
            return inserted
        }

        return uniqueJobs.sorted { lhs, rhs in
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
    }
}
