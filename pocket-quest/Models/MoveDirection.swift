import Foundation

enum MoveDirection: CaseIterable {
    case up
    case down
    case left
    case right

    var systemImage: String {
        switch self {
        case .up:
            return "chevron.up"
        case .down:
            return "chevron.down"
        case .left:
            return "chevron.left"
        case .right:
            return "chevron.right"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .up:
            return "Move up"
        case .down:
            return "Move down"
        case .left:
            return "Move left"
        case .right:
            return "Move right"
        }
    }
}
