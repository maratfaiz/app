import SwiftUI

// MARK: - Card surface

/// Elevated rounded surface used for grouped content throughout the app.
struct CardSurface: ViewModifier {
    var radius: CGFloat = Theme.Radius.medium
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
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }
}

extension View {
    func cardSurface(radius: CGFloat = Theme.Radius.medium, padding: CGFloat = Theme.Spacing.md) -> some View {
        modifier(CardSurface(radius: radius, padding: padding))
    }
}

// MARK: - Primary gradient button

/// Full-width call-to-action with the brand gradient and a press animation.
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var systemImage: String?
    var gradient: LinearGradient = Theme.brandGradient
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient, in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .shadow(color: Theme.primary.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Subtle scale-down on press, reused by several tappable surfaces.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Segmented progress bar

/// Rounded progress bar with an optional gradient fill.
struct GradientProgressBar: View {
    var value: Double // 0...1
    var height: CGFloat = 8
    var gradient: LinearGradient = Theme.brandGradient

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(gradient)
                    .frame(width: max(height, geo.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
    }
}

// MARK: - Circular progress ring

struct ProgressRing: View {
    var value: Double // 0...1
    var lineWidth: CGFloat = 6
    var gradient: LinearGradient = Theme.brandGradient
    var showLabel: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if showLabel {
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: value)
    }
}

// MARK: - Stat pill

/// Compact labelled metric used in deck headers and stats.
struct StatPill: View {
    let value: String
    let label: LocalizedStringKey
    let systemImage: String
    var tint: Color = Theme.primary

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.headline, design: .rounded))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
    }
}

// MARK: - Confetti

/// Lightweight confetti burst shown on celebratory results screens.
struct ConfettiView: View {
    var isActive: Bool
    private let pieces = 60

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<pieces, id: \.self) { index in
                    ConfettiPiece(
                        isActive: isActive,
                        containerSize: geo.size,
                        seed: index
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiPiece: View {
    let isActive: Bool
    let containerSize: CGSize
    let seed: Int

    private var color: Color {
        [Theme.primary, Theme.violet, Theme.pink, Theme.success, Theme.warning, Theme.sky][seed % 6]
    }

    @State private var animate = false

    var body: some View {
        let startX = CGFloat((seed * 53) % 100) / 100 * containerSize.width
        let drift = CGFloat(((seed * 37) % 100) - 50)
        let delay = Double(seed % 12) * 0.03
        let size = CGFloat(6 + (seed % 5) * 2)

        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size * 1.6)
            .rotationEffect(.degrees(animate ? Double((seed * 47) % 360) : 0))
            .position(
                x: startX + (animate ? drift : 0),
                y: animate ? containerSize.height + 40 : -40
            )
            .opacity(animate ? 0 : 1)
            .onChange(of: isActive) { _, active in
                guard active else { return }
                withAnimation(.easeIn(duration: 1.8).delay(delay)) {
                    animate = true
                }
            }
    }
}
