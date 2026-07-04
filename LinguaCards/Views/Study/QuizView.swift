import SwiftUI
import SwiftData

/// Multiple-choice quiz with four options per question.
struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

    @State private var viewModel: QuizViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Multiple choice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = QuizViewModel(deck: deck, modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: QuizViewModel) -> some View {
        if viewModel.isFinished {
            StudyResultsView(
                correct: viewModel.correctCount,
                incorrect: viewModel.incorrectCount,
                onRestart: {
                    self.viewModel = QuizViewModel(deck: deck, modelContext: modelContext)
                },
                onDone: { dismiss() }
            )
        } else if let question = viewModel.currentQuestion {
            VStack(spacing: 24) {
                ProgressView(value: viewModel.progress)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Text("What is the translation of")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Text(question.card.front)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                        SpeakerButton(
                            text: question.card.front,
                            language: deck.sourceLang,
                            font: .title2
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        Button {
                            viewModel.select(option)
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.body.weight(.medium))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if viewModel.hasAnswered {
                                    if viewModel.isCorrectOption(option) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if viewModel.selectedOption == option {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(optionBackground(option, viewModel: viewModel), in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.hasAnswered)
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    withAnimation {
                        viewModel.advance()
                    }
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(viewModel.hasAnswered ? 1 : 0)
            }
            .padding(.top, 8)
        }
    }

    private func optionBackground(_ option: String, viewModel: QuizViewModel) -> Color {
        guard viewModel.hasAnswered else {
            return Color(.secondarySystemGroupedBackground)
        }
        if viewModel.isCorrectOption(option) {
            return .green.opacity(0.18)
        }
        if viewModel.selectedOption == option {
            return .red.opacity(0.18)
        }
        return Color(.secondarySystemGroupedBackground)
    }
}
