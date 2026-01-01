import SwiftUI
import Charts

struct TagCorrelationView: View {
    let correlations: [CorrelationEngine.TagCorrelation]
    let maxItems: Int

    init(correlations: [CorrelationEngine.TagCorrelation], maxItems: Int = 10) {
        self.correlations = correlations
        self.maxItems = maxItems
    }

    private var displayedCorrelations: [CorrelationEngine.TagCorrelation] {
        Array(correlations.prefix(maxItems))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            Text("Tag correlaties")
                .font(.headline)

            if correlations.isEmpty {
                emptyState
            } else {
                correlationList
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nog geen correlaties",
            systemImage: "tag",
            description: Text("Voeg tags toe aan je mood entries om patronen te ontdekken")
        )
        .frame(height: 200)
    }

    private var correlationList: some View {
        VStack(spacing: Constants.Design.smallSpacing) {
            ForEach(displayedCorrelations) { correlation in
                TagCorrelationRow(correlation: correlation)
            }
        }
    }
}

// MARK: - Tag Correlation Row

struct TagCorrelationRow: View {
    let correlation: CorrelationEngine.TagCorrelation

    private var barColor: Color {
        if correlation.correlation > 0.3 {
            return .green
        } else if correlation.correlation > 0 {
            return .mint
        } else if correlation.correlation > -0.3 {
            return .orange
        } else {
            return .red
        }
    }

    private var correlationText: String {
        let percentage = abs(correlation.correlation * 100)
        let direction = correlation.isPositiveCorrelation ? "+" : "-"
        return "\(direction)\(Int(percentage))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(correlation.tag)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(correlation.occurrences)x")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(correlationText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(barColor)
                    .frame(width: 50, alignment: .trailing)
            }

            // Correlation bar
            GeometryReader { geometry in
                ZStack(alignment: correlation.isPositiveCorrelation ? .leading : .trailing) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    // Center line
                    Rectangle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    // Correlation bar
                    let barWidth = abs(correlation.correlation) * (geometry.size.width / 2)
                    let xOffset = correlation.isPositiveCorrelation
                        ? geometry.size.width / 2
                        : geometry.size.width / 2 - barWidth

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: barWidth)
                        .offset(x: xOffset - (correlation.isPositiveCorrelation ? 0 : geometry.size.width / 2))
                        .frame(maxWidth: .infinity, alignment: correlation.isPositiveCorrelation ? .leading : .trailing)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bar Chart Version

struct TagCorrelationChart: View {
    let correlations: [CorrelationEngine.TagCorrelation]

    var body: some View {
        if correlations.isEmpty {
            Text("Nog geen data")
                .foregroundStyle(.secondary)
        } else {
            Chart {
                ForEach(correlations.prefix(8)) { correlation in
                    BarMark(
                        x: .value("Correlatie", correlation.correlation),
                        y: .value("Tag", correlation.tag)
                    )
                    .foregroundStyle(correlation.isPositiveCorrelation ? Color.green : Color.red)
                }

                RuleMark(x: .value("Neutraal", 0))
                    .foregroundStyle(.secondary)
            }
            .chartXScale(domain: -1...1)
            .chartXAxis {
                AxisMarks(values: [-1, -0.5, 0, 0.5, 1]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v * 100))%")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Top Tags Summary

struct TopTagsSummary: View {
    let correlations: [CorrelationEngine.TagCorrelation]

    // Tags die positief zijn volgens Constants en een sterke correlatie hebben
    private var positiveTagCorrelations: [CorrelationEngine.TagCorrelation] {
        correlations
            .filter { Constants.Tags.positive.contains($0.tag) }
            .sorted { $0.correlation > $1.correlation }
            .prefix(3)
            .map { $0 }
    }

    // Tags die negatief zijn volgens Constants en een sterke (negatieve) correlatie hebben
    private var negativeTagCorrelations: [CorrelationEngine.TagCorrelation] {
        correlations
            .filter { Constants.Tags.negative.contains($0.tag) }
            .sorted { $0.correlation < $1.correlation }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            if !positiveTagCorrelations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Positieve tags", systemImage: "face.smiling.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)

                    FlowLayout(spacing: 8) {
                        ForEach(positiveTagCorrelations) { correlation in
                            TagSummaryPillWithCorrelation(
                                tag: correlation.tag,
                                correlation: correlation.correlation,
                                isPositiveTag: true
                            )
                        }
                    }
                }
            }

            if !negativeTagCorrelations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Negatieve tags", systemImage: "face.dashed.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)

                    FlowLayout(spacing: 8) {
                        ForEach(negativeTagCorrelations) { correlation in
                            TagSummaryPillWithCorrelation(
                                tag: correlation.tag,
                                correlation: correlation.correlation,
                                isPositiveTag: false
                            )
                        }
                    }
                }
            }

            if positiveTagCorrelations.isEmpty && negativeTagCorrelations.isEmpty {
                Text("Log meer entries met tags om patronen te ontdekken")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TagSummaryPillWithCorrelation: View {
    let tag: String
    let correlation: Double
    let isPositiveTag: Bool

    private var correlationIndicator: String {
        if correlation > 0.1 {
            return "↑"
        } else if correlation < -0.1 {
            return "↓"
        } else {
            return "→"
        }
    }

    private var backgroundColor: Color {
        isPositiveTag ? Color.green.opacity(0.15) : Color.red.opacity(0.15)
    }

    private var textColor: Color {
        isPositiveTag ? .green : .red
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
            Text(correlationIndicator)
                .fontWeight(.bold)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .foregroundStyle(textColor)
        .clipShape(Capsule())
    }
}

struct TagSummaryPill: View {
    let tag: String
    let isPositive: Bool

    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
            .foregroundStyle(isPositive ? .green : .red)
            .clipShape(Capsule())
    }
}

#Preview {
    let sampleCorrelations: [CorrelationEngine.TagCorrelation] = [
        .init(tag: "Goed geslapen", averageMood: 2.5, occurrences: 15, correlation: 0.65),
        .init(tag: "Gesport/bewogen", averageMood: 2.0, occurrences: 12, correlation: 0.45),
        .init(tag: "Sociaal contact gehad", averageMood: 1.5, occurrences: 20, correlation: 0.35),
        .init(tag: "Slecht geslapen", averageMood: -2.0, occurrences: 8, correlation: -0.55),
        .init(tag: "Stress/spanning", averageMood: -1.5, occurrences: 10, correlation: -0.40),
        .init(tag: "Hoofdpijn", averageMood: -1.8, occurrences: 5, correlation: -0.35)
    ]

    return ScrollView {
        VStack(spacing: 24) {
            TagCorrelationView(correlations: sampleCorrelations)
                .padding()

            Divider()

            TopTagsSummary(correlations: sampleCorrelations)
                .padding()
        }
    }
}
