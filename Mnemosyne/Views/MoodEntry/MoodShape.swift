import SwiftUI

struct MoodShape: View {
    let moodScore: Double
    @State private var animationPhase: Double = 0

    // Normalized score van 0 tot 1
    private var normalizedScore: Double {
        (moodScore - Constants.Mood.minScore) / (Constants.Mood.maxScore - Constants.Mood.minScore)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let baseRadius = min(size.width, size.height) / 2 * 0.8
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Teken de hoofdvorm
                let path = createMoodPath(
                    center: center,
                    baseRadius: baseRadius,
                    time: time
                )

                // Gradient vulling op basis van stemming
                let colors = Color.moodColors(for: moodScore)
                let gradient = Gradient(colors: colors)

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: center.x - baseRadius, y: center.y - baseRadius),
                        endPoint: CGPoint(x: center.x + baseRadius, y: center.y + baseRadius)
                    )
                )

                // Voeg zachte schaduw toe
                context.addFilter(.shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10))

                // Teken binnenste highlight
                let innerPath = createMoodPath(
                    center: center,
                    baseRadius: baseRadius * 0.3,
                    time: time * 0.8
                )

                context.fill(
                    innerPath,
                    with: .color(.white.opacity(0.3))
                )
            }
        }
        .animation(.spring(response: Constants.Design.animationDuration, dampingFraction: Constants.Design.springDamping), value: moodScore)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stemmingsindicator")
        .accessibilityValue(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        switch moodScore {
        case 3...5: return "Zeer positieve stemming, bloem-achtige vorm"
        case 1..<3: return "Positieve stemming"
        case -1..<1: return "Neutrale stemming"
        case -3..<(-1): return "Negatieve stemming"
        default: return "Zeer negatieve stemming, sombere vorm"
        }
    }

    private func createMoodPath(center: CGPoint, baseRadius: Double, time: Double) -> Path {
        var path = Path()

        // Aantal punten voor de vorm - meer punten voor vloeiendere vormen
        let pointCount = 120

        // Vormparameters gebaseerd op stemming
        let blobiness = lerp(from: 0.15, to: 0.05, progress: normalizedScore) // Meer blob bij negatief
        let petalCount = lerp(from: 3, to: 8, progress: normalizedScore) // Meer "bloemblaadjes" bij positief
        let petalDepth = lerp(from: 0.0, to: 0.2, progress: normalizedScore) // Diepere petals bij positief
        let animationSpeed = lerp(from: 0.3, to: 0.8, progress: normalizedScore)

        for i in 0..<pointCount {
            let angle = (Double(i) / Double(pointCount)) * 2 * .pi

            // Basis blob beweging
            var radius = baseRadius

            // Organische blob vorm (meer uitgesproken bij negatieve stemming)
            radius += baseRadius * blobiness * sin(3 * angle + time * animationSpeed)
            radius += baseRadius * blobiness * 0.5 * cos(5 * angle - time * animationSpeed * 0.7)

            // Bloemblaadjes effect (meer uitgesproken bij positieve stemming)
            if normalizedScore > 0.5 {
                let petalEffect = sin(petalCount * angle) * petalDepth * baseRadius
                radius += petalEffect * (normalizedScore - 0.5) * 2
            }

            // Zachte pulsering
            let pulse = 1.0 + 0.02 * sin(time * 2)
            radius *= pulse

            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }

    private func lerp(from: Double, to: Double, progress: Double) -> Double {
        from + (to - from) * progress
    }
}

// MARK: - Mood Label

struct MoodLabel: View {
    let moodScore: Double

    private var label: String {
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

    var body: some View {
        Text(label)
            .font(.title2)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: label)
    }
}

#Preview {
    VStack(spacing: 40) {
        MoodShape(moodScore: -4.0)
            .frame(width: 200, height: 200)

        MoodShape(moodScore: 0.0)
            .frame(width: 200, height: 200)

        MoodShape(moodScore: 4.0)
            .frame(width: 200, height: 200)
    }
    .padding()
}
