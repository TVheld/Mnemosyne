import SwiftUI

struct CycleView: View {
    @StateObject private var cycleManager = CycleManager.shared
    @State private var showingConfiguration = false
    @State private var showingPillForgotten = false
    @State private var selectedMonth = Date()

    var body: some View {
        NavigationStack {
            Group {
                if cycleManager.isConfigured {
                    configuredView
                } else {
                    notConfiguredView
                }
            }
            .navigationTitle("Cyclus")
            .toolbar {
                if cycleManager.isConfigured {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(action: { showingConfiguration = true }) {
                                Label("Cyclus aanpassen", systemImage: "gearshape")
                            }
                            Button(action: { showingPillForgotten = true }) {
                                Label("Pil vergeten", systemImage: "exclamationmark.triangle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingConfiguration) {
                CycleConfigurationView(isPresented: $showingConfiguration)
            }
            .sheet(isPresented: $showingPillForgotten) {
                PillForgottenView(isPresented: $showingPillForgotten)
            }
        }
    }

    // MARK: - Configured View

    private var configuredView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current status card
                currentStatusCard

                // Calendar
                cycleCalendar

                // Predictions
                predictionsSection

                // Statistics
                statisticsSection
            }
            .padding()
        }
    }

    // MARK: - Current Status Card

    private var currentStatusCard: some View {
        VStack(spacing: 16) {
            // Cycle day indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dag \(cycleManager.currentCycleDay)")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("van je cyclus")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status indicator
                statusBadge
            }

            Divider()

            // Period info
            if cycleManager.isInStopWeek {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.pink)
                    Text("Je bent nu ongesteld")
                        .font(.subheadline)
                    Spacer()
                }
            } else if let daysUntil = cycleManager.daysUntilPeriod {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.pink)
                    Text("Nog \(daysUntil) dagen tot ongesteldheid")
                        .font(.subheadline)
                    Spacer()
                }
            }

            // Pill brand
            if let brand = cycleManager.configuration?.pillBrand, !brand.isEmpty {
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(.blue)
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(statusBackgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusBadge: some View {
        Group {
            if cycleManager.isInStopWeek {
                Text("Ongesteld")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.pink)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            } else if cycleManager.isPMSPeriod {
                Text("PMS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.purple)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            } else {
                Text("Actief")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private var statusBackgroundGradient: some ShapeStyle {
        if cycleManager.isInStopWeek {
            return LinearGradient(
                colors: [.pink.opacity(0.1), .pink.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if cycleManager.isPMSPeriod {
            return LinearGradient(
                colors: [.purple.opacity(0.1), .purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.green.opacity(0.1), .green.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Calendar

    private var cycleCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kalender")
                .font(.headline)

            CycleCalendarView(selectedMonth: $selectedMonth)
        }
    }

    // MARK: - Predictions

    private var predictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voorspellingen")
                .font(.headline)

            let predictions = cycleManager.predictedPeriodDates(count: 3)

            ForEach(predictions.indices, id: \.self) { index in
                let prediction = predictions[index]
                HStack {
                    Circle()
                        .fill(index == 0 ? .pink : .pink.opacity(0.5))
                        .frame(width: 8, height: 8)

                    Text(formatPrediction(prediction))
                        .font(.subheadline)

                    Spacer()

                    if index == 0 {
                        Text("Volgende")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatPrediction(_ interval: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMM"

        let start = formatter.string(from: interval.start)
        let end = formatter.string(from: interval.end)
        return "\(start) - \(end)"
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistieken")
                .font(.headline)

            HStack(spacing: 16) {
                StatCard(
                    title: "Cycluslengte",
                    value: "\(cycleManager.configuration?.cycleLength ?? 28)",
                    unit: "dagen"
                )

                StatCard(
                    title: "Stopweek",
                    value: "Dag \(cycleManager.configuration?.stopWeekStart ?? 22)-\(cycleManager.configuration?.stopWeekEnd ?? 28)",
                    unit: ""
                )
            }
        }
    }

    // MARK: - Not Configured View

    private var notConfiguredView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.pink)

            Text("Configureer je cyclus")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Stel je menstruatiecyclus in om voorspellingen te krijgen en patronen te ontdekken.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingConfiguration = true }) {
                Text("Configureren")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CycleView()
}
