import Foundation
import Observation
import SwiftData

/// Quizlet-style Learn mode: an adaptive session that escalates each term
/// from multiple-choice recognition to written recall, requeuing anything
/// the user gets wrong until every term is mastered for the session.
@Observable
final class LearnViewModel {

    enum QuestionType: Equatable {
        case multipleChoice(options: [String])
        case written
    }

    enum Phase: Equatable {
        case asking
        case feedback(correct: Bool)
    }

    static let minimumCards = 4

    let deck: Deck
    let options: StudyOptions
    private let modelContext: ModelContext
    private let cards: [Card]

    private var engine: LearnEngine
    private(set) var phase: Phase = .asking
    private(set) var correctCount = 0
    private(set) var incorrectCount = 0
    /// The option the user tapped in a multiple-choice question, for styling.
    private(set) var selectedOption: String?
    var writtenInput = ""

    /// Result awaiting application to the engine on `advance()`, so the
    /// current card stays visible while its feedback is shown.
    private var pendingCorrect: Bool?
    /// Options for the current multiple-choice question, cached so they don't
    /// reshuffle on every re-render.
    private(set) var currentOptions: [String] = []

    init(deck: Deck, options: StudyOptions, modelContext: ModelContext) {
        self.deck = deck
        self.options = options
        self.modelContext = modelContext
        self.cards = deck.cards(for: options)
        self.engine = LearnEngine(count: cards.count)
        refreshOptions()
    }

    // MARK: - Derived state

    var isFinished: Bool { engine.isFinished }
    var progress: Double { engine.progress }
    var graduatedCount: Int { engine.graduatedCount }
    var totalCount: Int { cards.count }
    var remainingCount: Int { engine.remainingCount }

    var currentCard: Card? {
        guard let index = engine.currentIndex, cards.indices.contains(index) else { return nil }
        return cards[index]
    }

    var promptText: String { currentCard?.prompt(for: options.direction) ?? "" }
    var expectedAnswer: String { currentCard?.answer(for: options.direction) ?? "" }
    var promptLanguage: String { deck.promptLanguage(for: options.direction) }
    var answerLanguage: String { deck.answerLanguage(for: options.direction) }

    /// Difficulty escalates with the card's box level within the session:
    /// box 0 is recognition (multiple choice), higher boxes are recall (written).
    var questionType: QuestionType {
        if engine.currentBox == 0, !currentOptions.isEmpty {
            return .multipleChoice(options: currentOptions)
        }
        return .written
    }

    // MARK: - Actions

    func submitMultipleChoice(_ option: String) {
        guard phase == .asking else { return }
        selectedOption = option
        grade(correct: option == expectedAnswer)
    }

    func submitWritten() {
        guard phase == .asking else { return }
        grade(correct: AnswerMatcher.isCorrect(input: writtenInput, expected: expectedAnswer))
    }

    func advance() {
        guard case .feedback = phase else { return }

        // Apply the deferred result to the scheduling engine now.
        if let correct = pendingCorrect {
            correct ? engine.recordCorrect() : engine.recordWrong()
        }
        pendingCorrect = nil
        selectedOption = nil
        writtenInput = ""
        phase = .asking
        refreshOptions()

        if engine.isFinished {
            finishSession()
        }
    }

    func isCorrectOption(_ option: String) -> Bool {
        option == expectedAnswer
    }

    // MARK: - Internals

    private func grade(correct: Bool) {
        guard let card = currentCard else { return }
        pendingCorrect = correct
        if correct {
            correctCount += 1
            Haptics.success()
            card.applyReview(.good)
        } else {
            incorrectCount += 1
            Haptics.error()
            card.applyReview(.again)
        }
        phase = .feedback(correct: correct)
    }

    /// Regenerates the multiple-choice options for the current front-of-queue
    /// card (only needed when it's a box-0 recognition question).
    private func refreshOptions() {
        guard engine.currentBox == 0, let card = currentCard else {
            currentOptions = []
            return
        }
        let correct = card.answer(for: options.direction)
        let distractors = cards
            .filter { $0.id != card.id }
            .map { $0.answer(for: options.direction) }
            .filter { $0 != correct }
        let unique = Array(Set(distractors)).shuffled().prefix(3)
        currentOptions = (Array(unique) + [correct]).shuffled()
    }

    private func finishSession() {
        guard correctCount + incorrectCount > 0 else { return }
        let session = StudySession(correct: correctCount, incorrect: incorrectCount, mode: .learn)
        session.deck = deck
        modelContext.insert(session)
        try? modelContext.save()
    }
}
