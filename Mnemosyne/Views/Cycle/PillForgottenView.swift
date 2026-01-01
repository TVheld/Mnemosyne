import SwiftUI

struct PillForgottenView: View {
    @Binding var isPresented: Bool
    @StateObject private var cycleManager = CycleManager.shared

    @State private var daysToShift: Int = 1
    @State private var shiftAllFuture: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Dagen vergeten: \(daysToShift)", value: $daysToShift, in: 1...7)
                } header: {
                    Text("Hoeveel dagen?")
                } footer: {
                    Text("Maximaal 7 dagen. Bij meer dan 7 dagen adviseren we om je cyclus volledig te resetten.")
                }

                Section {
                    Toggle("Verschuif hele toekomstige cyclus", isOn: $shiftAllFuture)
                } footer: {
                    if shiftAllFuture {
                        Text("Je hele cyclus wordt met \(daysToShift) dag(en) verschoven. Alle toekomstige voorspellingen worden aangepast.")
                    } else {
                        Text("Alleen deze cyclus wordt aangepast. Volgende cycli blijven op het originele schema.")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Huidige voorspelling")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let prediction = cycleManager.predictedPeriodDates(count: 1).first {
                            Text(formatPrediction(prediction))
                                .strikethrough()
                                .foregroundStyle(.secondary)
                        }

                        Text("Nieuwe voorspelling")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        Text(newPredictionString())
                            .foregroundStyle(.pink)
                            .fontWeight(.medium)
                    }
                } header: {
                    Text("Voorspelling wijziging")
                }
            }
            .navigationTitle("Pil vergeten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleren") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Toepassen") {
                        applyShift()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatPrediction(_ interval: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMM"

        return "\(formatter.string(from: interval.start)) - \(formatter.string(from: interval.end))"
    }

    private func newPredictionString() -> String {
        guard let prediction = cycleManager.predictedPeriodDates(count: 1).first else {
            return "-"
        }

        let calendar = Calendar.current
        let newStart = calendar.date(byAdding: .day, value: daysToShift, to: prediction.start)!
        let newEnd = calendar.date(byAdding: .day, value: daysToShift, to: prediction.end)!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMM"

        return "\(formatter.string(from: newStart)) - \(formatter.string(from: newEnd))"
    }

    private func applyShift() {
        cycleManager.shiftCycle(by: daysToShift, shiftAllFuture: shiftAllFuture)
        isPresented = false
    }
}

#Preview {
    PillForgottenView(isPresented: .constant(true))
}
