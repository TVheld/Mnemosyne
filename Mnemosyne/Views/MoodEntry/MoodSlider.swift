import SwiftUI

struct MoodSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    @State private var isDragging = false
    @GestureState private var dragOffset: CGFloat = 0

    private let trackHeight: CGFloat = 8
    private let thumbSize: CGFloat = 32

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbPosition = normalizedValue * (width - thumbSize)

            ZStack(alignment: .leading) {
                // Track achtergrond
                trackBackground(width: width)

                // Gevulde track
                filledTrack(width: thumbPosition + thumbSize / 2)

                // Thumb
                thumb
                    .offset(x: thumbPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                isDragging = true
                                let newPosition = gesture.location.x - thumbSize / 2
                                let clampedPosition = max(0, min(width - thumbSize, newPosition))
                                let newValue = range.lowerBound + (clampedPosition / (width - thumbSize)) * (range.upperBound - range.lowerBound)
                                value = newValue

                                // Haptic feedback bij belangrijke punten
                                provideHapticFeedback(for: newValue)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
            .frame(height: thumbSize)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Stemming slider")
            .accessibilityValue(accessibilityValueText)
            .accessibilityHint("Veeg naar links of rechts om je stemming aan te passen")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    value = min(range.upperBound, value + 0.5)
                case .decrement:
                    value = max(range.lowerBound, value - 0.5)
                @unknown default:
                    break
                }
            }
        }
        .frame(height: thumbSize)
    }

    private var accessibilityValueText: String {
        let label = moodLabel(for: value)
        return "\(label), score \(String(format: "%.1f", value))"
    }

    private func moodLabel(for score: Double) -> String {
        switch score {
        case 3...5: return "Zeer aangenaam"
        case 1..<3: return "Aangenaam"
        case -1..<1: return "Neutraal"
        case -3..<(-1): return "Onaangenaam"
        default: return "Zeer onaangenaam"
        }
    }

    // MARK: - Components

    private func trackBackground(width: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.negativeGradientMiddle.opacity(0.5),
                        Color.neutralGradientMiddle.opacity(0.5),
                        Color.positiveGradientMiddle.opacity(0.5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: trackHeight)
            .frame(maxWidth: .infinity)
            .offset(y: (thumbSize - trackHeight) / 2)
    }

    private func filledTrack(width: CGFloat) -> some View {
        Capsule()
            .fill(Color.shapeColor(for: value))
            .frame(width: max(0, width), height: trackHeight)
            .offset(y: (thumbSize - trackHeight) / 2)
            .animation(.spring(response: 0.1, dampingFraction: 0.8), value: value)
    }

    private var thumb: some View {
        Circle()
            .fill(.white)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.2), radius: isDragging ? 8 : 4, x: 0, y: isDragging ? 4 : 2)
            .overlay(
                Circle()
                    .fill(Color.shapeColor(for: value))
                    .frame(width: thumbSize * 0.5, height: thumbSize * 0.5)
            )
            .scaleEffect(isDragging ? 1.2 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
    }

    // MARK: - Haptic Feedback

    @State private var lastHapticValue: Double?

    private func provideHapticFeedback(for newValue: Double) {
        let significantPoints: [Double] = [-5, -3, -1, 0, 1, 3, 5]
        let threshold = 0.3

        for point in significantPoints {
            let wasNear = lastHapticValue.map { abs($0 - point) < threshold } ?? false
            let isNear = abs(newValue - point) < threshold

            if isNear && !wasNear {
                let generator = UIImpactFeedbackGenerator(style: point == 0 ? .medium : .light)
                generator.impactOccurred()
                break
            }
        }

        lastHapticValue = newValue
    }
}

// MARK: - Slider Labels

struct SliderLabels: View {
    var body: some View {
        HStack {
            Text("ZEER ONAANGENAAM")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Spacer()

            Text("ZEER AANGENAAM")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var value: Double = 0

        var body: some View {
            VStack(spacing: 20) {
                Text("Score: \(value, specifier: "%.1f")")
                    .font(.headline)

                MoodSlider(value: $value, range: -5...5)
                    .padding(.horizontal)

                SliderLabels()
                    .padding(.horizontal)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
