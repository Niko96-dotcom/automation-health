import SwiftUI
import ActiveJobsCore

struct ContentView: View {
    @ObservedObject var store: JobStore
    @State private var searchText = ""

    private var filteredJobs: [JobPresentation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return store.jobs
        }

        return store.jobs.filter { $0.searchText.contains(query) }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                jobs: filteredJobs,
                selectedJobID: $store.selectedJobID,
                lastScannedDescription: store.lastScannedDescription,
                isScanning: store.isScanning
            )
            .searchable(text: $searchText, placement: .sidebar)
            .navigationSplitViewColumnWidth(min: 280, ideal: 340)
        } detail: {
            DetailView(job: store.selectedJob, errorMessage: store.errorMessage)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    store.refresh()
                } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
                .help("Scan launchd and Hermes cron jobs again")
                .disabled(store.isScanning)
            }
        }
    }
}
