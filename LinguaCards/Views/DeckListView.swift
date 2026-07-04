import SwiftUI
import SwiftData

/// Home screen: all decks with card counts and mastery progress.
struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    @State private var isCreatingDeck = false
    @State private var deckToEdit: Deck?

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    EmptyStateView(
                        systemImage: "rectangle.stack.badge.plus",
                        title: "No decks yet",
                        message: "Create your first deck to start learning new words.",
                        actionTitle: "Create a deck",
                        action: { isCreatingDeck = true }
                    )
                } else {
                    List {
                        ForEach(decks) { deck in
                            NavigationLink(value: deck) {
                                DeckRowView(deck: deck)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(deck)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    deckToEdit = deck
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Decks")
            .navigationDestination(for: Deck.self) { deck in
                DeckDetailView(deck: deck)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCreatingDeck = true
                    } label: {
                        Label("New deck", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isCreatingDeck) {
                DeckFormView(deck: nil)
            }
            .sheet(item: $deckToEdit) { deck in
                DeckFormView(deck: deck)
            }
        }
    }

    private func delete(_ deck: Deck) {
        modelContext.delete(deck)
        try? modelContext.save()
    }
}

/// One row in the deck list: title, language pair, card count and progress ring.
struct DeckRowView: View {
    let deck: Deck

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.title)
                    .font(.headline)

                Text("\(LanguageCatalog.flag(for: deck.sourceLang)) \(LanguageCatalog.name(for: deck.sourceLang)) → \(LanguageCatalog.flag(for: deck.targetLang)) \(LanguageCatalog.name(for: deck.targetLang))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text("\(deck.cardCount) cards")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if deck.dueCount > 0 {
                        Text("\(deck.dueCount) due")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: deck.masteredFraction)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(deck.masteredFraction, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .frame(width: 44, height: 44)
        }
        .padding(.vertical, 4)
    }
}
