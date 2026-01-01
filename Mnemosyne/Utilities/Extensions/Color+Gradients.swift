import SwiftUI

extension Color {
    // MARK: - Gradient Colors

    // Positieve stemming kleuren (warm)
    static let positiveGradientStart = Color(red: 1.0, green: 0.6, blue: 0.4)   // Oranje
    static let positiveGradientMiddle = Color(red: 1.0, green: 0.4, blue: 0.6)  // Roze
    static let positiveGradientEnd = Color(red: 1.0, green: 0.8, blue: 0.4)     // Geel

    // Neutrale stemming kleuren (zacht)
    static let neutralGradientStart = Color(red: 0.7, green: 0.8, blue: 0.9)    // Lichtblauw
    static let neutralGradientMiddle = Color(red: 0.85, green: 0.85, blue: 0.9) // Lichtgrijs
    static let neutralGradientEnd = Color(red: 0.8, green: 0.75, blue: 0.85)    // Lavendel

    // Negatieve stemming kleuren (koel)
    static let negativeGradientStart = Color(red: 0.4, green: 0.5, blue: 0.7)   // Blauw
    static let negativeGradientMiddle = Color(red: 0.5, green: 0.4, blue: 0.6)  // Paars
    static let negativeGradientEnd = Color(red: 0.5, green: 0.55, blue: 0.6)    // Grijs

    // MARK: - Gradient Functions

    static func moodGradient(for score: Double) -> LinearGradient {
        let colors = moodColors(for: score)
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func moodColors(for score: Double) -> [Color] {
        let normalizedScore = (score - Constants.Mood.minScore) / (Constants.Mood.maxScore - Constants.Mood.minScore)

        if normalizedScore < 0.4 {
            // Negatief
            let intensity = normalizedScore / 0.4
            return interpolateColors(
                from: [.negativeGradientStart, .negativeGradientMiddle, .negativeGradientEnd],
                to: [.neutralGradientStart, .neutralGradientMiddle, .neutralGradientEnd],
                progress: intensity
            )
        } else if normalizedScore > 0.6 {
            // Positief
            let intensity = (normalizedScore - 0.6) / 0.4
            return interpolateColors(
                from: [.neutralGradientStart, .neutralGradientMiddle, .neutralGradientEnd],
                to: [.positiveGradientStart, .positiveGradientMiddle, .positiveGradientEnd],
                progress: intensity
            )
        } else {
            // Neutraal
            return [.neutralGradientStart, .neutralGradientMiddle, .neutralGradientEnd]
        }
    }

    private static func interpolateColors(from: [Color], to: [Color], progress: Double) -> [Color] {
        zip(from, to).map { fromColor, toColor in
            interpolateColor(from: fromColor, to: toColor, progress: progress)
        }
    }

    private static func interpolateColor(from: Color, to: Color, progress: Double) -> Color {
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]

        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * progress
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * progress
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * progress

        return Color(red: r, green: g, blue: b)
    }

    // MARK: - Shape Colors

    static func shapeColor(for score: Double) -> Color {
        let normalizedScore = (score - Constants.Mood.minScore) / (Constants.Mood.maxScore - Constants.Mood.minScore)

        if normalizedScore < 0.4 {
            return .negativeGradientMiddle
        } else if normalizedScore > 0.6 {
            return .positiveGradientMiddle
        } else {
            return .neutralGradientMiddle
        }
    }
}
