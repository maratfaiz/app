import SwiftUI
import SwiftData

/// Top-level tab navigation, gated behind first-launch onboarding.
struct RootView: View {
    @Query private var decks: [Deck]
    @AppStorage("com.linguacards.didOnboard") private var didOnboard = false

    private var totalDue: Int {
        decks.reduce(0) { $0 + $1.dueCount }
    }

    var body: some View {
        ZStack {
            TabView {
                DeckListView()
                    .tabItem { Label("Decks", systemImage: "rectangle.stack.fill") }

                ReviewTodayView()
                    .tabItem { Label("Review", systemImage: "clock.fill") }
                    .badge(totalDue)

                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            }
            .tint(Theme.primary)

            if !didOnboard {
                OnboardingView { didOnboard = true }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut, value: didOnboard)
    }
}
