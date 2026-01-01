import SwiftUI
import Combine

@MainActor
class MoodEntryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var moodScore: Double = 0.0
    @Published var selectedTags: Set<String> = []
    @Published var note: String = ""
    @Published var menstrualFlow: String? = nil

    @Published var currentStep: EntryStep = .mood
    @Published var showConfirmation = false
    @Published var todayEntries: [MoodEntry] = []

    // MARK: - Dependencies

    private let repository: MoodEntryRepository
    private let cycleManager = CycleManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Entry Steps

    enum EntryStep {
        case mood
        case tags
        case flow      // Only shown during stop week
        case confirmation
    }

    // MARK: - Computed Properties

    var moodLabel: String {
        switch moodScore {
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

    var canProceed: Bool {
        true // Mood score is altijd geldig binnen de range
    }

    var todayEntryCount: Int {
        todayEntries.count
    }

    var streakCount: Int {
        repository.streak()
    }

    var shouldShowFlowTracking: Bool {
        cycleManager.isConfigured && cycleManager.isInStopWeek
    }

    // MARK: - Init

    init(repository: MoodEntryRepository = MoodEntryRepository()) {
        self.repository = repository
        loadTodayEntries()
    }

    // MARK: - Actions

    func loadTodayEntries() {
        todayEntries = repository.fetchTodayEntries()
    }

    func proceedToTags() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentStep = .tags
        }
    }

    func proceedFromTags() {
        if shouldShowFlowTracking {
            proceedToFlow()
        } else {
            proceedToConfirmation()
        }
    }

    func proceedToFlow() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentStep = .flow
        }
    }

    func proceedToConfirmation() {
        saveEntry()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentStep = .confirmation
            showConfirmation = true
        }
    }

    func skipTags() {
        if shouldShowFlowTracking {
            proceedToFlow()
        } else {
            proceedToConfirmation()
        }
    }

    func skipFlow() {
        proceedToConfirmation()
    }

    func saveEntry() {
        let entry = repository.createEntry(
            score: moodScore,
            tags: Array(selectedTags),
            note: note.isEmpty ? nil : note,
            menstrualFlow: menstrualFlow
        )
        loadTodayEntries()

        // Mark notification as completed for current time slot
        NotificationManager.shared.markEntryCompleted()

        // Sync to HealthKit in background
        Task {
            await HealthKitManager.shared.syncEntry(entry)
        }
    }

    func reset() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            moodScore = 0.0
            selectedTags = []
            note = ""
            menstrualFlow = nil
            currentStep = .mood
            showConfirmation = false
        }
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func goBack() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            switch currentStep {
            case .mood:
                break
            case .tags:
                currentStep = .mood
            case .flow:
                currentStep = .tags
            case .confirmation:
                if shouldShowFlowTracking {
                    currentStep = .flow
                } else {
                    currentStep = .tags
                }
            }
        }
    }
}
