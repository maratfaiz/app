import SwiftUI
import SwiftData

/// Multiple-choice quiz with four options per question.
struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    var options: StudyOptions = .default

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
                viewModel = QuizViewModel(deck: deck, options: options, modelContext: modelContext)
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
                    self.viewModel = QuizViewModel(deck: deck, options: options, modelContext: modelContext)
                },
                onDone: { dismiss() }
            )
        } else if let question = viewModel.currentQuestion {
            VStack(spacing: 24) {
                GradientProgressBar(value: viewModel.progress)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Text("What is the translation of")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Text(question.prompt)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                        SpeakerButton(text: question.prompt, language: viewModel.promptLanguage, font: .title2)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        Button {
                            viewModel.select(option)
                        } label: {
                            optionLabel(option, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.hasAnswered)
                    }
                }
                .padding(.horizontal, 24)

                PrimaryButton(title: "Next", systemImage: "arrow.right") {
                    withAnimation { viewModel.advance() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(viewModel.hasAnswered ? 1 : 0)
            }
            .padding(.top, 8)
        }
    }

    private func optionLabel(_ option: String, viewModel: QuizViewModel) -> some View {
        HStack {
            Text(option)
                .font(.body.weight(.medium))
                .multilineTextAlignment(.leading)
            Spacer()
            if viewModel.hasAnswered {
                if viewModel.isCorrectOption(option) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success)
                } else if viewModel.selectedOption == option {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.danger)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(optionBackground(option, viewModel: viewModel), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(optionBorder(option, viewModel: viewModel), lineWidth: 1.5)
        )
    }

    private func optionBackground(_ option: String, viewModel: QuizViewModel) -> Color {
        guard viewModel.hasAnswered else { return Color(.secondarySystemGroupedBackground) }
        if viewModel.isCorrectOption(option) { return Theme.success.opacity(0.15) }
        if viewModel.selectedOption == option { return Theme.danger.opacity(0.15) }
        return Color(.secondarySystemGroupedBackground)
    }

    private func optionBorder(_ option: String, viewModel: QuizViewModel) -> Color {
        guard viewModel.hasAnswered else { return .clear }
        if viewModel.isCorrectOption(option) { return Theme.success }
        if viewModel.selectedOption == option { return Theme.danger }
        return .clear
    }
}
