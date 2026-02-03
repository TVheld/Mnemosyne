import Foundation
import CoreData
import Combine

@MainActor
class CycleManager: ObservableObject {
    static let shared = CycleManager()

    // MARK: - Published Properties

    @Published var isConfigured = false
    @Published var currentCycleDay: Int = 0
    @Published var isInStopWeek = false
    @Published var isPMSPeriod = false
    @Published var daysUntilPeriod: Int?
    @Published var configuration: CycleConfiguration?

    // MARK: - Private Properties

    private let viewContext = PersistenceController.shared.container.viewContext

    // MARK: - Init

    private init() {
        loadConfiguration()
    }

    // MARK: - Configuration

    func loadConfiguration() {
        let request: NSFetchRequest<CycleConfiguration> = CycleConfiguration.fetchRequest()
        request.fetchLimit = 1

        do {
            let results = try viewContext.fetch(request)
            if let config = results.first, config.isConfigured {
                configuration = config
                isConfigured = true
                updateCycleStatus()
            } else {
                isConfigured = false
            }
        } catch {
            print("Error loading cycle configuration: \(error)")
        }
    }

    func saveConfiguration(
        pillBrand: String,
        cycleLength: Int,
        stopWeekStart: Int,
        stopWeekEnd: Int,
        cycleStartDate: Date
    ) {
        let config: CycleConfiguration

        if let existing = configuration {
            config = existing
        } else {
            config = CycleConfiguration(context: viewContext)
            config.id = UUID()
        }

        config.pillBrand = pillBrand
        config.cycleLength = Int16(cycleLength)
        config.stopWeekStart = Int16(stopWeekStart)
        config.stopWeekEnd = Int16(stopWeekEnd)
        config.currentCycleStartDate = cycleStartDate
        config.isConfigured = true
        config.lastModified = Date()

        do {
            try viewContext.save()
            configuration = config
            isConfigured = true
            updateCycleStatus()
        } catch {
            print("Error saving cycle configuration: \(error)")
        }
    }

    // MARK: - Cycle Status

