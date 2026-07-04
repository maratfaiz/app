import Foundation
import Observation
import SwiftData

/// Typing test: shows the term, the user types the translation,
/// answers are checked with fuzzy matching.
@Observable
final class TypingTestViewModel {

    enum Phase: Equatable {
        case answering
        case feedback(AnswerMatcher.Verdict)
    }

    let deck: Deck
    private let modelContext: ModelContext

    private(set) var cards: [Card]
    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var incorrectCount = 0
    private(set) var phase = Phase.answering
    var input = ""

    init(deck: Deck, modelContext: ModelContext) {
        self.deck = deck
        self.modelContext = modelContext
        self.cards = deck.cards.shuffled()
    }

    var currentCard: Card? {
        cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    var isFinished: Bool { currentIndex >= cards.count }

    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }

    func submit() {
        guard phase == .answering, let card = currentCard else { return }
        let verdict = AnswerMatcher.evaluate(input: input, expected: card.back)
        phase = .feedback(verdict)

        switch verdict {
        case .correct:
            correctCount += 1
            Haptics.success()
            card.applyReview(.good)
        case .almostCorrect:
            correctCount += 1
            Haptics.warning()
            card.applyReview(.hard)
        case .wrong:
            incorrectCount += 1
            Haptics.error()
            card.applyReview(.again)
        }
    }

    /// Skipping counts as not knowing the answer.
    func reveal() {
        guard phase == .answering, let card = currentCard else { return }
        phase = .feedback(.wrong)
        incorrectCount += 1
        Haptics.error()
        card.applyReview(.again)
    }

    func advance() {
        guard case .feedback = phase else { return }
        input = ""
        phase = .answering
        currentIndex += 1
        if isFinished {
            finishSession()
        }
    }

    private func finishSession() {
        guard correctCount + incorrectCount > 0 else { return }
        let session = StudySession(
            correct: correctCount,
            incorrect: incorrectCount,
            mode: .typing
        )
        session.deck = deck
        modelContext.insert(session)
        try? modelContext.save()
    }
}
