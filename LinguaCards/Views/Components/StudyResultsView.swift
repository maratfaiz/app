import SwiftUI

/// Shared end-of-session summary shown by every study mode, with a
/// celebratory confetti burst and gradient score ring.
struct StudyResultsView: View {
    let correct: Int
    let incorrect: Int
    var onRestart: (() -> Void)?
    var onDone: () -> Void

    @State private var showConfetti = false
    @State private var appeared = false

    private var total: Int { correct + incorrect }
    private var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }

    private var headline: LocalizedStringKey {
        switch accuracy {
        case 0.9...: return "Outstanding!"
        case 0.7..<0.9: return "Great job!"
        case 0.5..<0.7: return "Keep going!"
        default: return "Practice makes perfect"
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    ProgressRing(value: accuracy, lineWidth: 14, showLabel: false)
                        .frame(width: 180, height: 180)
                    VStack(spacing: 2) {
                        Text(accuracy, format: .percent.precision(.fractionLength(0)))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("score")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

                Text(headline)
                    .font(.title.bold())

                HStack(spacing: 16) {
                    resultTile(count: correct, label: "Correct", color: Theme.success, systemImage: "checkmark.circle.fill")
                    resultTile(count: incorrect, label: "Incorrect", color: Theme.danger, systemImage: "xmark.circle.fill")
                }

                Spacer()

                VStack(spacing: 10) {
                    if let onRestart {
                        PrimaryButton(title: "Study again", systemImage: "arrow.clockwise") {
                            onRestart()
                        }
                    }
                    Button(action: onDone) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(24)

            if accuracy >= 0.7 {
                ConfettiView(isActive: showConfetti)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            showConfetti = true
            Haptics.success()
        }
    }

    private func resultTile(count: Int, label: LocalizedStringKey, color: Color, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)
            Text(count, format: .number)
                .font(.system(.title, design: .rounded).bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
    }
}
