import SwiftUI
import SwiftData

/// Home screen: all decks as vibrant gradient cards, with search.
struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    @State private var isCreatingDeck = false
    @State private var deckToEdit: Deck?
    @State private var searchText = ""

    private var filteredDecks: [Deck] {
        guard !searchText.isEmpty else { return decks }
        return decks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.desc.localizedCaseInsensitiveContains(searchText)
        }
    }

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
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredDecks) { deck in
                                NavigationLink(value: deck) {
                                    DeckCardView(deck: deck)
                                }
                                .buttonStyle(PressableButtonStyle())
                                .contextMenu {
                                    Button {
                                        deckToEdit = deck
                                    } label: {
                                        Label("Edit deck", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        delete(deck)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .searchable(text: $searchText, prompt: "Search decks")
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
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
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

/// A vibrant gradient deck card with title, language pair, counts and progress.
struct DeckCardView: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.title)
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(verbatim: "\(LanguageCatalog.flag(for: deck.sourceLang)) \(LanguageCatalog.name(for: deck.sourceLang))  →  \(LanguageCatalog.flag(for: deck.targetLang)) \(LanguageCatalog.name(for: deck.targetLang))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                ProgressRing(value: deck.masteredFraction, lineWidth: 5, gradient: LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom), showLabel: false)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(deck.masteredFraction, format: .percent.precision(.fractionLength(0)))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    )
            }

            HStack(spacing: 8) {
                pill(text: "\(deck.cardCount) cards", systemImage: "rectangle.stack")
                if deck.dueCount > 0 {
                    pill(text: "\(deck.dueCount) due", systemImage: "clock")
                }
                if !deck.starredCards.isEmpty {
                    pill(text: "\(deck.starredCards.count)", systemImage: "star.fill")
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gradient(for: deck.id), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: Theme.gradientColors(for: deck.id).first?.opacity(0.35) ?? .clear, radius: 14, y: 8)
    }

    private func pill(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.2), in: Capsule())
    }
}
