import SwiftUI

/// Speaks the given text in the given language when tapped.
struct SpeakerButton: View {
    let text: String
    let language: String
    var font: Font = .body

    var body: some View {
        Button {
            SpeechService.shared.speak(text, language: language)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(font)
                .foregroundStyle(.tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Pronounce"))
    }
}
