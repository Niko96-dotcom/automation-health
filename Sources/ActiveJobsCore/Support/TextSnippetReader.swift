import Foundation

enum TextSnippetReader {
    private static let maximumBytes = 24_000

    static func read(url: URL) -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        guard
            let handle = try? FileHandle(forReadingFrom: url)
        else {
            return nil
        }
        defer { try? handle.close() }

        let size = (try? handle.seekToEnd()) ?? 0
        let offset = size > UInt64(maximumBytes) ? size - UInt64(maximumBytes) : 0
        try? handle.seek(toOffset: offset)
        let data = handle.readDataToEndOfFile()

        guard var text = String(data: data, encoding: .utf8) else {
            return nil
        }

        if offset > 0 {
            if let newline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: newline)...])
            }
            text = "[Showing last \(maximumBytes / 1000) KB]\n" + text
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
