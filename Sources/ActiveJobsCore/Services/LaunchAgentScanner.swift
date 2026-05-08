import Foundation

public struct LaunchAgentScanner: JobScanning, @unchecked Sendable {
    private let homeDirectory: URL
    private let launchAgentDirectories: [URL]
    private let fileManager: FileManager

    public init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        launchAgentDirectories: [URL]? = nil,
        fileManager: FileManager = .default
    ) {
        self.homeDirectory = homeDirectory
        self.launchAgentDirectories = launchAgentDirectories ?? [
            homeDirectory.appending(path: "Library/LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchDaemons")
        ]
        self.fileManager = fileManager
    }

    public func scan() throws -> [ScheduledJob] {
        try launchAgentDirectories.flatMap(scanDirectory)
    }

    private func scanDirectory(_ directory: URL) throws -> [ScheduledJob] {
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        let files = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return files
            .filter { $0.pathExtension == "plist" }
            .compactMap(parsePlist)
    }

    private func parsePlist(_ url: URL) -> ScheduledJob? {
        guard
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else {
            return nil
        }

        let label = plist["Label"] as? String ?? url.deletingPathExtension().lastPathComponent
        let command = command(from: plist)
        let schedule = scheduleDescription(from: plist)
        guard schedule != nil || shouldShowRunAtLoadJob(label: label, command: command, plist: plist) else {
            return nil
        }

        let stdout = plist["StandardOutPath"] as? String
        let stderr = plist["StandardErrorPath"] as? String
        let logPath = stdout ?? stderr
        let logURL = logPath.map(URL.init(fileURLWithPath:))
        let logContents = logURL.flatMap(TextSnippetReader.read(url:))
        let logModified = logURL.flatMap { modifiedDate(for: $0) }
        let launchState = LaunchctlStatusReader.status(label: label)

        return ScheduledJob(
            id: label,
            name: label,
            source: .launchd,
            schedule: schedule ?? loginScheduleDescription(from: plist),
            command: command,
            state: launchState.state ?? "loaded",
            lastStatus: launchState.lastExitCode.map { "exit \($0)" },
            lastRun: logModified,
            nextRun: nil,
            definition: "LaunchAgent plist: \(url.path)",
            lastRunDetails: logContents,
            detailPath: logPath
        )
    }

    private func command(from plist: [String: Any]) -> String? {
        if let args = plist["ProgramArguments"] as? [String], !args.isEmpty {
            return args.joined(separator: " ")
        }

        if let program = plist["Program"] as? String, !program.isEmpty {
            return program
        }

        return nil
    }

    private func scheduleDescription(from plist: [String: Any]) -> String? {
        if let calendar = plist["StartCalendarInterval"] {
            return calendarDescription(calendar)
        }

        if let interval = plist["StartInterval"] as? Int {
            return intervalDescription(seconds: interval)
        }

        if let watchPaths = plist["WatchPaths"] as? [String], !watchPaths.isEmpty {
            return "watches: \(watchPaths.joined(separator: ", "))"
        }

        if let queueDirectories = plist["QueueDirectories"] as? [String], !queueDirectories.isEmpty {
            return "queues: \(queueDirectories.joined(separator: ", "))"
        }

        return nil
    }

    private func calendarDescription(_ value: Any) -> String {
        let entries: [[String: Any]]
        if let array = value as? [[String: Any]] {
            entries = array
        } else if let dictionary = value as? [String: Any] {
            entries = [dictionary]
        } else {
            return "calendar"
        }

        let formatted = entries.map { entry in
            let hour = entry["Hour"] as? Int
            let minute = entry["Minute"] as? Int
            let time: String
            if let hour, let minute {
                time = String(format: "%02d:%02d", hour, minute)
            } else {
                time = "calendar"
            }

            let weekday = (entry["Weekday"] as? Int).map { "weekday \($0)" }
            let day = (entry["Day"] as? Int).map { "day \($0)" }
            return [weekday, day, time].compactMap(\.self).joined(separator: " ")
        }

        return formatted.joined(separator: ", ")
    }

    private func intervalDescription(seconds: Int) -> String {
        if seconds % 3600 == 0 {
            let hours = seconds / 3600
            return hours == 1 ? "every hour" : "every \(hours) hours"
        }

        if seconds % 60 == 0 {
            let minutes = seconds / 60
            return "every \(minutes) minutes"
        }

        return "every \(seconds) seconds"
    }

    private func shouldShowRunAtLoadJob(label: String, command: String?, plist: [String: Any]) -> Bool {
        let runAtLoad = plist["RunAtLoad"] as? Bool == true
        let keepAlive = plist["KeepAlive"] != nil
        guard runAtLoad || keepAlive else {
            return false
        }

        let searchable = "\(label) \(command ?? "")".lowercased()
        let interestingTerms = [
            "hermes", "codex", "knowledge", "clipper", ".py", ".sh", ".zsh",
            "python", "node", "script", "download"
        ]
        return interestingTerms.contains { searchable.contains($0) }
    }

    private func loginScheduleDescription(from plist: [String: Any]) -> String {
        var parts: [String] = []
        if plist["RunAtLoad"] as? Bool == true {
            parts.append("at login")
        }
        if plist["KeepAlive"] != nil {
            parts.append("keep alive")
        }
        return parts.isEmpty ? "loaded" : parts.joined(separator: ", ")
    }

    private func modifiedDate(for url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}

private struct LaunchctlStatusReader {
    static func status(label: String) -> (state: String?, lastExitCode: Int?) {
        let uid = getuid()
        let output = runLaunchctl(arguments: ["print", "gui/\(uid)/\(label)"])
            ?? runLaunchctl(arguments: ["print", "system/\(label)"])
            ?? ""

        let state = firstMatch(in: output, pattern: #"state = ([^\n]+)"#)
        let exitCode = firstMatch(in: output, pattern: #"last exit code = (-?\d+)"#).flatMap(Int.init)
        return (state, exitCode)
    }

    private static func runLaunchctl(arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard
            let match = regex.firstMatch(in: text, range: range),
            match.numberOfRanges > 1,
            let swiftRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
