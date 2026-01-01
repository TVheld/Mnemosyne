import Foundation
import HealthKit
import CoreData
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var lastSyncDate: Date?

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()

    // Types we want to write
    private let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()

        // Category types
        if let headache = HKCategoryType.categoryType(forIdentifier: .headache) {
            types.insert(headache)
        }
        if let abdominalCramps = HKCategoryType.categoryType(forIdentifier: .abdominalCramps) {
            types.insert(abdominalCramps)
        }
        if let fatigue = HKCategoryType.categoryType(forIdentifier: .fatigue) {
            types.insert(fatigue)
        }
        if let nausea = HKCategoryType.categoryType(forIdentifier: .nausea) {
            types.insert(nausea)
        }
        if let bloating = HKCategoryType.categoryType(forIdentifier: .bloating) {
            types.insert(bloating)
        }
        if let sleepAnalysis = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        if let sexualActivity = HKCategoryType.categoryType(forIdentifier: .sexualActivity) {
            types.insert(sexualActivity)
        }
        if let menstrualFlow = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) {
            types.insert(menstrualFlow)
        }

        // Quantity types
        if let water = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(water)
        }

        // Workout type
        types.insert(HKWorkoutType.workoutType())

        return types
    }()

    // Types we want to read
    private var readTypes: Set<HKObjectType> {
        Set(writeTypes.map { $0 as HKObjectType })
    }

    // MARK: - Init

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            isAuthorized = false
            authorizationError = "HealthKit niet beschikbaar op dit apparaat"
            return
        }

        // Check if we have authorization for at least one type
        if let headacheType = HKCategoryType.categoryType(forIdentifier: .headache) {
            let status = healthStore.authorizationStatus(for: headacheType)
            isAuthorized = status == .sharingAuthorized
        }
    }

    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit niet beschikbaar"
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            checkAuthorizationStatus()
            return isAuthorized
        } catch {
            authorizationError = error.localizedDescription
            return false
        }
    }

    // MARK: - Write Data

    func syncEntry(_ entry: MoodEntry) async {
        guard isAuthorized else { return }

        let tags = entry.tags ?? []
        let timestamp = entry.timestamp ?? Date()

        // Sync tags to HealthKit
        for tag in tags {
            await writeTagToHealthKit(tag: tag, date: timestamp)
        }

        // Sync menstrual flow if present
        if let flowString = entry.menstrualFlow,
           let flow = Constants.MenstrualFlow(rawValue: flowString) {
            await writeMenstrualFlow(flow: flow, date: timestamp)
        }

        // Mark as synced
        entry.syncedToHealthKit = true
        PersistenceController.shared.save()
        lastSyncDate = Date()
    }

    private func writeTagToHealthKit(tag: String, date: Date) async {
        switch tag {
        case "Hoofdpijn":
            await writeCategorySample(identifier: .headache, date: date)

        case "Buikpijn":
            await writeCategorySample(identifier: .abdominalCramps, date: date)

        case "Moe/uitgeput":
            await writeCategorySample(identifier: .fatigue, date: date)

        case "Misselijkheid":
            await writeCategorySample(identifier: .nausea, date: date)

        case "Opgeblazen gevoel":
            await writeCategorySample(identifier: .bloating, date: date)

        case "Goed geslapen":
            await writeSleepSample(quality: .good, date: date)

        case "Slecht geslapen":
            await writeSleepSample(quality: .poor, date: date)

        case "Gesport/bewogen":
            await writeWorkoutSample(date: date)

        case "Genoeg water gedronken":
            await writeWaterIntake(date: date)

        case "Intieme momenten":
            await writeCategorySample(identifier: .sexualActivity, date: date)

        default:
            // Tags without HealthKit mapping
            break
        }
    }

    // MARK: - Category Samples

    private func writeCategorySample(identifier: HKCategoryTypeIdentifier, date: Date, value: Int = HKCategoryValue.notApplicable.rawValue) async {
        guard let type = HKCategoryType.categoryType(forIdentifier: identifier) else { return }

        let sample = HKCategorySample(
            type: type,
            value: value,
            start: date,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )

        do {
            try await healthStore.save(sample)
        } catch {
            print("Error saving \(identifier.rawValue): \(error)")
        }
    }

    // MARK: - Sleep Samples

    enum SleepQuality {
        case good, poor
    }

    private func writeSleepSample(quality: SleepQuality, date: Date) async {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        // Estimate sleep duration based on quality
        let hours: TimeInterval = quality == .good ? 8 * 3600 : 5 * 3600
        let startDate = Calendar.current.date(byAdding: .hour, value: -Int(hours / 3600), to: date) ?? date

        let value: HKCategoryValueSleepAnalysis = quality == .good ? .asleepCore : .asleepCore

        let sample = HKCategorySample(
            type: type,
            value: value.rawValue,
            start: startDate,
            end: date,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "MnemosyneQuality": quality == .good ? "good" : "poor"
            ]
        )

        do {
            try await healthStore.save(sample)
        } catch {
            print("Error saving sleep: \(error)")
        }
    }

    // MARK: - Workout Samples

    private func writeWorkoutSample(date: Date) async {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other

        do {
            let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)
            try await builder.beginCollection(at: date.addingTimeInterval(-1800))
            try await builder.endCollection(at: date)
            try await builder.finishWorkout()
        } catch {
            print("Error saving workout: \(error)")
        }
    }

    // MARK: - Water Intake

    private func writeWaterIntake(date: Date) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }

        // Log 2 liters as "genoeg water"
        let quantity = HKQuantity(unit: .liter(), doubleValue: 2.0)
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date.startOfDay,
            end: date,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )

        do {
            try await healthStore.save(sample)
        } catch {
            print("Error saving water intake: \(error)")
        }
    }

    // MARK: - Menstrual Flow

    private func writeMenstrualFlow(flow: Constants.MenstrualFlow, date: Date) async {
        guard let type = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) else { return }

        let value: Int
        switch flow {
        case .none:
            return // Don't write "none" to HealthKit
        case .spotting:
            value = 1 // unspecified
        case .light:
            value = 2 // light
        case .medium:
            value = 3 // medium
        case .heavy:
            value = 4 // heavy
        }

        let sample = HKCategorySample(
            type: type,
            value: value,
            start: date.startOfDay,
            end: date.endOfDay,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )

        do {
            try await healthStore.save(sample)
        } catch {
            print("Error saving menstrual flow: \(error)")
        }
    }

    // MARK: - Sync All Unsynced

    func syncAllUnsynced() async {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.predicate = NSPredicate(format: "syncedToHealthKit == NO")

        do {
            let entries = try context.fetch(request)
            for entry in entries {
                await syncEntry(entry)
            }
        } catch {
            print("Error fetching unsynced entries: \(error)")
        }
    }
}
