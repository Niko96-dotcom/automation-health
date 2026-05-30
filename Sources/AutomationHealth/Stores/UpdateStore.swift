import Combine
import Foundation
import Sparkle

/// Represents the current state of the Sparkle update cycle.
enum UpdateState: Equatable {
    case idle
    case checking
    case updateAvailable(version: String)
    case upToDate
    case error(message: String)
}

@MainActor
final class UpdateStore: ObservableObject {
    @Published var currentVersion: String = ""
    @Published var canCheckForUpdates: Bool = false
    @Published var updateState: UpdateState = .idle
    @Published var automaticallyChecksForUpdates: Bool = true
    @Published var updatesUnavailableReason: String?

    let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            ?? "Unknown"
        self.automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        self.canCheckForUpdates = updater.canCheckForUpdates
        updatesUnavailableReason = Self.updatesUnavailableReasonIfAny()
    }

    func startUpdater() {
        if let reason = updatesUnavailableReason {
            canCheckForUpdates = false
            automaticallyChecksForUpdates = false
            updater.automaticallyChecksForUpdates = false
            return
        }

        do {
            try updater.start()
        } catch {
            updateState = .error(message: error.localizedDescription)
            canCheckForUpdates = false
            return
        }

        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)

        updater.publisher(for: \.sessionInProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inProgress in
                guard let self else { return }
                if inProgress {
                    updateState = .checking
                } else if case .checking = updateState {
                    // Sparkle clears sessionInProgress before delegate callbacks in some paths.
                    updateState = .idle
                }
            }
            .store(in: &cancellables)
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        automaticallyChecksForUpdates = enabled
        updater.automaticallyChecksForUpdates = enabled
    }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Sparkle Delegate Bridge

/// Bridges SPUUpdaterDelegate callbacks to UpdateStore's published state.
/// Instantiated by AutomationHealthApp (plan 14-02) and passed as the
/// SPUUpdater's delegate.  UpdateStore observes KVO properties; the delegate
/// transitions updateState for events KVO does not cover (found/not-found/error).
@MainActor
final class UpdateStoreDelegate: NSObject, SPUUpdaterDelegate {
    var store: UpdateStore?

    private static let releaseAppcastFeedURL =
        "https://github.com/Niko96-dotcom/automation-health/releases/latest/download/appcast.xml"

    /// Provides the appcast feed URL for the Sparkle updater.
    /// Uses the latest GitHub Release asset so older installed versions can discover new builds.
    /// Dev builds (suffixed with -dev or version 0.0.0) return nil
    /// because no corresponding release appcast exists to check against.
    func feedURLString(for updater: SPUUpdater) -> String? {
        guard let info = Bundle.main.infoDictionary,
              let version = info["CFBundleShortVersionString"] as? String,
              !UpdateStore.isLocalDevelopmentVersion(version) else {
            return nil
        }
        return Self.releaseAppcastFeedURL
    }

    /// Called when Sparkle discovers a valid update in the appcast.
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        store?.updateState = .updateAvailable(version: item.displayVersionString)
    }

    /// Called when Sparkle completes a check and finds no update.
    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        store?.applyUpdateCheckResult(error)
    }

    /// Called when the update driver finishes an update check cycle.
    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: (any Error)?
    ) {
        guard let store else { return }
        if let error {
            store.applyUpdateCheckResult(error)
        } else if case .checking = store.updateState {
            store.updateState = .idle
        }
    }

    /// Called when the update driver aborts with an error (e.g. download failure).
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        store?.updateState = .error(message: error.localizedDescription)
    }
}

extension UpdateStore {
    static func isLocalDevelopmentVersion(_ version: String) -> Bool {
        version.hasSuffix("-dev") || version == "0.0.0-dev" || version == "0.0.0"
    }

    static func updatesUnavailableReasonIfAny() -> String? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "This build has no bundle version."
        }

        if Self.isLocalDevelopmentVersion(version) {
            return "Local development builds do not check for updates. Install a release from GitHub Releases to use Sparkle."
        }

        guard let publicKey = Bundle.main.infoDictionary?["SUPublicEDKey"] as? String,
              !publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "This build has no Sparkle public key configured."
        }

        return nil
    }

    fileprivate func applyUpdateCheckResult(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == SUSparkleErrorDomain, nsError.code == SUError.noUpdateError.rawValue {
            updateState = .upToDate
        } else {
            updateState = .error(message: error.localizedDescription)
        }
    }
}
