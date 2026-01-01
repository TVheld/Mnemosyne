import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var currentPage = 0

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.3),
                    Color.orange.opacity(0.2),
                    Color.yellow.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.pink : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.top, 20)

                // Content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)

                    FeaturesPage()
                        .tag(1)

                    NotificationPermissionPage(notificationManager: notificationManager)
                        .tag(2)

                    HealthKitPermissionPage(
                        healthKitManager: healthKitManager,
                        onComplete: completeOnboarding
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button(action: previousPage) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Terug")
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if currentPage < totalPages - 1 {
                        Button(action: nextPage) {
                            HStack {
                                Text("Volgende")
                                Image(systemName: "chevron.right")
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.pink)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }

    private func nextPage() {
        withAnimation {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
    }

    private func previousPage() {
        withAnimation {
            currentPage = max(currentPage - 1, 0)
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App icon/logo
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.pink)
                .padding()
                .background(
                    Circle()
                        .fill(Color.pink.opacity(0.1))
                        .frame(width: 150, height: 150)
                )

            VStack(spacing: 12) {
                Text("Welkom bij")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("Mnemosyne")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.pink)

                Text("Godin van herinnering")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            Text("Ontdek patronen in je stemming en cyclus")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Features Page

struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Wat kun je doen?")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "face.smiling",
                    color: .orange,
                    title: "Stemming vastleggen",
                    description: "Log je stemming met een simpele slider"
                )

                FeatureRow(
                    icon: "tag",
                    color: .blue,
                    title: "Context toevoegen",
                    description: "Voeg tags toe zoals 'goed geslapen' of 'stress'"
                )

                FeatureRow(
                    icon: "calendar.circle",
                    color: .pink,
                    title: "Cyclus bijhouden",
                    description: "Track je menstruatiecyclus en zie patronen"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    title: "Inzichten ontdekken",
                    description: "Bekijk correlaties en trends over tijd"
                )
            }
            .padding(.horizontal, 30)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Notification Permission Page

struct NotificationPermissionPage: View {
    @ObservedObject var notificationManager: NotificationManager

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 70))
                .foregroundStyle(.orange)
                .padding()
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 140, height: 140)
                )

            VStack(spacing: 12) {
                Text("Herinneringen")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Ontvang 3x per dag een herinnering om je stemming vast te leggen")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if notificationManager.isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Notificaties zijn ingeschakeld")
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button(action: requestNotifications) {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Schakel notificaties in")
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)

                Button("Later instellen") {
                    // Skip - do nothing
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    private func requestNotifications() {
        Task {
            await notificationManager.requestAuthorization()
        }
    }
}

// MARK: - HealthKit Permission Page

struct HealthKitPermissionPage: View {
    @ObservedObject var healthKitManager: HealthKitManager
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 70))
                .foregroundStyle(.red)
                .padding()
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 140, height: 140)
                )

            VStack(spacing: 12) {
                Text("Apple Health")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Synchroniseer je stemmingsdata met Apple Health voor een compleet overzicht")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if healthKitManager.isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("HealthKit is verbonden")
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if healthKitManager.isHealthKitAvailable {
                Button(action: requestHealthKit) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Verbind met Apple Health")
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            } else {
                Text("HealthKit is niet beschikbaar op dit apparaat")
                    .foregroundStyle(.secondary)
            }

            Button(action: onComplete) {
                HStack {
                    Text("Start met Mnemosyne")
                    Image(systemName: "arrow.right")
                }
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.pink)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()
        }
        .padding()
    }

    private func requestHealthKit() {
        Task {
            await healthKitManager.requestAuthorization()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
