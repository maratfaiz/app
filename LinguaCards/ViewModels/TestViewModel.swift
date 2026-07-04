import Foundation
import Observation
import SwiftData

/// Quizlet-style Test mode: generates a fixed set of mixed-type questions,
/// lets the user answer them all, then grades and shows a review.
@Observable
final class TestViewModel {

    enum Kind: Equatable {
        case written
        case multipleChoice(options: [String])
        /// Shows the prompt paired with `shown`; the user judges if it matches.
        case trueFalse(shown: String, isActuallyCorrect: Bool)
    }

    @Observable
    final class Question: Identifiable {
        let id = UUID()
        let card: Card
        let prompt: String
        let expected: String
        let promptLanguage: String
        let kind: Kind

        // User responses (one is used depending on kind).
        var writtenAnswer = ""
        var selectedOption: String?
        var trueFalseAnswer: Bool?

        init(card: Card, prompt: String, expected: String, promptLanguage: String, kind: Kind) {
            self.card = card
            self.prompt = prompt
            self.expected = expected
            self.promptLanguage = promptLanguage
            self.kind = kind
        }

        var isAnswered: Bool {
            switch kind {
            case .written: return !writtenAnswer.trimmingCharacters(in: .whitespaces).isEmpty
            case .multipleChoice: return selectedOption != nil
            case .trueFalse: return trueFalseAnswer != nil
            }
        }

        var isCorrect: Bool {
            switch kind {
            case .written:
                return AnswerMatcher.isCorrect(input: writtenAnswer, expected: expected)
            case .multipleChoice:
                return selectedOption == expected
            case .trueFalse(_, let isActuallyCorrect):
                return trueFalseAnswer == isActuallyCorrect
            }
        }
    }

    static let minimumCards = 4
    static let maxQuestions = 12

    let deck: Deck
    let options: StudyOptions
    private let modelContext: ModelContext

    private(set) var questions: [Question]
    private(set) var isSubmitted = false

    init(deck: Deck, options: StudyOptions, modelContext: ModelContext) {
        self.deck = deck
        self.options = options
        self.modelContext = modelContext
        self.questions = Self.makeQuestions(deck: deck, options: options)
    }

    var correctCount: Int { questions.filter(\.isCorrect).count }
    var score: Double {
        questions.isEmpty ? 0 : Double(correctCount) / Double(questions.count)
    }
    var allAnswered: Bool { questions.allSatisfy(\.isAnswered) }
    var answeredCount: Int { questions.filter(\.isAnswered).count }

    func submit() {
        guard !isSubmitted else { return }
        isSubmitted = true

        var correct = 0
        var incorrect = 0
        for question in questions {
            if question.isCorrect {
                correct += 1
                question.card.applyReview(.good)
            } else {
                incorrect += 1
                question.card.applyReview(.again)
            }
        }
        score >= 0.8 ? Haptics.success() : Haptics.warning()

        let session = StudySession(correct: correct, incorrect: incorrect, mode: .test)
        session.deck = deck
        modelContext.insert(session)
        try? modelContext.save()
    }

    // MARK: - Question generation

    static func makeQuestions(deck: Deck, options: StudyOptions) -> [Question] {
        let pool = deck.cards(for: options)
        guard pool.count >= 2 else { return [] }

        let chosen = Array(pool.shuffled().prefix(maxQuestions))
        let direction = options.direction

        return chosen.enumerated().map { offset, card in
            let prompt = card.prompt(for: direction)
            let expected = card.answer(for: direction)
            let language = deck.promptLanguage(for: direction)

            // Rotate through the three question kinds for variety.
            let kind: Kind
            switch offset % 3 {
            case 0:
                kind = .multipleChoice(options: makeOptions(card: card, pool: pool, direction: direction))
            case 1:
                kind = makeTrueFalse(card: card, pool: pool, direction: direction)
            default:
                kind = .written
            }

            return Question(
                card: card,
                prompt: prompt,
                expected: expected,
                promptLanguage: language,
                kind: kind
            )
        }
    }

    private static func makeOptions(card: Card, pool: [Card], direction: StudyDirection) -> [String] {
        let correct = card.answer(for: direction)
        let distractors = pool
            .filter { $0.id != card.id }
            .map { $0.answer(for: direction) }
            .filter { $0 != correct }
        let unique = Array(Set(distractors)).shuffled().prefix(3)
        return (Array(unique) + [correct]).shuffled()
    }

    private static func makeTrueFalse(card: Card, pool: [Card], direction: StudyDirection) -> Kind {
        let correct = card.answer(for: direction)
        // 50/50 whether we show the real answer or a decoy.
        if Bool.random(),
           let decoy = pool
            .filter({ $0.id != card.id })
            .map({ $0.answer(for: direction) })
            .filter({ $0 != correct })
            .randomElement() {
            return .trueFalse(shown: decoy, isActuallyCorrect: false)
        }
        return .trueFalse(shown: correct, isActuallyCorrect: true)
    }
}
