import Foundation
import CoreData

extension MoodEntry {
    // MARK: - Convenience Properties

    var tagsArray: [String] {
        get { tags ?? [] }
        set { tags = newValue }
    }

    var safeTimestamp: Date {
        timestamp ?? Date()
    }

    var safeId: UUID {
        id ?? UUID()
    }

    // MARK: - Mood Label

    var moodLabel: String {
        switch score {
        case -5.0 ..< -3.0:
            return "Zeer onaangenaam"
        case -3.0 ..< -1.0:
            return "Onaangenaam"
        case -1.0 ..< 1.0:
            return "Neutraal"
        case 1.0 ..< 3.0:
            return "Aangenaam"
        case 3.0 ... 5.0:
            return "Zeer aangenaam"
        default:
            return "Neutraal"
        }
    }

    // MARK: - Tag Categories

    var hasNegativeTags: Bool {
        guard let tags = tags else { return false }
        return tags.contains { Constants.Tags.negative.contains($0) }
    }

    var hasPositiveTags: Bool {
        guard let tags = tags else { return false }
        return tags.contains { Constants.Tags.positive.contains($0) }
    }

    var negativeTags: [String] {
        guard let tags = tags else { return [] }
        return tags.filter { Constants.Tags.negative.contains($0) }
    }

    var positiveTags: [String] {
        guard let tags = tags else { return [] }
        return tags.filter { Constants.Tags.positive.contains($0) }
    }

    // MARK: - Fetch Requests

    static func fetchRequest(for date: Date) -> NSFetchRequest<MoodEntry> {
        let request = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)]

        return request
    }

    static func fetchRequest(from startDate: Date, to endDate: Date) -> NSFetchRequest<MoodEntry> {
        let request = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")

        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)]

        return request
    }
}

