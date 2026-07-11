import Foundation
import Testing
@testable import pocket_games

@MainActor
struct GameStatsPersistenceTests {
    @Test
    func rockPaperScissorsScoreSurvivesRecreation() {
        let defaults = makeDefaults()
        let store = GameStatsStore(defaults: defaults)
        let first = RockPaperScissorsViewModel(
            computerMoveProvider: { .scissors },
            statsStore: store
        )

        first.play(.rock)

        let restored = RockPaperScissorsViewModel(statsStore: GameStatsStore(defaults: defaults))
        #expect(restored.score.playerWins == 1)
        #expect(restored.score.computerWins == 0)
        #expect(restored.score.draws == 0)
    }

    @Test
    func wordGameRecordSurvivesRecreation() {
        let defaults = makeDefaults()
        let allowedWords: Set<String> = ["QUEST"]
        let first = WordleViewModel(
            answerProvider: { "QUEST" },
            allowedWords: allowedWords,
            statsStore: GameStatsStore(defaults: defaults)
        )

        for letter in "QUEST" {
            first.enter(letter)
        }
        first.submitGuess()

        let restored = WordleViewModel(
            answerProvider: { "QUEST" },
            allowedWords: allowedWords,
            statsStore: GameStatsStore(defaults: defaults)
        )
        #expect(restored.wins == 1)
        #expect(restored.losses == 0)
    }

    @Test
    func bestScoreAndAttemptsSurviveRecreation() {
        let defaults = makeDefaults()
        let store = GameStatsStore(defaults: defaults)
        let first = ClicksPerSecondViewModel(duration: 0.1, statsStore: store)

        first.tapTarget()
        first.tapTarget()
        first.advanceForTesting(seconds: 0.1)

        let restored = ClicksPerSecondViewModel(
            duration: 0.1,
            statsStore: GameStatsStore(defaults: defaults)
        )
        #expect(restored.bestClicksPerSecond > 0)
        #expect(restored.attempts == 1)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "GameStatsPersistenceTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }
}
