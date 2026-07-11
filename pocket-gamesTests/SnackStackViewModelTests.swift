import Foundation
import Testing
@testable import pocket_games

@MainActor
struct SnackStackViewModelTests {
    @Test
    func invalidSwapIsRevertedWithoutUsingAMove() {
        let viewModel = SnackStackViewModel(statsStore: GameStatsStore(defaults: nil))
        let originalBoard = testBoard()
        viewModel.setBoardForTesting(originalBoard)

        viewModel.selectSnack(at: 0)
        viewModel.selectSnack(at: 1)

        #expect(viewModel.board == originalBoard)
        #expect(viewModel.movesRemaining == 15)
        #expect(viewModel.score == 0)
    }

    @Test
    func validSwapCreatesMatchAndScores() {
        let viewModel = SnackStackViewModel(
            snackProvider: { .juice },
            statsStore: GameStatsStore(defaults: nil)
        )
        var board = testBoard()
        board[0] = .cookie
        board[1] = .popcorn
        board[2] = .cookie
        board[5] = .cookie
        viewModel.setBoardForTesting(board)

        viewModel.selectSnack(at: 1)
        viewModel.selectSnack(at: 5)

        #expect(viewModel.movesRemaining == 14)
        #expect(viewModel.score >= 150)
        #expect(viewModel.bestScore == viewModel.score)
    }

    private func testBoard() -> [SnackKind] {
        let snacks = SnackKind.allCases
        return (0..<16).map { index in
            snacks[(index + index / 4) % snacks.count]
        }
    }
}
