import Foundation

public struct CandidateScriptScanner: JobScanning, @unchecked Sendable {
    public struct Configuration: Hashable, Sendable {
        public let maxDepth: Int
        public let maxVisitedFiles: Int
        public let maxResults: Int
        public let maximumCandidateBytes: Int
        public let scriptExtensions: Set<String>
        public let ignoredDirectoryNames: Set<String>

        public static let `default` = Configuration(
            maxDepth: 2,
            maxVisitedFiles: 2_000,
            maxResults: 200,
            maximumCandidateBytes: 1_000_000,
            scriptExtensions: ["sh", "zsh", "bash", "command", "py", "rb", "js", "swift", "scpt", "applescript", "pl"],
            ignoredDirectoryNames: [".git", ".build", "build", "dist", "DerivedData", "node_modules", "vendor", ".venv", "venv", "__pycache__", ".swiftpm"]
        )

        public init(
            maxDepth: Int,
            maxVisitedFiles: Int,
            maxResults: Int,
            maximumCandidateBytes: Int,
            scriptExtensions: Set<String>,
            ignoredDirectoryNames: Set<String>
        ) {
            self.maxDepth = maxDepth
            self.maxVisitedFiles = maxVisitedFiles
            self.maxResults = maxResults
            self.maximumCandidateBytes = maximumCandidateBytes
            self.scriptExtensions = scriptExtensions
            self.ignoredDirectoryNames = ignoredDirectoryNames
        }
    }

    private let homeDirectory: URL
    private let candidateRootDirectories: [URL]?
    private let configuration: Configuration
    private let fileManager: FileManager

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        candidateRootDirectories: [URL]? = nil,
        configuration: Configuration = .default,
        fileManager: FileManager = .default
    ) {
        self.homeDirectory = homeDirectory
        self.candidateRootDirectories = candidateRootDirectories
        self.configuration = configuration
        self.fileManager = fileManager
    }

    public func scan() throws -> JobScanResult {
        var jobs: [ScheduledJob] = []
        var notes: [ScanNote] = []
        var visitedFiles = 0
        var stopScanning = false

        for root in roots {
            guard !stopScanning else {
                break
            }

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                notes.append(ScanNote(
                    source: .candidateScripts,
                    severity: .info,
                    message: "Missing candidate script directory",
                    detail: root.path
                ))
                continue
            }

            scanDirectory(
                root: root,
                directory: root,
                depth: 0,
                jobs: &jobs,
                notes: &notes,
                visitedFiles: &visitedFiles,
                stopScanning: &stopScanning
            )
        }

        return JobScanResult(jobs: jobs, notes: notes)
    }

    private var roots: [URL] {
        candidateRootDirectories ?? [
            homeDirectory.appending(path: "Scripts"),
            homeDirectory.appending(path: "bin"),
            homeDirectory.appending(path: ".local/bin"),
            homeDirectory.appending(path: "Library/Scripts"),
            homeDirectory.appending(path: "Documents/Scripts")
        ]
    }

    private func scanDirectory(
        root: URL,
        directory: URL,
        depth: Int,
        jobs: inout [ScheduledJob],
        notes: inout [ScanNote],
        visitedFiles: inout Int,
        stopScanning: inout Bool
    ) {
        guard !stopScanning else {
            return
        }

        let children: [URL]
        do {
            children = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isExecutableKey, .fileSizeKey],
                options: []
            )
        } catch {
            notes.append(ScanNote(
                source: .candidateScripts,
                severity: .warning,
                message: "Unreadable candidate script directory",
                detail: "\(directory.path): \(error.localizedDescription)"
            ))
            return
        }

        for child in children.sorted(by: { $0.path.localizedStandardCompare($1.path) == .orderedAscending }) {
            guard !stopScanning else {
                break
            }

            let name = child.lastPathComponent
            if name.hasPrefix(".") {
                notes.append(ScanNote(
                    source: .candidateScripts,
                    severity: .info,
                    message: "Ignored candidate path",
                    detail: child.path
                ))
                continue
            }

            let values = (try? child.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .isExecutableKey, .fileSizeKey])) ?? URLResourceValues()

            if values.isDirectory == true {
                guard !configuration.ignoredDirectoryNames.contains(name) else {
                    notes.append(ScanNote(
                        source: .candidateScripts,
                        severity: .info,
                        message: "Ignored candidate path",
                        detail: child.path
                    ))
                    continue
                }

                guard depth < configuration.maxDepth else {
                    continue
                }

                scanDirectory(
                    root: root,
                    directory: child,
                    depth: depth + 1,
                    jobs: &jobs,
                    notes: &notes,
                    visitedFiles: &visitedFiles,
                    stopScanning: &stopScanning
                )
                continue
            }

            guard values.isRegularFile == true else {
                continue
            }

            visitedFiles += 1
            if visitedFiles >= configuration.maxVisitedFiles {
                notes.append(ScanNote(
                    source: .candidateScripts,
                    severity: .warning,
                    message: "Candidate scan visited-file cap reached",
                    detail: "\(configuration.maxVisitedFiles)"
                ))
                stopScanning = true
                break
            }

            if let fileSize = values.fileSize, fileSize > configuration.maximumCandidateBytes {
                notes.append(ScanNote(
                    source: .candidateScripts,
                    severity: .info,
                    message: "Skipped oversized candidate script",
                    detail: child.path
                ))
                continue
            }

            guard isCandidateScript(child, root: root, isExecutable: values.isExecutable == true) else {
                continue
            }

            if jobs.count >= configuration.maxResults {
                notes.append(ScanNote(
                    source: .candidateScripts,
                    severity: .warning,
                    message: "Candidate scan result cap reached",
                    detail: "\(configuration.maxResults)"
                ))
                stopScanning = true
                break
            }

            jobs.append(candidateJob(for: child))
        }
    }

    private func isCandidateScript(_ url: URL, root: URL, isExecutable: Bool) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        if configuration.scriptExtensions.contains(pathExtension) {
            return true
        }

        return pathExtension.isEmpty && isExecutable && allowsExtensionlessExecutables(root: root)
    }

    private func allowsExtensionlessExecutables(root: URL) -> Bool {
        let components = root.standardizedFileURL.pathComponents
        return root.lastPathComponent == "bin" || components.suffix(2) == [".local", "bin"]
    }

    private func candidateJob(for url: URL) -> ScheduledJob {
        ScheduledJob(
            id: "candidate-\(slug(from: url.path))",
            name: url.deletingPathExtension().lastPathComponent,
            source: .candidateScripts,
            confidence: .candidate,
            origin: .userAuthored,
            schedule: "Script candidate (no schedule evidence)",
            command: url.path,
            state: "candidate",
            lastStatus: nil,
            lastRun: nil,
            nextRun: nil,
            definition: "Candidate script discovered at \(url.path).",
            lastRunDetails: nil,
            detailPath: url.path
        )
    }

    private func slug(from value: String) -> String {
        let scalars = value.lowercased().unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars).split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? "script" : collapsed
    }
}
