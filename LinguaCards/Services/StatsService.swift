import Foundation

/// Pure helpers for streaks and aggregated study statistics.
enum StatsService {

    /// One day in the study heatmap (GitHub-contribution-style calendar).
    struct HeatCell: Identifiable, Equatable {
        let date: Date
        let count: Int
        var id: Date { date }

        /// Intensity bucket 0...4 for coloring.
        var level: Int {
            switch count {
            case 0: return 0
            case 1...4: return 1
            case 5...9: return 2
            case 10...19: return 3
            default: return 4
            }
        }
    }

    /// The week-aligned list of days shown in the heatmap, ending today and
    /// starting on the first day of a week so columns are clean. Pure and
    /// testable — no sessions involved.
    static func heatmapDays(
        weeks: Int = 16,
        calendar: Calendar = .current,
        today: Date = .now
    ) -> [Date] {
        let end = calendar.startOfDay(for: today)
        guard let rawStart = calendar.date(byAdding: .day, value: -(weeks * 7 - 1), to: end) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: rawStart)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: -offset, to: rawStart) else {
            return []
        }

        var days: [Date] = []
        var cursor = start
        while cursor <= end {
            days.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }

    /// A day-aligned grid of study activity for the last `weeks` weeks, ending
    /// today, with answer counts tallied per day.
    static func studyHeatmap(
        sessions: [StudySession],
        weeks: Int = 16,
        calendar: Calendar = .current,
        today: Date = .now
    ) -> [HeatCell] {
        var counts: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            counts[day, default: 0] += session.total
        }
        return heatmapDays(weeks: weeks, calendar: calendar, today: today)
            .map { HeatCell(date: $0, count: counts[$0] ?? 0) }
    }

    /// Number of consecutive calendar days with at least one session,
    /// counting back from today. A streak is still "alive" if the most
    /// recent session was yesterday (today's studying just hasn't happened yet).
    static func streak(
        sessionDates: [Date],
        calendar: Calendar = .current,
        today: Date = .now
    ) -> Int {
        let studyDays = Set(sessionDates.map { calendar.startOfDay(for: $0) })
        guard !studyDays.isEmpty else { return 0 }

        let todayStart = calendar.startOfDay(for: today)
        var cursor = todayStart
        if !studyDays.contains(cursor) {
            // Allow the streak to survive until the end of today.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  studyDays.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var count = 0
        while studyDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    /// One aggregated point per day for charting recent activity.
    struct DailyActivity: Identifiable {
        var id: Date { day }
        let day: Date
        var correct: Int
        var incorrect: Int
    }

    /// Aggregates sessions into per-day totals for the last `days` days
    /// (including today), with zero-filled gaps so charts have a stable axis.
    static func dailyActivity(
        sessions: [StudySession],
        days: Int = 14,
        calendar: Calendar = .current,
        today: Date = .now
    ) -> [DailyActivity] {
        let todayStart = calendar.startOfDay(for: today)
        guard let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: todayStart) else {
            return []
        }

        var byDay: [Date: DailyActivity] = [:]
        for offset in 0..<days {
            if let day = calendar.date(byAdding: .day, value: offset, to: windowStart) {
                byDay[day] = DailyActivity(day: day, correct: 0, incorrect: 0)
            }
        }

        for session in sessions {
            let day = calendar.startOfDay(for: session.date)
            guard var activity = byDay[day] else { continue }
            activity.correct += session.correct
            activity.incorrect += session.incorrect
            byDay[day] = activity
        }

        return byDay.values.sorted { $0.day < $1.day }
    }
}
