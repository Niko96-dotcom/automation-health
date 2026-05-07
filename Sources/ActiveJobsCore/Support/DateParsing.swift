import Foundation

enum FlexibleDateParser {
    static func parse(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else {
            return nil
        }

        let fractionalISOFormatter = ISO8601DateFormatter()
        fractionalISOFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalISOFormatter.date(from: value) {
            return date
        }

        let plainISOFormatter = ISO8601DateFormatter()
        plainISOFormatter.formatOptions = [.withInternetDateTime]
        if let date = plainISOFormatter.date(from: value) {
            return date
        }

        return nil
    }
}

enum JobDateFormatters {
    static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
