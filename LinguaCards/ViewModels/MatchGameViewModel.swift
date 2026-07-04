import Foundation
import Observation
import SwiftData

/// Match game: a grid of terms and translations; tap matching pairs, timed.
@Observable
final class MatchGameViewModel {

    struct Tile: Identifiable, Equatable {
        let id = UUID()
        let cardID: UUID
        let text: String
        let isTerm: Bool
        var isMatched = false
    }

    /// Number of card pairs per round.
    static let pairCount = 6
    static let minimumCards = 3

    let deck: Deck
    private let modelContext: ModelContext

    private(set) var tiles: [Tile] = []
    private(set) var selectedTileID: UUID?
    /// Tiles briefly highlighted red after a wrong pairing.
    private(set) var mismatchedTileIDs: Set<UUID> = []
    private(set) var mistakes = 0
    private(set) var startedAt = Date.now
    private(set) var finishedAt: Date?

    init(deck: Deck, modelContext: ModelContext) {
        self.deck = deck
        self.modelContext = modelContext
        startNewRound()
    }

    var isFinished: Bool { finishedAt != nil }

    var matchedPairs: Int {
        tiles.filter { $0.isMatched && $0.isTerm }.count
    }

    var totalPairs: Int {
        tiles.count / 2
    }

    func elapsed(now: Date = .now) -> TimeInterval {
        (finishedAt ?? now).timeIntervalSince(startedAt)
    }

    func startNewRound() {
        let chosen = Array(deck.cards.shuffled().prefix(Self.pairCount))
        var newTiles: [Tile] = []
        for card in chosen {
            newTiles.append(Tile(cardID: card.id, text: card.front, isTerm: true))
            newTiles.append(Tile(cardID: card.id, text: card.back, isTerm: false))
        }
        tiles = newTiles.shuffled()
        selectedTileID = nil
        mismatchedTileIDs = []
        mistakes = 0
        startedAt = .now
        finishedAt = nil
    }

    func tap(_ tile: Tile) {
        guard !isFinished, !tile.isMatched, mismatchedTileIDs.isEmpty else { return }

        guard let firstID = selectedTileID else {
            selectedTileID = tile.id
            Haptics.tap()
            return
        }

        if firstID == tile.id {
            selectedTileID = nil
            return
        }

        guard let first = tiles.first(where: { $0.id == firstID }) else {
            selectedTileID = nil
            return
        }

        if first.cardID == tile.cardID && first.isTerm != tile.isTerm {
            setMatched([first.id, tile.id])
            selectedTileID = nil
            Haptics.success()
            if tiles.allSatisfy(\.isMatched) {
                finish()
            }
        } else {
            mistakes += 1
            mismatchedTileIDs = [first.id, tile.id]
            selectedTileID = nil
            Haptics.error()
        }
    }

    /// Called by the view shortly after a mismatch to clear the red highlight.
    func clearMismatch() {
        mismatchedTileIDs = []
    }

    private func setMatched(_ ids: Set<UUID>) {
        for index in tiles.indices where ids.contains(tiles[index].id) {
            tiles[index].isMatched = true
        }
    }

    private func finish() {
        finishedAt = .now
        let session = StudySession(
            correct: totalPairs,
            incorrect: mistakes,
            mode: .match
        )
        session.deck = deck
        modelContext.insert(session)
        try? modelContext.save()
    }
}
