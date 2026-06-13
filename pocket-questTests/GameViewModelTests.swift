import XCTest
@testable import pocket_quest

@MainActor
final class GameViewModelTests: XCTestCase {
    func testComputerBlocksImmediatePlayerWin() {
        let viewModel = GameViewModel(difficulty: .hard, computerDelayNanoseconds: 0)
        viewModel.setBoardForTesting([
            Move(player: .human, index: 0),
            Move(player: .human, index: 1),
            nil,
            nil,
            Move(player: .computer, index: 4),
            nil,
            nil,
            nil,
            nil
        ])

        viewModel.playHumanMove(at: 8)

        XCTAssertEqual(viewModel.board[2]?.player, .computer)
        XCTAssertEqual(viewModel.gameState, .inProgress)
    }

    func testComputerTakesWinningMove() {
        let viewModel = GameViewModel(difficulty: .hard, computerDelayNanoseconds: 0)
        viewModel.setBoardForTesting([
            Move(player: .computer, index: 0),
            Move(player: .computer, index: 1),
            nil,
            Move(player: .human, index: 3),
            Move(player: .human, index: 4),
            nil,
            nil,
            nil,
            nil
        ])

        viewModel.playHumanMove(at: 8)

        XCTAssertEqual(viewModel.board[2]?.player, .computer)
        XCTAssertEqual(viewModel.gameState, .won(.computer))
        XCTAssertEqual(viewModel.winningLine, [0, 1, 2])
        XCTAssertEqual(viewModel.score.computerWins, 1)
    }

    func testDrawIsDetected() {
        let viewModel = GameViewModel(difficulty: .hard, computerDelayNanoseconds: 0)
        viewModel.setBoardForTesting([
            Move(player: .human, index: 0),
            Move(player: .computer, index: 1),
            Move(player: .human, index: 2),
            Move(player: .human, index: 3),
            Move(player: .computer, index: 4),
            Move(player: .computer, index: 5),
            Move(player: .computer, index: 6),
            Move(player: .human, index: 7),
            nil
        ])

        viewModel.playHumanMove(at: 8)

        XCTAssertEqual(viewModel.gameState, .draw)
        XCTAssertEqual(viewModel.score.draws, 1)
        XCTAssertTrue(viewModel.winningLine.isEmpty)
    }

    func testNewGameKeepsScoresAndClearsBoard() {
        let viewModel = GameViewModel(difficulty: .hard, computerDelayNanoseconds: 0)
        viewModel.setBoardForTesting([
            Move(player: .human, index: 0),
            Move(player: .computer, index: 1),
            Move(player: .human, index: 2),
            Move(player: .human, index: 3),
            Move(player: .computer, index: 4),
            Move(player: .computer, index: 5),
            Move(player: .computer, index: 6),
            Move(player: .human, index: 7),
            nil
        ])

        viewModel.playHumanMove(at: 8)
        viewModel.startNewGame()

        XCTAssertEqual(viewModel.score.draws, 1)
        XCTAssertEqual(viewModel.gameState, .inProgress)
        XCTAssertTrue(viewModel.board.allSatisfy { $0 == nil })
    }

    func testEasyDifficultyUsesFirstOpenSquare() {
        let viewModel = GameViewModel(difficulty: .easy, computerDelayNanoseconds: 0)

        viewModel.playHumanMove(at: 0)

        XCTAssertEqual(viewModel.board[1]?.player, .computer)
    }

    func testMediumDifficultyBlocksImmediatePlayerWin() {
        let viewModel = GameViewModel(difficulty: .medium, computerDelayNanoseconds: 0)
        viewModel.setBoardForTesting([
            Move(player: .human, index: 0),
            Move(player: .human, index: 1),
            nil,
            nil,
            Move(player: .computer, index: 4),
            nil,
            nil,
            nil,
            nil
        ])

        viewModel.playHumanMove(at: 8)

        XCTAssertEqual(viewModel.board[2]?.player, .computer)
    }

    func testRockPaperScissorsPlayerWin() {
        let viewModel = RockPaperScissorsViewModel(computerMoveProvider: { .scissors })

        viewModel.play(.rock)

        XCTAssertEqual(viewModel.playerMove, .rock)
        XCTAssertEqual(viewModel.computerMove, .scissors)
        XCTAssertEqual(viewModel.roundResult, .playerWin)
        XCTAssertEqual(viewModel.score.playerWins, 1)
    }

    func testRockPaperScissorsComputerWin() {
        let viewModel = RockPaperScissorsViewModel(computerMoveProvider: { .paper })

        viewModel.play(.rock)

        XCTAssertEqual(viewModel.roundResult, .computerWin)
        XCTAssertEqual(viewModel.score.computerWins, 1)
    }

    func testRockPaperScissorsDraw() {
        let viewModel = RockPaperScissorsViewModel(computerMoveProvider: { .paper })

        viewModel.play(.paper)

        XCTAssertEqual(viewModel.roundResult, .draw)
        XCTAssertEqual(viewModel.score.draws, 1)
    }

