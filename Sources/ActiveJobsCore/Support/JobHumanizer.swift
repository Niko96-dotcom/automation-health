import Foundation

public enum JobHealthKind: String, Hashable, Sendable {
    case alive
    case waiting
    case stale
    case failed
    case unknown
}

public struct JobHealth: Hashable, Sendable {
    public let kind: JobHealthKind
    public let label: String
    public let detail: String
}

public enum JobHumanizer {
    public static func displayName(_ rawName: String, source: JobSource) -> String {
        let cleaned = rawName
            .replacingOccurrences(of: "com.user.", with: "")
            .replacingOccurrences(of: "com.niko.", with: "")
            .replacingOccurrences(of: "com.", with: "")
            .replacingOccurrences(of: "ai.", with: "")
            .replacingOccurrences(of: ".wake", with: "")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        return cleaned
            .split(separator: " ")
            .enumerated()
            .map { index, word in
                let lowercased = word.lowercased()
                if let acronym = acronyms[lowercased] {
                    return acronym
                }
                if index > 0, smallWords.contains(lowercased) {
                    return lowercased
                }
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }

    public static func scheduleDescription(_ rawSchedule: String) -> String {
        let schedule = rawSchedule.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !schedule.isEmpty else {
            return "No schedule found"
        }

        if schedule == "at login, keep alive" {
            return "Starts at login and stays running"
        }

        if schedule == "at login" {
            return "Starts at login"
        }

        if schedule == "keep alive" {
            return "Stays running"
        }

        if schedule.lowercased().hasPrefix("every ") {
            return schedule.prefix(1).uppercased() + schedule.dropFirst()
        }

        if let cron = cronDescription(schedule) {
            return cron
        }

        if let times = timeListDescription(schedule) {
            return times
        }

        if schedule.hasPrefix("watches:") {
            return "Runs when watched files change"
        }

        if schedule.hasPrefix("queues:") {
            return "Runs when files are queued"
        }

        return schedule
    }

    public static func relativeRunDescription(for date: Date?, relativeTo now: Date = Date()) -> String {
        guard let date else {
            return "Not scheduled"
        }

        let calendar = Calendar.current
        let time = timeString(from: date)

        let startOfNow = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)
        let dayOffset = calendar.dateComponents([.day], from: startOfNow, to: startOfDate).day

        if dayOffset == 0 {
            return "Today at \(time)"
        }

        if dayOffset == 1 {
            return "Tomorrow at \(time)"
        }

        if dayOffset == -1 {
            return "Yesterday at \(time)"
        }

        if let days = dayOffset {
            if days > 1, days < 7 {
                return "\(weekdayString(from: date)) at \(time)"
            }
            if days < -1, days > -7 {
                return "Last \(weekdayString(from: date)) at \(time)"
            }
        }

        return "\(dateString(from: date)) at \(time)"
    }

    private static func cronDescription(_ schedule: String) -> String? {
        let parts = schedule.split(separator: " ").map(String.init)
        guard parts.count == 5 else {
            return nil
        }

        let minute = parts[0]
        let hour = parts[1]
        let day = parts[2]
        let month = parts[3]
        let weekday = parts[4]

        if minute.hasPrefix("*/"), hour == "*", day == "*", month == "*", weekday == "*" {
            return "Every \(minute.dropFirst(2)) minutes"
        }

        if minute == "0", hour.hasPrefix("*/"), day == "*", month == "*", weekday == "*" {
            return "Every \(hour.dropFirst(2)) hours"
        }

        guard let minuteValue = Int(minute), let hourValue = Int(hour) else {
            return nil
        }

        let time = String(format: "%02d:%02d", hourValue, minuteValue)
        if day == "*", month == "*", weekday == "*" {
            return "Daily at \(time)"
        }

        if day == "*", month == "*", let weekdayValue = Int(weekday) {
            return "\(weekdayName(weekdayValue)) at \(time)"
        }

        if month == "*", weekday == "*", let dayValue = Int(day) {
            return "Monthly on day \(dayValue) at \(time)"
        }

        return nil
    }

