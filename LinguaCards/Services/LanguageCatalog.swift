import Foundation

/// The languages offered in deck settings, with speech-synthesis-friendly codes.
struct LanguageOption: Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }

    /// Emoji flag used purely as a visual hint in pickers.
    var flag: String {
        switch code {
        case "en-US": return "🇺🇸"
        case "en-GB": return "🇬🇧"
        case "ru-RU": return "🇷🇺"
        case "es-ES": return "🇪🇸"
        case "fr-FR": return "🇫🇷"
        case "de-DE": return "🇩🇪"
        case "it-IT": return "🇮🇹"
        case "pt-BR": return "🇧🇷"
        case "ja-JP": return "🇯🇵"
        case "zh-CN": return "🇨🇳"
        case "ko-KR": return "🇰🇷"
        default: return "🌐"
        }
    }
}

enum LanguageCatalog {
    static let all: [LanguageOption] = [
        LanguageOption(code: "en-US", name: "English (US)"),
        LanguageOption(code: "en-GB", name: "English (UK)"),
        LanguageOption(code: "ru-RU", name: "Русский"),
        LanguageOption(code: "es-ES", name: "Español"),
        LanguageOption(code: "fr-FR", name: "Français"),
        LanguageOption(code: "de-DE", name: "Deutsch"),
        LanguageOption(code: "it-IT", name: "Italiano"),
        LanguageOption(code: "pt-BR", name: "Português"),
        LanguageOption(code: "ja-JP", name: "日本語"),
        LanguageOption(code: "zh-CN", name: "中文"),
        LanguageOption(code: "ko-KR", name: "한국어"),
    ]

    static func name(for code: String) -> String {
        all.first(where: { $0.code == code })?.name ?? code
    }

    static func flag(for code: String) -> String {
        all.first(where: { $0.code == code })?.flag ?? "🌐"
    }
}
