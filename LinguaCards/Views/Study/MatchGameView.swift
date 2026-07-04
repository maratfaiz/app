import SwiftUI
import SwiftData

/// Match game: tap pairs of terms and translations, against the clock.
struct MatchGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

    @State private var viewModel: MatchGameViewModel?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Match game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MatchGameViewModel(deck: deck, modelContext: modelContext)
            }
        }
        .onChange(of: viewModel?.mismatchedTileIDs.isEmpty) { _, isEmpty in
            guard isEmpty == false else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                viewModel?.clearMismatch()
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: MatchGameViewModel) -> some View {
        if viewModel.isFinished {
            finishedView(viewModel)
        } else {
            VStack(spacing: 16) {
                header(viewModel)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.tiles) { tile in
                        tileView(tile, viewModel: viewModel)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private func header(_ viewModel: MatchGameViewModel) -> some View {
        HStack {
            Label("\(viewModel.matchedPairs) / \(viewModel.totalPairs)", systemImage: "square.grid.2x2")
                .font(.subheadline.weight(.semibold))

            Spacer()

            TimelineView(.periodic(from: viewModel.startedAt, by: 1)) { context in
                Label(
                    Duration.seconds(viewModel.elapsed(now: context.date))
                        .formatted(.time(pattern: .minuteSecond)),
                    systemImage: "stopwatch"
                )
                .font(.subheadline.weight(.semibold).monospacedDigit())
            }

            Spacer()

            Label("\(viewModel.mistakes)", systemImage: "xmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 20)
    }

    private func tileView(_ tile: MatchGameViewModel.Tile, viewModel: MatchGameViewModel) -> some View {
        let isSelected = viewModel.selectedTileID == tile.id
        let isMismatched = viewModel.mismatchedTileIDs.contains(tile.id)

        return Button {
            viewModel.tap(tile)
        } label: {
            Text(tile.text)
                .font(.callout.weight(.medium))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(8)
                .frame(maxWidth: .infinity, minHeight: 84)
                .background(tileBackground(isSelected: isSelected, isMismatched: isMismatched), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
                            lineWidth: isSelected ? 2 : 1
                        )
                }
        }
        .buttonStyle(.plain)
        .opacity(tile.isMatched ? 0 : 1)
        .scaleEffect(tile.isMatched ? 0.6 : 1)
        .animation(.spring(duration: 0.35), value: tile.isMatched)
        .disabled(tile.isMatched)
    }

    private func tileBackground(isSelected: Bool, isMismatched: Bool) -> Color {
        if isMismatched { return .red.opacity(0.2) }
        if isSelected { return .accentColor.opacity(0.15) }
        return Color(.secondarySystemGroupedBackground)
    }

    private func finishedView(_ viewModel: MatchGameViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)

            Text("All matched!")
                .font(.title.bold())

            VStack(spacing: 8) {
                Label(
                    Duration.seconds(viewModel.elapsed())
                        .formatted(.time(pattern: .minuteSecond)),
                    systemImage: "stopwatch"
                )
                .font(.title2.weight(.semibold).monospacedDigit())

                Text("Mistakes: \(viewModel.mistakes)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation {
                    viewModel.startNewRound()
                }
            } label: {
                Text("Play again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(24)
        .onAppear {
            Haptics.success()
        }
    }
}
