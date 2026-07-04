import SwiftUI

/// Segmented bar showing how a deck's cards split across mastery levels,
/// in the spirit of Quizlet's "Still learning / Mastered" progress.
struct MasteryBar: View {
    let breakdown: [MasteryLevel: Int]
    var height: CGFloat = 12
    var showLegend: Bool = true

    private var total: Int {
        MasteryLevel.allCases.reduce(0) { $0 + (breakdown[$1] ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(MasteryLevel.allCases, id: \.self) { level in
                        let count = breakdown[level] ?? 0
                        if count > 0 {
                            Capsule()
                                .fill(level == .new ? Color.primary.opacity(0.12) : level.color)
                                .frame(width: max(0, geo.size.width * fraction(count)))
                        }
                    }
                }
            }
            .frame(height: height)

            if showLegend {
                HStack(spacing: 16) {
                    ForEach(MasteryLevel.allCases, id: \.self) { level in
                        let count = breakdown[level] ?? 0
                        HStack(spacing: 5) {
                            Circle()
                                .fill(level == .new ? Color.secondary.opacity(0.4) : level.color)
                                .frame(width: 8, height: 8)
                            Text(level.title)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(count)")
                                .font(.caption2.weight(.bold))
                        }
                    }
                }
            }
        }
    }

    private func fraction(_ count: Int) -> Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
}
