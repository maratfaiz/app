import SwiftUI
import SwiftData

/// Write mode: the prompt is shown, the user types the answer.
struct TypingTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    var options: StudyOptions = .default

    @State private var viewModel: TypingTestViewModel?
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
            .navigationTitle("Write")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TypingTestViewModel(deck: deck, options: options, modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: TypingTestViewModel) -> some View {
        if viewModel.isFinished {
            StudyResultsView(
                correct: viewModel.correctCount,
                incorrect: viewModel.incorrectCount,
                onRestart: {
                    self.viewModel = TypingTestViewModel(deck: deck, options: options, modelContext: modelContext)
                },
                onDone: { dismiss() }
            )
        } else if let card = viewModel.currentCard {
            VStack(spacing: 24) {
                GradientProgressBar(value: viewModel.progress)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Text("Type the translation of")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Text(viewModel.promptText)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                        SpeakerButton(text: viewModel.promptText, language: viewModel.promptLanguage, font: .title2)
                    }

                    if let example = card.example, !example.isEmpty {
                        Text(example)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)

                TextField("Your answer", text: Bindable(viewModel).input)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($inputFocused)
                    .submitLabel(.done)
                    .onSubmit { viewModel.submit() }
                    .disabled(viewModel.phase != .answering)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(fieldBorder(viewModel), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 24)

                feedback(viewModel)

                Spacer()

                controls(viewModel)
            }
            .padding(.top, 8)
            .onAppear { inputFocused = true }
        }
    }

    private func fieldBorder(_ viewModel: TypingTestViewModel) -> Color {
        switch viewModel.phase {
        case .answering: return .clear
        case .feedback(.correct): return Theme.success
        case .feedback(.almostCorrect): return Theme.warning
        case .feedback(.wrong): return Theme.danger
        }
    }

    @ViewBuilder
    private func feedback(_ viewModel: TypingTestViewModel) -> some View {
        switch viewModel.phase {
        case .answering:
            EmptyView()
        case .feedback(let verdict):
            VStack(spacing: 8) {
                switch verdict {
                case .correct:
                    Label("Correct!", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.success)
                case .almostCorrect:
                    Label("Almost! Watch the spelling.", systemImage: "checkmark.circle.badge.questionmark").foregroundStyle(Theme.warning)
                case .wrong:
                    Label("Incorrect", systemImage: "xmark.circle.fill").foregroundStyle(Theme.danger)
                }

                HStack(spacing: 8) {
                    Text(viewModel.expectedAnswer)
                        .font(.title3.weight(.semibold))
                    SpeakerButton(text: viewModel.expectedAnswer, language: viewModel.answerLanguage)
                }
            }
            .font(.headline)
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func controls(_ viewModel: TypingTestViewModel) -> some View {
        VStack(spacing: 10) {
            if viewModel.phase == .answering {
                PrimaryButton(title: "Check", systemImage: "checkmark") {
                    viewModel.submit()
                }
                .disabled(viewModel.input.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("I don't know") {
                    viewModel.reveal()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
                PrimaryButton(title: "Next", systemImage: "arrow.right") {
                    viewModel.advance()
                    inputFocused = true
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}
