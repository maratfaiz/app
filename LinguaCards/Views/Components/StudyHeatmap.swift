import SwiftUI

/// GitHub-contribution-style calendar of study activity — a glanceable map of
/// how consistently you've been studying. Something even Quizlet doesn't show.
struct StudyHeatmap: View {
    let cells: [StatsService.HeatCell]

    private var weeks: [[StatsService.HeatCell]] {
        stride(from: 0, to: cells.count, by: 7).map {
            Array(cells[$0..<min($0 + 7, cells.count)])
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Color.primary.opacity(0.06)
        case 1: return Theme.primary.opacity(0.35)
        case 2: return Theme.primary.opacity(0.55)
        case 3: return Theme.primary.opacity(0.8)
        default: return Theme.violet
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: 4) {
                            ForEach(week) { cell in
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(color(for: cell.level))
                                    .frame(width: 13, height: 13)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                Text("Less").font(.caption2).foregroundStyle(.secondary)
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color(for: level))
                        .frame(width: 11, height: 11)
                }
                Text("More").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
