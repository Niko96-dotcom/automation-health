import Foundation

public protocol CronCommandRunning: Sendable {
    func listCurrentUserCrontab() -> CronCommandResult
}

public struct CronCommandResult: Sendable, Hashable {
    public let output: String
    public let errorOutput: String
    public let exitCode: Int32

    public init(output: String, errorOutput: String, exitCode: Int32) {
        self.output = output
        self.errorOutput = errorOutput
        self.exitCode = exitCode
    }
}

public struct ProcessCronCommandRunner: CronCommandRunning, Sendable {
    public init() {}

    public func listCurrentUserCrontab() -> CronCommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/crontab")
        process.arguments = ["-l"]

        let output = Pipe()
        let errorOutput = Pipe()
        process.standardOutput = output
        process.standardError = errorOutput

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return CronCommandResult(output: "", errorOutput: error.localizedDescription, exitCode: 127)
        }

        return CronCommandResult(
            output: String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            errorOutput: String(data: errorOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }
}

public struct CronScanner: JobScanning, @unchecked Sendable {
    private let commandRunner: CronCommandRunning
    private let systemCrontabFiles: [URL]
    private let cronTabDirectories: [URL]
    private let fileManager: FileManager

    public init(
        commandRunner: CronCommandRunning = ProcessCronCommandRunner(),
        systemCrontabFiles: [URL] = [URL(fileURLWithPath: "/etc/crontab")],
        cronTabDirectories: [URL] = [URL(fileURLWithPath: "/usr/lib/cron/tabs")],
        fileManager: FileManager = .default
    ) {
        self.commandRunner = commandRunner
        self.systemCrontabFiles = systemCrontabFiles
        self.cronTabDirectories = cronTabDirectories
        self.fileManager = fileManager
    }

    public func scan() throws -> JobScanResult {
        var jobs: [ScheduledJob] = []
        var notes: [ScanNote] = []

        let currentUserResult = commandRunner.listCurrentUserCrontab()
        if currentUserResult.exitCode == 0 {
            jobs.append(contentsOf: parseCrontab(
                currentUserResult.output,
                scope: "current-user-crontab",
                origin: .userAuthored,
                format: .user
            ))
        } else {
            notes.append(ScanNote(
                source: .cron,
                severity: .warning,
                message: "crontab -l unavailable",
                detail: currentUserResult.errorOutput.isEmpty ? "exit \(currentUserResult.exitCode)" : currentUserResult.errorOutput
            ))
        }

        for file in systemCrontabFiles {
            guard fileManager.fileExists(atPath: file.path) else {
                notes.append(ScanNote(
                    source: .cron,
                    severity: .info,
                    message: "Missing cron file",
                    detail: file.path
                ))
                continue
            }

            do {
                let contents = try String(contentsOf: file, encoding: .utf8)
                jobs.append(contentsOf: parseCrontab(
                    contents,
                    scope: "system-\(slug(from: file.path))",
                    origin: .system,
                    format: .system
                ))
            } catch {
                notes.append(ScanNote(
                    source: .cron,
                    severity: .warning,
                    message: "Unreadable cron file",
                    detail: "\(file.path): \(error.localizedDescription)"
                ))
            }
        }

        for directory in cronTabDirectories {
            guard fileManager.fileExists(atPath: directory.path) else {
                notes.append(ScanNote(
                    source: .cron,
                    severity: .info,
                    message: "Missing cron tab directory",
                    detail: directory.path
                ))
                continue
            }

            do {
                let files = try fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )

                for file in files {
                    let isDirectory = (try? file.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                    guard !isDirectory else {
                        continue
                    }

                    do {
                        let contents = try String(contentsOf: file, encoding: .utf8)
                        jobs.append(contentsOf: parseCrontab(
                            contents,
                            scope: "system-\(slug(from: file.path))",
                            origin: .system,
                            format: .system
                        ))
                    } catch {
                        notes.append(ScanNote(
                            source: .cron,
                            severity: .warning,
                            message: "Unreadable cron file",
                            detail: "\(file.path): \(error.localizedDescription)"
                        ))
                    }
                }
            } catch {
                notes.append(ScanNote(
                    source: .cron,
                    severity: .warning,
                    message: "Unreadable cron tab directory",
                    detail: "\(directory.path): \(error.localizedDescription)"
                ))
            }
        }

        return JobScanResult(jobs: jobs, notes: notes)
    }

    private func parseCrontab(
        _ contents: String,
        scope: String,
        origin: JobOrigin,
        format: CronLineFormat
    ) -> [ScheduledJob] {
        contents
            .components(separatedBy: .newlines)
            .enumerated()
            .compactMap { lineIndex, rawLine in
                parseLine(
                    rawLine,
                    lineNumber: lineIndex + 1,
                    scope: scope,
                    origin: origin,
                    format: format
                )
            }
    }

    private func parseLine(
        _ rawLine: String,
        lineNumber: Int,
        scope: String,
        origin: JobOrigin,
        format: CronLineFormat
    ) -> ScheduledJob? {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), !isEnvironmentAssignment(trimmed) else {
            return nil
        }

        let parsed: ParsedCronLine?
        if trimmed.hasPrefix("@") {
            parsed = parseSpecialLine(trimmed, format: format)
        } else {
            parsed = parseFiveFieldLine(trimmed, format: format)
        }

        guard let parsed, !parsed.command.isEmpty else {
            return nil
        }

        return ScheduledJob(
            id: "\(scope)-line-\(lineNumber)-\(slug(from: parsed.command))",
            name: cronName(command: parsed.command),
            source: .cron,
            confidence: .scheduled,
            origin: origin,
            schedule: parsed.schedule,
            command: parsed.command,
            state: "scheduled",
            lastStatus: nil,
            lastRun: nil,
            nextRun: nil,
            definition: rawLine,
            lastRunDetails: nil,
            detailPath: nil
        )
    }

    private func parseSpecialLine(_ line: String, format: CronLineFormat) -> ParsedCronLine? {
        let maxSplits = format == .user ? 1 : 2
        let parts = line.split(maxSplits: maxSplits, whereSeparator: \.isWhitespace).map(String.init)
        guard let schedule = parts.first, specialSchedules.contains(schedule), parts.count == maxSplits + 1 else {
            return nil
        }

        return ParsedCronLine(schedule: schedule, command: parts[maxSplits])
    }

    private func parseFiveFieldLine(_ line: String, format: CronLineFormat) -> ParsedCronLine? {
        let maxSplits = format == .user ? 5 : 6
        let parts = line.split(maxSplits: maxSplits, whereSeparator: \.isWhitespace).map(String.init)
        guard parts.count == maxSplits + 1 else {
            return nil
        }

        return ParsedCronLine(schedule: parts.prefix(5).joined(separator: " "), command: parts[maxSplits])
    }

    private func isEnvironmentAssignment(_ line: String) -> Bool {
        line.range(of: #"^[A-Za-z_][A-Za-z0-9_]*\s*="#, options: .regularExpression) != nil
    }

    private func cronName(command: String) -> String {
        let firstToken = command.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? command
        let name = URL(fileURLWithPath: firstToken).lastPathComponent
        return name.isEmpty ? command : name
    }

    private func slug(from value: String) -> String {
        let scalars = value.lowercased().unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars).split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? "entry" : collapsed
    }

    private let specialSchedules: Set<String> = [
        "@reboot",
        "@yearly",
        "@annually",
        "@monthly",
        "@weekly",
        "@daily",
        "@midnight",
        "@hourly"
    ]
}

private enum CronLineFormat {
    case user
    case system
}

private struct ParsedCronLine {
    let schedule: String
    let command: String
}
