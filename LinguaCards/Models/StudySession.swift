import Foundation
import SwiftData

/// The kind of exercise a study session used.
enum StudyMode: String, Codable, CaseIterable {
    case learn
    case flashcards
    case quiz
    case typing
    case match
    case test
    case arcade
    case review
}

/// A record of one completed study round, used for stats and streaks.
@Model
final class StudySession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var correct: Int
    var incorrect: Int
    private var modeRaw: String

    var deck: Deck?

    var mode: StudyMode {
        get { StudyMode(rawValue: modeRaw) ?? .flashcards }
        set { modeRaw = newValue.rawValue }
    }

    init(date: Date = .now, correct: Int, incorrect: Int, mode: StudyMode) {
        self.id = UUID()
        self.date = date
        self.correct = correct
        self.incorrect = incorrect
        self.modeRaw = mode.rawValue
    }
}

extension StudySession {
    var total: Int { correct + incorrect }

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}
