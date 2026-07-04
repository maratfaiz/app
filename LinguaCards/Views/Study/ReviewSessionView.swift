import SwiftUI
import SwiftData

/// Spaced-repetition review of due cards with Again / Hard / Good / Easy grading.
struct ReviewSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let decks: [Deck]

    @State private var viewModel: ReviewViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ReviewViewModel(decks: decks, modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: ReviewViewModel) -> some View {
        if viewModel.totalCount == 0 {
            EmptyStateView(
                systemImage: "checkmark.circle",
                title: "All caught up!",
                message: "No cards are due for review right now. Come back later.",
                actionTitle: "Done",
                action: { dismiss() }
            )
        } else if viewModel.isFinished {
            StudyResultsView(
                correct: viewModel.correctCount,
                incorrect: viewModel.incorrectCount,
                onRestart: nil,
                onDone: { dismiss() }
            )
        } else if let card = viewModel.currentCard {
            VStack(spacing: 20) {
                ProgressView(value: viewModel.progress)
                    .padding(.horizontal)

                Text("\(viewModel.currentIndex + 1) / \(viewModel.totalCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                FlipCardView(
                    card: card,
                    sourceLang: card.deck?.sourceLang ?? "en-US",
                    targetLang: card.deck?.targetLang ?? "ru-RU",
                    isFlipped: viewModel.isFlipped,
                    onTap: { viewModel.flip() }
                )
                .id(card.id)
                .padding(.horizontal, 24)

                if viewModel.isFlipped {
                    gradeButtons(viewModel)
                } else {
                    Button {
                        viewModel.flip()
                    } label: {
                        Text("Show answer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .padding(.top, 8)
        }
    }

    private func gradeButtons(_ viewModel: ReviewViewModel) -> some View {
        HStack(spacing: 10) {
            gradeButton(viewModel, grade: .again, title: "Again", color: .red)
            gradeButton(viewModel, grade: .hard, title: "Hard", color: .orange)
            gradeButton(viewModel, grade: .good, title: "Good", color: .green)
            gradeButton(viewModel, grade: .easy, title: "Easy", color: .blue)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func gradeButton(
        _ viewModel: ReviewViewModel,
        grade: ReviewGrade,
        title: LocalizedStringKey,
        color: Color
    ) -> some View {
        Button {
            withAnimation {
                viewModel.grade(grade)
            }
        } label: {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}
