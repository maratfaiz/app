import XCTest
@testable import LinguaCards

final class FallingWordsEngineTests: XCTestCase {

    private func items(_ n: Int) -> [FallingItem] {
        (0..<n).map { FallingItem(prompt: "p\($0)", answer: "a\($0)", options: ["a\($0)", "x", "y", "z"]) }
    }

    func testCorrectAnswerScoresAndAdvances() {
        var engine = FallingWordsEngine(items: items(3))
        XCTAssertTrue(engine.answer("a0"))
        XCTAssertEqual(engine.score, 10)
        XCTAssertEqual(engine.streak, 1)
        XCTAssertEqual(engine.lives, 3)
        XCTAssertEqual(engine.current?.prompt, "p1")
    }

    func testStreakBonusGrows() {
        var engine = FallingWordsEngine(items: items(3))
        engine.answer("a0") // +10
        engine.answer("a1") // +10 + 2
        engine.answer("a2") // +10 + 4
        XCTAssertEqual(engine.score, 10 + 12 + 14)
        XCTAssertEqual(engine.bestStreak, 3)
    }

    func testWrongAnswerLosesLifeAndResetsStreak() {
        var engine = FallingWordsEngine(items: items(3))
        engine.answer("a0")           // streak 1
        XCTAssertFalse(engine.answer("wrong"))
        XCTAssertEqual(engine.lives, 2)
        XCTAssertEqual(engine.streak, 0)
        XCTAssertEqual(engine.bestStreak, 1)
    }

    func testTimeoutLosesLife() {
        var engine = FallingWordsEngine(items: items(3))
        engine.timeout()
        XCTAssertEqual(engine.lives, 2)
        XCTAssertEqual(engine.missedCount, 1)
        XCTAssertEqual(engine.current?.prompt, "p1")
    }

    func testGameOverAtZeroLives() {
        var engine = FallingWordsEngine(items: items(5), lives: 2)
        engine.answer("wrong")
        engine.answer("wrong")
        XCTAssertTrue(engine.isOver)
        // Further input is ignored once over.
        let before = engine.score
        engine.answer("a2")
        XCTAssertEqual(engine.score, before)
    }

    func testGameOverWhenAllCleared() {
        var engine = FallingWordsEngine(items: items(2))
        engine.answer("a0")
        engine.answer("a1")
        XCTAssertTrue(engine.isOver)
        XCTAssertEqual(engine.correctCount, 2)
        XCTAssertEqual(engine.progress, 1.0)
    }

    func testFallDurationDecreases() {
        var engine = FallingWordsEngine(items: items(10))
        let d0 = engine.fallDuration
        engine.answer("a0")
        XCTAssertLessThan(engine.fallDuration, d0)
        XCTAssertGreaterThanOrEqual(engine.fallDuration, 2.0)
    }
}
