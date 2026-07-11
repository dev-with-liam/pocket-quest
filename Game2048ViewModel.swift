import Combine
import Foundation

@MainActor
final class Game2048ViewModel: ObservableObject {
    @Published private(set) var board: [Tile2048?]
    @Published private(set) var score = 0
    @Published private(set) var bestScore = 0
    @Published private(set) var wins = 0
    @Published private(set) var losses = 0
    @Published private(set) var hasWon = false
    @Published private(set) var isGameOver = false

    private let tileValueProvider: () -> Int
    private let tileIndexProvider: ([Int]) -> Int?
    private let statsStore: GameStatsStore

    init(
        tileValueProvider: @escaping () -> Int = { Int.random(in: 1...10) == 1 ? 4 : 2 },
        tileIndexProvider: @escaping ([Int]) -> Int? = { $0.randomElement() },
        statsStore: GameStatsStore = GameStatsStore()
    ) {
        self.tileValueProvider = tileValueProvider
        self.tileIndexProvider = tileIndexProvider
        self.statsStore = statsStore
        self.board = Array(repeating: nil, count: 16)
        self.bestScore = statsStore.integer(forKey: "stats.mergeSummit.bestScore")
        self.wins = statsStore.integer(forKey: "stats.mergeSummit.wins")
        self.losses = statsStore.integer(forKey: "stats.mergeSummit.losses")
        startNewGame()
    }

    var statusText: String {
        if isGameOver {
            return "No moves left"
        }

        if hasWon {
            return "2048 reached"
        }

        return "Join matching tiles"
    }

    func startNewGame() {
        board = Array(repeating: nil, count: 16)
        score = 0
        hasWon = false
        isGameOver = false
        addRandomTile()
        addRandomTile()
    }

    @discardableResult
    func move(_ direction: MoveDirection) -> Bool {
        guard !isGameOver else { return false }

        var newBoard = board
        var moveScore = 0

        for line in lines(for: direction) {
            let values = line.compactMap { board[$0]?.value }
            let merged = merge(values)
            moveScore += merged.score

            for offset in line.indices {
                let boardIndex = line[offset]
                if offset < merged.values.count {
                    newBoard[boardIndex] = Tile2048(value: merged.values[offset])
                } else {
                    newBoard[boardIndex] = nil
                }
            }
        }

        guard newBoard.map({ $0?.value }) != board.map({ $0?.value }) else { return false }

        board = newBoard
        score += moveScore
        bestScore = max(bestScore, score)
        statsStore.set(bestScore, forKey: "stats.mergeSummit.bestScore")
        let reachedWinningTile = !hasWon && board.contains { $0?.value == 2048 }
        hasWon = hasWon || reachedWinningTile
        if reachedWinningTile {
            wins += 1
            statsStore.set(wins, forKey: "stats.mergeSummit.wins")
        }
        addRandomTile()
        isGameOver = !canMove()
        if isGameOver && !hasWon {
            losses += 1
            statsStore.set(losses, forKey: "stats.mergeSummit.losses")
        }
        return true
    }

#if DEBUG
    func setBoardForTesting(_ values: [Int?], score: Int = 0) {
        guard values.count == board.count else { return }
        board = values.map { value in
            value.map { Tile2048(value: $0) }
        }
        self.score = score
        bestScore = max(bestScore, score)
        statsStore.set(bestScore, forKey: "stats.mergeSummit.bestScore")
        hasWon = board.contains { $0?.value == 2048 }
        isGameOver = !canMove()
    }
#endif

    private func merge(_ values: [Int]) -> (values: [Int], score: Int) {
        var result: [Int] = []
        var score = 0
        var index = 0

        while index < values.count {
            if index + 1 < values.count, values[index] == values[index + 1] {
                let mergedValue = values[index] * 2
                result.append(mergedValue)
                score += mergedValue
                index += 2
            } else {
                result.append(values[index])
                index += 1
            }
        }

        return (result, score)
    }

    private func addRandomTile() {
        let emptyIndices = board.indices.filter { board[$0] == nil }
        guard let index = tileIndexProvider(Array(emptyIndices)) else { return }
        board[index] = Tile2048(value: tileValueProvider())
    }

    private func canMove() -> Bool {
        if board.contains(where: { $0 == nil }) {
            return true
        }

        for row in 0..<4 {
            for column in 0..<4 {
                let index = row * 4 + column
                let value = board[index]?.value

                if column < 3, value == board[index + 1]?.value {
                    return true
                }

                if row < 3, value == board[index + 4]?.value {
                    return true
                }
            }
        }

        return false
    }

    private func lines(for direction: MoveDirection) -> [[Int]] {
        switch direction {
        case .left:
            return (0..<4).map { row in (0..<4).map { row * 4 + $0 } }
        case .right:
            return (0..<4).map { row in (0..<4).reversed().map { row * 4 + $0 } }
        case .up:
            return (0..<4).map { column in (0..<4).map { $0 * 4 + column } }
        case .down:
            return (0..<4).map { column in (0..<4).reversed().map { $0 * 4 + column } }
        }
    }
}
