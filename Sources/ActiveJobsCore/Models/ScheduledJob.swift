import Foundation

public enum JobSource: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case launchd
    case hermesCron
    case cron
    case shortcuts
    case automator
    case candidateScripts
    case manualRecords

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .launchd:
            "launchd"
        case .hermesCron:
            "Hermes cron"
        case .cron:
            "cron"
        case .shortcuts:
            "Shortcuts"
        case .automator:
            "Automator"
        case .candidateScripts:
            "Candidate scripts"
        case .manualRecords:
            "Manual records"
        }
    }
}

public enum JobConfidence: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case scheduled
    case registered
    case candidate
    case manual

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .scheduled:
            "Scheduled"
        case .registered:
            "Registered"
        case .candidate:
            "Candidate"
        case .manual:
            "Manual"
        }
    }

    public var description: String {
        switch self {
        case .scheduled:
            "Direct schedule evidence"
        case .registered:
            "Registered automation without schedule evidence"
        case .candidate:
            "Possible automation candidate"
        case .manual:
            "User-added app record"
        }
    }
}

public enum JobOrigin: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case userAuthored
    case thirdPartyApp
    case system
    case unknown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .userAuthored:
            "User-authored"
        case .thirdPartyApp:
            "Third-party app"
        case .system:
            "System"
        case .unknown:
            "Unknown"
        }
    }
}

public enum ScanNoteSeverity: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case info
    case warning
    case error

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .info:
            "Info"
        case .warning:
            "Warning"
        case .error:
            "Error"
        }
    }
}

public struct ScanNote: Identifiable, Hashable, Sendable {
    public let id: String
    public let source: JobSource
    public let severity: ScanNoteSeverity
    public let message: String
    public let detail: String?

    public init(
        id: String? = nil,
        source: JobSource,
        severity: ScanNoteSeverity,
        message: String,
        detail: String? = nil
    ) {
        self.source = source
        self.severity = severity
        self.message = message
        self.detail = detail
        self.id = id ?? [
            source.rawValue,
            severity.rawValue,
            message,
            detail ?? ""
        ].joined(separator: ":")
    }
}

public struct ScheduledJob: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let source: JobSource
    public let confidence: JobConfidence
    public let origin: JobOrigin
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
        confidence: JobConfidence = .scheduled,
        origin: JobOrigin = .unknown,
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
        self.confidence = confidence
        self.origin = origin
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
