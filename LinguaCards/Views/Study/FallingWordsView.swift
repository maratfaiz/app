import SwiftUI
import SwiftData

/// Falling Words arcade: a term drops from the top and you must tap its
/// translation before it lands. Miss it — or tap wrong — and you lose a life.
struct FallingWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    var options: StudyOptions = .default

    @State private var viewModel: FallingWordsViewModel?
    @State private var fall: Double = 0
    @State private var flash: FlashKind?

    private enum FlashKind { case correct, wrong }

    private let tick = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Falling Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = FallingWordsViewModel(deck: deck, options: options, modelContext: modelContext)
            }
        }
        .onReceive(tick) { _ in step() }
    }

    private func step() {
        guard let viewModel, !viewModel.isOver, viewModel.current != nil else { return }
        fall += 0.02 / viewModel.fallDuration
        if fall >= 1 {
            viewModel.timeout()
            fall = 0
        }
    }

    @ViewBuilder
    private func content(_ viewModel: FallingWordsViewModel) -> some View {
        if viewModel.isOver {
            gameOver(viewModel)
        } else {
            VStack(spacing: 16) {
                hud(viewModel)
                fallField(viewModel)
                answers(viewModel)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            .auroraBackground()
        }
    }

    private func hud(_ viewModel: FallingWordsViewModel) -> some View {
        HStack {
            Label("\(viewModel.score)", systemImage: "star.fill")
                .foregroundStyle(Theme.warning)
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<viewModel.startingLives, id: \.self) { i in
                    Image(systemName: i < viewModel.lives ? "heart.fill" : "heart")
                        .foregroundStyle(Theme.danger)
                }
            }
            Spacer()
            Label("\(viewModel.streak)", systemImage: "bolt.fill")
                .foregroundStyle(Theme.primary)
        }
        .font(.headline)
        .padding(.horizontal, 24)
    }

    private func fallField(_ viewModel: FallingWordsViewModel) -> some View {
        GeometryReader { geo in
            let tileHeight: CGFloat = 76
            if let item = viewModel.current {
                fallingTile(item)
                    .frame(width: geo.size.width - 48, height: tileHeight)
                    .position(
                        x: geo.size.width / 2,
                        y: tileHeight / 2 + fall * (geo.size.height - tileHeight)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }

    private func fallingTile(_ item: FallingItem) -> some View {
        HStack(spacing: 10) {
            Text(item.prompt)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            SpeakerButton(text: item.prompt, language: deck.promptLanguage(for: options.direction), font: .title3)
                .tint(.white)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .background(Theme.gradient(atIndex: deck.colorIndex), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(flashColor, lineWidth: flash == nil ? 0 : 3)
        )
        .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
    }

    private var flashColor: Color {
        switch flash {
        case .correct: return Theme.success
        case .wrong: return Theme.danger
        case nil: return .clear
        }
    }

    private func answers(_ viewModel: FallingWordsViewModel) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.current?.options ?? [], id: \.self) { option in
                Button {
                    tapAnswer(option, viewModel: viewModel)
                } label: {
                    Text(option)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }

    private func tapAnswer(_ option: String, viewModel: FallingWordsViewModel) {
        let correct = viewModel.answer(option)
        flash = correct ? .correct : .wrong
        fall = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            flash = nil
        }
    }

    private func gameOver(_ viewModel: FallingWordsViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.primary)
            Text("Game over")
                .font(.system(.largeTitle, design: .rounded).bold())

            VStack(spacing: 6) {
                Text("\(viewModel.score)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primary)
                Text("points")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 28) {
                stat("\(viewModel.bestStreak)", "Best streak", "bolt.fill", Theme.primary)
                stat("\(viewModel.engine.correctCount)", "Correct", "checkmark.circle.fill", Theme.success)
                stat("\(viewModel.engine.missedCount)", "Missed", "xmark.circle.fill", Theme.danger)
            }

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "Play again", systemImage: "arrow.clockwise") {
                    viewModel.restart()
                    fall = 0
                }
                Button("Done") { dismiss() }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .auroraBackground()
        .onAppear { Haptics.success() }
    }

    private func stat(_ value: String, _ label: LocalizedStringKey, _ image: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: image).foregroundStyle(color)
            Text(value).font(.system(.title3, design: .rounded).bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
