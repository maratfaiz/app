import SwiftUI

/// Central design system: colors, gradients, spacing, radii and typography.
///
/// Everything visual routes through here so the app reads as one system in
/// both light and dark mode.
enum Theme {

    // MARK: - Brand palette

    /// Primary brand indigo.
    static let primary = Color(hex: 0x5468FF)
    /// Secondary violet, used in gradients and accents.
    static let violet = Color(hex: 0x8B5CF6)
    /// Playful pink highlight.
    static let pink = Color(hex: 0xEC4899)

    static let success = Color(hex: 0x22C55E)
    static let warning = Color(hex: 0xF59E0B)
    static let danger = Color(hex: 0xEF4444)
    static let sky = Color(hex: 0x0EA5E9)

    /// The signature brand gradient (indigo → violet).
    static let brandGradient = LinearGradient(
        colors: [Color(hex: 0x5468FF), Color(hex: 0x8B5CF6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Layout

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 18
        static let large: CGFloat = 26
        static let card: CGFloat = 28
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Deck gradients

    /// A curated set of two-color gradients assigned to decks so each one
    /// has its own recognizable identity, like a real flashcard app.
    static let deckGradients: [[Color]] = [
        [Color(hex: 0x5468FF), Color(hex: 0x8B5CF6)], // indigo → violet
        [Color(hex: 0xEC4899), Color(hex: 0xF97316)], // pink → orange
        [Color(hex: 0x06B6D4), Color(hex: 0x3B82F6)], // cyan → blue
        [Color(hex: 0x10B981), Color(hex: 0x22D3EE)], // emerald → cyan
        [Color(hex: 0xF59E0B), Color(hex: 0xEF4444)], // amber → red
        [Color(hex: 0x8B5CF6), Color(hex: 0xEC4899)], // violet → pink
        [Color(hex: 0x0EA5E9), Color(hex: 0x6366F1)], // sky → indigo
        [Color(hex: 0x14B8A6), Color(hex: 0x0EA5E9)], // teal → sky
    ]

    /// Deterministic gradient index from a UUID's raw bytes (not `hashValue`,
    /// which is per-process randomized). Used to seed a new deck's color.
    static func gradientIndex(for id: UUID) -> Int {
        let bytes = id.uuid
        let sum = Int(bytes.0) &+ Int(bytes.6) &+ Int(bytes.9) &+ Int(bytes.15)
        return sum % deckGradients.count
    }

    static func colors(atIndex index: Int) -> [Color] {
        deckGradients[((index % deckGradients.count) + deckGradients.count) % deckGradients.count]
    }

    static func gradient(atIndex index: Int) -> LinearGradient {
        LinearGradient(colors: colors(atIndex: index), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func gradientColors(for id: UUID) -> [Color] {
        colors(atIndex: gradientIndex(for: id))
    }

    static func gradient(for id: UUID) -> LinearGradient {
        gradient(atIndex: gradientIndex(for: id))
    }
}

extension Color {
    /// Initializes a color from a 0xRRGGBB integer.
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
