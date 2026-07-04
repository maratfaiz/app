import SwiftUI
import SwiftData

/// Swipeable flashcards: tap to flip, swipe right = known, left = unknown.
struct FlashcardsStudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

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
                viewModel = FlashcardsViewModel(deck: deck, modelContext: modelContext)
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
                    self.viewModel = FlashcardsViewModel(deck: deck, modelContext: modelContext)
                },
                onDone: { dismiss() }
            )
        } else if let card = viewModel.currentCard {
            VStack(spacing: 20) {
                ProgressView(value: viewModel.progress)
                    .padding(.horizontal)

                HStack {
                    Label("\(viewModel.unknownCount)", systemImage: "xmark.circle")
                        .foregroundStyle(.red)
                    Spacer()
                    Text("\(viewModel.currentIndex + 1) / \(viewModel.cards.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(viewModel.knownCount)", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24)

                ZStack {
                    if let next = viewModel.nextCard {
                        FlipCardView(
                            card: next,
                            sourceLang: deck.sourceLang,
                            targetLang: deck.targetLang,
                            isFlipped: false
                        )
                        .scaleEffect(0.94)
                        .opacity(0.5)
                        .allowsHitTesting(false)
                    }

                    FlipCardView(
                        card: card,
                        sourceLang: deck.sourceLang,
                        targetLang: deck.targetLang,
                        isFlipped: viewModel.isFlipped,
                        onTap: { viewModel.flip() }
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
                    Button {
                        commitSwipe(viewModel, known: false)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2.bold())
                            .frame(width: 60, height: 60)
                            .background(.red.opacity(0.15), in: Circle())
                            .foregroundStyle(.red)
                    }
                    Button {
                        commitSwipe(viewModel, known: true)
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title2.bold())
                            .frame(width: 60, height: 60)
                            .background(.green.opacity(0.15), in: Circle())
                            .foregroundStyle(.green)
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.top, 8)
        }
    }

    /// "Know" / "Still learning" badge that fades in while dragging.
    @ViewBuilder
    private func swipeBadge(known: Bool) -> some View {
        let visible = known ? dragOffset.width > 30 : dragOffset.width < -30
        Text(known ? "Know it" : "Learning")
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(known ? .green : .red, in: Capsule())
            .foregroundStyle(.white)
            .rotationEffect(.degrees(known ? -12 : 12))
            .opacity(visible ? 1 : 0)
            .padding(16)
    }

    private func dragGesture(_ viewModel: FlashcardsViewModel) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    commitSwipe(viewModel, known: true)
                } else if value.translation.width < -swipeThreshold {
                    commitSwipe(viewModel, known: false)
                } else {
                    withAnimation(.spring(duration: 0.3)) {
                        dragOffset = .zero
                    }
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
