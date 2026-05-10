import Combine
import Foundation
import ActiveJobsCore
import AutomationHealthCore

@MainActor
final class JobStore: ObservableObject {
    private struct PendingRefresh {
        let preferredSelectionID: String?
    }

    @Published private(set) var jobs: [JobPresentation] = []
    @Published private(set) var scanNotes: [ScanNote] = []
    @Published var selectedJobID: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isScanning = false
    @Published private(set) var lastScannedAt: Date?

    private let inventory: JobInventory
    private let manualRecordStore: ManualRecordStore
    private var pendingRefresh: PendingRefresh?

    init(inventory: JobInventory? = nil, manualRecordStore: ManualRecordStore = .live()) {
        self.manualRecordStore = manualRecordStore
        self.inventory = inventory ?? JobInventory.live(
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
            manualRecordStore: manualRecordStore
        )
    }

    var selectedJob: JobPresentation? {
        guard let selectedJobID else {
            return jobs.first
        }
        return jobs.first { $0.id == selectedJobID }
    }

    var lastScannedDescription: String {
        guard let lastScannedAt else {
            return "Not scanned yet"
        }
        return AppDateFormatters.shortTime.string(from: lastScannedAt)
    }

    func refresh() {
        refresh(preferredSelectionID: nil)
    }

    func addManualRecord(_ draft: ManualRecordDraft) {
        do {
            let record = try manualRecordStore.create(draft)
            refresh(preferredSelectionID: record.scheduledJob.selectionID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateManualRecord(id: UUID, draft: ManualRecordDraft) {
        do {
            let record = try manualRecordStore.update(id: id, draft: draft)
            refresh(preferredSelectionID: record.scheduledJob.selectionID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeManualRecord(id: UUID) {
        let removedSelectionID = manualSelectionID(for: id)
        let preferredSelectionID: String?
        if selectedJobID == removedSelectionID, let selectedIndex = jobs.firstIndex(where: { $0.id == removedSelectionID }) {
            let remainingIDs = jobs.map(\.id).filter { $0 != removedSelectionID }
            preferredSelectionID = remainingIDs.indices.contains(selectedIndex) ? remainingIDs[selectedIndex] : remainingIDs.first
        } else {
            preferredSelectionID = selectedJobID
        }

        do {
            try manualRecordStore.delete(id: id)
            refresh(preferredSelectionID: preferredSelectionID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refresh(preferredSelectionID: String?) {
        guard !isScanning else {
            pendingRefresh = PendingRefresh(preferredSelectionID: preferredSelectionID)
            return
        }

        isScanning = true
        let inventory = inventory

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    let now = Date()
                    let result = try inventory.refresh()
                    return (
                        jobs: result.jobs.map { JobPresentation(job: $0, now: now) },
                        notes: result.notes
                    )
                }
            }.value

            switch result {
            case let .success(refreshed):
                jobs = refreshed.jobs
                scanNotes = refreshed.notes
                errorMessage = nil
                lastScannedAt = Date()

                if let preferredSelectionID, refreshed.jobs.contains(where: { $0.id == preferredSelectionID }) {
                    selectedJobID = preferredSelectionID
                    break
                }

                if let selectedJobID, refreshed.jobs.contains(where: { $0.id == selectedJobID }) {
                    break
                }
                selectedJobID = refreshed.jobs.first?.id
            case let .failure(error):
                errorMessage = error.localizedDescription
                scanNotes = [
                    ScanNote(
                        source: .launchd,
                        severity: .error,
                        message: "Scan failed",
                        detail: error.localizedDescription
                    )
                ]
                lastScannedAt = Date()
            }

            let queuedRefresh = self.pendingRefresh
            self.pendingRefresh = nil
            isScanning = false

            if let queuedRefresh {
                refresh(preferredSelectionID: queuedRefresh.preferredSelectionID)
            }
        }
    }

    private func manualSelectionID(for id: UUID) -> String {
        "\(JobSource.manualRecords.rawValue):manual-\(id.uuidString)"
    }
}

enum AppDateFormatters {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
