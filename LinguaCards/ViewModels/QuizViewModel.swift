import Foundation
import Observation
import SwiftData

/// Multiple-choice quiz: for each card, 4 answer options drawn from the deck.
@Observable
final class QuizViewModel {

    struct Question: Identifiable {
        let id = UUID()
        let card: Card
        let prompt: String
        let answer: String
        let options: [String]
    }

    /// Minimum deck size for a meaningful 4-option quiz.
    static let minimumCards = 4

    let deck: Deck
    let options: StudyOptions
    private let modelContext: ModelContext

    private(set) var questions: [Question] = []
    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var incorrectCount = 0
    /// The option the user picked for the current question, nil while undecided.
    private(set) var selectedOption: String?

    init(deck: Deck, options: StudyOptions = .default, modelContext: ModelContext) {
        self.deck = deck
        self.options = options
        self.modelContext = modelContext
        self.questions = Self.makeQuestions(from: deck.cards(for: options), direction: options.direction)
    }

    var currentQuestion: Question? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var promptLanguage: String { deck.promptLanguage(for: options.direction) }

    var isFinished: Bool { currentIndex >= questions.count }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    var hasAnswered: Bool { selectedOption != nil }

    func select(_ option: String) {
        guard !hasAnswered, let question = currentQuestion else { return }
        selectedOption = option

        let isCorrect = option == question.answer
        if isCorrect {
            correctCount += 1
            Haptics.success()
        } else {
            incorrectCount += 1
            Haptics.error()
        }
        question.card.applyReview(isCorrect ? .good : .again)
    }

    func advance() {
        guard hasAnswered else { return }
        selectedOption = nil
        currentIndex += 1
        if isFinished {
            finishSession()
        }
    }

    func isCorrectOption(_ option: String) -> Bool {
        option == currentQuestion?.answer
    }

    private func finishSession() {
        guard correctCount + incorrectCount > 0 else { return }
        let session = StudySession(
            correct: correctCount,
            incorrect: incorrectCount,
            mode: .quiz
        )
        session.deck = deck
        modelContext.insert(session)
        try? modelContext.save()
    }

    static func makeQuestions(from cards: [Card], direction: StudyDirection) -> [Question] {
        guard cards.count >= minimumCards else { return [] }

        return cards.map { card in
            let answer = card.answer(for: direction)
            let distractors = cards
                .filter { $0.id != card.id }
                .map { $0.answer(for: direction) }
                .filter { $0 != answer }
            let options = (Array(Set(distractors)).shuffled().prefix(3) + [answer]).shuffled()
            return Question(
                card: card,
                prompt: card.prompt(for: direction),
                answer: answer,
                options: Array(options)
            )
        }
    }
}
