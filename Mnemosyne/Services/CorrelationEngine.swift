import Foundation
import CoreData

/// Engine voor het berekenen van correlaties tussen mood, tags en cyclusdata
class CorrelationEngine: ObservableObject {
    static let shared = CorrelationEngine()

    // MARK: - Data Structures

    struct TagCorrelation: Identifiable {
        let id = UUID()
        let tag: String
        let averageMood: Double
        let occurrences: Int
        let correlation: Double // -1 to +1

        var isPositiveCorrelation: Bool {
            correlation > 0
        }
    }

    struct DayMoodData: Identifiable {
        let id = UUID()
        let date: Date
        let averageMood: Double
        let entryCount: Int
        let tags: [String]
    }

    struct CycleDayMoodData: Identifiable {
        let id = UUID()
        let cycleDay: Int
        let averageMood: Double
        let entryCount: Int
        let isStopWeek: Bool
    }

    struct WeekdayMoodData: Identifiable {
        let id = UUID()
        let weekday: Int // 1 = Sunday, 7 = Saturday
        let averageMood: Double
        let entryCount: Int

        var weekdayName: String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "nl_NL")
            return formatter.weekdaySymbols[weekday - 1]
        }

        var shortWeekdayName: String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "nl_NL")
            return formatter.shortWeekdaySymbols[weekday - 1]
        }
    }

    struct TimeOfDayMoodData: Identifiable {
        let id = UUID()
        let hour: Int
        let averageMood: Double
        let entryCount: Int

        var timeLabel: String {
            switch hour {
            case 5..<12: return "Ochtend"
            case 12..<17: return "Middag"
            case 17..<21: return "Avond"
            default: return "Nacht"
            }
        }
    }

    // MARK: - Tag Correlations

    func calculateTagCorrelations(entries: [MoodEntry]) -> [TagCorrelation] {
        guard !entries.isEmpty else { return [] }

        let overallAverage = entries.reduce(0.0) { $0 + $1.score } / Double(entries.count)
        var tagData: [String: (totalScore: Double, count: Int)] = [:]

        // Verzamel data per tag
        for entry in entries {
            let tags = entry.tags ?? []
            for tag in tags {
                if let existing = tagData[tag] {
                    tagData[tag] = (existing.totalScore + entry.score, existing.count + 1)
                } else {
                    tagData[tag] = (entry.score, 1)
                }
            }
        }

        // Bereken correlaties
        var correlations: [TagCorrelation] = []

        for (tag, data) in tagData {
            let averageMood = data.totalScore / Double(data.count)

            // Simpele correlatie: verschil van overall gemiddelde, genormaliseerd
            let correlation = (averageMood - overallAverage) / 5.0 // Normaliseer naar -1 tot +1
            let clampedCorrelation = max(-1.0, min(1.0, correlation))

            correlations.append(TagCorrelation(
                tag: tag,
                averageMood: averageMood,
                occurrences: data.count,
                correlation: clampedCorrelation
            ))
        }

        // Sorteer op absolute correlatie (sterkste eerst)
        return correlations.sorted { abs($0.correlation) > abs($1.correlation) }
    }

    // MARK: - Daily Mood Data

    func calculateDailyMoodData(entries: [MoodEntry], days: Int = 30) -> [DayMoodData] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endDate) else {
            return []
        }

        // Groepeer entries per dag
        var dayGroups: [Date: [MoodEntry]] = [:]

        for entry in entries {
            guard let timestamp = entry.timestamp else { continue }
            let dayStart = calendar.startOfDay(for: timestamp)

            if dayStart >= startDate && dayStart <= endDate {
                if dayGroups[dayStart] != nil {
                    dayGroups[dayStart]?.append(entry)
                } else {
                    dayGroups[dayStart] = [entry]
                }
            }
        }

        // Genereer data voor elke dag
        var result: [DayMoodData] = []
        var currentDate = startDate

        while currentDate <= endDate {
            if let entriesForDay = dayGroups[currentDate], !entriesForDay.isEmpty {
                let averageMood = entriesForDay.reduce(0.0) { $0 + $1.score } / Double(entriesForDay.count)
                let allTags = entriesForDay.flatMap { $0.tags ?? [] }

                result.append(DayMoodData(
                    date: currentDate,
                    averageMood: averageMood,
                    entryCount: entriesForDay.count,
                    tags: allTags
                ))
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return result
    }

    // MARK: - Cycle Mood Data

    func calculateCycleMoodData(entries: [MoodEntry], cycleLength: Int, stopWeekStart: Int, cycleStartDate: Date?) -> [CycleDayMoodData] {
        guard let cycleStart = cycleStartDate else {
            return []
        }

        let calendar = Calendar.current
        var cycleDayGroups: [Int: [Double]] = [:]

        // Groepeer entries per cyclusdag
        for entry in entries {
            guard let timestamp = entry.timestamp else { continue }

            let daysSinceStart = calendar.dateComponents([.day], from: cycleStart, to: timestamp).day ?? 0
            let cycleDay = ((daysSinceStart % cycleLength) + cycleLength) % cycleLength + 1

            if cycleDayGroups[cycleDay] != nil {
                cycleDayGroups[cycleDay]?.append(entry.score)
            } else {
                cycleDayGroups[cycleDay] = [entry.score]
            }
        }

        // Genereer data voor elke cyclusdag
        var result: [CycleDayMoodData] = []

        for day in 1...cycleLength {
            let scores = cycleDayGroups[day] ?? []
            let averageMood = scores.isEmpty ? 0.0 : scores.reduce(0.0, +) / Double(scores.count)
            let isStopWeek = day >= stopWeekStart

            result.append(CycleDayMoodData(
                cycleDay: day,
                averageMood: averageMood,
                entryCount: scores.count,
                isStopWeek: isStopWeek
            ))
        }

        return result
    }

    // MARK: - Weekday Analysis

    func calculateWeekdayMoodData(entries: [MoodEntry]) -> [WeekdayMoodData] {
        let calendar = Calendar.current
        var weekdayGroups: [Int: [Double]] = [:]

        for entry in entries {
            guard let timestamp = entry.timestamp else { continue }
            let weekday = calendar.component(.weekday, from: timestamp)

            if weekdayGroups[weekday] != nil {
                weekdayGroups[weekday]?.append(entry.score)
            } else {
                weekdayGroups[weekday] = [entry.score]
            }
        }

        var result: [WeekdayMoodData] = []

        // Begin met maandag (2) en eindig met zondag (1)
        let orderedWeekdays = [2, 3, 4, 5, 6, 7, 1]

        for weekday in orderedWeekdays {
            let scores = weekdayGroups[weekday] ?? []
            let averageMood = scores.isEmpty ? 0.0 : scores.reduce(0.0, +) / Double(scores.count)

            result.append(WeekdayMoodData(
                weekday: weekday,
                averageMood: averageMood,
                entryCount: scores.count
            ))
        }

        return result
    }

    // MARK: - Time of Day Analysis

    func calculateTimeOfDayMoodData(entries: [MoodEntry]) -> [TimeOfDayMoodData] {
        let calendar = Calendar.current
        var timeGroups: [String: (totalScore: Double, count: Int)] = [
            "Ochtend": (0, 0),
            "Middag": (0, 0),
            "Avond": (0, 0),
            "Nacht": (0, 0)
        ]

        for entry in entries {
            guard let timestamp = entry.timestamp else { continue }
            let hour = calendar.component(.hour, from: timestamp)

            let timeOfDay: String
            switch hour {
            case 5..<12: timeOfDay = "Ochtend"
            case 12..<17: timeOfDay = "Middag"
            case 17..<21: timeOfDay = "Avond"
            default: timeOfDay = "Nacht"
            }

            if let existing = timeGroups[timeOfDay] {
                timeGroups[timeOfDay] = (existing.totalScore + entry.score, existing.count + 1)
            }
        }

        let orderedTimes = ["Ochtend", "Middag", "Avond", "Nacht"]
        var result: [TimeOfDayMoodData] = []

        for (index, time) in orderedTimes.enumerated() {
            let data = timeGroups[time] ?? (0, 0)
            let averageMood = data.count > 0 ? data.totalScore / Double(data.count) : 0.0

            result.append(TimeOfDayMoodData(
                hour: [8, 14, 19, 23][index],
                averageMood: averageMood,
                entryCount: data.count
            ))
        }

        return result
    }

    // MARK: - Mood Distribution

    func calculateMoodDistribution(entries: [MoodEntry]) -> [Int: Int] {
        var distribution: [Int: Int] = [:]

        // Initialiseer alle buckets
        for i in -5...5 {
            distribution[i] = 0
        }

        for entry in entries {
            let bucket = Int(round(entry.score))
            let clampedBucket = max(-5, min(5, bucket))
            distribution[clampedBucket, default: 0] += 1
        }

        return distribution
    }

    // MARK: - Statistics

    func calculateStatistics(entries: [MoodEntry]) -> (average: Double, standardDeviation: Double, min: Double, max: Double) {
        guard !entries.isEmpty else {
            return (0, 0, 0, 0)
        }

        let scores = entries.map { $0.score }
        let average = scores.reduce(0.0, +) / Double(scores.count)

        let squaredDifferences = scores.map { pow($0 - average, 2) }
        let variance = squaredDifferences.reduce(0.0, +) / Double(scores.count)
        let standardDeviation = sqrt(variance)

        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 0

        return (average, standardDeviation, minScore, maxScore)
    }

    // MARK: - Trend Analysis

    func calculateTrend(entries: [MoodEntry], days: Int = 7) -> Double {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return 0
        }

        let recentEntries = entries.filter { entry in
            guard let timestamp = entry.timestamp else { return false }
            return timestamp >= startDate && timestamp <= endDate
        }

        guard recentEntries.count >= 2 else { return 0 }

        // Simpele lineaire regressie
        let sortedEntries = recentEntries.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }

        var sumX = 0.0
        var sumY = 0.0
        var sumXY = 0.0
        var sumX2 = 0.0
        let n = Double(sortedEntries.count)

        for (index, entry) in sortedEntries.enumerated() {
            let x = Double(index)
            let y = entry.score

            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return 0 }

        let slope = (n * sumXY - sumX * sumY) / denominator

        return slope
    }
}
