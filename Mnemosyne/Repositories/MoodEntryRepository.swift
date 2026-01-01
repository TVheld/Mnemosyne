import CoreData
import Combine

class MoodEntryRepository: ObservableObject {
    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
    }

    // MARK: - Create

    @discardableResult
    func createEntry(score: Double, tags: [String] = [], note: String? = nil, menstrualFlow: String? = nil) -> MoodEntry {
        let entry = MoodEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.score = score
        entry.tags = tags
        entry.note = note
        entry.menstrualFlow = menstrualFlow
        entry.syncedToHealthKit = false
        entry.syncedToCloudKit = false
        entry.lastModified = Date()

        save()
        return entry
    }

    // MARK: - Read

    func fetchAllEntries() -> [MoodEntry] {
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    func fetchEntries(for date: Date) -> [MoodEntry] {
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    func fetchTodayEntries() -> [MoodEntry] {
        fetchEntries(for: Date())
    }

    func fetchEntry(by id: UUID) -> MoodEntry? {
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Fetch error: \(error)")
            return nil
        }
    }

    // MARK: - Update

    func updateEntry(_ entry: MoodEntry, score: Double? = nil, tags: [String]? = nil, note: String? = nil, menstrualFlow: String? = nil) {
        if let score = score {
            entry.score = score
        }
        if let tags = tags {
            entry.tags = tags
        }
        if let note = note {
            entry.note = note
        }
        if let menstrualFlow = menstrualFlow {
            entry.menstrualFlow = menstrualFlow
        }
        entry.lastModified = Date()
        entry.syncedToCloudKit = false

        save()
    }

    // MARK: - Delete

    func deleteEntry(_ entry: MoodEntry) {
        viewContext.delete(entry)
        save()
    }

    func deleteEntry(by id: UUID) {
        if let entry = fetchEntry(by: id) {
            deleteEntry(entry)
        }
    }

    // MARK: - Statistics

    func todayEntryCount() -> Int {
        fetchTodayEntries().count
    }

    func averageScore(for entries: [MoodEntry]) -> Double? {
        guard !entries.isEmpty else { return nil }
        let total = entries.reduce(0) { $0 + $1.score }
        return total / Double(entries.count)
    }

    func streak() -> Int {
        var currentDate = Date()
        var streakCount = 0

        while true {
            let entries = fetchEntries(for: currentDate)
            if entries.isEmpty {
                break
            }
            streakCount += 1
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        return streakCount
    }

    // MARK: - Private

    private func save() {
        PersistenceController.shared.save()
    }
}
