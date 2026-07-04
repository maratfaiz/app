import Foundation
import Observation
import SwiftData

/// A deck shared to the community. Value type so it is trivially Codable and
/// can be seeded, persisted locally, or (in future) fetched from a backend.
struct CommunityDeck: Identifiable, Codable, Hashable {
    struct CardDTO: Codable, Hashable {
        var front: String
        var back: String
        var example: String?
    }

    var id: UUID
    var title: String
    var desc: String
    var sourceLang: String
    var targetLang: String
    var subject: String
    var authorName: String
    var authorHandle: String
    var authorColorIndex: Int
    /// Simulated popularity used for the "Popular" rail and social proof.
    var saves: Int
    var cards: [CardDTO]
    /// The deck's own color + emoji, carried so it looks the same for everyone.
    var colorIndex: Int
    var emoji: String

    var cardCount: Int { cards.count }

    init(
        id: UUID = UUID(),
        title: String,
        desc: String,
        sourceLang: String,
        targetLang: String,
        subject: String,
        authorName: String,
        authorHandle: String,
        authorColorIndex: Int,
        saves: Int,
        cards: [CardDTO],
        colorIndex: Int = 0,
        emoji: String = ""
    ) {
        self.id = id
        self.title = title
        self.desc = desc
        self.sourceLang = sourceLang
        self.targetLang = targetLang
        self.subject = subject
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.authorColorIndex = authorColorIndex
        self.saves = saves
        self.cards = cards
        self.colorIndex = colorIndex
        self.emoji = emoji
    }
}

/// Backs the Community (Explore) tab: a curated set of featured decks plus any
/// decks the user has published, persisted locally as JSON in `UserDefaults`.
@Observable
final class CommunityStore {
    static let shared = CommunityStore()

    private let defaults: UserDefaults
    private let publishedKey = "com.linguacards.community.published"

    private(set) var published: [CommunityDeck]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: publishedKey),
           let decoded = try? JSONDecoder().decode([CommunityDeck].self, from: data) {
            self.published = decoded
        } else {
            self.published = []
        }
    }

    /// Featured decks first, then the user's own published decks.
    var all: [CommunityDeck] {
        CommunityStore.featured + published
    }

    var subjects: [String] {
        var seen = Set<String>()
        return all.compactMap { deck in
            seen.insert(deck.subject).inserted ? deck.subject : nil
        }
    }

    func decks(inSubject subject: String) -> [CommunityDeck] {
        all.filter { $0.subject == subject }
    }

    var popular: [CommunityDeck] {
        all.sorted { $0.saves > $1.saves }
    }

    /// Publishes a local deck to the community under the given author.
    func publish(_ deck: Deck, author: ProfileStore) {
        let dto = CommunityDeck(
            title: deck.title,
            desc: deck.desc,
            sourceLang: deck.sourceLang,
            targetLang: deck.targetLang,
            subject: "My decks",
            authorName: author.displayName.isEmpty ? "You" : author.displayName,
            authorHandle: author.handle.isEmpty ? "@you" : author.handle,
            authorColorIndex: author.avatarColorIndex,
            saves: 0,
            cards: deck.cards.map { CommunityDeck.CardDTO(front: $0.front, back: $0.back, example: $0.example) },
            colorIndex: deck.colorIndex,
            emoji: deck.emoji
        )
        published.insert(dto, at: 0)
        persist()
    }

    func isPublished(_ deck: Deck) -> Bool {
        published.contains { $0.title == deck.title && $0.cards.count == deck.cards.count }
    }

    /// Clones a community deck into the user's local library.
    @discardableResult
    func importDeck(_ community: CommunityDeck, into context: ModelContext) -> Deck {
        let deck = Deck(
            title: community.title,
            desc: community.desc,
            sourceLang: community.sourceLang,
            targetLang: community.targetLang,
            colorIndex: community.emoji.isEmpty && community.colorIndex == 0 ? nil : community.colorIndex,
            emoji: community.emoji
        )
        context.insert(deck)
        for card in community.cards {
            let newCard = Card(front: card.front, back: card.back, example: card.example)
            newCard.deck = deck
            context.insert(newCard)
        }
        try? context.save()
        return deck
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(published) {
            defaults.set(data, forKey: publishedKey)
        }
    }
}
