import SwiftUI

enum ThemeTextColor: String, CaseIterable, Identifiable {
    case gradientGreenBlue
    case navy
    case plum
    case teal
    case coral
    case indigo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gradientGreenBlue: return "Sky Blue"
        case .navy: return "Black"
        case .plum: return "Purple"
        case .teal: return "Teal"
        case .coral: return "Coral"
        case .indigo: return "Indigo"
        }
    }

    var accentColor: Color {
        switch self {
        case .gradientGreenBlue: return Color(red: 0.22, green: 0.53, blue: 0.95)
        case .navy: return .black
        case .plum: return BrandPalette.plum
        case .teal: return BrandPalette.tealInk
        case .coral: return BrandPalette.coralInk
        case .indigo: return Color(red: 0.24, green: 0.22, blue: 0.52)
        }
    }

    var foregroundStyle: AnyShapeStyle {
        AnyShapeStyle(Color.primary)
    }
}

enum ThemeBackground: String, CaseIterable, Identifiable {
    case candy
    case sunset
    case ocean
    case aurora
    case berry
    case retroSky

    var id: String { rawValue }

    var label: String {
        switch self {
        case .candy: return "Sky Blue"
        case .sunset: return "Peach"
        case .ocean: return "Ocean Blue"
        case .aurora: return "Mint"
        case .berry: return "Lavender"
        case .retroSky: return "Cloud White"
        }
    }

    var colors: [Color] {
        switch self {
        case .candy:
            return [.blue.opacity(0.10), .cyan.opacity(0.08), .mint.opacity(0.08)]
        case .sunset:
            return [.orange.opacity(0.12), .pink.opacity(0.10), .yellow.opacity(0.08)]
        case .ocean:
            return [.cyan.opacity(0.12), .blue.opacity(0.10), .teal.opacity(0.08)]
        case .aurora:
            return [.mint.opacity(0.12), .cyan.opacity(0.10), .purple.opacity(0.08)]
        case .berry:
            return [.pink.opacity(0.12), .purple.opacity(0.10), .red.opacity(0.08)]
        case .retroSky:
            return [.white, Color(red: 0.97, green: 0.99, blue: 1.0)]
        }
    }

    var accent: Color {
        switch self {
        case .candy:
            return .blue
        case .sunset:
            return .orange
        case .ocean:
            return .cyan
        case .aurora:
            return .mint
        case .berry:
            return .purple
        case .retroSky:
            return .blue
        }
    }

    var overlayGlow: Color {
        switch self {
        case .candy:
            return .cyan.opacity(0.16)
        case .sunset:
            return .pink.opacity(0.16)
        case .ocean:
            return .blue.opacity(0.16)
        case .aurora:
            return .mint.opacity(0.16)
        case .berry:
            return .purple.opacity(0.16)
        case .retroSky:
            return .blue.opacity(0.10)
        }
    }
}

extension Color {
    static func themeInk(_ theme: ThemeTextColor) -> Color {
        theme.accentColor
    }
}
