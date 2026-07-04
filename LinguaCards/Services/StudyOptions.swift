import Foundation

/// Which side of the card is shown as the prompt.
enum StudyDirection: String, CaseIterable, Identifiable {
    /// Show the term, recall the translation.
    case termToTranslation
    /// Show the translation, recall the term.
    case translationToTerm

    var id: String { rawValue }

    var label: String {
        switch self {
        case .termToTranslation: return "Term → Translation"
        case .translationToTerm: return "Translation → Term"
        }
    }
}

/// User-configurable options applied when launching a study mode.
struct StudyOptions: Equatable {
    var direction: StudyDirection = .termToTranslation
    var starredOnly: Bool = false
    var shuffle: Bool = true

    static let `default` = StudyOptions()
}

extension Card {
    /// The prompt text for a given study direction.
    func prompt(for direction: StudyDirection) -> String {
        direction == .termToTranslation ? front : back
    }

    /// The expected answer text for a given study direction.
    func answer(for direction: StudyDirection) -> String {
        direction == .termToTranslation ? back : front
    }
}

extension Deck {
    /// The cards to study given the chosen options (applies starred filter).
    func cards(for options: StudyOptions) -> [Card] {
        let base = options.starredOnly ? starredCards : cards
        return options.shuffle ? base.shuffled() : base
    }

    /// Language code to speak for a prompt in the given direction.
    func promptLanguage(for direction: StudyDirection) -> String {
        direction == .termToTranslation ? sourceLang : targetLang
    }

    func answerLanguage(for direction: StudyDirection) -> String {
        direction == .termToTranslation ? targetLang : sourceLang
    }
}
