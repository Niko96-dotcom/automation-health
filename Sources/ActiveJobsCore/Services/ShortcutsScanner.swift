import Foundation

public protocol ShortcutsCommandRunning: Sendable {
    func listShortcuts() -> ShortcutsCommandResult
}

public struct ShortcutsCommandResult: Sendable, Hashable {
    public let output: String
    public let errorOutput: String
    public let exitCode: Int32

    public init(output: String, errorOutput: String, exitCode: Int32) {
        self.output = output
        self.errorOutput = errorOutput
        self.exitCode = exitCode
    }
}

public struct ProcessShortcutsCommandRunner: ShortcutsCommandRunning, Sendable {
    public init() {}

    public func listShortcuts() -> ShortcutsCommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list", "--show-identifiers"]

        let output = Pipe()
        let errorOutput = Pipe()
        process.standardOutput = output
        process.standardError = errorOutput

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ShortcutsCommandResult(output: "", errorOutput: error.localizedDescription, exitCode: 127)
        }

        return ShortcutsCommandResult(
            output: String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            errorOutput: String(data: errorOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }
}

public struct ShortcutsScanner: JobScanning, Sendable {
    private let commandRunner: ShortcutsCommandRunning

    public init(commandRunner: ShortcutsCommandRunning = ProcessShortcutsCommandRunner()) {
        self.commandRunner = commandRunner
    }

    public func scan() throws -> JobScanResult {
        let result = commandRunner.listShortcuts()
        guard result.exitCode == 0 else {
            return JobScanResult(notes: [
                ScanNote(
                    source: .shortcuts,
                    severity: .warning,
                    message: "Shortcuts list failed",
                    detail: result.errorOutput.isEmpty ? "exit \(result.exitCode)" : result.errorOutput
                )
            ])
        }

        let jobs = result.output
            .components(separatedBy: .newlines)
            .compactMap(parseShortcutLine)

        return JobScanResult(jobs: jobs, notes: [])
    }

    private func parseShortcutLine(_ rawLine: String) -> ScheduledJob? {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let parsed = shortcutNameAndIdentifier(from: trimmed)
        let identifier = parsed.identifier ?? slug(from: parsed.name)
        let definition = parsed.identifier.map { "\(parsed.name) (\($0))" } ?? parsed.name

        return ScheduledJob(
            id: "shortcut-\(slug(from: identifier))",
            name: parsed.name,
            source: .shortcuts,
            confidence: .registered,
            origin: .userAuthored,
            schedule: "Registered shortcut (no schedule evidence)",
            command: nil,
            state: "registered",
            lastStatus: nil,
            lastRun: nil,
            nextRun: nil,
            definition: definition,
            lastRunDetails: nil,
            detailPath: nil
        )
    }

    private func shortcutNameAndIdentifier(from line: String) -> (name: String, identifier: String?) {
        guard
            line.last == ")",
            let openIndex = line.lastIndex(of: "("),
            openIndex > line.startIndex
        else {
            return (line, nil)
        }

        let name = line[..<openIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        let identifierStart = line.index(after: openIndex)
        let identifierEnd = line.index(before: line.endIndex)
        let identifier = String(line[identifierStart..<identifierEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (name.isEmpty ? line : name, identifier.isEmpty ? nil : identifier)
    }

    private func slug(from value: String) -> String {
        let scalars = value.lowercased().unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars).split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? "shortcut" : collapsed
    }
}
