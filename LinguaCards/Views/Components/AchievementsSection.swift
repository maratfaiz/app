import SwiftUI

extension AchievementKind {
    /// Badge gradient colors, unique per achievement.
    var colors: [Color] {
        switch self {
        case .firstDeck: return [Color(hex: 0x5468FF), Color(hex: 0x8B5CF6)]
        case .deckCollector: return [Color(hex: 0x06B6D4), Color(hex: 0x3B82F6)]
        case .wordWizard: return [Color(hex: 0x8B5CF6), Color(hex: 0xEC4899)]
        case .memoryMaster: return [Color(hex: 0x6366F1), Color(hex: 0x0EA5E9)]
        case .onFire: return [Color(hex: 0xF59E0B), Color(hex: 0xEF4444)]
        case .unstoppable: return [Color(hex: 0xF97316), Color(hex: 0xEC4899)]
        case .quizWhiz: return [Color(hex: 0x10B981), Color(hex: 0x22D3EE)]
        case .communityStar: return [Color(hex: 0xF59E0B), Color(hex: 0xF97316)]
        case .generous: return [Color(hex: 0xEC4899), Color(hex: 0x8B5CF6)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Profile section showing achievement badges in a grid, unlocked ones lit up.
struct AchievementsSection: View {
    let stats: LearnerStats

    private var statuses: [AchievementStatus] {
        AchievementsEngine.evaluate(stats)
    }

    private var unlockedCount: Int {
        AchievementsEngine.unlockedCount(stats)
    }

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                Spacer()
                Text("\(unlockedCount)/\(AchievementKind.allCases.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(statuses) { status in
                    AchievementBadge(status: status)
                }
            }
        }
    }
}

/// One badge: a gradient medal when unlocked, or a greyed disc with a
/// progress ring when still locked.
struct AchievementBadge: View {
    let status: AchievementStatus

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if status.unlocked {
                    Circle()
                        .fill(status.kind.gradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: (status.kind.colors.first ?? .clear).opacity(0.4), radius: 8, y: 4)
                    Image(systemName: status.kind.systemImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: status.progress)
                        .stroke(status.kind.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                    Image(systemName: status.kind.systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(status.kind.title)
                .font(.caption2.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(status.unlocked ? .primary : .secondary)
                .lineLimit(2)
                .frame(height: 28, alignment: .top)
        }
        .frame(maxWidth: .infinity)
    }
}
