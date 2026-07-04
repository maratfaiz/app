import Foundation
import SwiftData

/// A study set: a titled collection of cards with a source and target language.
@Model
final class Deck {
    @Attribute(.unique) var id: UUID
    var title: String
    var desc: String
    /// BCP-47 code of the language of the card fronts (terms), e.g. "en-US".
    var sourceLang: String
    /// BCP-47 code of the language of the card backs (translations), e.g. "ru-RU".
    var targetLang: String
    var createdAt: Date

    /// Index into `Theme.deckGradients` — the deck's personal color.
    var colorIndex: Int = 0
    /// Optional emoji shown as the deck's icon.
    var emoji: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card]

    @Relationship(deleteRule: .cascade, inverse: \StudySession.deck)
    var sessions: [StudySession]

    init(
        title: String,
        desc: String = "",
        sourceLang: String = "en-US",
        targetLang: String = "ru-RU",
        createdAt: Date = .now,
        colorIndex: Int? = nil,
        emoji: String = ""
    ) {
        let id = UUID()
        self.id = id
        self.title = title
        self.desc = desc
        self.sourceLang = sourceLang
        self.targetLang = targetLang
        self.createdAt = createdAt
        // Seed a varied color from the id when the caller doesn't pick one.
        self.colorIndex = colorIndex ?? Theme.gradientIndex(for: id)
        self.emoji = emoji
        self.cards = []
        self.sessions = []
    }
}

extension Deck {
    var cardCount: Int { cards.count }

    var dueCards: [Card] {
        cards.filter(\.isDue)
    }

    var dueCount: Int { dueCards.count }

    var masteredCount: Int {
        cards.filter(\.isMastered).count
    }

    var starredCards: [Card] {
        cards.filter(\.isStarred)
    }

    /// Number of cards in each mastery bucket, for progress bars.
    func masteryBreakdown() -> [MasteryLevel: Int] {
        var counts: [MasteryLevel: Int] = [.new: 0, .learning: 0, .mastered: 0]
        for card in cards {
            counts[card.masteryLevel, default: 0] += 1
        }
        return counts
    }

    /// Fraction of cards considered mastered, in 0...1.
    var masteredFraction: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(masteredCount) / Double(cards.count)
    }

    /// Consecutive days (ending today or yesterday) with at least one study session.
    var studyStreak: Int {
        StatsService.streak(sessionDates: sessions.map(\.date))
    }
}
