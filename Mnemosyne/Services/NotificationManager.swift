import UserNotifications
import SwiftUI
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var notificationTimes: [DateComponents] = Constants.Notifications.defaultTimes
    @Published var lastEntryTimestamps: [Int: Date] = [:] // Slot index -> last entry time

    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkAuthorizationStatus()
        loadSavedTimes()
        loadLastEntryTimestamps()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            if granted {
                await scheduleAllNotifications()
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Persistent Notification Logic

    /// Call this when a mood entry is saved to stop reminders for current slot
    func markEntryCompleted() {
        let currentSlot = getCurrentTimeSlot()
        if let slot = currentSlot {
            lastEntryTimestamps[slot] = Date()
            saveLastEntryTimestamps()

            // Cancel pending reminders for this slot
            cancelRemindersForSlot(slot)
        }

        clearBadge()
    }

    /// Get current time slot (0, 1, 2) based on notification times
    private func getCurrentTimeSlot() -> Int? {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute

        // Find which slot we're in (or just passed)
        for (index, time) in notificationTimes.enumerated().reversed() {
            let slotHour = time.hour ?? 0
            let slotMinute = time.minute ?? 0
            let slotTotalMinutes = slotHour * 60 + slotMinute

            if currentTotalMinutes >= slotTotalMinutes {
                return index
            }
        }

        return nil
    }

    /// Check if entry exists for current slot today
    func hasEntryForCurrentSlot() -> Bool {
        guard let slot = getCurrentTimeSlot() else { return false }
        guard let lastEntry = lastEntryTimestamps[slot] else { return false }

        return Calendar.current.isDateInToday(lastEntry)
    }

    // MARK: - Scheduling

    func scheduleAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()

        guard isAuthorized else { return }

        for (index, time) in notificationTimes.enumerated() {
            // Schedule main notification
            await scheduleNotification(at: time, identifier: "mood_reminder_\(index)", isReminder: false)

            // Schedule persistent reminders (every 15 minutes for 2 hours)
            await schedulePersistentReminders(forSlot: index, startTime: time)
        }
    }

    private func scheduleNotification(at time: DateComponents, identifier: String, isReminder: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = isReminder ? "Herinnering" : "Hoe voel je je nu?"
        content.body = isReminder
            ? "Je hebt je stemming nog niet vastgelegd. Neem even de tijd."
            : "Neem even de tijd om je stemming vast te leggen."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MOOD_ENTRY"

        var dateComponents = time
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }

    private func schedulePersistentReminders(forSlot slot: Int, startTime: DateComponents) async {
        let reminderIntervalMinutes = 15
        let maxReminders = 8 // 2 hours worth of reminders

        guard let startHour = startTime.hour, let startMinute = startTime.minute else { return }

        for reminderIndex in 1...maxReminders {
            var reminderTime = DateComponents()
            let totalMinutes = startHour * 60 + startMinute + (reminderIndex * reminderIntervalMinutes)
            reminderTime.hour = (totalMinutes / 60) % 24
            reminderTime.minute = totalMinutes % 60

            let identifier = "mood_reminder_\(slot)_persistent_\(reminderIndex)"
            await scheduleNotification(at: reminderTime, identifier: identifier, isReminder: true)
        }
    }

    private func cancelRemindersForSlot(_ slot: Int) {
        var identifiersToCancel: [String] = []

        // Cancel all persistent reminders for this slot
        for reminderIndex in 1...8 {
            identifiersToCancel.append("mood_reminder_\(slot)_persistent_\(reminderIndex)")
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToCancel)

        // Also remove the main notification from notification center
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ["mood_reminder_\(slot)"])
    }

    // MARK: - Time Management

    func updateNotificationTime(at index: Int, to time: DateComponents) {
        guard index < notificationTimes.count else { return }
        notificationTimes[index] = time
        saveTimes()

        Task {
            await scheduleAllNotifications()
        }
    }

    func setNotificationTimes(_ times: [DateComponents]) {
        notificationTimes = times
        saveTimes()

        Task {
            await scheduleAllNotifications()
        }
    }

    // MARK: - Persistence

    private func saveTimes() {
        let timesData = notificationTimes.map { components -> [String: Int] in
            var dict: [String: Int] = [:]
            if let hour = components.hour { dict["hour"] = hour }
            if let minute = components.minute { dict["minute"] = minute }
            return dict
        }
        UserDefaults.standard.set(timesData, forKey: "notificationTimes")
    }

    private func loadSavedTimes() {
        guard let timesData = UserDefaults.standard.array(forKey: "notificationTimes") as? [[String: Int]] else {
            return
        }

        notificationTimes = timesData.map { dict -> DateComponents in
            var components = DateComponents()
            components.hour = dict["hour"]
            components.minute = dict["minute"]
            return components
        }
    }

    private func saveLastEntryTimestamps() {
        let data = lastEntryTimestamps.mapKeys { String($0) }
        let encoded = data.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(encoded, forKey: "lastEntryTimestamps")
    }

    private func loadLastEntryTimestamps() {
        guard let data = UserDefaults.standard.dictionary(forKey: "lastEntryTimestamps") as? [String: Double] else {
            return
        }

        lastEntryTimestamps = data.compactMapKeys { Int($0) }.mapValues { Date(timeIntervalSince1970: $0) }
    }

    // MARK: - Badge Management

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Helper

    func timeString(for components: DateComponents) -> String {
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }

    func dateComponents(from date: Date) -> DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: date)
    }

    func date(from components: DateComponents) -> Date {
        var fullComponents = components
        fullComponents.year = Calendar.current.component(.year, from: Date())
        fullComponents.month = Calendar.current.component(.month, from: Date())
        fullComponents.day = Calendar.current.component(.day, from: Date())
        return Calendar.current.date(from: fullComponents) ?? Date()
    }
}

// MARK: - Dictionary Extensions

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }

    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: compactMap { key, value in
            guard let newKey = transform(key) else { return nil }
            return (newKey, value)
        })
    }
}
