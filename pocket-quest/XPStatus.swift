import Foundation

struct XPStatus {
    private static let startingLevelCost = 300
    private static let levelCostIncrease = 150

    let level: Int
    let remainingXP: Int
    let xpIntoLevel: Int
    let xpRequiredForNextLevel: Int

    init(xp: Int) {
        var currentLevel = 1
        var xpRemaining = max(0, xp)
        var levelCost = Self.costToAdvance(from: currentLevel)

        while xpRemaining >= levelCost {
            xpRemaining -= levelCost
            currentLevel += 1
            levelCost = Self.costToAdvance(from: currentLevel)
        }

        level = currentLevel
        xpIntoLevel = xpRemaining
        xpRequiredForNextLevel = levelCost
        remainingXP = levelCost - xpRemaining
    }

    var progress: Double {
        Double(xpIntoLevel) / Double(xpRequiredForNextLevel)
    }

    var rankTitle: String {
        switch level {
        case 1...2:
            return "Rookie"
        case 3...4:
            return "Explorer"
        case 5...7:
            return "Adventurer"
        case 8...11:
            return "Champion"
        default:
            return "Quest Legend"
        }
    }

    var levelBonus: Int {
        switch level {
        case 1...2:
            return 0
        case 3...4:
            return 5
        case 5...7:
            return 10
        case 8...11:
            return 15
        default:
            return 25
        }
    }

    var minimumPlayReward: Int {
        GameOption.minimumBaseXPReward + levelBonus
    }

    var maximumPlayReward: Int {
        GameOption.maximumBaseXPReward + levelBonus
    }

    var dailyReward: Int {
        500 + min(level - 1, 20) * 25
    }

    var nextPerk: (level: Int, bonus: Int)? {
        switch level {
        case ..<3:
            return (3, 5)
        case ..<5:
            return (5, 10)
        case ..<8:
            return (8, 15)
        case ..<12:
            return (12, 25)
        default:
            return nil
        }
    }

    func reward(for game: GameOption) -> Int {
        game.baseXPReward + levelBonus
    }

    private static func costToAdvance(from level: Int) -> Int {
        startingLevelCost + (level - 1) * levelCostIncrease
    }
}

extension GameOption {
    var baseXPReward: Int {
        switch difficulty {
        case "Hard":
            return 45
        case "Medium":
            return 30
        default:
            return 20
        }
    }

    static var minimumBaseXPReward: Int {
        allCases.map(\.baseXPReward).min() ?? 0
    }

    static var maximumBaseXPReward: Int {
        allCases.map(\.baseXPReward).max() ?? 0
    }
}
