import Combine
import Foundation

@MainActor
final class RockPaperScissorsViewModel: ObservableObject {
    struct Score: Equatable {
        var playerWins = 0
        var computerWins = 0
        var draws = 0
    }

    @Published private(set) var score = Score()
    @Published private(set) var playerMove: RockPaperScissorsMove?
    @Published private(set) var computerMove: RockPaperScissorsMove?
    @Published private(set) var roundResult: RoundResult?

    private let computerMoveProvider: () -> RockPaperScissorsMove
    private let statsStore: GameStatsStore

    init(
        computerMoveProvider: @escaping () -> RockPaperScissorsMove = {
            RockPaperScissorsMove.allCases.randomElement() ?? .rock
        },
        statsStore: GameStatsStore = GameStatsStore()
    ) {
        self.computerMoveProvider = computerMoveProvider
        self.statsStore = statsStore
        self.score = Score(
            playerWins: statsStore.integer(forKey: "stats.rockPaperScissors.playerWins"),
            computerWins: statsStore.integer(forKey: "stats.rockPaperScissors.computerWins"),
            draws: statsStore.integer(forKey: "stats.rockPaperScissors.draws")
        )
    }

    var statusText: String {
        roundResult?.rawValue ?? "Choose your move"
    }

    func play(_ move: RockPaperScissorsMove) {
        let computerChoice = computerMoveProvider()

        playerMove = move
        computerMove = computerChoice
        roundResult = result(for: move, against: computerChoice)
        record(roundResult)
    }

    func startNewRound() {
        playerMove = nil
        computerMove = nil
        roundResult = nil
    }

    func resetScores() {
        score = Score()
        saveScore()
        startNewRound()
    }

    private func result(for playerMove: RockPaperScissorsMove, against computerMove: RockPaperScissorsMove) -> RoundResult {
        if playerMove == computerMove {
            return .draw
        }

        return playerMove.beats(computerMove) ? .playerWin : .computerWin
    }

    private func record(_ result: RoundResult?) {
        switch result {
        case .playerWin:
            score.playerWins += 1
        case .computerWin:
            score.computerWins += 1
        case .draw:
            score.draws += 1
        case nil:
            break
        }
        saveScore()
    }

    private func saveScore() {
        statsStore.set(score.playerWins, forKey: "stats.rockPaperScissors.playerWins")
        statsStore.set(score.computerWins, forKey: "stats.rockPaperScissors.computerWins")
        statsStore.set(score.draws, forKey: "stats.rockPaperScissors.draws")
    }
}
