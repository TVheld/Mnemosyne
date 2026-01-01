import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MoodEntryView()
                .tabItem {
                    Label("Vandaag", systemImage: "sun.max.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("Geschiedenis", systemImage: "clock.fill")
                }
                .tag(1)

            InsightsView()
                .tabItem {
                    Label("Inzichten", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            CycleView()
                .tabItem {
                    Label("Cyclus", systemImage: "calendar.circle")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Instellingen", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.pink)
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Binnenkort beschikbaar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
