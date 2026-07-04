import Foundation
import Observation
import SwiftUI

/// The signed-in user's profile. Stored locally in `UserDefaults` — this is
/// an offline-first app, so an "account" lives on device. The shape is kept
/// backend-ready (handle, display name, avatar, joined date) so it could sync
/// to a server later without changing call sites.
@Observable
final class ProfileStore {
    static let shared = ProfileStore()

    private let defaults: UserDefaults
    private enum Key {
        static let hasAccount = "com.linguacards.profile.hasAccount"
        static let displayName = "com.linguacards.profile.displayName"
        static let handle = "com.linguacards.profile.handle"
        static let bio = "com.linguacards.profile.bio"
        static let avatarColorIndex = "com.linguacards.profile.avatarColorIndex"
        static let avatarEmoji = "com.linguacards.profile.avatarEmoji"
        static let joinedAt = "com.linguacards.profile.joinedAt"
    }

    var hasAccount: Bool { didSet { defaults.set(hasAccount, forKey: Key.hasAccount) } }
    var displayName: String { didSet { defaults.set(displayName, forKey: Key.displayName) } }
    var handle: String { didSet { defaults.set(handle, forKey: Key.handle) } }
    var bio: String { didSet { defaults.set(bio, forKey: Key.bio) } }
    var avatarColorIndex: Int { didSet { defaults.set(avatarColorIndex, forKey: Key.avatarColorIndex) } }
    var avatarEmoji: String { didSet { defaults.set(avatarEmoji, forKey: Key.avatarEmoji) } }
    var joinedAt: Date { didSet { defaults.set(joinedAt.timeIntervalSince1970, forKey: Key.joinedAt) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasAccount = defaults.bool(forKey: Key.hasAccount)
        self.displayName = defaults.string(forKey: Key.displayName) ?? ""
        self.handle = defaults.string(forKey: Key.handle) ?? ""
        self.bio = defaults.string(forKey: Key.bio) ?? ""
        self.avatarColorIndex = defaults.integer(forKey: Key.avatarColorIndex)
        self.avatarEmoji = defaults.string(forKey: Key.avatarEmoji) ?? ""
        let stored = defaults.double(forKey: Key.joinedAt)
        self.joinedAt = stored > 0 ? Date(timeIntervalSince1970: stored) : .now
    }

    /// Creates (or updates) the local account.
    func save(displayName: String, handle: String, bio: String, colorIndex: Int, emoji: String) {
        self.displayName = displayName.trimmingCharacters(in: .whitespaces)
        self.handle = ProfileStore.normalizeHandle(handle)
        self.bio = bio.trimmingCharacters(in: .whitespaces)
        self.avatarColorIndex = colorIndex
        self.avatarEmoji = emoji
        if !hasAccount {
            joinedAt = .now
            hasAccount = true
        }
    }

    /// Two-letter initials for the gradient avatar.
    var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        let result = String(letters).uppercased()
        return result.isEmpty ? "🙂" : result
    }

    var avatarColors: [Color] {
        Theme.deckGradients[avatarColorIndex % Theme.deckGradients.count]
    }

    var avatarGradient: LinearGradient {
        LinearGradient(colors: avatarColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func normalizeHandle(_ raw: String) -> String {
        let cleaned = raw
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
        return cleaned.hasPrefix("@") ? cleaned : "@" + cleaned
    }
}
