import SwiftUI
import SwiftData

/// Quizlet-style Test mode: answer a mixed set of questions, then get graded.
struct TestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    var options: StudyOptions = .default

    @State private var viewModel: TestViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TestViewModel(deck: deck, options: options, modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: TestViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isSubmitted {
                    scoreHeader(viewModel)
                }
                ForEach(Array(viewModel.questions.enumerated()), id: \.element.id) { index, question in
                    TestQuestionRow(
                        question: question,
                        index: index + 1,
                        isSubmitted: viewModel.isSubmitted
                    )
                }

                if viewModel.isSubmitted {
                    PrimaryButton(title: "Done", systemImage: "checkmark") {
                        dismiss()
                    }
                    .padding(.top, 8)
                } else {
                    PrimaryButton(title: "Submit test", systemImage: "paperplane.fill") {
                        withAnimation { viewModel.submit() }
                    }
                    .disabled(!viewModel.allAnswered)
                    .opacity(viewModel.allAnswered ? 1 : 0.5)

                    Text("\(viewModel.answeredCount) of \(viewModel.questions.count) answered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func scoreHeader(_ viewModel: TestViewModel) -> some View {
        VStack(spacing: 12) {
            ZStack {
                ProgressRing(value: viewModel.score, lineWidth: 12, showLabel: false)
                    .frame(width: 120, height: 120)
                VStack(spacing: 0) {
                    Text(viewModel.score, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("\(viewModel.correctCount)/\(viewModel.questions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(viewModel.score >= 0.8 ? "Great work!" : "Review the misses below")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardSurface()
    }
}

/// One question in a test: renders the right input for its kind and, once
/// submitted, shows whether the answer was correct.
private struct TestQuestionRow: View {
    @Bindable var question: TestViewModel.Question
    let index: Int
    let isSubmitted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Question \(index)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if isSubmitted {
                    Image(systemName: question.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(question.isCorrect ? Theme.success : Theme.danger)
                }
            }

            HStack(spacing: 10) {
                Text(question.prompt)
                    .font(.title3.bold())
                SpeakerButton(text: question.prompt, language: question.promptLanguage)
            }

            switch question.kind {
            case .written:
                writtenInput
            case .multipleChoice(let opts):
                multipleChoice(opts)
            case .trueFalse(let shown, _):
                trueFalse(shown: shown)
            }

            if isSubmitted && !question.isCorrect {
                Text("Answer: \(question.expected)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.success)
            }
        }
        .cardSurface()
    }

    private var writtenInput: some View {
        TextField("Type your answer", text: $question.writtenAnswer)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .disabled(isSubmitted)
    }

    private func multipleChoice(_ opts: [String]) -> some View {
        VStack(spacing: 8) {
            ForEach(opts, id: \.self) { option in
                Button {
                    question.selectedOption = option
                } label: {
                    HStack {
                        Image(systemName: question.selectedOption == option ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(question.selectedOption == option ? Theme.primary : .secondary)
                        Text(option).font(.subheadline)
                        Spacer()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(mcBackground(option), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSubmitted)
            }
        }
    }

    private func trueFalse(shown: String) -> some View {
        VStack(spacing: 8) {
            Text(shown)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.primary)
            HStack(spacing: 12) {
                tfButton(label: "True", value: true)
                tfButton(label: "False", value: false)
            }
        }
    }

    private func tfButton(label: LocalizedStringKey, value: Bool) -> some View {
        Button {
            question.trueFalseAnswer = value
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(tfBackground(value), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(question.trueFalseAnswer == value ? .white : .primary)
        }
        .buttonStyle(.plain)
        .disabled(isSubmitted)
    }

    private func mcBackground(_ option: String) -> Color {
        if isSubmitted {
            if option == question.expected { return Theme.success.opacity(0.15) }
            if question.selectedOption == option { return Theme.danger.opacity(0.15) }
        } else if question.selectedOption == option {
            return Theme.primary.opacity(0.12)
        }
        return Color(.tertiarySystemGroupedBackground)
    }

    private func tfBackground(_ value: Bool) -> Color {
        question.trueFalseAnswer == value ? Theme.primary : Color(.tertiarySystemGroupedBackground)
    }
}
