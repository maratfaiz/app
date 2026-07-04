import SwiftUI
import SwiftData
import Charts

/// Global statistics: streak, 14-day activity chart and per-deck mastery.
struct StatsView: View {
    @Query private var sessions: [StudySession]
    @Query(sort: \Deck.title) private var decks: [Deck]

    private var streak: Int {
        StatsService.streak(sessionDates: sessions.map(\.date))
    }

    private var activity: [StatsService.DailyActivity] {
        StatsService.dailyActivity(sessions: sessions)
    }

    private var totalAnswers: Int {
        sessions.reduce(0) { $0 + $1.total }
    }

    private var overallBreakdown: [MasteryLevel: Int] {
        var counts: [MasteryLevel: Int] = [.new: 0, .learning: 0, .mastered: 0]
        for deck in decks {
            for (level, count) in deck.masteryBreakdown() {
                counts[level, default: 0] += count
            }
        }
        return counts
    }

    private var hasCards: Bool {
        decks.contains { !$0.cards.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty && decks.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar.xaxis",
                        title: "No stats yet",
                        message: "Study a deck and your progress will show up here."
                    )
                } else {
                    List {
                        overviewSection
                        if hasCards {
                            masterySection
                        }
                        heatmapSection
                        activitySection
                        decksSection
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .auroraBackground()
            .navigationTitle("Stats")
        }
    }

    private var overviewSection: some View {
        Section {
            HStack(spacing: 12) {
                overviewTile(
                    value: "\(streak)",
                    label: "Day streak",
                    systemImage: "flame.fill",
                    color: .orange
                )
                overviewTile(
                    value: "\(totalAnswers)",
                    label: "Answers",
                    systemImage: "square.stack.3d.up.fill",
                    color: .blue
                )
                overviewTile(
                    value: "\(sessions.count)",
                    label: "Sessions",
                    systemImage: "calendar",
                    color: .green
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
            .listRowBackground(Color.clear)
        }
    }

    private var masterySection: some View {
        Section("Overall progress") {
            MasteryBar(breakdown: overallBreakdown)
                .padding(.vertical, 10)
        }
    }

    private var heatmapSection: some View {
        Section("Study activity") {
            StudyHeatmap(cells: StatsService.studyHeatmap(sessions: sessions))
                .padding(.vertical, 8)
        }
    }

    private var activitySection: some View {
        Section("Last 14 days") {
            Chart(activity) { day in
                BarMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Correct", day.correct)
                )
                .foregroundStyle(by: .value("Result", "Correct"))

                BarMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Incorrect", day.incorrect)
                )
                .foregroundStyle(by: .value("Result", "Incorrect"))
            }
            .chartForegroundStyleScale([
                "Correct": Color.green,
                "Incorrect": Color.red.opacity(0.7),
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 200)
            .padding(.vertical, 8)
        }
    }

    private var decksSection: some View {
        Section("Mastery by deck") {
            if decks.isEmpty {
                Text("No decks yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(decks) { deck in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(deck.title)
                                .font(.body.weight(.medium))
                            Spacer()
                            Text(deck.masteredFraction, format: .percent.precision(.fractionLength(0)))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: deck.masteredFraction)
                            .tint(deck.masteredFraction >= 0.8 ? .green : .accentColor)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func overviewTile(
        value: String,
        label: LocalizedStringKey,
        systemImage: String,
        color: Color
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
