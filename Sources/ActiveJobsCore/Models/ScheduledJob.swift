import Foundation

public enum JobSource: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case launchd
    case hermesCron

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .launchd:
            "launchd"
        case .hermesCron:
            "Hermes cron"
        }
    }
}

public struct ScheduledJob: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let source: JobSource
    public let schedule: String
    public let command: String?
    public let state: String
    public let lastStatus: String?
    public let lastRun: Date?
    public let nextRun: Date?
    public let definition: String
    public let lastRunDetails: String?
    public let detailPath: String?

    public var selectionID: String {
        "\(source.rawValue):\(id)"
    }

    public init(
        id: String,
        name: String,
        source: JobSource,
        schedule: String,
        command: String?,
        state: String,
        lastStatus: String?,
        lastRun: Date?,
        nextRun: Date?,
        definition: String,
        lastRunDetails: String?,
        detailPath: String?
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.schedule = schedule
        self.command = command
        self.state = state
        self.lastStatus = lastStatus
        self.lastRun = lastRun
        self.nextRun = nextRun
        self.definition = definition
        self.lastRunDetails = lastRunDetails
        self.detailPath = detailPath
    }

    public var lastRunDescription: String {
        guard let lastRun else { return "Never" }
        return JobDateFormatters.shortDateTime(lastRun)
    }

    public var nextRunDescription: String {
        guard let nextRun else { return "Unknown" }
        return JobDateFormatters.shortDateTime(nextRun)
    }

    public var statusDescription: String {
        if let lastStatus, !lastStatus.isEmpty {
            return lastStatus
        }
        return state
    }
}