    private static func timeListDescription(_ schedule: String) -> String? {
        let parts = schedule
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count > 1, parts.allSatisfy(isClockTime) else {
            return nil
        }

        return "Daily at \(naturalList(parts))"
    }

    private static func naturalList(_ values: [String]) -> String {
        guard values.count > 1 else {
            return values.first ?? ""
        }

        let prefix = values.dropLast().joined(separator: ", ")
        return "\(prefix) and \(values.last!)"
    }

    private static func isClockTime(_ value: String) -> Bool {
        let parts = value.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            return false
        }
        return (0...23).contains(hour) && (0...59).contains(minute)
    }

    private static func weekdayName(_ launchdWeekday: Int) -> String {
        let names = [
            0: "Sundays",
            1: "Mondays",
            2: "Tuesdays",
            3: "Wednesdays",
            4: "Thursdays",
            5: "Fridays",
            6: "Saturdays",
            7: "Sundays"
        ]
        return names[launchdWeekday] ?? "Weekly"
    }

    private static let acronyms = [
        "api": "API",
        "bvg": "BVG",
        "ffc": "FFC",
        "ft": "FT",
        "pdf": "PDF",
        "ui": "UI",
        "x": "X"
    ]

    private static let smallWords: Set<String> = ["and", "for", "of", "or", "the", "to"]

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func weekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

public extension ScheduledJob {
    var displayName: String {
        JobHumanizer.displayName(name, source: source)
    }

    var humanScheduleDescription: String {
        JobHumanizer.scheduleDescription(schedule)
    }

    func humanLastRunDescription(relativeTo now: Date = Date()) -> String {
        guard let lastRun else {
            return "No run recorded yet"
        }
        return JobHumanizer.relativeRunDescription(for: lastRun, relativeTo: now)
    }

    func humanNextRunDescription(relativeTo now: Date = Date()) -> String {
        JobHumanizer.relativeRunDescription(for: nextRun, relativeTo: now)
    }

    func health(relativeTo now: Date = Date()) -> JobHealth {
        let status = (lastStatus ?? "").lowercased()
        let stateText = state.lowercased()

        if stateText.contains("running") {
            return JobHealth(kind: .alive, label: "Alive", detail: "Running now")
        }

        if isFailureStatus(status) {
            return JobHealth(kind: .failed, label: "Needs attention", detail: "Last run did not finish cleanly")
        }

        if lastRun == nil, nextRun != nil {
            return JobHealth(kind: .waiting, label: "Waiting", detail: "First run is scheduled")
        }

        if let nextRun, nextRun < now.addingTimeInterval(-3600) {
            return JobHealth(kind: .stale, label: "Stale", detail: "Missed its expected run time")
        }

        if let lastRun {
            let age = now.timeIntervalSince(lastRun)
            if age > staleThreshold {
                return JobHealth(kind: .stale, label: "Stale", detail: "No recent successful activity")
            }

            if status.isEmpty || status == "ok" || status == "success" || status == "exit 0" {
                return JobHealth(kind: .alive, label: "Alive", detail: "Last run looks healthy")
            }
        }

        if status == "ok" || status == "success" || status == "exit 0" {
            return JobHealth(kind: .alive, label: "Alive", detail: "Last known result was healthy")
        }

        return JobHealth(kind: .unknown, label: "Unknown", detail: "Not enough run history yet")
    }

    private var staleThreshold: TimeInterval {
        let humanSchedule = humanScheduleDescription.lowercased()
        if humanSchedule.contains("every hour") {
            return 3 * 3600
        }
        if humanSchedule.contains("every ") && humanSchedule.contains("minutes") {
            return 90 * 60
        }
        if humanSchedule.contains("daily") {
            return 36 * 3600
        }
        return 48 * 3600
    }

    private func isFailureStatus(_ status: String) -> Bool {
        if status.contains("fail") || status.contains("error") {
            return true
        }

        guard status.hasPrefix("exit ") else {
            return false
        }

        return status != "exit 0"
    }
}
