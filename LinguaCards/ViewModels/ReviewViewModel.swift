import Foundation
import Observation
import SwiftData

/// Spaced-repetition review: presents due cards and applies the chosen
/// SM-2 grade (Again / Hard / Good / Easy) after each answer.
///
/// Can review a single deck or the due cards of every deck at once.
@Observable
final class ReviewViewModel {
    private let modelContext: ModelContext

    private(set) var cards: [Card]
    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var incorrectCount = 0
    var isFlipped = false

    /// Per-deck tallies so a session record can be written for each deck involved.
    private var deckTallies: [PersistentIdentifier: (deck: Deck, correct: Int, incorrect: Int)] = [:]

    init(decks: [Deck], modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cards = decks
            .flatMap(\.dueCards)
            .sorted { $0.nextReview < $1.nextReview }
    }

    var currentCard: Card? {
        cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    var isFinished: Bool { currentIndex >= cards.count }

    var totalCount: Int { cards.count }

    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }

    func flip() {
        isFlipped.toggle()
        Haptics.tap()
    }

    func grade(_ grade: ReviewGrade) {
        guard let card = currentCard else { return }
        card.applyReview(grade)

        let wasCorrect = grade != .again
        if wasCorrect {
            correctCount += 1
            Haptics.success()
        } else {
            incorrectCount += 1
            Haptics.error()
        }

        if let deck = card.deck {
            var tally = deckTallies[deck.persistentModelID] ?? (deck, 0, 0)
            if wasCorrect {
                tally.correct += 1
            } else {
                tally.incorrect += 1
            }
            deckTallies[deck.persistentModelID] = tally
        }

        isFlipped = false
        currentIndex += 1
        if isFinished {
            finishSession()
        }
    }

    private func finishSession() {
        for (_, tally) in deckTallies {
            let session = StudySession(
                correct: tally.correct,
                incorrect: tally.incorrect,
                mode: .review
            )
            session.deck = tally.deck
            modelContext.insert(session)
        }
        try? modelContext.save()
    }
}
