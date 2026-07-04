import XCTest
@testable import LinguaCards

final class SRSSchedulerTests: XCTestCase {

    private let calendar = Calendar.current
    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    private func daysFromToday(to date: Date) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: date
        ).day ?? -1
    }

    // MARK: - New card progression

    func testFirstGoodReviewSchedulesOneDay() {
        let outcome = SRSScheduler.review(state: .new, grade: .good, now: now)

        XCTAssertEqual(outcome.state.repetitions, 1)
        XCTAssertEqual(outcome.state.interval, 1)
        XCTAssertEqual(outcome.state.easeFactor, SRSScheduler.defaultEase)
        XCTAssertEqual(daysFromToday(to: outcome.nextReview), 1)
    }

    func testSecondGoodReviewSchedulesSixDays() {
        let first = SRSScheduler.review(state: .new, grade: .good, now: now)
        let second = SRSScheduler.review(state: first.state, grade: .good, now: now)

        XCTAssertEqual(second.state.repetitions, 2)
        XCTAssertEqual(second.state.interval, 6)
        XCTAssertEqual(daysFromToday(to: second.nextReview), 6)
    }

    func testThirdGoodReviewMultipliesByEase() {
        var state = SRSState.new
        state = SRSScheduler.review(state: state, grade: .good, now: now).state
        state = SRSScheduler.review(state: state, grade: .good, now: now).state
        let third = SRSScheduler.review(state: state, grade: .good, now: now)

        // 6 days * 2.5 ease = 15 days
        XCTAssertEqual(third.state.interval, 15)
        XCTAssertEqual(third.state.repetitions, 3)
    }

    // MARK: - Again (lapse)

    func testAgainResetsRepetitionsAndInterval() {
        let mature = SRSState(easeFactor: 2.5, interval: 30, repetitions: 5)
        let outcome = SRSScheduler.review(state: mature, grade: .again, now: now)

        XCTAssertEqual(outcome.state.repetitions, 0)
        XCTAssertEqual(outcome.state.interval, 0)
        XCTAssertEqual(outcome.state.easeFactor, 2.3, accuracy: 0.0001)
        // Relearn delay keeps the card due the same day.
        XCTAssertEqual(
            outcome.nextReview,
            now.addingTimeInterval(SRSScheduler.relearnDelay)
        )
    }

    func testEaseNeverDropsBelowMinimum() {
        var state = SRSState(easeFactor: 1.35, interval: 10, repetitions: 3)
        state = SRSScheduler.review(state: state, grade: .again, now: now).state
        XCTAssertEqual(state.easeFactor, SRSScheduler.minimumEase)

        state = SRSScheduler.review(state: state, grade: .again, now: now).state
        XCTAssertEqual(state.easeFactor, SRSScheduler.minimumEase)
    }

    // MARK: - Hard

    func testHardGrowsIntervalSlowlyAndReducesEase() {
        let state = SRSState(easeFactor: 2.5, interval: 10, repetitions: 3)
        let outcome = SRSScheduler.review(state: state, grade: .hard, now: now)

        XCTAssertEqual(outcome.state.interval, 12) // 10 * 1.2
        XCTAssertEqual(outcome.state.easeFactor, 2.35, accuracy: 0.0001)
        XCTAssertEqual(outcome.state.repetitions, 4)
    }

    func testHardOnNewCardSchedulesAtLeastOneDay() {
        let outcome = SRSScheduler.review(state: .new, grade: .hard, now: now)
        XCTAssertEqual(outcome.state.interval, 1)
        XCTAssertEqual(daysFromToday(to: outcome.nextReview), 1)
    }

    // MARK: - Easy

    func testEasyAppliesBonusAndRaisesEase() {
        let state = SRSState(easeFactor: 2.5, interval: 10, repetitions: 3)
        let outcome = SRSScheduler.review(state: state, grade: .easy, now: now)

        XCTAssertEqual(outcome.state.interval, 33) // round(10 * 2.5 * 1.3)
        XCTAssertEqual(outcome.state.easeFactor, 2.65, accuracy: 0.0001)
    }

    func testEasyOnNewCardSchedulesTwoDays() {
        let outcome = SRSScheduler.review(state: .new, grade: .easy, now: now)
        XCTAssertEqual(outcome.state.interval, 2)
        XCTAssertEqual(outcome.state.repetitions, 1)
    }

    func testEaseNeverExceedsMaximum() {
        var state = SRSState(easeFactor: 2.95, interval: 10, repetitions: 3)
        state = SRSScheduler.review(state: state, grade: .easy, now: now).state
        XCTAssertEqual(state.easeFactor, SRSScheduler.maximumEase)
    }

    // MARK: - Long-run sanity

    func testIntervalsGrowMonotonicallyWithGood() {
        var state = SRSState.new
        var previousInterval = 0.0
        for _ in 0..<8 {
            state = SRSScheduler.review(state: state, grade: .good, now: now).state
            XCTAssertGreaterThan(state.interval, previousInterval)
            previousInterval = state.interval
        }
    }
}
