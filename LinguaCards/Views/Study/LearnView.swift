import SwiftUI
import SwiftData

/// Quizlet-style Learn mode: adaptive questions that escalate from
/// multiple choice to written recall until every term is mastered.
struct LearnView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    var options: StudyOptions = .default

    @State private var viewModel: LearnViewModel?
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = LearnViewModel(deck: deck, options: options, modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: LearnViewModel) -> some View {
        if viewModel.isFinished {
            StudyResultsView(
                correct: viewModel.correctCount,
                incorrect: viewModel.incorrectCount,
                onRestart: {
                    self.viewModel = LearnViewModel(deck: deck, options: options, modelContext: modelContext)
                },
                onDone: { dismiss() }
            )
        } else {
            VStack(spacing: 20) {
                header(viewModel)

                Spacer()

                VStack(spacing: 12) {
                    Text(promptCaption(viewModel))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Text(viewModel.promptText)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                        SpeakerButton(text: viewModel.promptText, language: viewModel.promptLanguage, font: .title2)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                questionArea(viewModel)
            }
            .padding(.top, 8)
        }
    }

    private func header(_ viewModel: LearnViewModel) -> some View {
        VStack(spacing: 8) {
            GradientProgressBar(value: viewModel.progress)
            HStack {
                Label("\(viewModel.graduatedCount) mastered", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.success)
                Spacer()
                Label("\(viewModel.remainingCount) left", systemImage: "hourglass")
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 24)
    }

    private func promptCaption(_ viewModel: LearnViewModel) -> LocalizedStringKey {
        switch viewModel.questionType {
        case .multipleChoice: return "Choose the correct translation"
        case .written: return "Type the translation"
        }
    }

    @ViewBuilder
    private func questionArea(_ viewModel: LearnViewModel) -> some View {
        switch viewModel.questionType {
        case .multipleChoice(let opts):
            multipleChoice(viewModel, options: opts)
        case .written:
            written(viewModel)
        }
    }

    private func multipleChoice(_ viewModel: LearnViewModel, options opts: [String]) -> some View {
        VStack(spacing: 12) {
            ForEach(opts, id: \.self) { option in
                Button {
                    viewModel.submitMultipleChoice(option)
                } label: {
                    HStack {
                        Text(option).font(.body.weight(.medium))
                        Spacer()
                        if case .feedback = viewModel.phase {
                            if viewModel.isCorrectOption(option) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success)
                            } else if viewModel.selectedOption == option {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.danger)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(mcBackground(viewModel, option: option), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(mcBorder(viewModel, option: option), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.phase != .asking)
            }

            if case .feedback = viewModel.phase {
                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    withAnimation { viewModel.advance() }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func written(_ viewModel: LearnViewModel) -> some View {
        VStack(spacing: 14) {
            TextField("Your answer", text: Bindable(viewModel).writtenInput)
                .font(.title3)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($inputFocused)
                .submitLabel(.done)
                .onSubmit { viewModel.submitWritten() }
                .disabled(viewModel.phase != .asking)
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(writtenBorder(viewModel), lineWidth: 1.5)
                )

            if case .feedback(let correct) = viewModel.phase {
                HStack(spacing: 8) {
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(correct ? Theme.success : Theme.danger)
                    Text(viewModel.expectedAnswer).font(.headline)
                    SpeakerButton(text: viewModel.expectedAnswer, language: viewModel.answerLanguage)
                }
                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    viewModel.advance()
                    inputFocused = true
                }
            } else {
                PrimaryButton(title: "Check", systemImage: "checkmark") {
                    viewModel.submitWritten()
                }
                .disabled(viewModel.writtenInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .onAppear { inputFocused = true }
    }

    private func mcBackground(_ viewModel: LearnViewModel, option: String) -> Color {
        guard case .feedback = viewModel.phase else { return Color(.secondarySystemGroupedBackground) }
        if viewModel.isCorrectOption(option) { return Theme.success.opacity(0.15) }
        if viewModel.selectedOption == option { return Theme.danger.opacity(0.15) }
        return Color(.secondarySystemGroupedBackground)
    }

    private func mcBorder(_ viewModel: LearnViewModel, option: String) -> Color {
        guard case .feedback = viewModel.phase else { return .clear }
        if viewModel.isCorrectOption(option) { return Theme.success }
        if viewModel.selectedOption == option { return Theme.danger }
        return .clear
    }

    private func writtenBorder(_ viewModel: LearnViewModel) -> Color {
        switch viewModel.phase {
        case .asking: return .clear
        case .feedback(let correct): return correct ? Theme.success : Theme.danger
        }
    }
}
