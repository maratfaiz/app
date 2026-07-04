import UIKit

/// Centralized haptic feedback helpers.
enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Light tap, e.g. flipping a card or selecting a tile.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Firmer tap, e.g. committing a swipe.
    static func swipe() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
