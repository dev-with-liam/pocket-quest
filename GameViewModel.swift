import Foundation
import Combine

enum GameDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .easy:
            return "Casual"
        case .medium:
            return "Balanced"
        case .hard:
            return "Unbeatable"
        }
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    struct Score: Equatable {
        var playerWins = 0
        var computerWins = 0
        var draws = 0
    }

    enum GameState: Equatable {
        case inProgress
        case won(Player)
        case draw

        var isFinished: Bool {
            switch self {
            case .inProgress:
                false
            case .won, .draw:
                true
            }
        }
    }

    private struct WinningResult {
        let player: Player
        let line: [Int]
    }

    @Published private(set) var board: [Move?]
    @Published private(set) var score = Score()
    @Published private(set) var gameState: GameState = .inProgress
    @Published private(set) var winningLine: [Int] = []
    @Published private(set) var isComputerThinking = false
    @Published var difficulty: GameDifficulty
    @Published var isShowingGameOverAlert = false

    private let computerDelayNanoseconds: UInt64
    private let statsStore: GameStatsStore
    private let winningLines = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]
    private let preferredPositions = [4, 0, 2, 6, 8, 1, 3, 5, 7]

    init(
        difficulty: GameDifficulty = .hard,
        computerDelayNanoseconds: UInt64 = 350_000_000,
        statsStore: GameStatsStore = GameStatsStore()
    ) {
        self.difficulty = difficulty
        self.computerDelayNanoseconds = computerDelayNanoseconds
        self.statsStore = statsStore
        self.board = Array(repeating: nil, count: 9)
        self.score = Score(
            playerWins: statsStore.integer(forKey: "stats.ticTacToe.playerWins"),
            computerWins: statsStore.integer(forKey: "stats.ticTacToe.computerWins"),
            draws: statsStore.integer(forKey: "stats.ticTacToe.draws")
        )
    }

    var statusText: String {
        if isComputerThinking {
            return "Computer is thinking"
        }

        switch gameState {
        case .inProgress:
            return "Your turn"
        case .won(let player):
            return "\(player.displayName) wins"
        case .draw:
            return "Draw"
        }
    }

    var alertTitle: String {
        switch gameState {
        case .inProgress:
            return "Game Paused"
        case .won(let player):
            return "\(player.displayName) Wins"
        case .draw:
            return "It's a Draw"
        }
    }

    var alertMessage: String {
        switch gameState {
        case .inProgress:
            return "Keep playing to finish the match."
        case .won(.human):
            return "Nice move sequence. Start a new game to play again."
        case .won(.computer):
            return "The computer found a winning line on \(difficulty.rawValue). Try another opening."
        case .draw:
            return "Perfect play from both sides ends in a draw."
        }
    }

    func playHumanMove(at index: Int) {
        guard board.indices.contains(index),
              board[index] == nil,
              gameState == .inProgress,
              !isComputerThinking else {
            return
        }

        board[index] = Move(player: .human, index: index)
        resolveGameIfNeeded()

        guard gameState == .inProgress else { return }

        if computerDelayNanoseconds == 0 {
            playComputerMove()
        } else {
            isComputerThinking = true
            Task { [weak self] in
                guard let self else { return }
                try? await Task.sleep(nanoseconds: self.computerDelayNanoseconds)
                self.playComputerMove()
            }
        }
    }

    func startNewGame() {
        board = Array(repeating: nil, count: 9)
        gameState = .inProgress
        winningLine = []
        isComputerThinking = false
        isShowingGameOverAlert = false
    }

    func resetScores() {
        score = Score()
        saveScore()
        startNewGame()
    }

#if DEBUG
    func setBoardForTesting(_ moves: [Move?]) {
        guard moves.count == board.count else { return }
        board = moves
        gameState = .inProgress
        winningLine = []
        isComputerThinking = false
        isShowingGameOverAlert = false
    }
