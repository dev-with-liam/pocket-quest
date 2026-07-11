import Combine
import Foundation

nonisolated enum SnackKind: String, CaseIterable {
    case popcorn
    case pretzel
    case cookie
    case chips
    case donut
    case juice

    var symbol: String {
        switch self {
        case .popcorn: "🍿"
        case .pretzel: "🥨"
        case .cookie: "🍪"
        case .chips: "🥔"
        case .donut: "🍩"
        case .juice: "🧃"
        }
    }
}

@MainActor
final class SnackStackViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case won
        case lost
    }

    @Published private(set) var board: [SnackKind]
    @Published private(set) var selectedIndex: Int?
    @Published private(set) var score = 0
    @Published private(set) var movesRemaining: Int
    @Published private(set) var phase: Phase = .playing
    @Published private(set) var message = "Tap two neighboring snacks to swap."
    @Published private(set) var bestScore = 0
    @Published private(set) var wins = 0
    @Published private(set) var losses = 0
    @Published private(set) var rounds = 0

    let rows = 4
    let columns = 4
    let startingMoves = 15
    let targetScore = 1_000

    private let snackProvider: () -> SnackKind
    private let statsStore: GameStatsStore

    init(
        snackProvider: @escaping () -> SnackKind = {
            SnackKind.allCases.randomElement() ?? .popcorn
        },
        statsStore: GameStatsStore = GameStatsStore()
    ) {
        self.snackProvider = snackProvider
        self.statsStore = statsStore
        self.board = Array(repeating: .popcorn, count: 16)
        self.movesRemaining = startingMoves
        self.bestScore = statsStore.integer(forKey: "stats.snackStack.bestScore")
        self.wins = statsStore.integer(forKey: "stats.snackStack.wins")
        self.losses = statsStore.integer(forKey: "stats.snackStack.losses")
        self.rounds = statsStore.integer(forKey: "stats.snackStack.rounds")
        startNewRound()
    }

    func selectSnack(at index: Int) {
        guard phase == .playing, board.indices.contains(index) else { return }

        guard let selectedIndex else {
            self.selectedIndex = index
            message = "Choose a neighboring snack."
            return
        }

        if selectedIndex == index {
            self.selectedIndex = nil
            message = "Selection cleared."
        } else if areAdjacent(selectedIndex, index) {
            attemptSwap(from: selectedIndex, to: index)
        } else {
            self.selectedIndex = index
            message = "Snacks must be next to each other."
        }
    }

    func startNewRound() {
        score = 0
        movesRemaining = startingMoves
        phase = .playing
        selectedIndex = nil
        message = "Tap two neighboring snacks to swap."
        board = makeBoardWithoutMatches()
    }

    private func attemptSwap(from first: Int, to second: Int) {
        selectedIndex = nil
        board.swapAt(first, second)

        guard !matchedIndices(in: board).isEmpty else {
            board.swapAt(first, second)
            message = "That swap does not make a match."
            return
        }

        movesRemaining -= 1
        resolveCascades()
        bestScore = max(bestScore, score)
        statsStore.set(bestScore, forKey: "stats.snackStack.bestScore")

        if score >= targetScore {
            finish(won: true)
        } else if movesRemaining == 0 {
            finish(won: false)
        }
    }

    private func resolveCascades() {
        var cascade = 1

        while cascade <= 12 {
            let matches = matchedIndices(in: board)
            guard !matches.isEmpty else { break }

            score += matches.count * 50 * cascade
            collapse(matches)
            cascade += 1
        }

        if !matchedIndices(in: board).isEmpty {
            board = makeBoardWithoutMatches()
        }

        message = cascade > 2
            ? "Snack cascade x\(cascade - 1)!"
            : "Match made. Keep stacking."
    }

    private func collapse(_ matches: Set<Int>) {
        for column in 0..<columns {
            let survivors = (0..<rows)
                .reversed()
                .map { $0 * columns + column }
                .filter { !matches.contains($0) }
                .map { board[$0] }

            var values = survivors
            while values.count < rows {
                values.append(snackProvider())
            }

            for (offset, row) in (0..<rows).reversed().enumerated() {
                board[row * columns + column] = values[offset]
            }
        }
    }

    private func matchedIndices(in board: [SnackKind]) -> Set<Int> {
        var matches: Set<Int> = []

        for row in 0..<rows {
            var runStart = 0
            for column in 1...columns {
                let continues = column < columns
                    && board[row * columns + column] == board[row * columns + runStart]
                if !continues {
                    if column - runStart >= 3 {
                        for matchedColumn in runStart..<column {
                            matches.insert(row * columns + matchedColumn)
                        }
                    }
                    runStart = column
                }
            }
        }

        for column in 0..<columns {
            var runStart = 0
            for row in 1...rows {
                let continues = row < rows
                    && board[row * columns + column] == board[runStart * columns + column]
                if !continues {
                    if row - runStart >= 3 {
                        for matchedRow in runStart..<row {
                            matches.insert(matchedRow * columns + column)
                        }
                    }
                    runStart = row
                }
            }
        }

        return matches
    }

    private func makeBoardWithoutMatches() -> [SnackKind] {
        var result: [SnackKind] = []

        for index in 0..<(rows * columns) {
            var snack = snackProvider()
            var attempts = 0

            while createsStartingMatch(snack, at: index, in: result), attempts < 20 {
                snack = snackProvider()
                attempts += 1
            }

            if createsStartingMatch(snack, at: index, in: result) {
                snack = fallbackSnack(at: index, in: result)
            }
            result.append(snack)
        }

        return result
    }

    private func createsStartingMatch(_ snack: SnackKind, at index: Int, in board: [SnackKind]) -> Bool {
        let row = index / columns
        let column = index % columns
        let horizontal = column >= 2
            && board[index - 1] == snack
            && board[index - 2] == snack
        let vertical = row >= 2
            && board[index - columns] == snack
            && board[index - columns * 2] == snack
        return horizontal || vertical
    }

    private func fallbackSnack(at index: Int, in board: [SnackKind]) -> SnackKind {
        SnackKind.allCases.first {
            !createsStartingMatch($0, at: index, in: board)
        } ?? .popcorn
    }

    private func areAdjacent(_ first: Int, _ second: Int) -> Bool {
        let firstRow = first / columns
        let firstColumn = first % columns
        let secondRow = second / columns
        let secondColumn = second % columns
        return abs(firstRow - secondRow) + abs(firstColumn - secondColumn) == 1
    }

    private func finish(won: Bool) {
        phase = won ? .won : .lost
        rounds += 1
        if won {
            wins += 1
            message = "Snack Stack cleared!"
        } else {
            losses += 1
            message = "Out of moves. Try another stack."
        }
        statsStore.set(rounds, forKey: "stats.snackStack.rounds")
        statsStore.set(wins, forKey: "stats.snackStack.wins")
        statsStore.set(losses, forKey: "stats.snackStack.losses")
    }

#if DEBUG
    func setBoardForTesting(_ board: [SnackKind], movesRemaining: Int = 15) {
        guard board.count == rows * columns else { return }
        self.board = board
        self.movesRemaining = movesRemaining
        score = 0
        selectedIndex = nil
        phase = .playing
    }
#endif
}
