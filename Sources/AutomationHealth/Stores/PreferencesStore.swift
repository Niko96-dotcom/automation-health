import Combine
import Foundation
import ActiveJobsCore
import AutomationHealthCore

@MainActor
final class PreferencesStore: ObservableObject {
    @Published var groupingMode: SidebarGroupingMode {
        didSet {
            UserDefaults.standard.set(groupingMode.rawValue, forKey: "sidebarGroupingMode")
        }
    }

    @Published var collapseState: SidebarCollapseState {
        didSet {
            if let data = try? JSONEncoder().encode(collapseState) {
                UserDefaults.standard.set(data, forKey: "sidebarCollapseState")
            }
        }
    }

    @Published var scanOnLaunch: Bool {
        didSet { UserDefaults.standard.set(scanOnLaunch, forKey: "scanOnLaunch") }
    }

    @Published var scanMaxDepth: Int {
        didSet { UserDefaults.standard.set(scanMaxDepth, forKey: "scanMaxDepth") }
    }

    @Published var scanMaxResults: Int {
        didSet { UserDefaults.standard.set(scanMaxResults, forKey: "scanMaxResults") }
    }

    init(userDefaults: UserDefaults = .standard) {
        userDefaults.register(defaults: [
            "sidebarGroupingMode": SidebarGroupingMode.defaultMode.rawValue,
            "scanOnLaunch": true,
            "scanMaxDepth": 2,
            "scanMaxResults": 200
        ])

        let rawGroupingMode = userDefaults.string(forKey: "sidebarGroupingMode") ?? ""
        groupingMode = SidebarGroupingMode(rawValue: rawGroupingMode) ?? .defaultMode

        if let collapseData = userDefaults.data(forKey: "sidebarCollapseState"),
           let decoded = try? JSONDecoder().decode(SidebarCollapseState.self, from: collapseData) {
            collapseState = decoded
        } else {
            collapseState = SidebarCollapseState()
        }

        scanOnLaunch = userDefaults.bool(forKey: "scanOnLaunch")
        scanMaxDepth = userDefaults.integer(forKey: "scanMaxDepth")
        scanMaxResults = userDefaults.integer(forKey: "scanMaxResults")
    }

    var candidateScannerConfiguration: CandidateScriptScanner.Configuration {
        CandidateScriptScanner.Configuration(
            maxDepth: scanMaxDepth,
            maxVisitedFiles: CandidateScriptScanner.Configuration.default.maxVisitedFiles,
            maxResults: scanMaxResults,
            maximumCandidateBytes: CandidateScriptScanner.Configuration.default.maximumCandidateBytes,
            scriptExtensions: CandidateScriptScanner.Configuration.default.scriptExtensions,
            ignoredDirectoryNames: CandidateScriptScanner.Configuration.default.ignoredDirectoryNames
        )
    }
}
