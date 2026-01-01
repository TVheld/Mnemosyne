import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<MoodEntry>

    @State private var selectedEntry: MoodEntry?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationTitle("Geschiedenis")
            .sheet(item: $selectedEntry) { entry in
                MoodEntryDetailView(entry: entry)
            }
        }
    }

    // MARK: - Entry List

    private var entryList: some View {
        List {
            ForEach(groupedEntries, id: \.key) { date, dayEntries in
                Section {
                    ForEach(dayEntries) { entry in
                        MoodEntryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntry = entry
                            }
                    }
                    .onDelete { indexSet in
                        deleteEntries(at: indexSet, from: dayEntries)
                    }
                } header: {
                    Text(sectionTitle(for: date))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Nog geen entries")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Begin met het vastleggen van je stemming")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Grouped Entries

    private var groupedEntries: [(key: Date, value: [MoodEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp ?? Date())
        }
        return grouped.sorted { $0.key > $1.key }
    }

    // MARK: - Helpers

    private func sectionTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Vandaag"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Gisteren"
        } else {
            return date.dateString
        }
    }

    private func deleteEntries(at offsets: IndexSet, from dayEntries: [MoodEntry]) {
        for index in offsets {
            let entry = dayEntries[index]
            viewContext.delete(entry)
        }

        do {
            try viewContext.save()
        } catch {
            print("Delete error: \(error)")
        }
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
