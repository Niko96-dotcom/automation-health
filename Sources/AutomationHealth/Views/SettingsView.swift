import SwiftUI
import AutomationHealthCore

struct SettingsView: View {
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var updateStore: UpdateStore

    private var maxDepthBinding: Binding<Double> {
        Binding(
            get: { Double(preferences.scanMaxDepth) },
            set: { preferences.scanMaxDepth = Int($0) }
        )
    }

    private var maxResultsBinding: Binding<Double> {
        Binding(
            get: { Double(preferences.scanMaxResults) },
            set: { preferences.scanMaxResults = Int($0) }
        )
    }

    var body: some View {
        Form {
            Section("Default View") {
                Picker("Default Grouping", selection: $preferences.groupingMode) {
                    ForEach(SidebarGroupingMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
            }

            Section("Candidate Scanning") {
                Toggle("Scan for candidate scripts on launch", isOn: $preferences.scanOnLaunch)
                Text("When enabled, Automation Health searches supported script directories for automations that may not be registered in a known scheduler.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: maxDepthBinding, in: 0...5, step: 1) {
                    Text("Maximum Scan Depth")
                }
                Text("Limits how many subdirectory levels the candidate scanner traverses. Depth 0 scans only the top-level script directories.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: maxResultsBinding, in: 10...500, step: 10) {
                    Text("Maximum Results Per Scan")
                }
                Text("Limits the total number of candidate records produced by a single scan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Updates") {
                if let reason = updateStore.updatesUnavailableReason {
                    LabeledContent("Update checking is unavailable") {
                        Text("Unavailable")
                            .foregroundStyle(.secondary)
                    }
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if case .error(let message) = updateStore.updateState {
                    LabeledContent("Update checking is unavailable") {
                        Text("Unavailable")
                            .foregroundStyle(.secondary)
                    }
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    LabeledContent("Current Version") {
                        if case .checking = updateStore.updateState {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16, height: 16)
                                Text(updateStore.currentVersion)
                            }
                        } else {
                            Text(updateStore.currentVersion)
                        }
                    }

                    if let statusMessage = updateStore.checkStatusMessage {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Automatically check for updates", isOn: Binding(
                        get: { updateStore.automaticallyChecksForUpdates },
                        set: { updateStore.setAutomaticallyChecksForUpdates($0) }
                    ))

                    Button("Check for Updates") {
                        updateStore.checkForUpdates()
                    }
                    .disabled(!updateStore.canCheckForUpdates || updateStore.updateState == .checking)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
    }
}
