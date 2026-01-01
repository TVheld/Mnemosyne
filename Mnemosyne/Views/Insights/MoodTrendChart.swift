import SwiftUI
import Charts

struct MoodTrendChart: View {
    let data: [CorrelationEngine.DayMoodData]
    let showLabels: Bool

    init(data: [CorrelationEngine.DayMoodData], showLabels: Bool = true) {
        self.data = data
        self.showLabels = showLabels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.smallSpacing) {
            if showLabels {
                Text("Stemming verloop")
                    .font(.headline)
            }

            if data.isEmpty {
                emptyState
            } else {
                chart
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nog geen data",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("Log je stemming om trends te zien")
        )
        .frame(height: 200)
    }

    private var chart: some View {
        Chart {
            ForEach(data) { point in
                // Area gradient onder de lijn
                AreaMark(
                    x: .value("Datum", point.date),
                    y: .value("Stemming", point.averageMood)
                )
                .foregroundStyle(areaGradient)
                .interpolationMethod(.catmullRom)

                // Lijn
                LineMark(
                    x: .value("Datum", point.date),
                    y: .value("Stemming", point.averageMood)
                )
                .foregroundStyle(lineColor(for: point.averageMood))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                // Punten
                PointMark(
                    x: .value("Datum", point.date),
                    y: .value("Stemming", point.averageMood)
                )
                .foregroundStyle(lineColor(for: point.averageMood))
                .symbolSize(point.entryCount > 1 ? 40 : 25)
            }

            // Neutrale lijn
            RuleMark(y: .value("Neutraal", 0))
                .foregroundStyle(.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYScale(domain: -5...5)
        .chartYAxis {
            AxisMarks(values: [-5, -2.5, 0, 2.5, 5]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let score = value.as(Double.self) {
                        Text(moodLabel(for: score))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
            }
        }
        .frame(height: 200)
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.pink.opacity(0.3),
                Color.pink.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func lineColor(for score: Double) -> Color {
        if score > 2 {
            return .green
        } else if score > 0 {
            return .mint
        } else if score > -2 {
            return .orange
        } else {
            return .red
        }
    }

    private func moodLabel(for score: Double) -> String {
        switch score {
        case 5: return "😊"
        case 2.5: return "🙂"
        case 0: return "😐"
        case -2.5: return "😕"
        case -5: return "😢"
        default: return ""
        }
    }
}

// MARK: - Compact Version

struct MoodTrendChartCompact: View {
    let data: [CorrelationEngine.DayMoodData]

    var body: some View {
        if data.isEmpty {
            Text("Nog geen data")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(height: 60)
        } else {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value("Stemming", point.averageMood)
                    )
                    .foregroundStyle(.pink)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: -5...5)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
    }
}

#Preview {
    let sampleData: [CorrelationEngine.DayMoodData] = {
        let calendar = Calendar.current
        return (0..<14).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                return nil
            }
            return CorrelationEngine.DayMoodData(
                date: date,
                averageMood: Double.random(in: -3...4),
                entryCount: Int.random(in: 1...3),
                tags: []
            )
        }.reversed()
    }()

    return VStack {
        MoodTrendChart(data: Array(sampleData))
            .padding()

        MoodTrendChartCompact(data: Array(sampleData))
            .padding()
    }
}
