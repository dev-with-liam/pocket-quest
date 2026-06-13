import Foundation

enum GameOption: String, CaseIterable, Identifiable {
    case ticTacToe = "Tic-Tac-Toe"
    case rockPaperScissors = "Rock Paper Scissors"
    case coinFlip = "Coin Flip"
    case targetTap = "Target Tap"
    case twentyFortyEight = "2048"
    case memoryMatch = "Memory Match"
    case numberGuess = "Number Guess"
    case reactionTime = "Reaction Time"
    case clicksPerSecond = "Clicks Per Second"
    case stopTimer = "Stop Timer"
    case colorRush = "Color Rush"
    case wordle = "Wordle"
    case hangman = "Hangman"
    case nimDuel = "Nim Duel"
    case codeBreaker = "Code Breaker"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .ticTacToe:
            return "xmark.circle.fill"
        case .rockPaperScissors:
            return "hand.raised.fill"
        case .coinFlip:
            return "circlebadge.2.fill"
        case .targetTap:
            return "scope"
        case .twentyFortyEight:
            return "square.grid.4x3.fill"
        case .memoryMatch:
            return "rectangle.on.rectangle.angled.fill"
        case .numberGuess:
            return "number.circle.fill"
        case .reactionTime:
            return "timer"
        case .clicksPerSecond:
            return "hand.tap.fill"
        case .stopTimer:
            return "stopwatch.fill"
        case .colorRush:
            return "paintpalette.fill"
        case .wordle:
            return "textformat.abc"
        case .hangman:
            return "figure.stand"
        case .nimDuel:
            return "circle.grid.cross.fill"
        case .codeBreaker:
            return "lock.open.fill"
        }
    }

    var category: GameCategory {
        switch self {
        case .rockPaperScissors, .coinFlip, .targetTap:
            return .arcade
        case .twentyFortyEight, .wordle, .hangman, .memoryMatch, .numberGuess:
            return .puzzle
        case .ticTacToe, .nimDuel, .codeBreaker:
            return .strategy
        case .reactionTime, .clicksPerSecond, .stopTimer, .colorRush:
            return .reaction
        }
    }

    var shortDescription: String {
        switch self {
        case .ticTacToe:
            return "Beat the AI in a classic strategy match."
        case .rockPaperScissors:
            return "Pick your move and outguess the computer."
        case .coinFlip:
            return "Call heads or tails and test your luck."
        case .targetTap:
            return "Tap moving targets before time runs out."
        case .twentyFortyEight:
            return "Swipe tiles, merge numbers, chase 2048."
        case .memoryMatch:
            return "Flip cards and match every hidden pair."
        case .numberGuess:
            return "Use clues to find the secret number."
        case .reactionTime:
            return "Wait for green, then tap as fast as you can."
        case .clicksPerSecond:
            return "Measure how many taps you can land in time."
        case .stopTimer:
            return "Stop the clock as close to five seconds as possible."
        case .colorRush:
            return "Tap only when the color matches the target."
        case .wordle:
            return "Guess the hidden word in six tries."
        case .hangman:
            return "Find the word before your chances run out."
        case .nimDuel:
            return "Take stones and force the computer into the last move."
        case .codeBreaker:
            return "Crack the secret three-color code."
        }
    }

    var difficulty: String {
        switch self {
        case .ticTacToe, .wordle, .nimDuel, .codeBreaker:
            return "Medium"
        case .twentyFortyEight, .hangman, .memoryMatch:
            return "Hard"
        case .rockPaperScissors, .reactionTime, .clicksPerSecond, .coinFlip, .targetTap, .numberGuess, .stopTimer, .colorRush:
            return "Easy"
        }
    }

    var statLabel: String {
        switch self {
        case .ticTacToe:
            return "Best Streak: 0"
        case .rockPaperScissors:
            return "Rounds Won: 0"
        case .coinFlip:
            return "Best Streak: 0"
        case .targetTap:
            return "Best Hits: 0"
        case .twentyFortyEight:
            return "Best Tile: 2048"
        case .memoryMatch:
            return "Best Moves: --"
        case .numberGuess:
            return "Best Guess: --"
        case .reactionTime:
            return "Best Time: -- ms"
        case .clicksPerSecond:
            return "Best CPS: --"
        case .stopTimer:
            return "Best Miss: --"
        case .colorRush:
            return "Best Score: 0"
        case .wordle:
            return "Words Solved: 0"
        case .hangman:
            return "Words Saved: 0"
        case .nimDuel:
            return "Wins: 0"
        case .codeBreaker:
            return "Fastest Solve: --"
        }
    }

    var tintName: String {
        switch self {
        case .ticTacToe:
            return "blue"
        case .rockPaperScissors:
            return "orange"
        case .coinFlip:
            return "yellow"
        case .targetTap:
            return "pink"
        case .twentyFortyEight:
            return "green"
        case .memoryMatch:
            return "indigo"
        case .numberGuess:
            return "teal"
        case .reactionTime:
            return "purple"
        case .clicksPerSecond:
            return "red"
        case .stopTimer:
            return "blue"
        case .colorRush:
            return "orange"
        case .wordle:
            return "mint"
        case .hangman:
            return "cyan"
        case .nimDuel:
            return "purple"
        case .codeBreaker:
            return "red"
        }
    }
}

enum GameCategory: String, CaseIterable, Identifiable {
    case arcade = "Arcade"
    case puzzle = "Puzzle"
    case strategy = "Strategy"
    case reaction = "Reaction"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .arcade:
            return "gamecontroller.fill"
        case .puzzle:
            return "puzzlepiece.extension.fill"
        case .strategy:
            return "brain.head.profile"
        case .reaction:
            return "bolt.fill"
        }
    }
}
