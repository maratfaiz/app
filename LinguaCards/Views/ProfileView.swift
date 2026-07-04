import SwiftUI
import SwiftData

/// The account tab: gradient identity header, learning stats and the decks
/// the user has shared to the community.
struct ProfileView: View {
    @Environment(ProfileStore.self) private var profile
    @Environment(CommunityStore.self) private var community
    @Query private var decks: [Deck]
    @Query private var sessions: [StudySession]

    @State private var isEditing = false

    private var totalCards: Int { decks.reduce(0) { $0 + $1.cardCount } }
    private var totalMastered: Int { decks.reduce(0) { $0 + $1.masteredCount } }
    private var streak: Int { StatsService.streak(sessionDates: sessions.map(\.date)) }
    private var totalAnswers: Int { sessions.reduce(0) { $0 + $1.total } }

    private var learnerStats: LearnerStats {
        LearnerStats(
            deckCount: decks.count,
            totalCards: totalCards,
            masteredCount: totalMastered,
            streak: streak,
            totalAnswers: totalAnswers,
            sharedDecks: community.published.count
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    statsRow
                    AchievementsSection(stats: learnerStats)
                        .padding(16)
                        .cardSurface(padding: 0)
                    publishedSection
                    NavigationLink {
                        StatsView()
                    } label: {
                        HStack {
                            Label("View full stats", systemImage: "chart.bar.fill")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .cardSurface()
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                AccountSetupView(isCreating: false)
                    .environment(profile)
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            AvatarView(colors: profile.avatarColors, text: profile.avatarEmoji.isEmpty ? profile.initials : profile.avatarEmoji, size: 88)
            VStack(spacing: 4) {
                Text(profile.displayName.isEmpty ? "Your name" : profile.displayName)
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundStyle(.white)
                Text(profile.handle.isEmpty ? "@handle" : profile.handle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            Label("Joined \(profile.joinedAt.formatted(.dateTime.month(.wide).year()))", systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(profile.avatarGradient, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: (profile.avatarColors.first ?? .clear).opacity(0.3), radius: 14, y: 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(value: "\(decks.count)", label: "Decks", systemImage: "rectangle.stack.fill")
            StatPill(value: "\(totalCards)", label: "Cards", systemImage: "square.stack.3d.up.fill", tint: Theme.sky)
            StatPill(value: "\(totalMastered)", label: "Mastered", systemImage: "checkmark.seal.fill", tint: Theme.success)
            StatPill(value: "\(streak)", label: "Streak", systemImage: "flame.fill", tint: Theme.warning)
        }
    }

    @ViewBuilder
    private var publishedSection: some View {
        let mine = community.published
        VStack(alignment: .leading, spacing: 10) {
            Text("Shared to community")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if mine.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.title)
                        .foregroundStyle(.tint)
                    Text("You haven't shared any decks yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Open a deck and tap Share to publish it.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .cardSurface()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(mine.enumerated()), id: \.element.id) { index, deck in
                        if index > 0 { Divider().padding(.leading, 16) }
                        HStack(spacing: 12) {
                            AvatarView(colors: profile.avatarColors, text: profile.avatarEmoji.isEmpty ? profile.initials : profile.avatarEmoji, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(deck.title).font(.body.weight(.medium))
                                Text("\(deck.cardCount) cards · \(LanguageCatalog.flag(for: deck.targetLang)) \(LanguageCatalog.name(for: deck.targetLang))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.success)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            }
        }
    }
}
