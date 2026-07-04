import SwiftUI
import SwiftData

/// Explore tab: browse and search community decks, then add them to your library.
struct CommunityView: View {
    @Environment(CommunityStore.self) private var community
    @State private var searchText = ""

    private var searchResults: [CommunityDeck] {
        guard !searchText.isEmpty else { return [] }
        return community.all.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.desc.localizedCaseInsensitiveContains(searchText)
                || $0.subject.localizedCaseInsensitiveContains(searchText)
                || $0.authorName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if searchText.isEmpty {
                    browse
                } else {
                    results
                }
            }
            .auroraBackground()
            .navigationTitle("Explore")
            .navigationDestination(for: CommunityDeck.self) { deck in
                CommunityDeckDetailView(deck: deck)
            }
            .searchable(text: $searchText, prompt: "Search decks, subjects, people")
        }
    }

    private var browse: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Popular rail
            sectionHeader("Popular this week", systemImage: "flame.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(community.popular.prefix(6))) { deck in
                        NavigationLink(value: deck) {
                            FeaturedDeckCard(deck: deck)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }

            // By subject
            ForEach(community.subjects, id: \.self) { subject in
                sectionHeader(LocalizedStringKey(subject), systemImage: "square.grid.2x2.fill")
                VStack(spacing: 10) {
                    ForEach(community.decks(inSubject: subject)) { deck in
                        NavigationLink(value: deck) {
                            CommunityDeckRow(deck: deck)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
    }

    private var results: some View {
        VStack(spacing: 10) {
            if searchResults.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .padding(.top, 60)
            } else {
                ForEach(searchResults) { deck in
                    NavigationLink(value: deck) {
                        CommunityDeckRow(deck: deck)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .padding(16)
    }

    private func sectionHeader(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.bold())
            .padding(.horizontal, 16)
    }
}

/// Large gradient card used in the horizontal "Popular" rail.
struct FeaturedDeckCard: View {
    let deck: CommunityDeck

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(deck.subject.uppercased())
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.white.opacity(0.22), in: Capsule())
                Spacer()
                Label("\(deck.saves)", systemImage: "bookmark.fill")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)

            Spacer()

            Text(deck.title)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(.white)
                .lineLimit(2)
            HStack(spacing: 6) {
                AvatarView(colors: Theme.deckGradients[deck.authorColorIndex % Theme.deckGradients.count], text: authorInitials, size: 22)
                Text(deck.authorHandle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Text("\(deck.cardCount) terms · \(LanguageCatalog.flag(for: deck.targetLang))")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(16)
        .frame(width: 220, height: 180, alignment: .topLeading)
        .background(Theme.gradient(for: deck.id), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
    }

    private var authorInitials: String {
        let parts = deck.authorName.split(separator: " ")
        return String(parts.prefix(2).compactMap { $0.first }).uppercased()
    }
}

/// Compact community deck row used in subject lists and search results.
struct CommunityDeckRow: View {
    let deck: CommunityDeck

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.gradient(for: deck.id))
                .frame(width: 48, height: 48)
                .overlay(Text(LanguageCatalog.flag(for: deck.targetLang)).font(.title3))

            VStack(alignment: .leading, spacing: 2) {
                Text(deck.title).font(.body.weight(.semibold))
                Text(deck.desc).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 4) {
                    Text(deck.authorHandle)
                    Text("·")
                    Text("\(deck.cardCount) terms")
                    Text("·")
                    Image(systemName: "bookmark.fill").font(.system(size: 8))
                    Text("\(deck.saves)")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(12)
        .cardSurface(padding: 0)
        .padding(.horizontal, 0)
        .contentShape(Rectangle())
    }
}
