import SwiftUI

/// Shared end-of-session summary shown by every study mode.
struct StudyResultsView: View {
    let correct: Int
    let incorrect: Int
    var onRestart: (() -> Void)?
    var onDone: () -> Void

    private var total: Int { correct + incorrect }

    private var accuracy: Double {
        total > 0 ? Double(correct) / Double(total) : 0
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: accuracy >= 0.8 ? "trophy.fill" : "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Session complete!")
                .font(.title.bold())

            Text(accuracy, format: .percent.precision(.fractionLength(0)))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .contentTransition(.numericText())

            HStack(spacing: 32) {
                VStack {
                    Text(correct, format: .number)
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                    Text("Correct")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text(incorrect, format: .number)
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                    Text("Incorrect")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let onRestart {
                Button(action: onRestart) {
                    Text("Study again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Button(action: onDone) {
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
