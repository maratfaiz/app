import Foundation

/// Pure helpers for streaks and aggregated study statistics.
enum StatsService {

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
