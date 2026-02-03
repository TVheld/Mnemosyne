import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    // Check if iCloud sync is enabled
    // Strategy: Check UserDefaults first, then use a simple heuristic for reinstalls
    private static var iCloudSyncEnabled: Bool {
        // Check UserDefaults (set during onboarding)
        if UserDefaults.standard.object(forKey: "iCloudSyncEnabled") != nil {
            return UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        }

        // Fresh install: check if user completed onboarding before (hasn't, since no UserDefaults)
        // In this case, we default to TRUE to attempt CloudKit sync
        // This ensures data recovery after reinstall for users who had iCloud enabled
        // If user never used iCloud, this is harmless - CloudKit will just be empty
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompletedOnboarding {
            // Fresh install - default to enabling CloudKit to recover any existing data
            print("PersistenceController: Fresh install detected, enabling CloudKit to check for existing data")
            return true
        }

        return false
    }

    // Save iCloud sync preference
    static func setICloudSyncEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "iCloudSyncEnabled")
    }

    // Preview voor SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Maak sample data voor previews
        for i in 0..<10 {
            let entry = MoodEntry(context: viewContext)
            entry.id = UUID()
            entry.timestamp = Date().addingTimeInterval(-Double(i) * 3600 * 8)
            entry.score = Double.random(in: -5...5)
            entry.tags = ["Energiek", "Productieve dag"]
            entry.syncedToHealthKit = false
            entry.syncedToCloudKit = false
            entry.lastModified = Date()
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview Core Data save error: \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Mnemosyne")

        // Configure CloudKit sync
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store description found")
        }

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
            description.cloudKitContainerOptions = nil
        } else if PersistenceController.iCloudSyncEnabled {
            // Enable CloudKit sync only if user opted in
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.Bartsteinhaus.mnemosyne"
            )

            // Enable history tracking for sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        } else {
            // Local only - no CloudKit sync
            description.cloudKitContainerOptions = nil

            // Still enable history tracking for local consistency
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this more gracefully
                print("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Listen for remote changes (only relevant if iCloud sync is enabled)
        if PersistenceController.iCloudSyncEnabled {
            NotificationCenter.default.addObserver(
                forName: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator,
                queue: .main
            ) { _ in
                // Notify that remote changes occurred
                NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
            }
        }
    }

    // MARK: - Save Context

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - Data Export

    func exportAllData() -> Data? {
        let context = container.viewContext

        // Fetch all mood entries
        let moodFetch: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        moodFetch.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)]

        // Fetch cycle configuration
        let cycleFetch: NSFetchRequest<CycleConfiguration> = CycleConfiguration.fetchRequest()

        do {
            let moodEntries = try context.fetch(moodFetch)
            let cycleConfigs = try context.fetch(cycleFetch)

            var exportData: [String: Any] = [:]

            // Export mood entries
            let moodData = moodEntries.map { entry -> [String: Any] in
                var dict: [String: Any] = [
                    "id": entry.id?.uuidString ?? "",
                    "score": entry.score,
                    "timestamp": entry.timestamp?.ISO8601Format() ?? ""
                ]
                if let tags = entry.tags {
                    dict["tags"] = tags
                }
                if let note = entry.note {
                    dict["note"] = note
                }
                if let flow = entry.menstrualFlow {
                    dict["menstrualFlow"] = flow
                }
                return dict
            }
            exportData["moodEntries"] = moodData

            // Export cycle configuration
            if let config = cycleConfigs.first {
                exportData["cycleConfiguration"] = [
                    "cycleLength": config.cycleLength,
                    "stopWeekStart": config.stopWeekStart,
                    "stopWeekEnd": config.stopWeekEnd,
                    "pillBrand": config.pillBrand ?? "",
                    "currentCycleStartDate": config.currentCycleStartDate?.ISO8601Format() ?? ""
                ]
            }

            // Add metadata
            exportData["exportDate"] = Date().ISO8601Format()
            exportData["appVersion"] = Bundle.main.appVersion

            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }

    // MARK: - Delete All Data

    func deleteAllData() {
        let context = container.viewContext

        // Delete mood entries
        let moodFetch: NSFetchRequest<NSFetchRequestResult> = MoodEntry.fetchRequest()
        let moodDelete = NSBatchDeleteRequest(fetchRequest: moodFetch)

        // Delete cycle configuration
        let cycleFetch: NSFetchRequest<NSFetchRequestResult> = CycleConfiguration.fetchRequest()
        let cycleDelete = NSBatchDeleteRequest(fetchRequest: cycleFetch)

        do {
            try context.execute(moodDelete)
            try context.execute(cycleDelete)
            save()

            // Reset related managers on main thread
            Task { @MainActor in
                CycleManager.shared.loadConfiguration()
            }
        } catch {
            print("Delete all data error: \(error)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
}
