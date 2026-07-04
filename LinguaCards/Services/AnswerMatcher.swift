import Foundation

/// Fuzzy matching of typed answers against expected translations.
///
/// Matching is tolerant of case, diacritics, surrounding punctuation and
/// extra whitespace, and allows small typos on longer answers via
/// Levenshtein distance. An expected answer may list alternatives
/// separated by "/", ";" or ",".
enum AnswerMatcher {

    enum Verdict: Equatable {
        /// Matches after normalization.
        case correct
        /// Within typo tolerance of an accepted answer.
        case almostCorrect
        case wrong
    }

    static func evaluate(input: String, expected: String) -> Verdict {
        let normalizedInput = normalize(input)
        guard !normalizedInput.isEmpty else { return .wrong }

        var best = Verdict.wrong
        for alternative in acceptedAnswers(from: expected) {
            let candidate = normalize(alternative)
            guard !candidate.isEmpty else { continue }

            if normalizedInput == candidate {
                return .correct
            }
            let distance = editDistance(normalizedInput, candidate)
            if distance <= typoTolerance(forLength: candidate.count) {
                best = .almostCorrect
            }
        }
        return best
    }

    /// Convenience: both exact and near matches count as correct.
    static func isCorrect(input: String, expected: String) -> Bool {
        evaluate(input: input, expected: expected) != .wrong
    }

    // MARK: - Internals

    /// Splits "дом / здание, строение" into individual accepted answers.
    static func acceptedAnswers(from expected: String) -> [String] {
        expected
            .split(whereSeparator: { "/;,".contains($0) })
            .map { String($0) }
    }

    /// Lowercases, strips diacritics, removes punctuation and collapses whitespace.
    static func normalize(_ text: String) -> String {
        let folded = text.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: nil
        )
        let cleanedScalars = folded.unicodeScalars.filter { scalar in
            !CharacterSet.punctuationCharacters.contains(scalar)
                && !CharacterSet.symbols.contains(scalar)
        }
        let cleaned = String(String.UnicodeScalarView(cleanedScalars))
        return cleaned
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// Allowed edit distance grows with answer length; short answers must be exact.
    static func typoTolerance(forLength length: Int) -> Int {
        switch length {
        case ..<4: return 0
        case 4...7: return 1
        default: return 2
        }
    }

    /// Damerau-Levenshtein distance (optimal string alignment), so a
    /// transposition of adjacent letters ("freind") counts as one edit.
    static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var matrix = [[Int]](
            repeating: [Int](repeating: 0, count: b.count + 1),
            count: a.count + 1
        )
        for i in 0...a.count { matrix[i][0] = i }
        for j in 0...b.count { matrix[0][j] = j }

        for i in 1...a.count {
            for j in 1...b.count {
                let substitutionCost = a[i - 1] == b[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,                    // deletion
                    matrix[i][j - 1] + 1,                    // insertion
                    matrix[i - 1][j - 1] + substitutionCost  // substitution
                )
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    matrix[i][j] = min(matrix[i][j], matrix[i - 2][j - 2] + 1)
                }
            }
        }
        return matrix[a.count][b.count]
    }
}
