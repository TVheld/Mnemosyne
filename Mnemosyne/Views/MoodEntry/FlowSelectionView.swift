import SwiftUI

struct FlowSelectionView: View {
    @Binding var selectedFlow: String?
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onBack: () -> Void

    private let flowOptions = [
        FlowOption(value: Constants.MenstrualFlow.none.rawValue, icon: "circle", color: .gray),
        FlowOption(value: Constants.MenstrualFlow.spotting.rawValue, icon: "drop", color: .pink.opacity(0.5)),
        FlowOption(value: Constants.MenstrualFlow.light.rawValue, icon: "drop.fill", color: .pink.opacity(0.7)),
        FlowOption(value: Constants.MenstrualFlow.medium.rawValue, icon: "drop.fill", color: .pink),
        FlowOption(value: Constants.MenstrualFlow.heavy.rawValue, icon: "drop.fill", color: .red)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Spacer()

            // Flow options
            VStack(spacing: 16) {
                Text("Wat is je menstruatie flow vandaag?")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("Dit helpt bij het bijhouden van je cyclus")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Flow buttons
                VStack(spacing: 12) {
                    ForEach(flowOptions) { option in
                        FlowOptionButton(
                            option: option,
                            isSelected: selectedFlow == option.value,
                            action: { selectedFlow = option.value }
                        )
                    }
                }
                .padding(.top, 24)
            }
            .padding(.horizontal)

            Spacer()

            // Bottom buttons
            bottomButtons
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("Menstruatie")
                .font(.headline)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, Constants.Design.smallSpacing)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button(action: onContinue) {
                Text(selectedFlow == nil ? "Overslaan" : "Doorgaan")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selectedFlow == nil ? Color.secondary : Color.pink)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Design.cornerRadius))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

// MARK: - Flow Option

struct FlowOption: Identifiable {
    let id = UUID()
    let value: String
    let icon: String
    let color: Color
}

struct FlowOptionButton: View {
    let option: FlowOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: option.icon)
                    .font(.title3)
                    .foregroundStyle(option.color)
                    .frame(width: 30)

                Text(option.value)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.pink)
                }
            }
            .padding()
            .background(isSelected ? Color.pink.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FlowSelectionView(
        selectedFlow: .constant("Normaal"),
        onContinue: {},
        onSkip: {},
        onBack: {}
    )
}
