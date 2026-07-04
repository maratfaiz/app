import XCTest
@testable import LinguaCards

final class AchievementsTests: XCTestCase {

    func testNothingUnlockedForNewLearner() {
        XCTAssertEqual(AchievementsEngine.unlockedCount(.zero), 0)
        for status in AchievementsEngine.evaluate(.zero) {
            XCTAssertFalse(status.unlocked)
        }
    }

    func testFirstDeckUnlocksAtOneDeck() {
        let stats = LearnerStats(deckCount: 1, totalCards: 3, masteredCount: 0, streak: 0, totalAnswers: 0, sharedDecks: 0)
        let first = AchievementsEngine.evaluate(stats).first { $0.kind == .firstDeck }
        XCTAssertEqual(first?.unlocked, true)
        // Deck Collector (goal 5) still locked but shows partial progress.
        let collector = AchievementsEngine.evaluate(stats).first { $0.kind == .deckCollector }
        XCTAssertEqual(collector?.unlocked, false)
        XCTAssertEqual(collector?.progress ?? 0, 0.2, accuracy: 0.0001)
    }

    func testProgressIsClampedToOne() {
        let stats = LearnerStats(deckCount: 99, totalCards: 0, masteredCount: 0, streak: 0, totalAnswers: 0, sharedDecks: 0)
        let collector = AchievementsEngine.evaluate(stats).first { $0.kind == .deckCollector }
        XCTAssertEqual(collector?.progress, 1.0)
        XCTAssertEqual(collector?.unlocked, true)
    }

    func testStreakAndSharingAchievements() {
        let stats = LearnerStats(deckCount: 6, totalCards: 120, masteredCount: 60, streak: 8, totalAnswers: 600, sharedDecks: 3)
        let unlocked = Set(AchievementsEngine.evaluate(stats).filter(\.unlocked).map(\.kind))
        XCTAssertTrue(unlocked.contains(.onFire))       // streak 8 >= 7
        XCTAssertFalse(unlocked.contains(.unstoppable)) // streak 8 < 30
        XCTAssertTrue(unlocked.contains(.communityStar))
        XCTAssertTrue(unlocked.contains(.generous))
        XCTAssertTrue(unlocked.contains(.wordWizard))
        XCTAssertTrue(unlocked.contains(.memoryMaster))
        XCTAssertTrue(unlocked.contains(.quizWhiz))
    }

    func testUnlockedSortedFirst() {
        let stats = LearnerStats(deckCount: 1, totalCards: 0, masteredCount: 0, streak: 0, totalAnswers: 0, sharedDecks: 0)
        let evaluated = AchievementsEngine.evaluate(stats)
        // The single unlocked achievement (firstDeck) should be at the front.
        XCTAssertEqual(evaluated.first?.unlocked, true)
    }
}
