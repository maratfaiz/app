import SwiftUI

/// A card that flips between its prompt and answer with a 3D rotation.
/// The answer side wears the deck's signature gradient.
struct FlipCardView: View {
    let card: Card
    let direction: StudyDirection
    let deckID: UUID
    let promptLanguage: String
    let answerLanguage: String
    let isFlipped: Bool
    var onTap: (() -> Void)?
    var onStar: (() -> Void)?

    private var promptText: String { card.prompt(for: direction) }
    private var answerText: String { card.answer(for: direction) }

    var body: some View {
        ZStack {
            promptFace
                .opacity(isFlipped ? 0 : 1)

            answerFace
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.4
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFlipped)
        .onTapGesture { onTap?() }
    }

    private var promptFace: some View {
        cardBody(
            text: promptText,
            caption: nil,
            language: promptLanguage,
            labelText: "Tap to flip",
            foreground: .primary,
            background: AnyView(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                    )
            ),
            starTint: card.isStarred ? Theme.warning : .secondary
        )
    }

    private var answerFace: some View {
        cardBody(
            text: answerText,
            caption: card.example,
            language: answerLanguage,
            labelText: "Answer",
            foreground: .white,
            background: AnyView(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Theme.gradient(for: deckID))
            ),
            starTint: card.isStarred ? .white : .white.opacity(0.6)
        )
    }

    private func cardBody(
        text: String,
        caption: String?,
        language: String,
        labelText: LocalizedStringKey,
        foreground: Color,
        background: AnyView,
        starTint: Color
    ) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(labelText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(foreground.opacity(0.5))
                Spacer()
                if let onStar {
                    Button {
                        onStar()
                    } label: {
                        Image(systemName: card.isStarred ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(starTint)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Text(text)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(foreground)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)

            if let caption, !caption.isEmpty {
                Text(caption)
                    .font(.callout)
                    .foregroundStyle(foreground.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack {
                SpeakerButton(text: text, language: language, font: .title2)
                    .tint(foreground)
                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }
}
