import Foundation
import Testing
@testable import pocket_quest

@MainActor
struct LogicPopViewModelTests {
    private let questions = [
        LogicQuestion(
            id: "one",
            prompt: "1 + 1?",
            choices: ["1", "2"],
            correctIndex: 1,
            explanation: "One plus one is two."
        ),
        LogicQuestion(
            id: "two",
            prompt: "Next: 2, 4, 6?",
            choices: ["7", "8"],
            correctIndex: 1,
            explanation: "The pattern adds two."
        )
    ]

    @Test
    func answerCanOnlyScoreOnce() {
        let viewModel = LogicPopViewModel(
            questionBank: questions,
            questionsPerRound: 2,
            statsStore: GameStatsStore(defaults: nil)
        )

        viewModel.chooseAnswer(at: 1)
        viewModel.chooseAnswer(at: 1)

        #expect(viewModel.score == 1)
        #expect(viewModel.totalCorrect == 1)
    }

    @Test
    func completedRoundSavesBestScoreAndStats() {
        let defaults = UserDefaults(suiteName: "LogicPopTests.\(UUID().uuidString)")!
        let first = LogicPopViewModel(
            questionBank: questions,
            questionsPerRound: 2,
            statsStore: GameStatsStore(defaults: defaults)
        )

        first.chooseAnswer(at: 1)
        first.continueRound()
        first.chooseAnswer(at: 1)
        first.continueRound()

        #expect(first.isRoundComplete)
        #expect(first.bestScore == 2)
        #expect(first.rounds == 1)

        let restored = LogicPopViewModel(
            questionBank: questions,
            questionsPerRound: 2,
            statsStore: GameStatsStore(defaults: defaults)
        )
        #expect(restored.bestScore == 2)
        #expect(restored.totalCorrect == 2)
        #expect(restored.rounds == 1)
    }
}
