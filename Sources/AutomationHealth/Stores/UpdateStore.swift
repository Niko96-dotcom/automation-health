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
final class UpdateStore: NSObject, ObservableObject {
    @Published var currentVersion: String = ""
    @Published var canCheckForUpdates: Bool = false
    @Published var updateState: UpdateState = .idle
    @Published var automaticallyChecksForUpdates: Bool = true
    @Published var updatesUnavailableReason: String?

    private var updater: SPUUpdater!
    private let policy: UpdatePolicy

    static func make(bundle: Bundle = .main) -> UpdateStore {
        UpdateStore(policy: .current(bundle: bundle), bundle: bundle)
    }

    private init(policy: UpdatePolicy, bundle: Bundle) {
        self.policy = policy
        super.init()

        let userDriver = SPUStandardUserDriver(hostBundle: bundle, delegate: nil)
        self.updater = SPUUpdater(
            hostBundle: bundle,
            applicationBundle: bundle,
            userDriver: userDriver,
            delegate: self
        )

        currentVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? bundle.infoDictionary?["CFBundleVersion"] as? String
            ?? "Unknown"
        automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        canCheckForUpdates = updater.canCheckForUpdates
        updatesUnavailableReason = policy.unavailableReason
    }

    func startUpdater() {
        if updatesUnavailableReason != nil {
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

    var checkStatusMessage: String? {
        switch updateState {
        case .upToDate:
            return "You're up to date."
        case .updateAvailable(let version):
            return "Update available: \(version). Use Check for Updates to install."
        case .idle, .checking, .error:
            return nil
        }
    }

    private var cancellables = Set<AnyCancellable>()
}

extension UpdateStore: SPUUpdaterDelegate {
    func feedURLString(for updater: SPUUpdater) -> String? {
        policy.feedURLString
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        updateState = .updateAvailable(version: item.displayVersionString)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        applyUpdateCheckResult(error)
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: (any Error)?
    ) {
        if let error {
            applyUpdateCheckResult(error)
        } else if case .checking = updateState {
            updateState = .idle
        }
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        updateState = .error(message: error.localizedDescription)
    }

    private func applyUpdateCheckResult(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == SUSparkleErrorDomain, nsError.code == SUError.noUpdateError.rawValue {
            updateState = .upToDate
        } else {
            updateState = .error(message: error.localizedDescription)
        }
    }
}
