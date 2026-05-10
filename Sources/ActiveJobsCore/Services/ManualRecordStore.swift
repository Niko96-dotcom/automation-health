import Foundation

public struct ManualAutomationRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let notes: String
    public let command: String?
    public let scheduleDescription: String?
    public let origin: JobOrigin
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        notes: String,
        command: String?,
        scheduleDescription: String?,
        origin: JobOrigin,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.command = command
        self.scheduleDescription = scheduleDescription
        self.origin = origin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var scheduledJob: ScheduledJob {
        ScheduledJob(
            id: "manual-\(id.uuidString)",
            name: name,
            source: .manualRecords,
            confidence: .manual,
            origin: origin,
            schedule: scheduleDescription ?? "Manual record (no schedule evidence)",
            command: command,
            state: "manual",
            lastStatus: nil,
            lastRun: nil,
            nextRun: nil,
            definition: notes.isEmpty ? "Manual app record: \(name)" : notes,
            lastRunDetails: nil,
            detailPath: nil
        )
    }
}

public struct ManualRecordDraft: Hashable, Sendable {
    public var name: String
    public var origin: JobOrigin
    public var scheduleDescription: String?
    public var command: String?
    public var notes: String

    public init(
        name: String = "",
        origin: JobOrigin = .unknown,
        scheduleDescription: String? = nil,
        command: String? = nil,
        notes: String = ""
    ) {
        self.name = name
        self.origin = origin
        self.scheduleDescription = scheduleDescription
        self.command = command
        self.notes = notes
    }
}

public struct ManualRecordStore: @unchecked Sendable {
    public enum StoreError: LocalizedError, Sendable {
        case missingRecord(UUID)
        case emptyName

        public var errorDescription: String? {
            switch self {
            case let .missingRecord(id):
                "Manual record not found: \(id.uuidString)"
            case .emptyName:
                "Manual record name is required."
            }
        }
    }

    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileURL: URL,
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public static func live(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> ManualRecordStore {
        ManualRecordStore(
            fileURL: homeDirectory
                .appending(path: "Library/Application Support/AutomationHealth/manual-records.json")
        )
    }

    public func loadRecords() throws -> [ManualAutomationRecord] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([ManualAutomationRecord].self, from: data)
    }

    @discardableResult
    public func create(_ draft: ManualRecordDraft, now: Date = Date()) throws -> ManualAutomationRecord {
        var records = try loadRecords()
        let record = ManualAutomationRecord(
            name: try normalizedName(from: draft),
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            command: normalizedOptional(draft.command),
            scheduleDescription: normalizedOptional(draft.scheduleDescription),
            origin: draft.origin,
            createdAt: now,
            updatedAt: now
        )
        records.append(record)
        try save(records)
        return record
    }

    @discardableResult
    public func update(id: UUID, draft: ManualRecordDraft, now: Date = Date()) throws -> ManualAutomationRecord {
        var records = try loadRecords()
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            throw StoreError.missingRecord(id)
        }

        let existing = records[index]
        let updated = ManualAutomationRecord(
            id: existing.id,
            name: try normalizedName(from: draft),
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            command: normalizedOptional(draft.command),
            scheduleDescription: normalizedOptional(draft.scheduleDescription),
            origin: draft.origin,
            createdAt: existing.createdAt,
            updatedAt: now
        )
        records[index] = updated
        try save(records)
        return updated
    }

    public func delete(id: UUID) throws {
        var records = try loadRecords()
        records.removeAll { $0.id == id }
        try save(records)
    }

    private func save(_ records: [ManualAutomationRecord]) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(records)
        try data.write(to: fileURL, options: [.atomic])
    }

    private func normalizedName(from draft: ManualRecordDraft) throws -> String {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw StoreError.emptyName
        }
        return name
    }

    private func normalizedOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public struct ManualRecordScanner: JobScanning, Sendable {
    private let store: ManualRecordStore

    public init(store: ManualRecordStore) {
        self.store = store
    }

    public func scan() throws -> JobScanResult {
        do {
            return JobScanResult(jobs: try store.loadRecords().map(\.scheduledJob))
        } catch {
            return JobScanResult(
                jobs: [],
                notes: [
                    ScanNote(
                        source: .manualRecords,
                        severity: .warning,
                        message: "Manual records unavailable",
                        detail: error.localizedDescription
                    )
                ]
            )
        }
    }
}
