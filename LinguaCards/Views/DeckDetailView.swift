import SwiftUI
import SwiftData

/// One deck: stats header, study mode launcher and the card list.
struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let deck: Deck

    @State private var isAddingCard = false
    @State private var cardToEdit: Card?
    @State private var isImporting = false
    @State private var isEditingDeck = false
    @State private var activeStudyMode: StudyMode?

    private var sortedCards: [Card] {
        deck.cards.sorted { $0.front.localizedCaseInsensitiveCompare($1.front) == .orderedAscending }
    }

    var body: some View {
        List {
            statsSection

            studySection

            cardsSection
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isAddingCard = true
                    } label: {
                        Label("Add card", systemImage: "plus")
                    }
                    Button {
                        isImporting = true
                    } label: {
                        Label("Bulk import", systemImage: "square.and.arrow.down.on.square")
                    }
                    Button {
                        isEditingDeck = true
                    } label: {
                        Label("Edit deck", systemImage: "pencil")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isAddingCard) {
            CardFormView(deck: deck, card: nil)
        }
        .sheet(item: $cardToEdit) { card in
            CardFormView(deck: deck, card: card)
        }
        .sheet(isPresented: $isImporting) {
            BulkImportView(deck: deck)
        }
        .sheet(isPresented: $isEditingDeck) {
            DeckFormView(deck: deck)
        }
        .fullScreenCover(item: $activeStudyMode) { mode in
            studyDestination(for: mode)
        }
    }

    // MARK: - Sections

    private var statsSection: some View {
        Section {
            HStack {
                statTile(
                    value: "\(deck.cardCount)",
                    label: "Cards",
                    systemImage: "rectangle.stack"
                )
                statTile(
                    value: deck.masteredFraction
                        .formatted(.percent.precision(.fractionLength(0))),
                    label: "Mastered",
                    systemImage: "checkmark.seal"
                )
                statTile(
                    value: "\(deck.dueCount)",
                    label: "Due today",
                    systemImage: "clock"
                )
                statTile(
                    value: "\(deck.studyStreak)",
                    label: "Day streak",
                    systemImage: "flame"
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
            .listRowBackground(Color.clear)

            if !deck.desc.isEmpty {
                Text(deck.desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var studySection: some View {
        Section("Study") {
            if deck.cards.isEmpty {
                Text("Add cards to unlock study modes.")
                    .foregroundStyle(.secondary)
            } else {
                if deck.dueCount > 0 {
                    studyModeRow(
                        mode: .review,
                        title: "Review due cards",
                        subtitle: "\(deck.dueCount) cards are waiting",
                        systemImage: "clock.badge.exclamationmark",
                        enabled: true
                    )
                }
                studyModeRow(
                    mode: .flashcards,
                    title: "Flashcards",
                    subtitle: "Swipe right if you know it",
                    systemImage: "rectangle.on.rectangle.angled",
                    enabled: true
                )
                studyModeRow(
                    mode: .quiz,
                    title: "Multiple choice",
                    subtitle: deck.cards.count >= QuizViewModel.minimumCards
                        ? "Pick the right translation"
                        : "Needs at least 4 cards",
                    systemImage: "list.bullet.circle",
                    enabled: deck.cards.count >= QuizViewModel.minimumCards
                )
                studyModeRow(
                    mode: .typing,
                    title: "Typing test",
                    subtitle: "Type the translation",
                    systemImage: "keyboard",
                    enabled: true
                )
                studyModeRow(
                    mode: .match,
                    title: "Match game",
                    subtitle: deck.cards.count >= MatchGameViewModel.minimumCards
                        ? "Pair terms with translations"
                        : "Needs at least 3 cards",
                    systemImage: "square.grid.2x2",
                    enabled: deck.cards.count >= MatchGameViewModel.minimumCards
                )
            }
        }
    }

    private var cardsSection: some View {
        Section("Cards") {
            if sortedCards.isEmpty {
                VStack(spacing: 12) {
                    Text("This deck is empty.")
                        .foregroundStyle(.secondary)
                    Button {
                        isAddingCard = true
                    } label: {
                        Label("Add your first card", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ForEach(sortedCards) { card in
                    CardRowView(card: card, deck: deck)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            cardToEdit = card
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(card)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    // MARK: - Pieces

    private func statTile(value: String, label: LocalizedStringKey, systemImage: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.tint)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func studyModeRow(
        mode: StudyMode,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        systemImage: String,
        enabled: Bool
    ) -> some View {
        Button {
            activeStudyMode = mode
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(enabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(enabled ? .primary : .secondary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .disabled(!enabled)
    }

    @ViewBuilder
    private func studyDestination(for mode: StudyMode) -> some View {
        switch mode {
        case .flashcards:
            FlashcardsStudyView(deck: deck)
        case .quiz:
            QuizView(deck: deck)
        case .typing:
            TypingTestView(deck: deck)
        case .match:
            MatchGameView(deck: deck)
        case .review:
            ReviewSessionView(decks: [deck])
        }
    }

    private func delete(_ card: Card) {
        modelContext.delete(card)
        try? modelContext.save()
    }
}

extension StudyMode: Identifiable {
    var id: String { rawValue }
}

/// One row in the card list with term, translation and pronunciation.
struct CardRowView: View {
    let card: Card
    let deck: Deck

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(card.front)
                    .font(.body.weight(.medium))
                Text(card.back)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let example = card.example, !example.isEmpty {
                    Text(example)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if card.isMastered {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else if card.isDue {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            SpeakerButton(text: card.front, language: deck.sourceLang)
        }
    }
}
