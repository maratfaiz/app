import Foundation

/// How the user graded their recall of a card during review.
enum ReviewGrade: Int, CaseIterable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3
}

/// The scheduling state of a card, independent of persistence so it is
/// trivially unit-testable.
struct SRSState: Equatable {
    var easeFactor: Double
    /// Days between reviews; 0 means "new or relearning, review again today".
    var interval: Double
    /// Number of consecutive successful reviews.
    var repetitions: Int

    static let new = SRSState(
        easeFactor: SRSScheduler.defaultEase,
        interval: 0,
        repetitions: 0
    )
}

/// Simplified SM-2 spaced repetition scheduler.
///
/// Differences from canonical SM-2:
/// - Four grades (Again / Hard / Good / Easy) instead of a 0-5 quality scale.
/// - "Again" resets repetitions and schedules a same-day retry.
/// - "Hard" grows the interval slowly (x1.2) and lowers ease.
/// - "Easy" applies an extra x1.3 bonus and raises ease.
enum SRSScheduler {
    static let defaultEase = 2.5
    static let minimumEase = 1.3
    static let maximumEase = 3.0
    /// Delay before a lapsed ("Again") card is shown once more, in seconds.
    static let relearnDelay: TimeInterval = 10 * 60

    struct Outcome: Equatable {
        var state: SRSState
        var nextReview: Date
    }

    static func review(state: SRSState, grade: ReviewGrade, now: Date = .now) -> Outcome {
        var next = state

        switch grade {
        case .again:
            next.repetitions = 0
            next.interval = 0
            next.easeFactor = clampEase(state.easeFactor - 0.20)

        case .hard:
            next.repetitions = state.repetitions + 1
            next.interval = max(1, (state.interval * 1.2).rounded())
            next.easeFactor = clampEase(state.easeFactor - 0.15)

        case .good:
            next.repetitions = state.repetitions + 1
            switch next.repetitions {
            case 1: next.interval = 1
            case 2: next.interval = 6
            default: next.interval = max(1, (state.interval * state.easeFactor).rounded())
            }

        case .easy:
            next.repetitions = state.repetitions + 1
            switch next.repetitions {
            case 1: next.interval = 2
            case 2: next.interval = 8
            default: next.interval = max(1, (state.interval * state.easeFactor * 1.3).rounded())
            }
            next.easeFactor = clampEase(state.easeFactor + 0.15)
        }

        let nextReview: Date
        if next.interval <= 0 {
            nextReview = now.addingTimeInterval(relearnDelay)
        } else {
            nextReview = Calendar.current.date(
                byAdding: .day,
                value: Int(next.interval),
                to: Calendar.current.startOfDay(for: now)
            ) ?? now.addingTimeInterval(next.interval * 86_400)
        }

        return Outcome(state: next, nextReview: nextReview)
    }

    private static func clampEase(_ ease: Double) -> Double {
        min(max(ease, minimumEase), maximumEase)
    }
}
