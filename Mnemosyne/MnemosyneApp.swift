import SwiftUI

@main
struct MnemosyneApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
