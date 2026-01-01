import SwiftUI

struct MoodEntryDetailView: View {
    let entry: MoodEntry
    @Environment(\.dismiss) private var dismiss

    private var moodScore: Double {
        entry.score
    }

    private var tags: [String] {
        entry.tags ?? []
    }

    private var timestamp: Date {
        entry.timestamp ?? Date()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Design.largeSpacing) {
                    // Header met gradient
                    headerSection

                    // Details
                    detailsSection

                    // Tags
                    if !tags.isEmpty {
                        tagsSection
                    }

                    // Notitie
                    if let note = entry.note, !note.isEmpty {
                        noteSection(note: note)
                    }

                    // Menstruatie flow (als aanwezig)
                    if let flow = entry.menstrualFlow, !flow.isEmpty {
                        menstrualFlowSection(flow: flow)
                    }

                    Spacer()
                }
            }
            .background(Color(.systemGroupedBackground))
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Constants.Design.spacing) {
            // Mood shape
            MoodShape(moodScore: moodScore)
                .frame(width: 150, height: 150)

            // Mood label
            Text(moodLabel)
                .font(.title)
                .fontWeight(.bold)

            // Score
            Text(String(format: "Score: %.1f", moodScore))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Design.largeSpacing)
        .background(Color.moodGradient(for: moodScore))
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(icon: "calendar", title: "Datum", value: timestamp.dateString)
            DetailRow(icon: "clock", title: "Tijd", value: timestamp.timeString)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
        .padding(.horizontal)
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Context")
                .font(.headline)
                .padding(.horizontal)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    let isPositive = Constants.Tags.positive.contains(tag)
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isPositive ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(isPositive ? .green : .orange)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
        .padding(.horizontal)
    }

    // MARK: - Note Section

    private func noteSection(note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notitie", systemImage: "note.text")
                .font(.headline)

            Text(note)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
        .padding(.horizontal)
    }

    // MARK: - Menstrual Flow Section

    private func menstrualFlowSection(flow: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Menstruatie flow", systemImage: "drop.fill")
                .font(.headline)
                .foregroundColor(.pink)

            Text(flow)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
        .padding(.horizontal)
    }

    // MARK: - Mood Label

    private var moodLabel: String {
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
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MoodEntryDetailView(entry: {
        let entry = MoodEntry(context: PersistenceController.preview.container.viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.score = 3.5
        entry.tags = ["Energiek", "Productieve dag", "Goed geslapen"]
        entry.note = "Vandaag was echt een goede dag. Ik heb veel gedaan en voel me energiek!"
        return entry
    }())
}
