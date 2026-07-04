import SwiftUI
import SwiftData

/// Top-level tab navigation, gated behind first-launch onboarding and account setup.
struct RootView: View {
    @Environment(ProfileStore.self) private var profile
    @Query private var decks: [Deck]
    @AppStorage("com.linguacards.didOnboard") private var didOnboard = false

    private var totalDue: Int {
        decks.reduce(0) { $0 + $1.dueCount }
    }

    var body: some View {
        ZStack {
            TabView {
                DeckListView()
                    .tabItem { Label("Library", systemImage: "rectangle.stack.fill") }

                CommunityView()
                    .tabItem { Label("Explore", systemImage: "globe") }

                ReviewTodayView()
                    .tabItem { Label("Review", systemImage: "clock.fill") }
                    .badge(totalDue)

                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            }
            .tint(Theme.primary)

            if !didOnboard {
                OnboardingView { didOnboard = true }
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut, value: didOnboard)
        .fullScreenCover(isPresented: needsAccount) {
            AccountSetupView(isCreating: true)
                .environment(profile)
        }
    }

    /// Show account creation once onboarding is done and no account exists yet.
    private var needsAccount: Binding<Bool> {
        Binding(
            get: { didOnboard && !profile.hasAccount },
            set: { _ in }
        )
    }
}
