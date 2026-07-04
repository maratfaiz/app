import SwiftUI
import SwiftData

/// Preview a community deck and add a copy to your own library.
struct CommunityDeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CommunityStore.self) private var community
    @Environment(\.dismiss) private var dismiss

    let deck: CommunityDeck

    @State private var didAdd = false

    private var authorInitials: String {
        let parts = deck.authorName.split(separator: " ")
        return String(parts.prefix(2).compactMap { $0.first }).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                cardsPreview
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .auroraBackground()
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            addBar
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(deck.subject.uppercased())
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.white.opacity(0.22), in: Capsule())
                Spacer()
                Label("\(deck.saves)", systemImage: "bookmark.fill")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)

            Text(deck.title)
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(.white)

            Text(verbatim: "\(LanguageCatalog.flag(for: deck.sourceLang)) \(LanguageCatalog.name(for: deck.sourceLang))  →  \(LanguageCatalog.flag(for: deck.targetLang)) \(LanguageCatalog.name(for: deck.targetLang))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            if !deck.desc.isEmpty {
                Text(deck.desc)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            HStack(spacing: 8) {
                AvatarView(colors: Theme.deckGradients[deck.authorColorIndex % Theme.deckGradients.count], text: authorInitials, size: 32)
                VStack(alignment: .leading, spacing: 0) {
                    Text(deck.authorName).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(deck.authorHandle).font(.caption).foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Text("\(deck.cardCount) terms")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gradient(for: deck.id), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
    }

    private var cardsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 0) {
                ForEach(Array(deck.cards.enumerated()), id: \.offset) { index, card in
                    if index > 0 { Divider().padding(.leading, 16) }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.front).font(.body.weight(.medium))
                            Text(card.back).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SpeakerButton(text: card.back, language: deck.targetLang)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        }
    }

    private var addBar: some View {
        VStack(spacing: 0) {
            Divider()
            PrimaryButton(
                title: didAdd ? "Added to your library" : "Add to my decks",
                systemImage: didAdd ? "checkmark.circle.fill" : "plus.circle.fill"
            ) {
                guard !didAdd else { dismiss(); return }
                community.importDeck(deck, into: modelContext)
                withAnimation { didAdd = true }
                Haptics.success()
            }
            .padding(16)
            .background(.bar)
        }
    }
}
