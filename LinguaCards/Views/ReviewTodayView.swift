import SwiftUI
import SwiftData

/// "Review today" tab: due cards across all decks, with a per-deck breakdown.
struct ReviewTodayView: View {
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    @State private var reviewTarget: ReviewTarget?

    private struct ReviewTarget: Identifiable {
        let id = UUID()
        let decks: [Deck]
    }

    private var decksWithDueCards: [Deck] {
        decks.filter { $0.dueCount > 0 }
    }

    private var totalDue: Int {
        decksWithDueCards.reduce(0) { $0 + $1.dueCount }
    }

    var body: some View {
        NavigationStack {
            Group {
                if totalDue == 0 {
                    EmptyStateView(
                        systemImage: "checkmark.circle",
                        title: "All caught up!",
                        message: "No cards are due for review today. Great job staying on schedule."
                    )
                } else {
                    List {
                        Section {
                            Button {
                                reviewTarget = ReviewTarget(decks: decksWithDueCards)
                            } label: {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(.tint)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Review everything")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("\(totalDue) cards due")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }

                        Section("By deck") {
                            ForEach(decksWithDueCards) { deck in
                                Button {
                                    reviewTarget = ReviewTarget(decks: [deck])
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(deck.title)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(.primary)
                                            Text("\(deck.dueCount) due")
                                                .font(.caption)
                                                .foregroundStyle(.orange)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .auroraBackground()
            .navigationTitle("Review today")
            .fullScreenCover(item: $reviewTarget) { target in
                ReviewSessionView(decks: target.decks)
            }
        }
    }
}
