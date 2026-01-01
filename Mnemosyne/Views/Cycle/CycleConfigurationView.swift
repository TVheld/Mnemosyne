import SwiftUI

struct CycleConfigurationView: View {
    @Binding var isPresented: Bool
    @StateObject private var cycleManager = CycleManager.shared

    @State private var pillBrand: String = ""
    @State private var cycleLength: Int = 28
    @State private var stopWeekStart: Int = 22
    @State private var cycleStartDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                // Pill info section
                Section {
                    TextField("Pilmerk (optioneel)", text: $pillBrand)

                    Stepper("Cycluslengte: \(cycleLength) dagen", value: $cycleLength, in: 21...35)
                } header: {
                    Text("Pil informatie")
                } footer: {
                    Text("De meeste pillen hebben een cyclus van 28 dagen.")
                }

                // Timing section
                Section {
                    Stepper("Stopweek begint op dag: \(stopWeekStart)", value: $stopWeekStart, in: 15...28)

                    HStack {
                        Text("Stopweek")
                        Spacer()
                        Text("Dag \(stopWeekStart) - \(cycleLength)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Stopweek")
                } footer: {
                    Text("Dit zijn de dagen waarop je geen pil slikt en meestal ongesteld wordt.")
                }

                // Start date section
                Section {
                    DatePicker(
                        "Dag 1 van huidige cyclus",
                        selection: $cycleStartDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "nl_NL"))
                } header: {
                    Text("Startdatum")
                } footer: {
                    Text("De eerste dag van je huidige pilstrip (of de dag waarop je begon na de stopweek).")
                }

                // Preview section
                Section {
                    HStack {
                        Text("Voorspelde ongesteldheid")
                        Spacer()
                        Text(predictedPeriodString())
                            .foregroundStyle(.pink)
                    }
                } header: {
                    Text("Voorspelling")
                }
            }
            .navigationTitle("Cyclus configuratie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleren") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bewaar") {
                        saveConfiguration()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadExistingConfiguration()
            }
        }
    }

    private func loadExistingConfiguration() {
        if let config = cycleManager.configuration {
            pillBrand = config.pillBrand ?? ""
            cycleLength = Int(config.cycleLength)
            stopWeekStart = Int(config.stopWeekStart)
            if let startDate = config.currentCycleStartDate {
                cycleStartDate = startDate
            }
        }
    }

    private func saveConfiguration() {
        cycleManager.saveConfiguration(
            pillBrand: pillBrand,
            cycleLength: cycleLength,
            stopWeekStart: stopWeekStart,
            stopWeekEnd: cycleLength,
            cycleStartDate: cycleStartDate
        )
        isPresented = false
    }

    private func predictedPeriodString() -> String {
        let calendar = Calendar.current
        let daysUntilStopWeek = stopWeekStart - 1

        guard let periodStart = calendar.date(byAdding: .day, value: daysUntilStopWeek, to: cycleStartDate) else {
            return "-"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMMM"

        return formatter.string(from: periodStart)
    }
}

#Preview {
    CycleConfigurationView(isPresented: .constant(true))
}
