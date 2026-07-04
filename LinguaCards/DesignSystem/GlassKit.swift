import SwiftUI

/// Soft, blurred pastel "aurora" backdrop that gives the frosted-glass panels
/// something to refract — the base of the app's Liquid Glass look. Adapts to
/// light and dark automatically (the base color follows the system).
struct AuroraBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)

            blob(Theme.primary, 300).offset(x: -130, y: -240)
            blob(Theme.pink, 280).offset(x: 150, y: -150)
            blob(Theme.sky, 320).offset(x: 130, y: 300)
            blob(Theme.violet, 280).offset(x: -150, y: 360)
            blob(Theme.success, 220).offset(x: 40, y: 60)
        }
        .ignoresSafeArea()
    }

    private func blob(_ color: Color, _ size: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.22))
            .frame(width: size, height: size)
            .blur(radius: 80)
    }
}

/// A frosted-glass panel: ultra-thin material, a bright hairline border and a
/// soft drop shadow. The signature surface of the Liquid Glass redesign.
struct GlassCard: ViewModifier {
    var radius: CGFloat = Theme.Radius.large
    var padding: CGFloat = Theme.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}

extension View {
    func glassCard(radius: CGFloat = Theme.Radius.large, padding: CGFloat = Theme.Spacing.md) -> some View {
        modifier(GlassCard(radius: radius, padding: padding))
    }

    /// Puts the aurora backdrop behind a screen's content.
    func auroraBackground() -> some View {
        background(AuroraBackground())
    }
}

/// A translucent pill/capsule used for glassy chips and small controls.
struct GlassChip: View {
    let text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).font(.caption2) }
            Text(text).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 0.5))
    }
}
