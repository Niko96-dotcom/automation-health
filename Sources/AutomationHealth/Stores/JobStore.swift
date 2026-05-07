import Combine
import Foundation
import ActiveJobsCore

@MainActor
final class JobStore: ObservableObject {
    @Published private(set) var jobs: [JobPresentation] = []
    @Published var selectedJobID: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isScanning = false
    @Published private(set) var lastScannedAt: Date?

    private let inventory: JobInventory

    init(inventory: JobInventory = .live()) {
        self.inventory = inventory
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
        guard !isScanning else {
            return
        }

        isScanning = true
        let inventory = inventory

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    let now = Date()
                    return try inventory.refresh().map { JobPresentation(job: $0, now: now) }
                }
            }.value

            switch result {
            case let .success(refreshed):
                jobs = refreshed
                errorMessage = nil
                lastScannedAt = Date()

                if let selectedJobID, refreshed.contains(where: { $0.id == selectedJobID }) {
                    break
                }
                selectedJobID = refreshed.first?.id
            case let .failure(error):
                errorMessage = error.localizedDescription
                lastScannedAt = Date()
            }

            isScanning = false
        }
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
