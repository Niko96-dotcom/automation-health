import Foundation

enum UpdatePolicy: Equatable {
    case enabled(feedURL: URL)
    case disabled(reason: String)

    private static let releaseAppcastFeedURL = URL(
        string: "https://github.com/Niko96-dotcom/automation-health/releases/latest/download/appcast.xml"
    )!

    static func current(bundle: Bundle = .main) -> UpdatePolicy {
        guard let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return .disabled(reason: "This build has no bundle version.")
        }

        if isLocalDevelopmentVersion(version) {
            return .disabled(
                reason: "Local development builds do not check for updates. Install a release from GitHub Releases to use Sparkle."
            )
        }

        guard let publicKey = bundle.infoDictionary?["SUPublicEDKey"] as? String,
              !publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .disabled(reason: "This build has no Sparkle public key configured.")
        }

        return .enabled(feedURL: releaseAppcastFeedURL)
    }

    var feedURLString: String? {
        switch self {
        case .enabled(let feedURL):
            return feedURL.absoluteString
        case .disabled:
            return nil
        }
    }

    var unavailableReason: String? {
        switch self {
        case .enabled:
            return nil
        case .disabled(let reason):
            return reason
        }
    }

    static func isLocalDevelopmentVersion(_ version: String) -> Bool {
        version.hasSuffix("-dev") || version == "0.0.0-dev" || version == "0.0.0"
    }
}
