import Foundation

/// A curated but generous set of emojis for personalizing decks and avatars,
/// grouped so the picker can show sections.
enum EmojiCatalog {
    struct Group: Identifiable {
        let id = UUID()
        let name: String
        let emojis: [String]
    }

    static let groups: [Group] = [
        Group(name: "Learning", emojis: [
            "📚", "📖", "✏️", "📝", "🎓", "🧠", "💡", "🔤", "🔡", "🗣️", "💬", "🧩", "🏫", "🧑‍🏫",
        ]),
        Group(name: "Travel & Places", emojis: [
            "✈️", "🌍", "🌎", "🌏", "🗺️", "🧳", "🏔️", "🏝️", "🏙️", "🗽", "🗼", "🏰", "⛩️", "🚀",
        ]),
        Group(name: "Food & Drink", emojis: [
            "🍎", "🍕", "🍜", "🍣", "🥐", "🍰", "☕️", "🍷", "🥑", "🌮", "🍔", "🧀", "🍫", "🍩",
        ]),
        Group(name: "Nature & Animals", emojis: [
            "🦊", "🐬", "🐱", "🐶", "🦉", "🦁", "🐼", "🦄", "🌸", "🌿", "🍀", "🌻", "🔥", "⚡️",
        ]),
        Group(name: "Symbols", emojis: [
            "⭐️", "🌟", "❤️", "💜", "💙", "💚", "🧡", "🎯", "🏆", "🎧", "🎨", "🎮", "🚦", "✅",
        ]),
        Group(name: "Flags", emojis: [
            "🇺🇸", "🇬🇧", "🇷🇺", "🇪🇸", "🇫🇷", "🇩🇪", "🇮🇹", "🇧🇷", "🇯🇵", "🇨🇳", "🇰🇷", "🇵🇹", "🇹🇷", "🇳🇱",
        ]),
    ]

    /// A flat list of every emoji, handy for compact pickers.
    static let all: [String] = groups.flatMap(\.emojis)
}
