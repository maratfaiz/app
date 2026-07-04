import Foundation

/// Snapshot of a learner's activity used to evaluate achievements. Kept as a
/// plain value type (no SwiftUI/SwiftData) so the logic is unit-testable.
struct LearnerStats: Equatable {
    var deckCount: Int
    var totalCards: Int
    var masteredCount: Int
    var streak: Int
    var totalAnswers: Int
    var sharedDecks: Int

    static let zero = LearnerStats(
        deckCount: 0, totalCards: 0, masteredCount: 0,
        streak: 0, totalAnswers: 0, sharedDecks: 0
    )
}

/// The badges a learner can unlock. Each maps to a goal and a source metric.
enum AchievementKind: String, CaseIterable, Identifiable {
    case firstDeck
    case deckCollector
    case wordWizard
    case memoryMaster
    case onFire
    case unstoppable
    case quizWhiz
    case communityStar
    case generous

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstDeck: return "Getting Started"
        case .deckCollector: return "Deck Collector"
        case .wordWizard: return "Word Wizard"
        case .memoryMaster: return "Memory Master"
        case .onFire: return "On Fire"
        case .unstoppable: return "Unstoppable"
        case .quizWhiz: return "Quiz Whiz"
        case .communityStar: return "Community Star"
        case .generous: return "Generous"
        }
    }

    var detail: String {
        switch self {
        case .firstDeck: return "Create your first deck"
        case .deckCollector: return "Build 5 decks"
        case .wordWizard: return "Collect 100 cards"
        case .memoryMaster: return "Master 50 cards"
        case .onFire: return "Reach a 7-day streak"
        case .unstoppable: return "Reach a 30-day streak"
        case .quizWhiz: return "Answer 500 questions"
        case .communityStar: return "Share a deck to the community"
        case .generous: return "Share 3 decks"
        }
    }

    var systemImage: String {
        switch self {
        case .firstDeck: return "flag.checkered"
        case .deckCollector: return "square.stack.3d.up.fill"
        case .wordWizard: return "wand.and.stars"
        case .memoryMaster: return "brain.head.profile"
        case .onFire: return "flame.fill"
        case .unstoppable: return "bolt.fill"
        case .quizWhiz: return "checkmark.seal.fill"
        case .communityStar: return "star.circle.fill"
        case .generous: return "gift.fill"
        }
    }

    var goal: Int {
        switch self {
        case .firstDeck: return 1
        case .deckCollector: return 5
        case .wordWizard: return 100
        case .memoryMaster: return 50
        case .onFire: return 7
        case .unstoppable: return 30
        case .quizWhiz: return 500
        case .communityStar: return 1
        case .generous: return 3
        }
    }

    func value(in stats: LearnerStats) -> Int {
        switch self {
        case .firstDeck, .deckCollector: return stats.deckCount
        case .wordWizard: return stats.totalCards
        case .memoryMaster: return stats.masteredCount
        case .onFire, .unstoppable: return stats.streak
        case .quizWhiz: return stats.totalAnswers
        case .communityStar, .generous: return stats.sharedDecks
        }
    }
}

/// The unlock state and progress of a single achievement for a learner.
struct AchievementStatus: Identifiable, Equatable {
    let kind: AchievementKind
    let value: Int

    var id: String { kind.rawValue }
    var goal: Int { kind.goal }
    var unlocked: Bool { value >= goal }
    var progress: Double {
        goal == 0 ? 1 : min(1, Double(value) / Double(goal))
    }
}

/// Evaluates all achievements from a stats snapshot.
enum AchievementsEngine {
    static func evaluate(_ stats: LearnerStats) -> [AchievementStatus] {
        AchievementKind.allCases
            .map { AchievementStatus(kind: $0, value: $0.value(in: stats)) }
            // Unlocked first, then those closest to unlocking.
            .sorted {
                if $0.unlocked != $1.unlocked { return $0.unlocked && !$1.unlocked }
                return $0.progress > $1.progress
            }
    }

    static func unlockedCount(_ stats: LearnerStats) -> Int {
        AchievementKind.allCases.filter { $0.value(in: stats) >= $0.goal }.count
    }
}
