import SwiftUI
import SwiftData

/// Top-level tab navigation.
struct RootView: View {
    @Query private var decks: [Deck]

    private var totalDue: Int {
        decks.reduce(0) { $0 + $1.dueCount }
    }

    var body: some View {
        TabView {
            DeckListView()
                .tabItem {
                    Label("Decks", systemImage: "rectangle.stack.fill")
                }

            ReviewTodayView()
                .tabItem {
                    Label("Review", systemImage: "clock.fill")
                }
                .badge(totalDue)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
    }
}
