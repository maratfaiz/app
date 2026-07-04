import SwiftUI
import SwiftData

/// Swipeable flashcards: tap to flip, swipe right = known, left = unknown.
struct FlashcardsStudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    var options: StudyOptions = .default

    @State private var viewModel: FlashcardsViewModel?
    @State private var dragOffset = CGSize.zero

    private let swipeThreshold: CGFloat = 110

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = FlashcardsViewModel(deck: deck, options: options, modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: FlashcardsViewModel) -> some View {
        if viewModel.isFinished {
            StudyResultsView(
                correct: viewModel.knownCount,
                incorrect: viewModel.unknownCount,
                onRestart: {
                    self.viewModel = FlashcardsViewModel(deck: deck, options: options, modelContext: modelContext)
                },
                onDone: { dismiss() }
            )
        } else if let card = viewModel.currentCard {
            VStack(spacing: 20) {
                GradientProgressBar(value: viewModel.progress)
                    .padding(.horizontal)

                HStack {
                    Label("\(viewModel.unknownCount)", systemImage: "xmark.circle.fill")
                        .foregroundStyle(Theme.danger)
                    Spacer()
                    Text("\(viewModel.currentIndex + 1) / \(viewModel.cards.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(viewModel.knownCount)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24)

                ZStack {
                    if let next = viewModel.nextCard {
                        FlipCardView(
                            card: next,
                            direction: options.direction,
                            deckID: deck.id,
                            promptLanguage: deck.promptLanguage(for: options.direction),
                            answerLanguage: deck.answerLanguage(for: options.direction),
                            isFlipped: false
                        )
                        .scaleEffect(0.94)
                        .opacity(0.5)
                        .allowsHitTesting(false)
                    }

                    FlipCardView(
                        card: card,
                        direction: options.direction,
                        deckID: deck.id,
                        promptLanguage: deck.promptLanguage(for: options.direction),
                        answerLanguage: deck.answerLanguage(for: options.direction),
                        isFlipped: viewModel.isFlipped,
                        onTap: { viewModel.flip() },
                        onStar: { viewModel.toggleStar() }
                    )
                    .id(card.id)
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width) / 16))
                    .overlay(alignment: .topLeading) { swipeBadge(known: true) }
                    .overlay(alignment: .topTrailing) { swipeBadge(known: false) }
                    .gesture(dragGesture(viewModel))
                }
                .padding(.horizontal, 24)

                HStack(spacing: 40) {
                    circleButton(system: "xmark", tint: Theme.danger) {
                        commitSwipe(viewModel, known: false)
                    }
                    circleButton(system: "checkmark", tint: Theme.success) {
                        commitSwipe(viewModel, known: true)
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.top, 8)
        }
    }

    private func circleButton(system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title2.bold())
                .frame(width: 64, height: 64)
                .background(tint.opacity(0.15), in: Circle())
                .foregroundStyle(tint)
        }
        .buttonStyle(PressableButtonStyle())
    }

    @ViewBuilder
    private func swipeBadge(known: Bool) -> some View {
        let visible = known ? dragOffset.width > 30 : dragOffset.width < -30
        Text(known ? "Know it" : "Learning")
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(known ? Theme.success : Theme.danger, in: Capsule())
            .foregroundStyle(.white)
            .rotationEffect(.degrees(known ? -12 : 12))
            .opacity(visible ? 1 : 0)
            .padding(16)
    }

    private func dragGesture(_ viewModel: FlashcardsViewModel) -> some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = value.translation }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    commitSwipe(viewModel, known: true)
                } else if value.translation.width < -swipeThreshold {
                    commitSwipe(viewModel, known: false)
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragOffset = .zero }
                }
            }
    }

    private func commitSwipe(_ viewModel: FlashcardsViewModel, known: Bool) {
        withAnimation(.easeIn(duration: 0.2)) {
            dragOffset = CGSize(width: known ? 600 : -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            viewModel.mark(known: known)
            dragOffset = .zero
        }
    }
}
