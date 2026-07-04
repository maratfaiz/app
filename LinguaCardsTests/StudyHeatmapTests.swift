import XCTest
@testable import LinguaCards

final class StudyHeatmapTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private let today = Date(timeIntervalSince1970: 1_750_000_000)

    private func session(daysAgo: Int, correct: Int, incorrect: Int) -> StudySession {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
        return StudySession(date: date, correct: correct, incorrect: incorrect, mode: .learn)
    }

    func testGridIsWeekAlignedAndEndsToday() {
        var cal = calendar
        cal.firstWeekday = 1
        let cells = StatsService.studyHeatmap(sessions: [], weeks: 8, calendar: cal, today: today)
        XCTAssertGreaterThanOrEqual(cells.count, 8 * 7)
        // Starts on the first day of a week (clean columns).
        XCTAssertEqual(cells.first.map { cal.component(.weekday, from: $0.date) }, cal.firstWeekday)
        // Ends today.
        XCTAssertEqual(cells.last.map { cal.startOfDay(for: $0.date) },
                       cal.startOfDay(for: today))
    }

    func testCountsAggregatePerDay() {
        let sessions = [
            session(daysAgo: 1, correct: 3, incorrect: 1), // 4 answers
            session(daysAgo: 1, correct: 2, incorrect: 0), // +2 -> 6 that day
            session(daysAgo: 3, correct: 1, incorrect: 0), // 1 answer
        ]
        let cells = StatsService.studyHeatmap(sessions: sessions, weeks: 8, calendar: calendar, today: today)
        let byDay = Dictionary(uniqueKeysWithValues: cells.map { (calendar.startOfDay(for: $0.date), $0) })

        let day1 = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: today)!)
        let day3 = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -3, to: today)!)
        XCTAssertEqual(byDay[day1]?.count, 6)
        XCTAssertEqual(byDay[day3]?.count, 1)
    }

    func testLevelBuckets() {
        XCTAssertEqual(StatsService.HeatCell(date: today, count: 0).level, 0)
        XCTAssertEqual(StatsService.HeatCell(date: today, count: 3).level, 1)
        XCTAssertEqual(StatsService.HeatCell(date: today, count: 7).level, 2)
        XCTAssertEqual(StatsService.HeatCell(date: today, count: 15).level, 3)
        XCTAssertEqual(StatsService.HeatCell(date: today, count: 40).level, 4)
    }
}
