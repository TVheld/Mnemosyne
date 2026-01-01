import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var showingTimePicker: Int? = nil
    @State private var debugModeEnabled = false
    @State private var shakeCount = 0
    @State private var showingSyncQueue = false

    var body: some View {
        NavigationStack {
            List {
                // Notificaties sectie
                notificationSection

                // Sync status sectie (placeholder voor Phase 2)
                syncSection

                // Debug sectie (verborgen tenzij debug mode)
                if debugModeEnabled {
                    debugSection
                }

                // Over sectie
                aboutSection
            }
            .navigationTitle("Instellingen")
            .onShake {
                handleShake()
            }
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section {
            // Notification status
            HStack {
                Label("Notificaties", systemImage: "bell.fill")
                Spacer()
                if notificationManager.isAuthorized {
                    Text("Aan")
                        .foregroundStyle(.green)
                } else {
                    Button("Inschakelen") {
                        Task {
                            await notificationManager.requestAuthorization()
                        }
                    }
                }
            }

            // Notification times
            ForEach(0..<3, id: \.self) { index in
                notificationTimeRow(index: index)
            }

            // Reminder interval (grayed out)
            HStack {
                Label("Herinnering interval", systemImage: "timer")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("15 minuten")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Herinneringen")
        } footer: {
            Text("Je ontvangt 3 keer per dag een herinnering om je stemming vast te leggen.")
        }
    }

    private func notificationTimeRow(index: Int) -> some View {
        HStack {
            Text("Herinnering \(index + 1)")

            Spacer()

            Button(action: { showingTimePicker = index }) {
                Text(notificationManager.timeString(for: notificationManager.notificationTimes[index]))
                    .foregroundStyle(.blue)
            }
        }
        .sheet(isPresented: Binding(
            get: { showingTimePicker == index },
            set: { if !$0 { showingTimePicker = nil } }
        )) {
            TimePickerSheet(
                time: Binding(
                    get: {
                        notificationManager.date(from: notificationManager.notificationTimes[index])
                    },
                    set: { newDate in
                        let components = notificationManager.dateComponents(from: newDate)
                        notificationManager.updateNotificationTime(at: index, to: components)
                    }
                ),
                onDismiss: { showingTimePicker = nil }
            )
            .presentationDetents([.height(300)])
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        Section {
            // CloudKit status
            HStack {
                Label("iCloud Sync", systemImage: "icloud.fill")
                Spacer()
                if cloudKitManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if cloudKitManager.isCloudKitAvailable {
                    if cloudKitManager.pendingSyncCount > 0 {
                        Text("\(cloudKitManager.pendingSyncCount) wachtend")
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("Niet beschikbaar")
                        .foregroundStyle(.secondary)
                }
            }

            if let lastSync = cloudKitManager.lastSyncDate {
                HStack {
                    Text("Laatste sync")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(lastSync.displayString)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            // Force sync button
            Button(action: {
                Task {
                    await cloudKitManager.forceSync()
                }
            }) {
                HStack {
                    Label("Forceer sync", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    if cloudKitManager.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(cloudKitManager.isSyncing || !cloudKitManager.isCloudKitAvailable)

            // HealthKit status
            HStack {
                Label("HealthKit", systemImage: "heart.fill")
                    .foregroundStyle(.pink)
                Spacer()
                if healthKitManager.isAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if healthKitManager.isHealthKitAvailable {
                    Button("Activeren") {
                        Task {
                            await healthKitManager.requestAuthorization()
                        }
                    }
                } else {
                    Text("Niet beschikbaar")
                        .foregroundStyle(.secondary)
                }
            }

            if healthKitManager.isAuthorized {
                Button(action: {
                    Task {
                        await healthKitManager.syncAllUnsynced()
                    }
                }) {
                    Label("Sync naar HealthKit", systemImage: "arrow.up.heart.fill")
                }
            }
        } header: {
            Text("Synchronisatie")
        } footer: {
            if let error = cloudKitManager.syncError {
                Text("CloudKit: \(error)")
                    .foregroundStyle(.red)
            } else if let error = healthKitManager.authorizationError {
                Text("HealthKit: \(error)")
                    .foregroundStyle(.red)
            } else {
                Text("Je data wordt automatisch gesynchroniseerd met iCloud en optioneel met Apple Health.")
            }
        }
    }

    // MARK: - Debug Section

    private var debugSection: some View {
        Section {
            // Data management
            Button(action: seedTestData) {
                Label("Seed test data (90 dagen)", systemImage: "wand.and.stars")
            }

            Button(role: .destructive, action: clearAllData) {
                Label("Wis alle mood data", systemImage: "trash")
            }

            Button(role: .destructive, action: clearCycleData) {
                Label("Wis cyclus configuratie", systemImage: "calendar.badge.minus")
            }

            // Sync options
            Button(action: {
                Task {
                    await cloudKitManager.forceSync()
                }
            }) {
                Label("Force CloudKit Sync", systemImage: "icloud.and.arrow.up")
            }

            Button(action: { showingSyncQueue = true }) {
                Label("View Sync Queue", systemImage: "list.bullet.rectangle")
            }
            .sheet(isPresented: $showingSyncQueue) {
                SyncQueueView()
            }

            // Onboarding reset
            Button(action: resetOnboarding) {
                Label("Reset onboarding", systemImage: "arrow.counterclockwise")
            }

            // Status info
            HStack {
                Label("CloudKit", systemImage: "icloud")
                Spacer()
                Text(cloudKitManager.isCloudKitAvailable ? "Beschikbaar" : "Niet beschikbaar")
                    .foregroundStyle(cloudKitManager.isCloudKitAvailable ? .green : .red)
            }

            HStack {
                Label("HealthKit", systemImage: "heart")
                Spacer()
                Text(healthKitManager.isAuthorized ? "Geautoriseerd" : "Niet geautoriseerd")
                    .foregroundStyle(healthKitManager.isAuthorized ? .green : .orange)
            }

            HStack {
                Label("Notificaties", systemImage: "bell")
                Spacer()
                Text(notificationManager.isAuthorized ? "Aan" : "Uit")
                    .foregroundStyle(notificationManager.isAuthorized ? .green : .orange)
            }

            // Entry count
            HStack {
                Label("Totaal entries", systemImage: "number")
                Spacer()
                Text("\(getTotalEntryCount())")
                    .foregroundStyle(.secondary)
            }

            // Disable debug mode
            Button(action: { debugModeEnabled = false }) {
                Label("Sluit debug mode", systemImage: "xmark.circle")
                    .foregroundStyle(.red)
            }
        } header: {
            HStack {
                Text("Debug")
                Spacer()
                Text("v\(Bundle.main.appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Debug mode actief. Schud 5x om te activeren/deactiveren.")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Versie")
                Spacer()
                Text("\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Ontwikkelaar")
                Spacer()
                Text("Voor Anne")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Met liefde gemaakt")
                Spacer()
                Text("\u{2665}")
                    .foregroundStyle(.pink)
            }
        } header: {
            Text("Over Mnemosyne")
        } footer: {
            Text("Mnemosyne - Godin van herinnering. Track je stemming, ontdek patronen.")
        }
    }

    // MARK: - Debug Mode

    private func handleShake() {
        shakeCount += 1
        if shakeCount >= 5 {
            debugModeEnabled = true
            shakeCount = 0

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        // Reset count na 2 seconden
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if shakeCount < 5 {
                shakeCount = 0
            }
        }
    }

    // MARK: - Debug Actions

    private func seedTestData() {
        let calendar = Calendar.current

        for day in 0..<90 {
            // 1-3 entries per dag
            let entriesPerDay = Int.random(in: 1...3)

            for entry in 0..<entriesPerDay {
                let date = calendar.date(byAdding: .day, value: -day, to: Date()) ?? Date()
                let hour = [8, 14, 20][entry % 3]
                let entryDate = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) ?? date

                let score = Double.random(in: -5...5)
                let tagCount = Int.random(in: 0...4)
                let allTags = Constants.Tags.all.shuffled()
                let selectedTags = Array(allTags.prefix(tagCount))

                let moodEntry = MoodEntry(context: PersistenceController.shared.container.viewContext)
                moodEntry.id = UUID()
                moodEntry.timestamp = entryDate
                moodEntry.score = score
                moodEntry.tags = selectedTags
                moodEntry.lastModified = Date()
            }
        }

        PersistenceController.shared.save()
    }

    private func clearAllData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = MoodEntry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try PersistenceController.shared.container.viewContext.execute(deleteRequest)
            PersistenceController.shared.save()
        } catch {
            print("Error clearing data: \(error)")
        }
    }

    private func clearCycleData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CycleConfiguration.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try PersistenceController.shared.container.viewContext.execute(deleteRequest)
            PersistenceController.shared.save()
            CycleManager.shared.loadConfiguration()
        } catch {
            print("Error clearing cycle data: \(error)")
        }
    }

    private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func getTotalEntryCount() -> Int {
        let fetchRequest: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        do {
            return try PersistenceController.shared.container.viewContext.count(for: fetchRequest)
        } catch {
            return 0
        }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var time: Date
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            DatePicker(
                "Kies een tijd",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .navigationTitle("Herinnering tijd")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gereed") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Shake Gesture

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}

// MARK: - Sync Queue View (Debug)

struct SyncQueueView: View {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                let queueItems = cloudKitManager.getSyncQueueInfo()

                if queueItems.isEmpty {
                    ContentUnavailableView(
                        "Sync Queue Leeg",
                        systemImage: "checkmark.circle",
                        description: Text("Alle data is gesynchroniseerd")
                    )
                } else {
                    ForEach(queueItems.indices, id: \.self) { index in
                        let item = queueItems[index]
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.entityType)
                                    .font(.headline)
                                Text(item.operation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.date.displayString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Sync Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gereed") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
