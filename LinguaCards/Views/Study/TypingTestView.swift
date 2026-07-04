import SwiftUI
import SwiftData

/// Typing test: the term is shown, the user types the translation.
struct TypingTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

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
            .navigationTitle("Typing test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TypingTestViewModel(deck: deck, modelContext: modelContext)
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
                    self.viewModel = TypingTestViewModel(deck: deck, modelContext: modelContext)
                },
                onDone: { dismiss() }
            )
        } else if let card = viewModel.currentCard {
            VStack(spacing: 24) {
                ProgressView(value: viewModel.progress)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Text("Type the translation of")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Text(card.front)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                        SpeakerButton(text: card.front, language: deck.sourceLang, font: .title2)
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
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($inputFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        viewModel.submit()
                    }
                    .disabled(viewModel.phase != .answering)
                    .padding(.horizontal, 24)

                feedback(viewModel, card: card)

                Spacer()

                controls(viewModel)
            }
            .padding(.top, 8)
            .onAppear { inputFocused = true }
        }
    }

    @ViewBuilder
    private func feedback(_ viewModel: TypingTestViewModel, card: Card) -> some View {
        switch viewModel.phase {
        case .answering:
            EmptyView()
        case .feedback(let verdict):
            VStack(spacing: 8) {
                switch verdict {
                case .correct:
                    Label("Correct!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                case .almostCorrect:
                    Label("Almost! Watch the spelling.", systemImage: "checkmark.circle.badge.questionmark")
                        .foregroundStyle(.orange)
                        .font(.headline)
                case .wrong:
                    Label("Incorrect", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.headline)
                }

                HStack(spacing: 8) {
                    Text(card.back)
                        .font(.title3.weight(.semibold))
                    SpeakerButton(text: card.back, language: deck.targetLang)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func controls(_ viewModel: TypingTestViewModel) -> some View {
        VStack(spacing: 10) {
            if viewModel.phase == .answering {
                Button {
                    viewModel.submit()
                } label: {
                    Text("Check")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.input.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    viewModel.reveal()
                } label: {
                    Text("I don't know")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                Button {
                    viewModel.advance()
                    inputFocused = true
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}
