import SwiftUI

enum Constants {
    // MARK: - Design Tokens
    enum Design {
        static let cornerRadius: CGFloat = 16
        static let pillCornerRadius: CGFloat = 20
        static let spacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 24

        static let animationDuration: Double = 0.3
        static let springDamping: Double = 0.7
    }

    // MARK: - Mood Score Range
    enum Mood {
        static let minScore: Double = -5.0
        static let maxScore: Double = 5.0
        static let neutralScore: Double = 0.0
    }

    // MARK: - Notification Defaults
    enum Notifications {
        static let defaultTimes: [DateComponents] = [
            DateComponents(hour: 8, minute: 0),
            DateComponents(hour: 14, minute: 0),
            DateComponents(hour: 20, minute: 0)
        ]
        static let reminderInterval: TimeInterval = 15 * 60 // 15 minuten
    }

    // MARK: - Tags
    enum Tags {
        static let negative: [String] = [
            "Hoofdpijn",
            "Buikpijn",
            "Slecht geslapen",
            "Stress/spanning",
            "Emotioneel/huilbui",
            "Moe/uitgeput",
            "Ruzie/conflict",
            "Lichaamsbeeld negatief",
            "Misselijkheid",
            "Opgeblazen gevoel"
        ]

        static let positive: [String] = [
            "Energiek",
            "Sociaal contact gehad",
            "Productieve dag",
            "Goed geslapen",
            "Gesport/bewogen",
            "Genoeg water gedronken",
            "Intieme momenten"
        ]

        static var all: [String] {
            negative + positive
        }
    }

    // MARK: - Menstrual Flow Options
    enum MenstrualFlow: String, CaseIterable {
        case none = "Geen"
        case spotting = "Spotting"
        case light = "Licht"
        case medium = "Normaal"
        case heavy = "Hevig"
    }
}
