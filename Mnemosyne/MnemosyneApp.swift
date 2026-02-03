import SwiftUI

@main
struct MnemosyneApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var needsRestart = false

    var body: some Scene {
        WindowGroup {
            if needsRestart {
                // Show restart required screen
                RestartRequiredView()
            } else if hasCompletedOnboarding {
                ContentView()
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            } else {
                OnboardingView(
                    isOnboardingComplete: $hasCompletedOnboarding,
                    onLocalOnlySelected: {
                        // User chose local-only on fresh install - need restart
                        // to reinitialize PersistenceController without CloudKit
                        needsRestart = true
                    }
                )
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
    }
}

// MARK: - Restart Required View

struct RestartRequiredView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("Herstart vereist")
                .font(.title)
                .fontWeight(.bold)

            Text("Je hebt gekozen voor lokale opslag. Sluit de app volledig af en open hem opnieuw om deze instelling te activeren.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 8) {
                Text("Hoe de app te sluiten:")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Veeg omhoog vanaf de onderkant van het scherm en veeg de app weg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}
