import SwiftUI

/// A card that flips between its front and back with a 3D rotation.
struct FlipCardView: View {
    let card: Card
    let sourceLang: String
    let targetLang: String
    let isFlipped: Bool
    var onTap: (() -> Void)?

    var body: some View {
        ZStack {
            face(
                text: card.front,
                caption: nil,
                language: sourceLang,
                background: Color(.secondarySystemGroupedBackground)
            )
            .opacity(isFlipped ? 0 : 1)

            face(
                text: card.back,
                caption: card.example,
                language: targetLang,
                background: Color.accentColor.opacity(0.12)
            )
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.4
        )
        .animation(.spring(duration: 0.45), value: isFlipped)
        .onTapGesture {
            onTap?()
        }
    }

    private func face(
        text: String,
        caption: String?,
        language: String,
        background: Color
    ) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Text(text)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)

            if let caption, !caption.isEmpty {
                Text(caption)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack {
                SpeakerButton(text: text, language: language, font: .title3)
                Spacer()
                Image(systemName: "hand.tap")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}
