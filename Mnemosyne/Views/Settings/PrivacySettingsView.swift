import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasGivenHealthDataConsent") private var hasGivenHealthDataConsent = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false

    @State private var showingExportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPrivacyPolicy = false
    @State private var showingWithdrawConsent = false
    @State private var exportData: Data?

    private var consentDateString: String {
        if let date = UserDefaults.standard.object(forKey: "consentDate") as? Date {
            return date.formatted(date: .long, time: .shortened)
        }
        return "Onbekend"
    }

    var body: some View {
        List {
            // Consent status
            Section {
                HStack {
                    Label("Toestemming gegeven", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text(consentDateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button(action: { showingWithdrawConsent = true }) {
                    Label("Trek toestemming in", systemImage: "xmark.shield")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Toestemming")
            } footer: {
                Text("Je hebt toestemming gegeven voor het verwerken van je gezondheidsdata.")
            }

            // Data storage
            Section {
                HStack {
                    Label("Data opslag", systemImage: iCloudSyncEnabled ? "icloud.fill" : "iphone")
                    Spacer()
                    Text(iCloudSyncEnabled ? "iCloud" : "Alleen dit apparaat")
                        .foregroundStyle(.secondary)
                }

                if iCloudSyncEnabled {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("iCloud sync is ingeschakeld. Apple kan technisch gezien toegang hebben tot je data.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Opslag")
            } footer: {
                Text("Je kunt de opslaglocatie wijzigen tijdens de onboarding door deze te resetten in debug mode.")
            }

            // Data rights (AVG)
            Section {
                // Export data
                Button(action: exportUserData) {
                    Label("Exporteer mijn data", systemImage: "square.and.arrow.up")
                }

                // View data
                NavigationLink {
                    DataOverviewView()
                } label: {
                    Label("Bekijk mijn data", systemImage: "eye")
                }

                // Delete data
                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label("Verwijder al mijn data", systemImage: "trash")
                }
            } header: {
                Text("Jouw rechten (AVG)")
            } footer: {
                Text("Je hebt het recht om je data in te zien, te exporteren en te verwijderen.")
            }

            // Privacy policy
            Section {
                Button(action: { showingPrivacyPolicy = true }) {
                    Label("Bekijk privacybeleid", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("Privacy")
        .sheet(isPresented: $showingExportSheet) {
            if let data = exportData {
                ShareSheet(items: [data])
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("Data verwijderen?", isPresented: $showingDeleteConfirmation) {
            Button("Annuleren", role: .cancel) { }
            Button("Verwijder alles", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("Dit verwijdert al je stemmingsdata en cyclusinstellingen. Dit kan niet ongedaan worden gemaakt.")
        }
        .alert("Toestemming intrekken?", isPresented: $showingWithdrawConsent) {
            Button("Annuleren", role: .cancel) { }
            Button("Intrekken en verwijderen", role: .destructive) {
                withdrawConsent()
            }
        } message: {
            Text("Als je je toestemming intrekt, wordt al je data verwijderd en moet je de app opnieuw instellen.")
        }
    }

    private func exportUserData() {
        if let data = PersistenceController.shared.exportAllData() {
            exportData = data
            showingExportSheet = true
        }
    }

    private func deleteAllData() {
        PersistenceController.shared.deleteAllData()
    }

    private func withdrawConsent() {
        // Delete all data
        PersistenceController.shared.deleteAllData()

        // Reset consent in UserDefaults
        hasGivenHealthDataConsent = false
        UserDefaults.standard.removeObject(forKey: "consentDate")
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        // Force app restart would be ideal here
        dismiss()
    }
}

// MARK: - Data Overview View

struct DataOverviewView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<MoodEntry>

    @StateObject private var cycleManager = CycleManager.shared

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Totaal mood entries")
                    Spacer()
                    Text("\(entries.count)")
                        .foregroundStyle(.secondary)
                }

                if let oldest = entries.last?.timestamp {
                    HStack {
                        Text("Oudste entry")
                        Spacer()
                        Text(oldest.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                }

                if let newest = entries.first?.timestamp {
                    HStack {
                        Text("Nieuwste entry")
                        Spacer()
                        Text(newest.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Stemmingsdata")
            }

            Section {
                if cycleManager.configuration != nil {
                    HStack {
                        Text("Cyclus geconfigureerd")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }

                    if let brand = cycleManager.configuration?.pillBrand, !brand.isEmpty {
                        HStack {
                            Text("Pilmerk")
                            Spacer()
                            Text(brand)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Geen cyclus geconfigureerd")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Cyclusdata")
            }

            Section {
                ForEach(entries.prefix(10)) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "-")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f", entry.score))
                                .fontWeight(.semibold)
                                .foregroundStyle(entry.score > 0 ? .green : (entry.score < 0 ? .red : .secondary))
                        }

                        if let tags = entry.tags, !tags.isEmpty {
                            Text(tags.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Recente entries (max 10)")
            }
        }
        .navigationTitle("Mijn Data")
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
