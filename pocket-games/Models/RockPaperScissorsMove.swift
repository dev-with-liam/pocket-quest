import Foundation

enum RockPaperScissorsMove: String, CaseIterable, Identifiable {
    case rock = "Rock"
    case paper = "Paper"
    case scissors = "Scissors"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .rock:
            return "circle.hexagongrid.fill"
        case .paper:
            return "doc.fill"
        case .scissors:
            return "scissors"
        }
    }

    func beats(_ other: RockPaperScissorsMove) -> Bool {
        switch (self, other) {
        case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
            return true
        default:
            return false
        }
    }
}
