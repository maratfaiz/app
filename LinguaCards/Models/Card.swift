import Foundation
import SwiftData
import SwiftUI

/// A single flashcard with SM-2 spaced-repetition scheduling state.
@Model
final class Card {
    @Attribute(.unique) var id: UUID
    /// The term, in the deck's source language.
    var front: String
    /// The translation, in the deck's target language.
    var back: String
    /// Optional example sentence illustrating the term.
    var example: String?

    // MARK: Spaced repetition state (simplified SM-2)
    var easeFactor: Double
    /// Current inter-review interval in days. 0 for new / relearning cards.
    var interval: Double
    var repetitions: Int
    var nextReview: Date

    /// User-flagged as important; can be studied in a "starred only" set.
    var isStarred: Bool

    var deck: Deck?

    init(front: String, back: String, example: String? = nil) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.example = example
        self.easeFactor = SRSScheduler.defaultEase
        self.interval = 0
        self.repetitions = 0
        self.nextReview = .now
        self.isStarred = false
    }
}

/// Coarse progress bucket used for progress bars and filtering, in the
/// spirit of Quizlet's "Not studied / Still learning / Mastered".
enum MasteryLevel: String, CaseIterable {
    case new
    case learning
    case mastered

    var title: LocalizedStringKey {
        switch self {
        case .new: return "Not studied"
        case .learning: return "Still learning"
        case .mastered: return "Mastered"
        }
    }

    var color: Color {
        switch self {
        case .new: return .secondary
        case .learning: return Theme.warning
        case .mastered: return Theme.success
        }
    }
}

extension Card {
    /// A card is due when its next review date falls today or earlier.
    var isDue: Bool {
        nextReview <= Calendar.current.endOfToday
    }

    /// Mastered = answered correctly several times in a row with a mature interval.
    var isMastered: Bool {
        repetitions >= 3 && interval >= 21
    }

    var masteryLevel: MasteryLevel {
        if isMastered { return .mastered }
        return repetitions > 0 ? .learning : .new
    }

    var srsState: SRSState {
        SRSState(easeFactor: easeFactor, interval: interval, repetitions: repetitions)
    }

    /// Applies a review grade, updating the SM-2 state and next review date.
    func applyReview(_ grade: ReviewGrade, now: Date = .now) {
        let outcome = SRSScheduler.review(state: srsState, grade: grade, now: now)
        easeFactor = outcome.state.easeFactor
        interval = outcome.state.interval
        repetitions = outcome.state.repetitions
        nextReview = outcome.nextReview
    }
}

extension Calendar {
    var endOfToday: Date {
        let start = startOfDay(for: .now)
        return date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? .now
    }
}