    func updateCycleStatus() {
        guard let config = configuration,
              let startDate = config.currentCycleStartDate else {
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cycleStart = calendar.startOfDay(for: startDate)

        // Calculate days since cycle start
        let daysSinceStart = calendar.dateComponents([.day], from: cycleStart, to: today).day ?? 0
        let cycleLength = Int(config.cycleLength)

        // Calculate current day in cycle (1-indexed)
        // Use proper modulo that handles negative numbers (when start date is in future)
        currentCycleDay = ((daysSinceStart % cycleLength) + cycleLength) % cycleLength + 1

        // Check if in stop week
        let stopStart = Int(config.stopWeekStart)
        let stopEnd = Int(config.stopWeekEnd)
        isInStopWeek = currentCycleDay >= stopStart && currentCycleDay <= stopEnd

        // Check if in PMS period
        let pmsStart = stopStart - Constants.Cycle.pmsDaysBeforeStopWeek
        isPMSPeriod = currentCycleDay >= pmsStart && currentCycleDay < stopStart

        // Days until period
        if currentCycleDay < stopStart {
            daysUntilPeriod = stopStart - currentCycleDay
        } else {
            daysUntilPeriod = (cycleLength - currentCycleDay) + stopStart
        }
    }

    // MARK: - Predictions

    func predictedPeriodDates(count: Int = 3) -> [DateInterval] {
        guard let config = configuration,
              let startDate = config.currentCycleStartDate else {
            return []
        }

        let calendar = Calendar.current
        let cycleLength = Int(config.cycleLength)
        let stopStart = Int(config.stopWeekStart)
        let stopEnd = Int(config.stopWeekEnd)
        let periodLength = stopEnd - stopStart + 1

        var predictions: [DateInterval] = []

        // Find current cycle start
        let today = calendar.startOfDay(for: Date())
        let cycleStart = calendar.startOfDay(for: startDate)
        let daysSinceStart = calendar.dateComponents([.day], from: cycleStart, to: today).day ?? 0
        let completedCycles = daysSinceStart / cycleLength

        // Calculate next periods
        for i in 0..<count {
            let cycleNumber = completedCycles + i
            let cycleStartDate = calendar.date(byAdding: .day, value: cycleNumber * cycleLength, to: cycleStart)!
            let periodStart = calendar.date(byAdding: .day, value: stopStart - 1, to: cycleStartDate)!
            let periodEnd = calendar.date(byAdding: .day, value: periodLength - 1, to: periodStart)!

            // Only include future or current periods
            if periodEnd >= today {
                predictions.append(DateInterval(start: periodStart, end: periodEnd))
            }

            if predictions.count >= count {
                break
            }
        }

        // If we don't have enough, look further ahead
        var futureOffset = count
        while predictions.count < count {
            let cycleNumber = completedCycles + futureOffset
            let cycleStartDate = calendar.date(byAdding: .day, value: cycleNumber * cycleLength, to: cycleStart)!
            let periodStart = calendar.date(byAdding: .day, value: stopStart - 1, to: cycleStartDate)!
            let periodEnd = calendar.date(byAdding: .day, value: periodLength - 1, to: periodStart)!
            predictions.append(DateInterval(start: periodStart, end: periodEnd))
            futureOffset += 1
        }

        return Array(predictions.prefix(count))
    }

    func isPeriodDay(_ date: Date) -> Bool {
        guard let config = configuration,
              let startDate = config.currentCycleStartDate else {
            return false
        }

        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let cycleStart = calendar.startOfDay(for: startDate)

        let daysSinceStart = calendar.dateComponents([.day], from: cycleStart, to: targetDate).day ?? 0
        let cycleLength = Int(config.cycleLength)
        // Use proper modulo that handles negative numbers
        let dayInCycle = ((daysSinceStart % cycleLength) + cycleLength) % cycleLength + 1

        let stopStart = Int(config.stopWeekStart)
        let stopEnd = Int(config.stopWeekEnd)

        return dayInCycle >= stopStart && dayInCycle <= stopEnd
    }

    func isPMSDay(_ date: Date) -> Bool {
        guard let config = configuration,
              let startDate = config.currentCycleStartDate else {
            return false
        }

        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let cycleStart = calendar.startOfDay(for: startDate)

        let daysSinceStart = calendar.dateComponents([.day], from: cycleStart, to: targetDate).day ?? 0
        let cycleLength = Int(config.cycleLength)
        // Use proper modulo that handles negative numbers
        let dayInCycle = ((daysSinceStart % cycleLength) + cycleLength) % cycleLength + 1

        let stopStart = Int(config.stopWeekStart)
        let pmsStart = stopStart - Constants.Cycle.pmsDaysBeforeStopWeek

        return dayInCycle >= pmsStart && dayInCycle < stopStart
    }

    // MARK: - Pill Forgotten

    func shiftCycle(by days: Int) {
        guard let config = configuration,
              let currentStart = config.currentCycleStartDate else {
            return
        }

        let calendar = Calendar.current
        config.currentCycleStartDate = calendar.date(byAdding: .day, value: days, to: currentStart)
        config.lastModified = Date()

        do {
            try viewContext.save()
            updateCycleStatus()
        } catch {
            print("Error shifting cycle: \(error)")
        }
    }

    // MARK: - Flow History

    func getFlowHistory(forMonth date: Date) -> [Date: String] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@ AND menstrualFlow != nil",
            startOfMonth as NSDate,
            endOfMonth as NSDate
        )

        do {
            let entries = try viewContext.fetch(request)
            var flowHistory: [Date: String] = [:]

            for entry in entries {
                if let timestamp = entry.timestamp,
                   let flow = entry.menstrualFlow {
                    let day = calendar.startOfDay(for: timestamp)
                    flowHistory[day] = flow
                }
            }

            return flowHistory
        } catch {
            print("Error fetching flow history: \(error)")
            return [:]
        }
    }

    // MARK: - Statistics

    func averageFlowIntensity(for period: DateInterval) -> Double? {
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@ AND menstrualFlow != nil",
            period.start as NSDate,
            period.end as NSDate
        )

        do {
            let entries = try viewContext.fetch(request)
            guard !entries.isEmpty else { return nil }

            let intensityValues: [Double] = entries.compactMap { entry in
                guard let flowString = entry.menstrualFlow,
                      let flow = Constants.MenstrualFlow(rawValue: flowString) else { return nil }
                switch flow {
                case .none: return nil
                case .spotting: return 1
                case .light: return 2
                case .medium: return 3
                case .heavy: return 4
                }
            }

            guard !intensityValues.isEmpty else { return nil }
            return intensityValues.reduce(0, +) / Double(intensityValues.count)
        } catch {
            return nil
        }
    }
}
