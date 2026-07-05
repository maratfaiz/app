import Foundation

/// One falling term with its correct answer and multiple-choice options.
struct FallingItem: Equatable {
    let prompt: String
    let answer: String
    let options: [String]
}

/// Pure game state for the Falling Words arcade: score, lives and streak,
/// independent of any animation. The view drives the falling motion and calls
/// `answer`/`timeout`; this type owns the scoring rules so they're testable.
struct FallingWordsEngine {
    let items: [FallingItem]
    let startingLives: Int

    private(set) var index = 0
    private(set) var score = 0
    private(set) var lives: Int
    private(set) var streak = 0
    private(set) var bestStreak = 0
    private(set) var correctCount = 0
    private(set) var missedCount = 0

    init(items: [FallingItem], lives: Int = 3) {
        self.items = items
        self.startingLives = lives
        self.lives = lives
    }

    var current: FallingItem? {
        items.indices.contains(index) ? items[index] : nil
    }

    var isOver: Bool { lives <= 0 || index >= items.count }

    var progress: Double {
        items.isEmpty ? 1 : Double(min(index, items.count)) / Double(items.count)
    }

    /// Difficulty ramps up: each cleared word shortens the fall time.
    var fallDuration: Double {
        max(2.0, 4.5 - Double(index) * 0.12)
    }

    /// Answers the current word. Returns whether it was correct.
    @discardableResult
    mutating func answer(_ option: String) -> Bool {
        guard let current, !isOver else { return false }
        let correct = option == current.answer
        if correct {
            correctCount += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
            // Base points plus an escalating streak bonus.
            score += 10 + (streak - 1) * 2
        } else {
            missedCount += 1
            streak = 0
            lives -= 1
        }
        index += 1
        return correct
    }

    /// The current word reached the bottom without being answered.
    mutating func timeout() {
        guard !isOver else { return }
        missedCount += 1
        streak = 0
        lives -= 1
        index += 1
    }
}