    func test2048MergesTilesAndAddsScore() {
        let viewModel = Game2048ViewModel(
            tileValueProvider: { 2 },
            tileIndexProvider: { indices in indices.first }
        )
        viewModel.setBoardForTesting([
            2, 2, nil, nil,
            nil, nil, nil, nil,
            nil, nil, nil, nil,
            nil, nil, nil, nil
        ])

        viewModel.move(.left)

        XCTAssertEqual(viewModel.board[0]?.value, 4)
        XCTAssertEqual(viewModel.score, 4)
        XCTAssertEqual(viewModel.board.compactMap { $0?.value }.count, 2)
    }

    func test2048DoesNotMoveWhenBoardCannotChange() {
        let viewModel = Game2048ViewModel(
            tileValueProvider: { 2 },
            tileIndexProvider: { indices in indices.first }
        )
        viewModel.setBoardForTesting([
            2, nil, nil, nil,
            nil, nil, nil, nil,
            nil, nil, nil, nil,
            nil, nil, nil, nil
        ])

        viewModel.move(.left)

        XCTAssertEqual(viewModel.board.compactMap { $0?.value }.count, 1)
        XCTAssertEqual(viewModel.score, 0)
    }

    func test2048DetectsGameOver() {
        let viewModel = Game2048ViewModel(
            tileValueProvider: { 2 },
            tileIndexProvider: { indices in indices.first }
        )
        viewModel.setBoardForTesting([
            2, 4, 2, 4,
            4, 2, 4, 2,
            2, 4, 2, 4,
            4, 2, 4, 2
        ])

        XCTAssertTrue(viewModel.isGameOver)
    }

    func testReactionTimeRecordsBestResult() async {
        var currentDate = Date(timeIntervalSince1970: 100)
        let viewModel = ReactionTimeViewModel(
            delayProvider: { 0 },
            nowProvider: { currentDate }
        )

        viewModel.start()
        await Task.yield()
        currentDate = Date(timeIntervalSince1970: 100.25)
        viewModel.tapTarget()

        XCTAssertEqual(viewModel.lastReactionMilliseconds, 250)
        XCTAssertEqual(viewModel.bestReactionMilliseconds, 250)
        XCTAssertEqual(viewModel.phase, .result)
    }

    func testReactionTimeDetectsEarlyTap() {
        let viewModel = ReactionTimeViewModel(delayProvider: { 1_000_000_000 })

        viewModel.start()
        viewModel.tapTarget()

        XCTAssertEqual(viewModel.phase, .early)
        XCTAssertNil(viewModel.lastReactionMilliseconds)
    }

    func testClicksPerSecondTracksClicksAndFinishes() {
        let viewModel = ClicksPerSecondViewModel(duration: 0.2)

        viewModel.start()
        viewModel.tapTarget()
        viewModel.tapTarget()
        viewModel.advanceForTesting(seconds: 0.2)

        XCTAssertEqual(viewModel.clickCount, 2)
        XCTAssertEqual(viewModel.phase, .finished)
        XCTAssertGreaterThan(viewModel.bestClicksPerSecond, 0)
    }

    func testWordleDetectsWinningGuess() {
        let viewModel = WordleViewModel(answerProvider: { "APPLE" })

        for letter in "APPLE" {
            viewModel.enter(letter)
        }
        viewModel.submitGuess()

        XCTAssertEqual(viewModel.gameState, .won)
        XCTAssertEqual(viewModel.wins, 1)
        XCTAssertEqual(viewModel.guesses, ["APPLE"])
        XCTAssertTrue(viewModel.isShowingAnswer)
        XCTAssertEqual(viewModel.answerText, "APPLE")
    }

    func testWordleRejectsInvalidWord() {
        let viewModel = WordleViewModel(answerProvider: { "APPLE" })

        for letter in "ZZZZZ" {
            viewModel.enter(letter)
        }
        viewModel.submitGuess()

        XCTAssertEqual(viewModel.gameState, .playing)
        XCTAssertTrue(viewModel.guesses.isEmpty)
        XCTAssertEqual(viewModel.message, "Not in word list")
    }

    func testWordleEvaluatesDuplicateLetters() {
        let viewModel = WordleViewModel(answerProvider: { "APPLE" })

        XCTAssertEqual(
            viewModel.evaluation(for: "PIZZA"),
            [.present, .absent, .absent, .absent, .present]
        )
    }

    func testHangmanDetectsWin() {
        let viewModel = HangmanViewModel(wordProvider: { "SWIFT" })

        for letter in "SWIFT" {
            viewModel.guess(letter)
        }

        XCTAssertEqual(viewModel.gameState, .won)
        XCTAssertEqual(viewModel.wins, 1)
        XCTAssertEqual(viewModel.displayWord, "S W I F T")
    }

    func testHangmanDetectsLoss() {
        let viewModel = HangmanViewModel(wordProvider: { "SWIFT" })

        for letter in "ABCDEG" {
            viewModel.guess(letter)
        }

        XCTAssertEqual(viewModel.gameState, .lost)
        XCTAssertEqual(viewModel.losses, 1)
        XCTAssertEqual(viewModel.remainingGuesses, 0)
        XCTAssertEqual(viewModel.displayWord, "S W I F T")
    }
}
