import SwiftUI

struct MoodEntryRow: View {
    let entry: MoodEntry

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
        HStack(spacing: 12) {
            // Mood indicator
            moodIndicator

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Tijd en label
                HStack {
                    Text(timestamp.timeString)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(moodLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Tags (als aanwezig)
                if !tags.isEmpty {
                    tagsView
                }

                // Notitie (als aanwezig)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Score indicator
            scoreIndicator
        }
        .padding(.vertical, 4)
    }

    // MARK: - Mood Indicator

    private var moodIndicator: some View {
        Circle()
            .fill(Color.moodGradient(for: moodScore))
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
    }

    // MARK: - Tags View

    private var tagsView: some View {
        HStack(spacing: 4) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            if tags.count > 3 {
                Text("+\(tags.count - 3)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Score Indicator

    private var scoreIndicator: some View {
        Text(String(format: "%.1f", moodScore))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .monospacedDigit()
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

#Preview {
    List {
        MoodEntryRow(entry: {
            let entry = MoodEntry(context: PersistenceController.preview.container.viewContext)
            entry.id = UUID()
            entry.timestamp = Date()
            entry.score = 3.5
            entry.tags = ["Energiek", "Productieve dag", "Goed geslapen"]
            entry.note = "Vandaag was een goede dag!"
            return entry
        }())

        MoodEntryRow(entry: {
            let entry = MoodEntry(context: PersistenceController.preview.container.viewContext)
            entry.id = UUID()
            entry.timestamp = Date().addingTimeInterval(-3600)
            entry.score = -2.0
            entry.tags = ["Hoofdpijn", "Moe/uitgeput"]
            return entry
        }())

        MoodEntryRow(entry: {
            let entry = MoodEntry(context: PersistenceController.preview.container.viewContext)
            entry.id = UUID()
            entry.timestamp = Date().addingTimeInterval(-7200)
            entry.score = 0.0
            entry.tags = []
            return entry
        }())
    }
    .listStyle(.insetGrouped)
}
