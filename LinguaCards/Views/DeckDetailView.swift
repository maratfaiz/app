import SwiftUI
import SwiftData

/// One deck: gradient header, study options, the study-mode grid and cards.
struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProfileStore.self) private var profile
    @Environment(CommunityStore.self) private var community
    let deck: Deck

    @State private var isAddingCard = false
    @State private var cardToEdit: Card?
    @State private var isImporting = false
    @State private var isEditingDeck = false
    @State private var activeStudyMode: StudyMode?
    @State private var options = StudyOptions.default
    @State private var didPublish = false

    private var studyableCount: Int {
        options.starredOnly ? deck.starredCards.count : deck.cardCount
    }

    private var sortedCards: [Card] {
        deck.cards.sorted { $0.front.localizedCaseInsensitiveCompare($1.front) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                header
                if !deck.cards.isEmpty {
                    optionsBar
                    if deck.dueCount > 0 {
                        reviewBanner
                    }
                    modeGrid
                }
                cardsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { isAddingCard = true } label: { Label("Add card", systemImage: "plus") }
                    Button { isImporting = true } label: { Label("Bulk import", systemImage: "square.and.arrow.down.on.square") }
                    Button { isEditingDeck = true } label: { Label("Edit deck", systemImage: "pencil") }
                    if !deck.cards.isEmpty {
                        Divider()
                        Button { publish() } label: {
                            Label(community.isPublished(deck) ? "Shared to community" : "Share to community", systemImage: "globe")
                        }
                        .disabled(community.isPublished(deck))
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isAddingCard) { CardFormView(deck: deck, card: nil) }
        .sheet(item: $cardToEdit) { card in CardFormView(deck: deck, card: card) }
        .sheet(isPresented: $isImporting) { BulkImportView(deck: deck) }
        .sheet(isPresented: $isEditingDeck) { DeckFormView(deck: deck) }
        .fullScreenCover(item: $activeStudyMode) { mode in
            studyDestination(for: mode)
        }
        .alert("Shared to community", isPresented: $didPublish) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("“\(deck.title)” is now in Explore for others to discover.")
        }
    }

    private func publish() {
        community.publish(deck, author: profile)
        Haptics.success()
        didPublish = true
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(verbatim: "\(LanguageCatalog.flag(for: deck.sourceLang)) \(LanguageCatalog.name(for: deck.sourceLang))")
                Image(systemName: "arrow.right")
                    .font(.caption)
                Text(verbatim: "\(LanguageCatalog.flag(for: deck.targetLang)) \(LanguageCatalog.name(for: deck.targetLang))")
                Spacer()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)

            if !deck.desc.isEmpty {
                Text(deck.desc)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            HStack(spacing: 20) {
                headerStat(value: "\(deck.cardCount)", label: "Cards")
                headerStat(value: deck.masteredFraction.formatted(.percent.precision(.fractionLength(0))), label: "Mastered")
                headerStat(value: "\(deck.dueCount)", label: "Due")
                headerStat(value: "\(deck.studyStreak)", label: "Streak")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gradient(for: deck.id), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: Theme.gradientColors(for: deck.id).first?.opacity(0.3) ?? .clear, radius: 14, y: 8)
        .padding(.top, 8)
    }

    private func headerStat(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Options

    private var optionsBar: some View {
        VStack(spacing: 12) {
            Picker("Direction", selection: $options.direction) {
                Text(verbatim: LanguageCatalog.flag(for: deck.sourceLang) + " → " + LanguageCatalog.flag(for: deck.targetLang))
                    .tag(StudyDirection.termToTranslation)
                Text(verbatim: LanguageCatalog.flag(for: deck.targetLang) + " → " + LanguageCatalog.flag(for: deck.sourceLang))
                    .tag(StudyDirection.translationToTerm)
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $options.starredOnly) {
                Label("Starred cards only (\(deck.starredCards.count))", systemImage: "star.fill")
                    .font(.subheadline)
            }
            .disabled(deck.starredCards.isEmpty)
            .tint(Theme.warning)
        }
        .cardSurface()
    }

    private var reviewBanner: some View {
        Button {
            activeStudyMode = .review
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Review due cards")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(deck.dueCount) cards are ready")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
            .background(
                LinearGradient(colors: [Theme.warning, Theme.danger], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var modeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(StudyModeInfo.deckModes) { info in
                let enabled = studyableCount >= info.minimumCards
                Button {
                    activeStudyMode = info.mode
                } label: {
                    modeCard(info, enabled: enabled)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(!enabled)
            }
        }
    }

    private func modeCard(_ info: StudyModeInfo, enabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: info.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(info.title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(info.subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(info.gradient, in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .opacity(enabled ? 1 : 0.4)
        .grayscale(enabled ? 0 : 0.6)
    }

    // MARK: - Cards

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cards")
                    .font(.title3.bold())
                Spacer()
                Button {
                    isAddingCard = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
            }

            if sortedCards.isEmpty {
                EmptyStateView(
                    systemImage: "tray",
                    title: "This deck is empty",
                    message: "Add cards or import a list to start studying.",
                    actionTitle: "Add your first card",
                    action: { isAddingCard = true }
                )
                .frame(height: 260)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedCards.enumerated()), id: \.element.id) { index, card in
                        if index > 0 { Divider().padding(.leading, 16) }
                        CardRowView(
                            card: card,
                            deck: deck,
                            onStar: { toggleStar(card) },
                            onTap: { cardToEdit = card }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(card)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            }
        }
    }

    // MARK: - Destinations & actions

    @ViewBuilder
    private func studyDestination(for mode: StudyMode) -> some View {
        switch mode {
        case .learn:
            LearnView(deck: deck, options: options)
        case .flashcards:
            FlashcardsStudyView(deck: deck, options: options)
        case .quiz:
            QuizView(deck: deck, options: options)
        case .typing:
            TypingTestView(deck: deck, options: options)
        case .match:
            MatchGameView(deck: deck, options: options)
        case .test:
            TestView(deck: deck, options: options)
        case .review:
            ReviewSessionView(decks: [deck])
        }
    }

    private func toggleStar(_ card: Card) {
        card.isStarred.toggle()
        Haptics.tap()
        try? modelContext.save()
    }

    private func delete(_ card: Card) {
        modelContext.delete(card)
        try? modelContext.save()
    }
}

extension StudyMode: Identifiable {
    var id: String { rawValue }
}

/// One row in the card list with term, translation, mastery dot and a star.
struct CardRowView: View {
    let card: Card
    let deck: Deck
    var onStar: () -> Void
    var onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(card.masteryLevel == .new ? Color.secondary.opacity(0.3) : card.masteryLevel.color)
                .frame(width: 8, height: 8)

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

            Button(action: onStar) {
                Image(systemName: card.isStarred ? "star.fill" : "star")
                    .foregroundStyle(card.isStarred ? Theme.warning : Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            SpeakerButton(text: card.front, language: deck.sourceLang)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
