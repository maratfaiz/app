import SwiftUI

/// First-launch welcome: a few gradient pages introducing the app.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private struct Page: Identifiable {
        let id = Int.random(in: 0...Int.max)
        let systemImage: String
        let title: LocalizedStringKey
        let message: LocalizedStringKey
        let colors: [Color]
    }

    private let pages: [Page] = [
        Page(
            systemImage: "sparkles",
            title: "Welcome to LinguaCards",
            message: "Learn any language with beautiful flashcards and proven study modes.",
            colors: [Color(hex: 0x5468FF), Color(hex: 0x8B5CF6)]
        ),
        Page(
            systemImage: "brain.head.profile",
            title: "Study your way",
            message: "Learn, Flashcards, Write, Match and Test — pick the mode that fits the moment.",
            colors: [Color(hex: 0xEC4899), Color(hex: 0xF97316)]
        ),
        Page(
            systemImage: "clock.arrow.circlepath",
            title: "Remember for good",
            message: "Spaced repetition schedules each card so you review right before you'd forget.",
            colors: [Color(hex: 0x06B6D4), Color(hex: 0x3B82F6)]
        ),
    ]

    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 28) {
                        Spacer()
                        Image(systemName: item.systemImage)
                            .font(.system(size: 90, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(radius: 12)
                        VStack(spacing: 12) {
                            Text(item.title)
                                .font(.system(.largeTitle, design: .rounded).bold())
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(item.message)
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .ignoresSafeArea()
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        Haptics.success()
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Get started")
                        .font(.headline)
                        .foregroundStyle(Color(hex: 0x5468FF))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}
