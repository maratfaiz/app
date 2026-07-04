import Foundation
import Observation
import SwiftData

/// Drives the swipeable flashcards mode: right = known (Good), left = unknown (Again).
@Observable
final class FlashcardsViewModel {
    let deck: Deck
    let options: StudyOptions
    private let modelContext: ModelContext

    private(set) var cards: [Card]
    private(set) var currentIndex = 0
    private(set) var knownCount = 0
    private(set) var unknownCount = 0
    var isFlipped = false

    init(deck: Deck, options: StudyOptions = .default, modelContext: ModelContext) {
        self.deck = deck
        self.options = options
        self.modelContext = modelContext
        self.cards = deck.cards(for: options)
    }

    var currentCard: Card? {
        cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    var nextCard: Card? {
        cards.indices.contains(currentIndex + 1) ? cards[currentIndex + 1] : nil
    }

    var isFinished: Bool { currentIndex >= cards.count }

    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }

    func flip() {
        isFlipped.toggle()
        Haptics.tap()
    }

    func toggleStar() {
        guard let card = currentCard else { return }
        card.isStarred.toggle()
        Haptics.tap()
        try? modelContext.save()
    }

    func mark(known: Bool) {
        guard let card = currentCard else { return }
        card.applyReview(known ? .good : .again)
        if known {
            knownCount += 1
        } else {
            unknownCount += 1
        }
        Haptics.swipe()
        isFlipped = false
        currentIndex += 1
        if isFinished {
            finishSession()
        }
    }

    private func finishSession() {
        guard knownCount + unknownCount > 0 else { return }
        let session = StudySession(
            correct: knownCount,
            incorrect: unknownCount,
            mode: .flashcards
        )
        session.deck = deck
        modelContext.insert(session)
        try? modelContext.save()
    }
}
