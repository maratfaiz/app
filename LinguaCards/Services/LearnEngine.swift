import Foundation

/// Adaptive scheduling core for Learn mode (Quizlet-style progressive study).
///
/// Each item advances through "boxes": a correct answer promotes it, a wrong
/// answer sends it back to box 0. An item graduates once it reaches
/// `requiredBox` correct answers in a row. Items are re-queued a few slots
/// back so the same card is not shown twice in a row. Pure and testable —
/// it works with indices only, no cards or persistence.
struct LearnEngine {
    struct Item: Equatable {
        let index: Int
        var box: Int
    }

    /// Correct answers needed (at escalating difficulty) to graduate an item.
    let requiredBox: Int
    let total: Int
    private(set) var queue: [Item]
    private(set) var graduated: Set<Int> = []

    init(count: Int, requiredBox: Int = 2) {
        self.total = count
        self.requiredBox = requiredBox
        self.queue = (0..<count).map { Item(index: $0, box: 0) }
    }

    var currentIndex: Int? { queue.first?.index }
    /// The box level of the current item, which drives question difficulty.
    var currentBox: Int? { queue.first?.box }
    var isFinished: Bool { queue.isEmpty }
    var graduatedCount: Int { graduated.count }
    var remainingCount: Int { total - graduated.count }

    var progress: Double {
        total == 0 ? 0 : Double(graduated.count) / Double(total)
    }

    mutating func recordCorrect() {
        guard var item = queue.first else { return }
        queue.removeFirst()
        item.box += 1
        if item.box >= requiredBox {
            graduated.insert(item.index)
        } else {
            reinsert(item)
        }
    }

    mutating func recordWrong() {
        guard var item = queue.first else { return }
        queue.removeFirst()
        item.box = 0
        reinsert(item)
    }

    /// Re-queues an item a few positions back so it isn't shown immediately.
    private mutating func reinsert(_ item: Item) {
        let offset = min(3, queue.count)
        queue.insert(item, at: offset)
    }
}
