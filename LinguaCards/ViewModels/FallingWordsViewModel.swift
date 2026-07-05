import Foundation
import Observation
import SwiftData

/// Drives the Falling Words arcade: builds the falling items from the deck and
/// records a study session when the game ends.
@Observable
final class FallingWordsViewModel {
    static let minimumCards = 4

    let deck: Deck
    let options: StudyOptions
    private let modelContext: ModelContext

    private(set) var engine: FallingWordsEngine
    private var didRecord = false

    init(deck: Deck, options: StudyOptions, modelContext: ModelContext) {
        self.deck = deck
        self.options = options
        self.modelContext = modelContext
        self.engine = FallingWordsEngine(items: Self.makeItems(deck: deck, options: options))
    }

    var current: FallingItem? { engine.current }
    var score: Int { engine.score }
    var lives: Int { engine.lives }
    var startingLives: Int { engine.startingLives }
    var streak: Int { engine.streak }
    var bestStreak: Int { engine.bestStreak }
    var progress: Double { engine.progress }
    var fallDuration: Double { engine.fallDuration }
    var isOver: Bool { engine.isOver }

    @discardableResult
    func answer(_ option: String) -> Bool {
        let correct = engine.answer(option)
        correct ? Haptics.success() : Haptics.error()
        if let card = currentAnsweredCard(option: option) {
            card.applyReview(correct ? .good : .again)
        }
        finishIfNeeded()
        return correct
    }

    func timeout() {
        engine.timeout()
        Haptics.warning()
        finishIfNeeded()
    }

    func restart() {
        engine = FallingWordsEngine(items: Self.makeItems(deck: deck, options: options))
        didRecord = false
    }

    // MARK: - Internals

    /// The card that was just answered (engine has already advanced the index).
    private func currentAnsweredCard(option: String) -> Card? {
        let answeredIndex = engine.index - 1
        let items = engine.items
        guard items.indices.contains(answeredIndex) else { return nil }
        let prompt = items[answeredIndex].prompt
        return deck.cards.first { $0.prompt(for: options.direction) == prompt }
    }

    private func finishIfNeeded() {
        guard engine.isOver, !didRecord else { return }
        didRecord = true
        let session = StudySession(
            correct: engine.correctCount,
            incorrect: engine.missedCount,
            mode: .arcade
        )
        session.deck = deck
        modelContext.insert(session)
        try? modelContext.save()
    }

    static func makeItems(deck: Deck, options: StudyOptions) -> [FallingItem] {
        let cards = deck.cards(for: options)
        guard cards.count >= 2 else { return [] }
        let direction = options.direction

        return cards.map { card in
            let answer = card.answer(for: direction)
            let distractors = cards
                .filter { $0.id != card.id }
                .map { $0.answer(for: direction) }
                .filter { $0 != answer }
            let opts = (Array(Set(distractors)).shuffled().prefix(3) + [answer]).shuffled()
            return FallingItem(
                prompt: card.prompt(for: direction),
                answer: answer,
                options: Array(opts)
            )
        }
    }
}
