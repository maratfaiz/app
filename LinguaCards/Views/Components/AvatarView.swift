import SwiftUI

/// Gradient circle avatar showing an emoji or initials.
struct AvatarView: View {
    let colors: [Color]
    let text: String
    var size: CGFloat = 44

    var body: some View {
        Text(text)
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Circle()
            )
            .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: (colors.first ?? .clear).opacity(0.35), radius: 6, y: 3)
    }
}
