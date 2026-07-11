import Foundation

enum GameOption: String, CaseIterable, Identifiable {
    case ticTacToe = "Tic-Tac-Toe"
    case rockPaperScissors = "Rock Paper Scissors"
    case coinFlip = "Lucky Toss"
    case targetTap = "Bullseye Blitz"
    case twentyFortyEight = "Merge Summit"
    case memoryMatch = "Pair Finder"
    case numberGuess = "Secret Number"
    case reactionTime = "Reaction Time"
    case clicksPerSecond = "Clicks Per Second"
    case stopTimer = "Time Freeze"
    case colorRush = "Hue Match"
    case wordle = "Guess the Word"
    case hangman = "Hangman"
    case nimDuel = "Stone Strategy"
    case codeBreaker = "Pattern Lock"
    case wormArena = "Worm Arena"
    case logicPop = "Logic Pop"
    case snackStack = "Snack Stack"
    case yetiKitchen = "Yeti's Kitchen"

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
        case .wormArena:
            return "scribble.variable"
        case .logicPop:
            return "lightbulb.max.fill"
        case .snackStack:
            return "takeoutbag.and.cup.and.straw.fill"
        case .yetiKitchen:
            return "frying.pan.fill"
        }
    }

    var category: GameCategory {
        switch self {
        case .rockPaperScissors, .coinFlip, .targetTap, .wormArena:
            return .arcade
        case .twentyFortyEight, .wordle, .hangman, .memoryMatch, .numberGuess, .logicPop, .snackStack, .yetiKitchen:
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
            return "Swipe tiles and merge matching numbers to climb higher."
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
        case .wormArena:
            return "Grow your worm, dodge rivals, and rule the garden."
        case .logicPop:
            return "Solve quick patterns, sequences, and simple logic questions."
        case .snackStack:
            return "Swap snacks, build matches, and trigger tasty cascades."
        case .yetiKitchen:
            return "Watch Rainbow Chef Yeti's show, then tap ingredients in order."
        }
    }

    var mascotHint: String {
        switch self {
        case .ticTacToe:
            return "Take the center or a corner first. Watch for two-way threats."
        case .rockPaperScissors:
            return "Mix your picks. Repeating the same move is easy to read."
        case .coinFlip:
            return "There is no strategy here. Pick a side and trust the toss."
        case .targetTap:
            return "Hit the target quickly after each move. It jumps every time you score."
        case .twentyFortyEight:
            return "Keep your highest tile in one corner and build outward."
        case .memoryMatch:
            return "Flip cards in a pattern and remember where pairs appear."
        case .numberGuess:
            return "Use the slider clues to narrow the range one step at a time."
        case .reactionTime:
            return "Wait for green. Tapping early slows your run."
        case .clicksPerSecond:
            return "Use a steady rhythm instead of panic tapping."
        case .stopTimer:
            return "Aim to stop just under five seconds, not exactly on the dot."
        case .colorRush:
            return "Trust the color, not the label."
        case .wordle:
            return "Start with common vowels and avoid duplicate letters early."
        case .hangman:
            return "Guess vowels and common consonants first."
        case .nimDuel:
            return "Try to leave a multiple of four when you can."
        case .codeBreaker:
            return "Use the feedback to lock in one color at a time."
        case .wormArena:
            return "Stay near the food trail and do not trap yourself."
        case .logicPop:
            return "Read the pattern, then pick the answer that stays consistent."
        case .snackStack:
            return "Look for swaps that make three in a row, then watch for cascades."
        case .yetiKitchen:
            return "Watch the show carefully, then tap ingredients in the same order."
        }
    }

    var difficulty: String {
        switch self {
        case .ticTacToe, .wordle, .nimDuel, .codeBreaker, .snackStack, .yetiKitchen:
            return "Medium"
        case .twentyFortyEight, .hangman, .memoryMatch, .wormArena:
            return "Hard"
        case .rockPaperScissors, .reactionTime, .clicksPerSecond, .coinFlip, .targetTap, .numberGuess, .stopTimer, .colorRush, .logicPop:
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
            return "Best Tile: --"
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
        case .wormArena:
            return "Best Food: 0"
        case .logicPop:
            return "Best Round: 0 / 5"
        case .snackStack:
            return "Best Score: 0"
        case .yetiKitchen:
            return "Recipes Mastered: 0"
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
        case .wormArena:
            return "green"
        case .logicPop:
            return "indigo"
        case .snackStack:
            return "pink"
        case .yetiKitchen:
            return "orange"
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