#endif

    private func playComputerMove() {
        guard gameState == .inProgress else {
            isComputerThinking = false
            return
        }

        if let index = bestComputerMove() {
            board[index] = Move(player: .computer, index: index)
        }

        isComputerThinking = false
        resolveGameIfNeeded()
    }

    private func resolveGameIfNeeded() {
        if let result = winningResult(in: board) {
            gameState = .won(result.player)
            winningLine = result.line
            recordScore(for: gameState)
            isShowingGameOverAlert = true
            return
        }

        if board.allSatisfy({ $0 != nil }) {
            gameState = .draw
            winningLine = []
            recordScore(for: gameState)
            isShowingGameOverAlert = true
        }
    }

    private func recordScore(for state: GameState) {
        switch state {
        case .won(.human):
            score.playerWins += 1
        case .won(.computer):
            score.computerWins += 1
        case .draw:
            score.draws += 1
        case .inProgress:
            break
        }
        saveScore()
    }

    private func saveScore() {
        statsStore.set(score.playerWins, forKey: "stats.ticTacToe.playerWins")
        statsStore.set(score.computerWins, forKey: "stats.ticTacToe.computerWins")
        statsStore.set(score.draws, forKey: "stats.ticTacToe.draws")
    }

    private func bestComputerMove() -> Int? {
        switch difficulty {
        case .easy:
            return availablePositions(in: board).first
        case .medium:
            return bestMediumMove()
        case .hard:
            return bestHardMove()
        }
    }

    private func bestMediumMove() -> Int? {
        if let winningMove = immediateWinningMove(for: .computer, in: board) {
            return winningMove
        }

        if let blockingMove = immediateWinningMove(for: .human, in: board) {
            return blockingMove
        }

        return preferredPositions.first { board[$0] == nil }
    }

    private func bestHardMove() -> Int? {
        var bestScore = Int.min
        var bestIndex: Int?

        for index in preferredPositions where board[index] == nil {
            var candidateBoard = board
            candidateBoard[index] = Move(player: .computer, index: index)
            let score = minimax(board: candidateBoard, isComputerTurn: false, depth: 0)

            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        return bestIndex
    }

    private func immediateWinningMove(for player: Player, in board: [Move?]) -> Int? {
        for index in preferredPositions where board[index] == nil {
            var candidateBoard = board
            candidateBoard[index] = Move(player: player, index: index)

            if winningResult(in: candidateBoard)?.player == player {
                return index
            }
        }

        return nil
    }

    private func availablePositions(in board: [Move?]) -> [Int] {
        board.indices.filter { board[$0] == nil }
    }

    // Minimax makes the computer unbeatable while still preserving a clear move order.
    private func minimax(board: [Move?], isComputerTurn: Bool, depth: Int) -> Int {
        if let result = winningResult(in: board) {
            switch result.player {
            case .computer:
                return 10 - depth
            case .human:
                return depth - 10
            }
        }

        if board.allSatisfy({ $0 != nil }) {
            return 0
        }

        if isComputerTurn {
            var bestScore = Int.min

            for index in preferredPositions where board[index] == nil {
                var candidateBoard = board
                candidateBoard[index] = Move(player: .computer, index: index)
                bestScore = max(bestScore, minimax(board: candidateBoard, isComputerTurn: false, depth: depth + 1))
            }

            return bestScore
        } else {
            var bestScore = Int.max

            for index in preferredPositions where board[index] == nil {
                var candidateBoard = board
                candidateBoard[index] = Move(player: .human, index: index)
                bestScore = min(bestScore, minimax(board: candidateBoard, isComputerTurn: true, depth: depth + 1))
            }

            return bestScore
        }
    }

    private func winningResult(in board: [Move?]) -> WinningResult? {
        for line in winningLines {
            guard let player = board[line[0]]?.player else { continue }

            if line.allSatisfy({ board[$0]?.player == player }) {
                return WinningResult(player: player, line: line)
            }
        }

        return nil
    }
}
