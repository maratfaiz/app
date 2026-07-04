import AVFoundation

/// Wraps AVSpeechSynthesizer to pronounce card text in a given language.
final class SpeechService {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// Speaks `text` using a voice for `languageCode` (BCP-47, e.g. "ru-RU").
    /// Falls back to the base language, then to the system default voice.
    func speak(_ text: String, language languageCode: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = voice(for: languageCode)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func voice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: languageCode) {
            return exact
        }
        let base = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
        return AVSpeechSynthesisVoice(language: base)
    }
}
