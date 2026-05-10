import Foundation

public struct AutomatorScanner: JobScanning, @unchecked Sendable {
    private let homeDirectory: URL
    private let workflowDirectories: [URL]?
    private let fileManager: FileManager

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        workflowDirectories: [URL]? = nil,
        fileManager: FileManager = .default
    ) {
        self.homeDirectory = homeDirectory
        self.workflowDirectories = workflowDirectories
        self.fileManager = fileManager
    }

    public func scan() throws -> JobScanResult {
        let directories = workflowDirectories ?? [
            homeDirectory.appending(path: "Library/Services"),
            homeDirectory.appending(path: "Library/Workflows")
        ]
        var jobs: [ScheduledJob] = []
        var notes: [ScanNote] = []

        for directory in directories {
            guard fileManager.fileExists(atPath: directory.path) else {
                notes.append(ScanNote(
                    source: .automator,
                    severity: .info,
                    message: "Missing Automator workflow directory",
                    detail: directory.path
                ))
                continue
            }

            do {
                let children = try fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )

                for child in children {
                    if let parsed = parseWorkflow(at: child, notes: &notes) {
                        jobs.append(parsed)
                    }
                }
            } catch {
                notes.append(ScanNote(
                    source: .automator,
                    severity: .warning,
                    message: "Unreadable Automator workflow directory",
                    detail: "\(directory.path): \(error.localizedDescription)"
                ))
            }
        }

        return JobScanResult(jobs: jobs, notes: notes)
    }

    private func parseWorkflow(at url: URL, notes: inout [ScanNote]) -> ScheduledJob? {
        let pathExtension = url.pathExtension.lowercased()
        guard pathExtension == "workflow" || pathExtension == "app" else {
            return nil
        }

        var info: [String: Any] = [:]
        let infoURL = url.appending(path: "Contents/Info.plist")
        if fileManager.fileExists(atPath: infoURL.path) {
            do {
                let data = try Data(contentsOf: infoURL)
                info = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] ?? [:]
            } catch {
                notes.append(ScanNote(
                    source: .automator,
                    severity: .warning,
                    message: "Unreadable Automator workflow metadata",
                    detail: "\(infoURL.path): \(error.localizedDescription)"
                ))
            }
        }

        guard pathExtension == "workflow" || isAutomatorApp(info: info) else {
            return nil
        }

        let name = (info["CFBundleDisplayName"] as? String)
            ?? (info["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent

        return ScheduledJob(
            id: "automator-\(slug(from: url.path))",
            name: name,
            source: .automator,
            confidence: .registered,
            origin: automatorOrigin(for: url),
            schedule: "Automator workflow (no schedule evidence)",
            command: nil,
            state: "registered",
            lastStatus: nil,
            lastRun: nil,
            nextRun: nil,
            definition: "Automator workflow: \(url.path)",
            lastRunDetails: nil,
            detailPath: url.path
        )
    }

    private func isAutomatorApp(info: [String: Any]) -> Bool {
        let searchable = [
            info["CFBundleDisplayName"] as? String,
            info["CFBundleName"] as? String,
            info["CFBundleIdentifier"] as? String,
            info["AMApplicationBuild"] as? String,
            info["NSHumanReadableCopyright"] as? String
        ]
            .compactMap(\.self)
            .joined(separator: " ")
            .lowercased()

        return searchable.contains("automator") || searchable.contains("workflow")
    }

    private func automatorOrigin(for url: URL) -> JobOrigin {
        let workflowPaths = [
            url.path,
            url.standardizedFileURL.path,
            url.resolvingSymlinksInPath().path
        ]
        let homePaths = [
            homeDirectory.path,
            homeDirectory.standardizedFileURL.path,
            homeDirectory.resolvingSymlinksInPath().path
        ]

        if workflowPaths.contains(where: { workflowPath in
            homePaths.contains(where: { workflowPath.hasPrefix($0) })
        }) {
            return .userAuthored
        }

        return .unknown
    }

    private func slug(from value: String) -> String {
        let scalars = value.lowercased().unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars).split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? "workflow" : collapsed
    }
}
