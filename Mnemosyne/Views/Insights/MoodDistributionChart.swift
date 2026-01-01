import SwiftUI
import Charts

struct MoodDistributionChart: View {
    let distribution: [Int: Int]

    private var sortedDistribution: [(score: Int, count: Int)] {
        (-5...5).map { score in
            (score: score, count: distribution[score] ?? 0)
        }
    }

    private var totalEntries: Int {
        distribution.values.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            Text("Stemming verdeling")
                .font(.headline)

            if totalEntries == 0 {
                emptyState
            } else {
                chart
                legend
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nog geen data",
            systemImage: "chart.bar",
            description: Text("Log je stemming om de verdeling te zien")
        )
        .frame(height: 200)
    }

    private var chart: some View {
        Chart {
            ForEach(sortedDistribution, id: \.score) { item in
                BarMark(
                    x: .value("Score", item.score),
                    y: .value("Aantal", item.count)
                )
                .foregroundStyle(colorForScore(item.score))
                .cornerRadius(4)
            }
        }
        .chartXScale(domain: -6...6)
        .chartXAxis {
            AxisMarks(values: [-5, -2, 0, 2, 5]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 150)
    }

    private var legend: some View {
        HStack(spacing: Constants.Design.largeSpacing) {
            legendItem(color: .red, label: "Laag")
            legendItem(color: .orange, label: "Neutraal")
            legendItem(color: .green, label: "Hoog")
        }
        .font(.caption)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case -5...(-3): return .red
        case -2...(-1): return .orange
        case 0: return .yellow
        case 1...2: return .mint
        case 3...5: return .green
        default: return .gray
        }
    }
}

// MARK: - Weekday Chart

struct WeekdayMoodChart: View {
    let data: [CorrelationEngine.WeekdayMoodData]

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            Text("Stemming per dag")
                .font(.headline)

            if data.isEmpty || data.allSatisfy({ $0.entryCount == 0 }) {
                emptyState
            } else {
                chart
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nog geen data",
            systemImage: "calendar",
            description: Text("Log je stemming om patronen per dag te zien")
        )
        .frame(height: 150)
    }

    private var chart: some View {
        Chart {
            ForEach(data) { day in
                BarMark(
                    x: .value("Dag", day.shortWeekdayName),
                    y: .value("Stemming", day.averageMood)
                )
                .foregroundStyle(colorForMood(day.averageMood))
                .cornerRadius(4)
            }

            RuleMark(y: .value("Neutraal", 0))
                .foregroundStyle(.secondary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYScale(domain: -5...5)
        .chartYAxis {
            AxisMarks(values: [-5, 0, 5]) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 150)
    }

    private func colorForMood(_ mood: Double) -> Color {
        if mood > 2 { return .green }
        if mood > 0 { return .mint }
        if mood > -2 { return .orange }
        return .red
    }
}

// MARK: - Time of Day Chart

struct TimeOfDayMoodChart: View {
    let data: [CorrelationEngine.TimeOfDayMoodData]

    private var timeLabels: [String] {
        ["Ochtend", "Middag", "Avond", "Nacht"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            Text("Stemming per moment")
                .font(.headline)

            if data.isEmpty || data.allSatisfy({ $0.entryCount == 0 }) {
                emptyState
            } else {
                chart
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nog geen data",
            systemImage: "clock",
            description: Text("Log op verschillende momenten om patronen te zien")
        )
        .frame(height: 150)
    }

    private var chart: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                BarMark(
                    x: .value("Tijd", timeLabels[index]),
                    y: .value("Stemming", item.averageMood)
                )
                .foregroundStyle(colorForMood(item.averageMood))
                .cornerRadius(4)
                .annotation(position: .top) {
                    if item.entryCount > 0 {
                        Text("\(item.entryCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            RuleMark(y: .value("Neutraal", 0))
                .foregroundStyle(.secondary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYScale(domain: -5...5)
        .chartYAxis {
            AxisMarks(values: [-5, 0, 5]) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 150)
    }

    private func colorForMood(_ mood: Double) -> Color {
        if mood > 2 { return .green }
        if mood > 0 { return .mint }
        if mood > -2 { return .orange }
        return .red
    }
}

// MARK: - Statistics Card

struct MoodStatisticsCard: View {
    let stats: (average: Double, standardDeviation: Double, min: Double, max: Double)
    let entryCount: Int
    let trend: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            Text("Statistieken")
                .font(.headline)

            HStack(spacing: Constants.Design.largeSpacing) {
                statItem(
                    value: String(format: "%.1f", stats.average),
                    label: "Gemiddeld",
                    icon: "chart.bar.fill"
                )

                statItem(
                    value: "\(entryCount)",
                    label: "Entries",
                    icon: "list.bullet"
                )

                statItem(
                    value: trendText,
                    label: "Trend",
                    icon: trendIcon,
                    color: trendColor
                )
            }

            HStack(spacing: Constants.Design.largeSpacing) {
                statItem(
                    value: String(format: "%.1f", stats.min),
                    label: "Laagste",
                    icon: "arrow.down",
                    color: .red
                )

                statItem(
                    value: String(format: "%.1f", stats.max),
                    label: "Hoogste",
                    icon: "arrow.up",
                    color: .green
                )

                statItem(
                    value: String(format: "%.1f", stats.standardDeviation),
                    label: "Variatie",
                    icon: "waveform"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
    }

    private var trendText: String {
        if abs(trend) < 0.1 {
            return "Stabiel"
        } else if trend > 0 {
            return "↑"
        } else {
            return "↓"
        }
    }

    private var trendIcon: String {
        if abs(trend) < 0.1 {
            return "minus"
        } else if trend > 0 {
            return "arrow.up.right"
        } else {
            return "arrow.down.right"
        }
    }

    private var trendColor: Color {
        if abs(trend) < 0.1 {
            return .secondary
        } else if trend > 0 {
            return .green
        } else {
            return .red
        }
    }

    private func statItem(value: String, label: String, icon: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let sampleDistribution: [Int: Int] = [
        -5: 2, -4: 3, -3: 5, -2: 8, -1: 12,
        0: 15, 1: 18, 2: 14, 3: 10, 4: 6, 5: 3
    ]

    let sampleWeekdayData: [CorrelationEngine.WeekdayMoodData] = [
        .init(weekday: 2, averageMood: 1.5, entryCount: 10),
        .init(weekday: 3, averageMood: 0.8, entryCount: 12),
        .init(weekday: 4, averageMood: -0.5, entryCount: 8),
        .init(weekday: 5, averageMood: 0.2, entryCount: 11),
        .init(weekday: 6, averageMood: 2.1, entryCount: 9),
        .init(weekday: 7, averageMood: 2.8, entryCount: 7),
        .init(weekday: 1, averageMood: 1.2, entryCount: 6)
    ]

    return ScrollView {
        VStack(spacing: 24) {
            MoodDistributionChart(distribution: sampleDistribution)
                .padding()

            WeekdayMoodChart(data: sampleWeekdayData)
                .padding()

            MoodStatisticsCard(
                stats: (average: 1.2, standardDeviation: 2.1, min: -4.5, max: 4.8),
                entryCount: 96,
                trend: 0.15
            )
            .padding()
        }
    }
}
