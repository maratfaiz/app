import XCTest
@testable import LinguaCards

final class LearnEngineTests: XCTestCase {

    func testStartsWithAllItemsQueued() {
        let engine = LearnEngine(count: 5)
        XCTAssertEqual(engine.total, 5)
        XCTAssertEqual(engine.remainingCount, 5)
        XCTAssertEqual(engine.graduatedCount, 0)
        XCTAssertFalse(engine.isFinished)
        XCTAssertEqual(engine.currentBox, 0)
    }

    func testEmptyEngineIsFinished() {
        let engine = LearnEngine(count: 0)
        XCTAssertTrue(engine.isFinished)
        XCTAssertNil(engine.currentIndex)
        XCTAssertEqual(engine.progress, 0)
    }

    func testItemGraduatesAfterRequiredCorrectAnswers() {
        var engine = LearnEngine(count: 1, requiredBox: 2)
        let index = engine.currentIndex
        engine.recordCorrect()
        XCTAssertEqual(engine.graduatedCount, 0, "one correct is not enough")
        XCTAssertEqual(engine.currentIndex, index, "single item requeues to itself")
        engine.recordCorrect()
        XCTAssertEqual(engine.graduatedCount, 1)
        XCTAssertTrue(engine.isFinished)
        XCTAssertEqual(engine.progress, 1.0)
    }

    func testWrongAnswerResetsBoxToZero() {
        var engine = LearnEngine(count: 1, requiredBox: 2)
        engine.recordCorrect()          // box 1
        XCTAssertEqual(engine.currentBox, 1)
        engine.recordWrong()            // back to box 0
        XCTAssertEqual(engine.currentBox, 0)
        XCTAssertEqual(engine.graduatedCount, 0)
    }

    func testWrongAnswerRequeuesInsteadOfDropping() {
        var engine = LearnEngine(count: 3)
        let first = engine.currentIndex
        engine.recordWrong()
        XCTAssertNotEqual(engine.currentIndex, first, "same card shouldn't repeat immediately")
        XCTAssertEqual(engine.remainingCount, 3, "nothing graduated yet")
    }

    func testAllItemsEventuallyGraduate() {
        var engine = LearnEngine(count: 6, requiredBox: 2)
        var guardCounter = 0
        while !engine.isFinished && guardCounter < 1000 {
            engine.recordCorrect()
            guardCounter += 1
        }
        XCTAssertTrue(engine.isFinished)
        XCTAssertEqual(engine.graduatedCount, 6)
        XCTAssertLessThan(guardCounter, 1000, "should terminate quickly")
    }

    func testProgressIsMonotonicUnderCorrectAnswers() {
        var engine = LearnEngine(count: 4, requiredBox: 2)
        var previous = 0.0
        var steps = 0
        while !engine.isFinished && steps < 100 {
            engine.recordCorrect()
            XCTAssertGreaterThanOrEqual(engine.progress, previous)
            previous = engine.progress
            steps += 1
        }
    }
}
