import SwiftUI

struct CycleCalendarView: View {
    @Binding var selectedMonth: Date
    @StateObject private var cycleManager = CycleManager.shared

    private let calendar = Calendar.current
    private let daysOfWeek = ["Ma", "Di", "Wo", "Do", "Vr", "Za", "Zo"]

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)

            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = daysInMonth()
            let flowHistory = cycleManager.getFlowHistory(forMonth: selectedMonth)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    if let day = day {
                        CalendarDayView(
                            date: day,
                            isToday: calendar.isDateInToday(day),
                            isPeriodDay: cycleManager.isPeriodDay(day),
                            isPMSDay: cycleManager.isPMSDay(day),
                            flow: flowHistory[calendar.startOfDay(for: day)]
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }

            // Legend
            legend
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth).capitalized
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        // Get the weekday of the first day (1 = Sunday, 2 = Monday, etc.)
        var firstWeekday = calendar.component(.weekday, from: startOfMonth)
        // Convert to Monday-based (0 = Monday)
        firstWeekday = (firstWeekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private var legend: some View {
        HStack(spacing: 16) {
            LegendItem(color: .pink, text: "Ongesteld")
            LegendItem(color: .purple.opacity(0.5), text: "PMS")
            LegendItem(color: .blue, text: "Vandaag")
        }
        .font(.caption)
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let isToday: Bool
    let isPeriodDay: Bool
    let isPMSDay: Bool
    let flow: String?

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .clipShape(Circle())

            // Day number
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(foregroundColor)

            // Flow indicator dot
            if let flow = flow, flow != Constants.MenstrualFlow.none.rawValue {
                Circle()
                    .fill(flowColor(for: flow))
                    .frame(width: 6, height: 6)
                    .offset(y: 12)
            }
        }
        .frame(height: 40)
    }

    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if isPeriodDay {
            return .pink.opacity(0.3)
        } else if isPMSDay {
            return .purple.opacity(0.2)
        } else {
            return .clear
        }
    }

    private var foregroundColor: Color {
        if isToday {
            return .white
        } else {
            return .primary
        }
    }

    private func flowColor(for flowString: String) -> Color {
        guard let flow = Constants.MenstrualFlow(rawValue: flowString) else { return .clear }
        switch flow {
        case .none: return .clear
        case .spotting: return .pink.opacity(0.5)
        case .light: return .pink.opacity(0.7)
        case .medium: return .pink
        case .heavy: return .red
        }
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    CycleCalendarView(selectedMonth: .constant(Date()))
}
