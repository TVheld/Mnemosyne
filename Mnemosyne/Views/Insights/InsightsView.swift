import SwiftUI
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var correlationEngine = CorrelationEngine.shared
    @StateObject private var cycleManager = CycleManager.shared

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<MoodEntry>

    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedSection: InsightSection = .overview

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Maand"
        case quarter = "3 maanden"
        case all = "Alles"

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .all: return nil
            }
        }
    }

    enum InsightSection: String, CaseIterable {
        case overview = "Overzicht"
        case tags = "Tags"
        case timing = "Timing"
        case cycle = "Cyclus"
    }

    private var filteredEntries: [MoodEntry] {
        guard let days = selectedTimeRange.days else {
            return Array(entries)
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { ($0.timestamp ?? Date()) >= cutoffDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Design.largeSpacing) {
                    // Time range picker
                    timeRangePicker

                    // Section picker
                    sectionPicker

                    // Content based on section
                    switch selectedSection {
                    case .overview:
                        overviewSection
                    case .tags:
                        tagsSection
                    case .timing:
                        timingSection
                    case .cycle:
                        cycleSection
                    }
                }
                .padding()
            }
            .navigationTitle("Inzichten")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Periode", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.Design.smallSpacing) {
                ForEach(InsightSection.allCases, id: \.self) { section in
                    sectionButton(section)
                }
            }
        }
    }

    private func sectionButton(_ section: InsightSection) -> some View {
        Button(action: { selectedSection = section }) {
            HStack(spacing: 6) {
                Image(systemName: iconForSection(section))
                Text(section.rawValue)
            }
            .font(.subheadline)
            .fontWeight(selectedSection == section ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(selectedSection == section ? Color.pink : Color(.systemGray5))
            .foregroundStyle(selectedSection == section ? .white : .primary)
            .clipShape(Capsule())
        }
    }

    private func iconForSection(_ section: InsightSection) -> String {
        switch section {
        case .overview: return "chart.line.uptrend.xyaxis"
        case .tags: return "tag"
        case .timing: return "clock"
        case .cycle: return "calendar.circle"
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: Constants.Design.largeSpacing) {
            // Quick stats
            let stats = correlationEngine.calculateStatistics(entries: filteredEntries)
            let trend = correlationEngine.calculateTrend(entries: filteredEntries)

            MoodStatisticsCard(
                stats: stats,
                entryCount: filteredEntries.count,
                trend: trend
            )

            // Trend chart
            insightCard {
                let dailyData = correlationEngine.calculateDailyMoodData(
                    entries: filteredEntries,
                    days: selectedTimeRange.days ?? 365
                )
                MoodTrendChart(data: dailyData)
            }

            // Distribution chart
            insightCard {
                let distribution = correlationEngine.calculateMoodDistribution(entries: filteredEntries)
                MoodDistributionChart(distribution: distribution)
            }

            // Top correlations summary
            insightCard {
                let correlations = correlationEngine.calculateTagCorrelations(entries: filteredEntries)
                TopTagsSummary(correlations: correlations)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(spacing: Constants.Design.largeSpacing) {
            let correlations = correlationEngine.calculateTagCorrelations(entries: filteredEntries)

            insightCard {
                TagCorrelationView(correlations: correlations)
            }

            if !correlations.isEmpty {
                insightCard {
                    VStack(alignment: .leading, spacing: Constants.Design.spacing) {
                        Text("Tag frequentie")
                            .font(.headline)

                        TagFrequencyView(correlations: correlations)
                    }
                }
            }
        }
    }

    // MARK: - Timing Section

    private var timingSection: some View {
        VStack(spacing: Constants.Design.largeSpacing) {
            // Weekday analysis
            insightCard {
                let weekdayData = correlationEngine.calculateWeekdayMoodData(entries: filteredEntries)
                WeekdayMoodChart(data: weekdayData)
            }

            // Time of day analysis
            insightCard {
                let timeData = correlationEngine.calculateTimeOfDayMoodData(entries: filteredEntries)
                TimeOfDayMoodChart(data: timeData)
            }

            // Best/worst days insight
            let weekdayData = correlationEngine.calculateWeekdayMoodData(entries: filteredEntries)
            if !weekdayData.allSatisfy({ $0.entryCount == 0 }) {
                insightCard {
                    BestWorstDaysView(weekdayData: weekdayData)
                }
            }
        }
    }

    // MARK: - Cycle Section

    private var cycleSection: some View {
        VStack(spacing: Constants.Design.largeSpacing) {
            if let config = cycleManager.configuration {
                let cycleData = correlationEngine.calculateCycleMoodData(
                    entries: filteredEntries,
                    cycleLength: Int(config.cycleLength),
                    stopWeekStart: Int(config.stopWeekStart),
                    cycleStartDate: config.currentCycleStartDate
                )

                insightCard {
                    CycleInsightsView(
                        data: cycleData,
                        cycleLength: Int(config.cycleLength),
                        stopWeekStart: Int(config.stopWeekStart)
                    )
                }

                insightCard {
                    CyclePhaseAnalysis(data: cycleData, stopWeekStart: Int(config.stopWeekStart))
                }

                PMSPatternView(data: cycleData, stopWeekStart: Int(config.stopWeekStart))
            } else {
                noCycleConfigured
            }
        }
    }

    private var noCycleConfigured: some View {
        ContentUnavailableView(
            "Cyclus niet geconfigureerd",
            systemImage: "calendar.circle",
            description: Text("Ga naar het Cyclus tabblad om je cyclus in te stellen")
        )
    }

    // MARK: - Helper Views

    private func insightCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Tag Frequency View

struct TagFrequencyView: View {
    let correlations: [CorrelationEngine.TagCorrelation]

    private var sortedByFrequency: [CorrelationEngine.TagCorrelation] {
        correlations.sorted { $0.occurrences > $1.occurrences }
    }

    private var maxOccurrences: Int {
        sortedByFrequency.first?.occurrences ?? 1
    }

    var body: some View {
        VStack(spacing: Constants.Design.smallSpacing) {
            ForEach(sortedByFrequency.prefix(8)) { correlation in
                HStack {
                    Text(correlation.tag)
                        .font(.caption)
                        .frame(width: 120, alignment: .leading)

                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pink.opacity(0.7))
                            .frame(width: geometry.size.width * CGFloat(correlation.occurrences) / CGFloat(maxOccurrences))
                    }
                    .frame(height: 16)

                    Text("\(correlation.occurrences)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Best/Worst Days View

struct BestWorstDaysView: View {
    let weekdayData: [CorrelationEngine.WeekdayMoodData]

    private var validData: [CorrelationEngine.WeekdayMoodData] {
        weekdayData.filter { $0.entryCount > 0 }
    }

    private var bestDay: CorrelationEngine.WeekdayMoodData? {
        validData.max { $0.averageMood < $1.averageMood }
    }

    private var worstDay: CorrelationEngine.WeekdayMoodData? {
        validData.min { $0.averageMood < $1.averageMood }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.spacing) {
            Text("Beste & slechtste dagen")
                .font(.headline)

            HStack(spacing: Constants.Design.largeSpacing) {
                if let best = bestDay {
                    dayCard(
                        day: best.weekdayName,
                        mood: best.averageMood,
                        icon: "face.smiling.fill",
                        color: .green,
                        label: "Beste dag"
                    )
                }

                if let worst = worstDay {
                    dayCard(
                        day: worst.weekdayName,
                        mood: worst.averageMood,
                        icon: "face.dashed",
                        color: .red,
                        label: "Moeilijkste dag"
                    )
                }
            }
        }
    }

    private func dayCard(day: String, mood: Double, icon: String, color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(day.capitalized)
                .font(.headline)

            Text(String(format: "%.1f", mood))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
    }
}

#Preview {
    InsightsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
