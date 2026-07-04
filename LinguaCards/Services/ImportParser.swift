import Foundation

/// Parses bulk-import text of the form "term - translation", one pair per line.
///
/// Accepted separators between term and translation: "-", "–", "—", "=", tab.
/// Lines without a separator or with an empty side are skipped.
enum ImportParser {

    struct ParsedCard: Equatable {
        var front: String
        var back: String
    }

    static let separators: [String] = ["\t", " - ", " – ", " — ", " = ", "-", "–", "—", "="]

    static func parse(_ text: String) -> [ParsedCard] {
        text
            .components(separatedBy: .newlines)
            .compactMap(parseLine)
    }

    static func parseLine(_ line: String) -> ParsedCard? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        for separator in separators {
            guard let range = trimmed.range(of: separator) else { continue }
            let front = String(trimmed[..<range.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            let back = String(trimmed[range.upperBound...])
                .trimmingCharacters(in: .whitespaces)
            if !front.isEmpty && !back.isEmpty {
                return ParsedCard(front: front, back: back)
            }
        }
        return nil
    }
}
