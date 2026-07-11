import SwiftUI

enum BrandPalette {
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.29)
    static let navy = Color(red: 0.15, green: 0.20, blue: 0.40)
    static let plum = Color(red: 0.32, green: 0.18, blue: 0.48)
    static let tealInk = Color(red: 0.08, green: 0.28, blue: 0.35)
    static let coralInk = Color(red: 0.44, green: 0.16, blue: 0.22)
    #if os(macOS)
    static let paper = Color(nsColor: .windowBackgroundColor)
    static let paperElevated = Color(nsColor: .controlBackgroundColor)
    #else
    static let paper = Color(uiColor: .systemBackground)
    static let paperElevated = Color(uiColor: .secondarySystemBackground)
    #endif
    static let shadow = Color.black.opacity(0.12)
    static let textGradient = LinearGradient(
        colors: [Color.primary, Color.primary],
        startPoint: .leading,
        endPoint: .trailing
    )
}
