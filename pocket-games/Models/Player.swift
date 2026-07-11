import Foundation

enum Player: String, CaseIterable, Identifiable {
    case human = "X"
    case computer = "O"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .human:
            "Player"
        case .computer:
            "Computer"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .human:
            "X"
        case .computer:
            "O"
        }
    }
}
