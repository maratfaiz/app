import SwiftUI

/// Presentation metadata for each study mode, used by the launcher grid.
struct StudyModeInfo: Identifiable {
    let mode: StudyMode
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let colors: [Color]
    /// Minimum number of cards required to launch this mode.
    let minimumCards: Int

    var id: String { mode.rawValue }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Modes offered on a deck (excludes SRS review, which has its own entry).
    static let deckModes: [StudyModeInfo] = [
        StudyModeInfo(
            mode: .learn,
            title: "Learn",
            subtitle: "Adaptive, mastery-based study",
            systemImage: "brain.head.profile",
            colors: [Color(hex: 0x5468FF), Color(hex: 0x8B5CF6)],
            minimumCards: LearnViewModel.minimumCards
        ),
        StudyModeInfo(
            mode: .flashcards,
            title: "Flashcards",
            subtitle: "Flip and swipe through cards",
            systemImage: "rectangle.on.rectangle.angled",
            colors: [Color(hex: 0x06B6D4), Color(hex: 0x3B82F6)],
            minimumCards: 1
        ),
        StudyModeInfo(
            mode: .test,
            title: "Test",
            subtitle: "Mixed questions, graded",
            systemImage: "checklist",
            colors: [Color(hex: 0xEC4899), Color(hex: 0xF97316)],
            minimumCards: TestViewModel.minimumCards
        ),
        StudyModeInfo(
            mode: .quiz,
            title: "Multiple choice",
            subtitle: "Pick the right translation",
            systemImage: "list.bullet.circle",
            colors: [Color(hex: 0x10B981), Color(hex: 0x22D3EE)],
            minimumCards: QuizViewModel.minimumCards
        ),
        StudyModeInfo(
            mode: .typing,
            title: "Write",
            subtitle: "Type the translation",
            systemImage: "keyboard",
            colors: [Color(hex: 0xF59E0B), Color(hex: 0xEF4444)],
            minimumCards: 1
        ),
        StudyModeInfo(
            mode: .match,
            title: "Match",
            subtitle: "Pair terms, against the clock",
            systemImage: "square.grid.2x2",
            colors: [Color(hex: 0x8B5CF6), Color(hex: 0xEC4899)],
            minimumCards: MatchGameViewModel.minimumCards
        ),
        StudyModeInfo(
            mode: .arcade,
            title: "Falling Words",
            subtitle: "Catch the translation before it lands",
            systemImage: "gamecontroller.fill",
            colors: [Color(hex: 0x6366F1), Color(hex: 0x0EA5E9)],
            minimumCards: FallingWordsViewModel.minimumCards
        ),
    ]
}
