import Foundation
import CloudKit
import CoreData
import Combine

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()

    // MARK: - Published Properties

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var pendingSyncCount = 0
    @Published var isCloudKitAvailable = false

    // MARK: - Private Properties

    private let container = CKContainer(identifier: "iCloud.com.Bartsteinhaus.mnemosyne")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        checkCloudKitAvailability()
    }

    // MARK: - Availability Check

    func checkCloudKitAvailability() {
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                switch status {
                case .available:
                    self?.isCloudKitAvailable = true
                    self?.syncError = nil
                case .noAccount:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "Geen iCloud account ingelogd"
                case .restricted:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "iCloud is beperkt"
                case .couldNotDetermine:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "Kan iCloud status niet bepalen"
                case .temporarilyUnavailable:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "iCloud tijdelijk niet beschikbaar"
                @unknown default:
                    self?.isCloudKitAvailable = false
                    self?.syncError = "Onbekende iCloud status"
                }

                if let error = error {
                    self?.syncError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Sync Status

    func updateSyncStatus() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.predicate = NSPredicate(format: "syncedToCloudKit == NO")

        do {
            let unsyncedEntries = try context.fetch(request)
            pendingSyncCount = unsyncedEntries.count
        } catch {
            print("Error fetching unsynced entries: \(error)")
        }
    }

    // MARK: - Force Sync

    func forceSync() async {
        guard isCloudKitAvailable else {
            syncError = "CloudKit niet beschikbaar"
            return
        }

        isSyncing = true
        syncError = nil

        // Trigger Core Data sync by making a small change
        let context = PersistenceController.shared.container.viewContext

        do {
            // Mark all entries as needing sync
            let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
            request.predicate = NSPredicate(format: "syncedToCloudKit == NO")
            let entries = try context.fetch(request)

            for entry in entries {
                entry.lastModified = Date()
            }

            try context.save()

            // Wait a moment for sync to propagate
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // Update sync status
            lastSyncDate = Date()
            updateSyncStatus()

        } catch {
            syncError = error.localizedDescription
        }

        isSyncing = false
    }

    // MARK: - Sync Queue Info (Debug)

    func getSyncQueueInfo() -> [(entityType: String, operation: String, date: Date)] {
        // This would connect to actual sync queue in production
        // For now, return pending entries info
        var queueInfo: [(entityType: String, operation: String, date: Date)] = []

        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.predicate = NSPredicate(format: "syncedToCloudKit == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.lastModified, ascending: false)]
        request.fetchLimit = 20

        do {
            let entries = try context.fetch(request)
            for entry in entries {
                queueInfo.append((
                    entityType: "MoodEntry",
                    operation: "sync",
                    date: entry.lastModified ?? Date()
                ))
            }
        } catch {
            print("Error fetching sync queue: \(error)")
        }

        return queueInfo
    }
}
