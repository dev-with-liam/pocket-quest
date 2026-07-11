import SwiftUI

enum YetiSkin: String, CaseIterable, Identifiable {
    case artist
    case cloud
    case sunset
    case galaxy
    case forest
    case neon

    var id: String { rawValue }

    var label: String {
        switch self {
        case .artist: return "Artist Yeti"
        case .cloud: return "Cloud Yeti"
        case .sunset: return "Sunset Yeti"
        case .galaxy: return "Galaxy Yeti"
        case .forest: return "Forest Yeti"
        case .neon: return "Neon Yeti"
        }
    }

    var subtitle: String {
        switch self {
        case .artist: return "Free level 1 skin"
        case .cloud: return "Level 3"
        case .sunset: return "Level 5"
        case .galaxy: return "Level 7"
        case .forest: return "Level 10"
        case .neon: return "Level 14"
        }
    }

    var unlockLevel: Int {
        switch self {
        case .artist: return 1
        case .cloud: return 3
        case .sunset: return 5
        case .galaxy: return 7
        case .forest: return 10
        case .neon: return 14
        }
    }

    var isFree: Bool { self == .artist }

    func isUnlocked(at level: Int) -> Bool {
        level >= unlockLevel
    }

    var bodyGradient: [Color] {
        switch self {
        case .artist:
            return [Color(red: 0.99, green: 0.99, blue: 0.96), Color(red: 0.87, green: 0.93, blue: 0.99)]
        case .cloud:
            return [Color(red: 0.98, green: 1.0, blue: 1.0), Color(red: 0.82, green: 0.92, blue: 0.99)]
        case .sunset:
            return [Color(red: 0.99, green: 0.90, blue: 0.74), Color(red: 0.98, green: 0.64, blue: 0.38)]
        case .galaxy:
            return [Color(red: 0.87, green: 0.84, blue: 1.0), Color(red: 0.50, green: 0.40, blue: 0.95)]
        case .forest:
            return [Color(red: 0.88, green: 0.97, blue: 0.90), Color(red: 0.35, green: 0.72, blue: 0.48)]
        case .neon:
            return [Color(red: 0.80, green: 1.0, blue: 0.95), Color(red: 0.18, green: 0.78, blue: 0.74)]
        }
    }

    var accentGradient: [Color] {
        switch self {
        case .artist:
            return [Color(red: 0.95, green: 0.48, blue: 0.62), Color(red: 0.90, green: 0.60, blue: 0.26)]
        case .cloud:
            return [Color(red: 0.72, green: 0.88, blue: 0.98), Color(red: 0.42, green: 0.62, blue: 0.96)]
        case .sunset:
            return [Color(red: 0.98, green: 0.68, blue: 0.36), Color(red: 0.95, green: 0.34, blue: 0.42)]
        case .galaxy:
            return [Color(red: 0.76, green: 0.58, blue: 0.98), Color(red: 0.45, green: 0.30, blue: 0.92)]
        case .forest:
            return [Color(red: 0.50, green: 0.84, blue: 0.58), Color(red: 0.20, green: 0.60, blue: 0.38)]
        case .neon:
            return [Color(red: 0.20, green: 0.92, blue: 0.78), Color(red: 0.98, green: 0.68, blue: 0.22)]
        }
    }

    var hatColor: Color {
        switch self {
        case .artist: return Color(red: 0.95, green: 0.48, blue: 0.62)
        case .cloud: return Color(red: 0.46, green: 0.68, blue: 0.98)
        case .sunset: return Color(red: 0.98, green: 0.54, blue: 0.30)
        case .galaxy: return Color(red: 0.55, green: 0.42, blue: 0.96)
        case .forest: return Color(red: 0.28, green: 0.72, blue: 0.44)
        case .neon: return Color(red: 0.12, green: 0.82, blue: 0.76)
        }
    }

    var propColor: Color {
        switch self {
        case .artist: return Color(red: 0.96, green: 0.66, blue: 0.22)
        case .cloud: return Color(red: 0.92, green: 0.96, blue: 1.0)
        case .sunset: return Color(red: 0.98, green: 0.82, blue: 0.42)
        case .galaxy: return Color(red: 0.95, green: 0.92, blue: 1.0)
        case .forest: return Color(red: 0.86, green: 0.94, blue: 0.82)
        case .neon: return Color(red: 0.98, green: 0.98, blue: 0.42)
        }
    }

    var accessoryLabel: String {
        switch self {
        case .artist: return "palette"
        case .cloud: return "cloud"
        case .sunset: return "sun.max.fill"
        case .galaxy: return "sparkles"
        case .forest: return "leaf.fill"
        case .neon: return "bolt.fill"
        }
    }
}

