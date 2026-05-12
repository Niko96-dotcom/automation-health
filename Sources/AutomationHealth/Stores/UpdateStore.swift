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

    let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            ?? "Unknown"
        self.automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        self.canCheckForUpdates = updater.canCheckForUpdates
    }

    func startUpdater() {
        do {
            try updater.start()
        } catch {
            updateState = .error(message: error.localizedDescription)
            return
        }

        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)

        updater.publisher(for: \.sessionInProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inProgress in
                if inProgress {
                    self?.updateState = .checking
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

    /// Provides the appcast feed URL for the Sparkle updater.
    /// Uses the GitHub Releases pattern established in Phase 13.
    /// Dev builds (suffixed with -dev or version 0.0.0) return nil
    /// because no corresponding release appcast exists to check against.
    func feedURLString(for updater: SPUUpdater) -> String? {
        guard let info = Bundle.main.infoDictionary,
              let version = info["CFBundleShortVersionString"] as? String,
              !version.hasSuffix("-dev"),
              !version.contains("0.0.0") else {
            return nil
        }
        return "https://github.com/nikomohr/AutomationHealth/releases/download/v\(version)/appcast.xml"
    }

    /// Called when Sparkle discovers a valid update in the appcast.
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        store?.updateState = .updateAvailable(version: item.displayVersionString)
    }

    /// Called when Sparkle completes a check and finds no update.
    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        store?.updateState = .upToDate
    }

    /// Called when the update driver aborts with an error (e.g. download failure).
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        store?.updateState = .error(message: error.localizedDescription)
    }
}
