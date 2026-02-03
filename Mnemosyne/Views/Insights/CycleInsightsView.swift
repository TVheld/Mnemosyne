import SwiftUI
import Charts

struct CycleInsightsView: View {
    let data: [CorrelationEngine.CycleDayMoodData]
    let cycleLength: Int
    let stopWeekStart: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            Text("Stemming per cyclusdag")
                .font(.headline)

            if data.isEmpty || data.allSatisfy({ $0.entryCount == 0 }) {
                emptyState
            } else {
                chart
                cycleLegend
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nog geen cyclusdata",
            systemImage: "calendar.circle",
            description: Text("Configureer je cyclus en log je stemming om patronen te zien")
        )
        .frame(height: 200)
    }

    private var chart: some View {
        CycleChart(
            data: data,
            cycleLength: cycleLength,
            stopWeekStart: stopWeekStart
        )
    }

    private var cycleLegend: some View {
        HStack(spacing: Constants.Design.largeSpacing) {
            legendItem(color: .blue, label: "Pilweek")
            legendItem(color: .pink, label: "Stopweek")
        }
        .font(.caption)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

// Separate struct to help compiler with type checking
private struct CycleChart: View {
    let data: [CorrelationEngine.CycleDayMoodData]
    let cycleLength: Int
    let stopWeekStart: Int

    private var stopWeekStartDouble: Double {
        Double(stopWeekStart) - 0.5
    }

    private var cycleLengthDouble: Double {
        Double(cycleLength) + 0.5
    }

    var body: some View {
        chartContent
            .chartXScale(domain: 0.5...cycleLengthDouble)
            .chartYScale(domain: -5.0...5.0)
            .chartXAxis {
                AxisMarks(values: xAxisValues) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: [-5, 0, 5]) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 180)
    }

    private var chartContent: some View {
        Chart {
            // Background
            RectangleMark(
                xStart: .value("Start", stopWeekStartDouble),
                xEnd: .value("End", cycleLengthDouble),
                yStart: .value("Min", -5.0),
                yEnd: .value("Max", 5.0)
            )
            .foregroundStyle(Color.pink.opacity(0.1))

            // Bars
            ForEach(data) { day in
                BarMark(
                    x: .value("Dag", day.cycleDay),
                    y: .value("Stemming", day.averageMood)
                )
                .foregroundStyle(day.isStopWeek ? Color.pink : Color.blue)
                .cornerRadius(2)
            }

            // Neutral line
            RuleMark(y: .value("Neutraal", 0.0))
                .foregroundStyle(Color.secondary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

            // Stop week marker
            RuleMark(x: .value("Stopweek", stopWeekStartDouble))
                .foregroundStyle(Color.pink.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }

    private var xAxisValues: [Int] {
        Array(stride(from: 1, through: cycleLength, by: 7))
    }
}

// MARK: - Cycle Phase Analysis

struct CyclePhaseAnalysis: View {
    let data: [CorrelationEngine.CycleDayMoodData]
    let stopWeekStart: Int

    private var pillWeekData: [CorrelationEngine.CycleDayMoodData] {
        data.filter { !$0.isStopWeek && $0.entryCount > 0 }
    }

    private var stopWeekData: [CorrelationEngine.CycleDayMoodData] {
        data.filter { $0.isStopWeek && $0.entryCount > 0 }
    }

    private var pillWeekAverage: Double {
        guard !pillWeekData.isEmpty else { return 0 }
        let total = pillWeekData.reduce(0.0) { $0 + $1.averageMood * Double($1.entryCount) }
        let count = pillWeekData.reduce(0) { $0 + $1.entryCount }
        return count > 0 ? total / Double(count) : 0
    }

    private var stopWeekAverage: Double {
        guard !stopWeekData.isEmpty else { return 0 }
        let total = stopWeekData.reduce(0.0) { $0 + $1.averageMood * Double($1.entryCount) }
        let count = stopWeekData.reduce(0) { $0 + $1.entryCount }
        return count > 0 ? total / Double(count) : 0
    }

    private var difference: Double {
        stopWeekAverage - pillWeekAverage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            Text("Cyclus analyse")
                .font(.headline)

            if pillWeekData.isEmpty && stopWeekData.isEmpty {
                Text("Log meer stemming entries om je cycluspatroon te ontdekken")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: Constants.Design.largeSpacing) {
                    phaseCard(
                        title: "Pilweek",
                        average: pillWeekAverage,
                        color: .blue,
                        icon: "pills.fill"
                    )

                    phaseCard(
                        title: "Stopweek",
                        average: stopWeekAverage,
                        color: .pink,
                        icon: "drop.fill"
                    )
                }

                // Difference insight
                if abs(difference) > 0.5 {
                    differenceInsight
                }
            }
        }
    }

    private func phaseCard(title: String, average: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(String(format: "%.1f", average))
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
    }

    private var differenceInsight: some View {
        HStack(spacing: Constants.Design.smallSpacing) {
            Image(systemName: difference < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(difference < 0 ? .red : .green)

            Text(insightText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
    }

    private var insightText: String {
        let absChange = abs(difference)
        if difference < 0 {
            return "Je stemming is gemiddeld \(String(format: "%.1f", absChange)) punten lager tijdens de stopweek"
        } else {
            return "Je stemming is gemiddeld \(String(format: "%.1f", absChange)) punten hoger tijdens de stopweek"
        }
    }
}

// MARK: - PMS Pattern Detection

struct PMSPatternView: View {
    let data: [CorrelationEngine.CycleDayMoodData]
    let stopWeekStart: Int

    private var prePMSDays: [CorrelationEngine.CycleDayMoodData] {
        // PMS periode voor stopweek
        let pmsStartDay = max(1, stopWeekStart - Constants.Cycle.pmsDaysBeforeStopWeek)
        let pmsEndDay = stopWeekStart - 1
        return data.filter { $0.cycleDay >= pmsStartDay && $0.cycleDay <= pmsEndDay && $0.entryCount > 0 }
    }

    private var normalDays: [CorrelationEngine.CycleDayMoodData] {
        // Dagen 5-15 (midden van cyclus, typisch stabiele periode)
        return data.filter { $0.cycleDay >= 5 && $0.cycleDay <= 15 && $0.entryCount > 0 }
    }

    private var pmsMoodDrop: Double {
        guard !prePMSDays.isEmpty && !normalDays.isEmpty else { return 0 }

        let pmsTotal = prePMSDays.reduce(0.0) { $0 + $1.averageMood * Double($1.entryCount) }
        let pmsCount = prePMSDays.reduce(0) { $0 + $1.entryCount }
        let pmsAvg = pmsCount > 0 ? pmsTotal / Double(pmsCount) : 0

        let normalTotal = normalDays.reduce(0.0) { $0 + $1.averageMood * Double($1.entryCount) }
        let normalCount = normalDays.reduce(0) { $0 + $1.entryCount }
        let normalAvg = normalCount > 0 ? normalTotal / Double(normalCount) : 0

        return pmsAvg - normalAvg
    }

    private var hasPMSPattern: Bool {
        pmsMoodDrop < -0.5
    }

    var body: some View {
        if hasPMSPattern {
            HStack(spacing: Constants.Design.smallSpacing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PMS patroon gedetecteerd")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Je stemming daalt gemiddeld \(String(format: "%.1f", abs(pmsMoodDrop))) punten in de dagen voor je stopweek")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
        }
    }
}

#Preview {
    let sampleData: [CorrelationEngine.CycleDayMoodData] = (1...28).map { day in
        let isStopWeek = day >= 22
        let baseMood: Double
        if isStopWeek {
            baseMood = -1.0
        } else if day >= 17 {
            baseMood = -0.5 // PMS days
        } else {
            baseMood = 1.5
        }

        return CorrelationEngine.CycleDayMoodData(
            cycleDay: day,
            averageMood: baseMood + Double.random(in: -1...1),
            entryCount: Int.random(in: 2...5),
            isStopWeek: isStopWeek
        )
    }

    return ScrollView {
        VStack(spacing: 24) {
            CycleInsightsView(data: sampleData, cycleLength: 28, stopWeekStart: 22)
                .padding()

            CyclePhaseAnalysis(data: sampleData, stopWeekStart: 22)
                .padding()

            PMSPatternView(data: sampleData, stopWeekStart: 22)
                .padding()
        }
    }
}
