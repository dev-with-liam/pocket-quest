import Combine
import Foundation

nonisolated struct LogicQuestion: Identifiable, Equatable {
    let id: String
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String
}

@MainActor
final class LogicPopViewModel: ObservableObject {
    @Published private(set) var questions: [LogicQuestion]
    @Published private(set) var questionIndex = 0
    @Published private(set) var selectedIndex: Int?
    @Published private(set) var score = 0
    @Published private(set) var bestScore = 0
    @Published private(set) var totalCorrect = 0
    @Published private(set) var rounds = 0
    @Published private(set) var isRoundComplete = false

    let questionsPerRound: Int

    private let questionBank: [LogicQuestion]
    private let statsStore: GameStatsStore

    init(
        questionBank: [LogicQuestion] = LogicPopViewModel.defaultQuestions,
        questionsPerRound: Int = 5,
        statsStore: GameStatsStore = GameStatsStore()
    ) {
        self.questionBank = questionBank
        self.questionsPerRound = min(max(1, questionsPerRound), questionBank.count)
        self.statsStore = statsStore
        self.questions = Array(questionBank.prefix(min(max(1, questionsPerRound), questionBank.count)))
        self.bestScore = statsStore.integer(forKey: "stats.logicPop.bestScore")
        self.totalCorrect = statsStore.integer(forKey: "stats.logicPop.totalCorrect")
        self.rounds = statsStore.integer(forKey: "stats.logicPop.rounds")
        startNewRound(shuffle: questionBank == LogicPopViewModel.defaultQuestions)
    }

    var currentQuestion: LogicQuestion {
        questions[questionIndex]
    }

    var progressText: String {
        "\(min(questionIndex + 1, questionsPerRound)) of \(questionsPerRound)"
    }

    var isAnswerCorrect: Bool? {
        selectedIndex.map { $0 == currentQuestion.correctIndex }
    }

    func chooseAnswer(at index: Int) {
        guard selectedIndex == nil, currentQuestion.choices.indices.contains(index) else { return }
        selectedIndex = index

        if index == currentQuestion.correctIndex {
            score += 1
            totalCorrect += 1
            statsStore.set(totalCorrect, forKey: "stats.logicPop.totalCorrect")
        }
    }

    func continueRound() {
        guard selectedIndex != nil else { return }

        if questionIndex + 1 < questionsPerRound {
            questionIndex += 1
            selectedIndex = nil
        } else {
            completeRound()
        }
    }

    func startNewRound(shuffle: Bool = true) {
        questions = shuffle
            ? Array(questionBank.shuffled().prefix(questionsPerRound))
            : Array(questionBank.prefix(questionsPerRound))
        questionIndex = 0
        selectedIndex = nil
        score = 0
        isRoundComplete = false
    }

    private func completeRound() {
        isRoundComplete = true
        rounds += 1
        bestScore = max(bestScore, score)
        statsStore.set(rounds, forKey: "stats.logicPop.rounds")
        statsStore.set(bestScore, forKey: "stats.logicPop.bestScore")
    }
}

extension LogicPopViewModel {
    nonisolated static let defaultQuestions: [LogicQuestion] = [
        LogicQuestion(
            id: "sequence-two",
            prompt: "What comes next?\n2, 4, 6, 8, ?",
            choices: ["A sandwich", "10", "Tuesday", "Purple"],
            correctIndex: 1,
            explanation: "Each number increases by 2, so the next number is 10."
        ),
        LogicQuestion(
            id: "odd-shape",
            prompt: "Which one does not belong?",
            choices: ["Triangle", "A sleepy potato", "Circle", "The moon's shoe"],
            correctIndex: 2,
            explanation: "A circle has no straight sides. The other shapes do."
        ),
        LogicQuestion(
            id: "days",
            prompt: "If today is Monday, what day is three days later?",
            choices: ["Monday 2", "Wednesday's uncle", "Thursday", "Pizza day"],
            correctIndex: 2,
            explanation: "Tuesday is one day later, Wednesday is two, and Thursday is three."
        ),
        LogicQuestion(
            id: "doubling",
            prompt: "What comes next?\n1, 2, 4, 8, ?",
            choices: ["A loud banana", "Fish", "Infinity-ish", "16"],
            correctIndex: 3,
            explanation: "Each number doubles, so 8 becomes 16."
        ),
        LogicQuestion(
            id: "all-cats",
            prompt: "All cats are animals. Milo is a cat. What must be true?",
            choices: ["Milo pays taxes", "Milo is an animal", "Milo is a toaster", "Milo owns the moon"],
            correctIndex: 1,
            explanation: "If every cat is an animal and Milo is a cat, Milo must be an animal."
        ),
        LogicQuestion(
            id: "letters",
            prompt: "What comes next?\nA, C, E, G, ?",
            choices: ["A second G", "I", "The letter 12", "Banana"],
            correctIndex: 1,
            explanation: "The pattern skips one letter each time, so I follows G."
        ),
        LogicQuestion(
            id: "heavier",
            prompt: "A rock is heavier than a leaf. A brick is heavier than the rock. Which is heaviest?",
            choices: ["A thought", "Seven feathers in a coat", "Brick", "Gravity's lunch"],
            correctIndex: 2,
            explanation: "The brick is heavier than the rock, which is already heavier than the leaf."
        ),
        LogicQuestion(
            id: "missing-number",
            prompt: "Which number is missing?\n5, 10, 15, ?, 25",
            choices: ["The number potato", "A confused 7", "20", "Yesterday"],
            correctIndex: 2,
            explanation: "The sequence adds 5 each time, so the missing number is 20."
        ),
        LogicQuestion(
            id: "opposite",
            prompt: "Which word is the opposite of EMPTY?",
            choices: ["Screaming", "Full", "Wednesday", "A bucket with Wi-Fi"],
            correctIndex: 1,
            explanation: "Full is the opposite of empty."
        ),
        LogicQuestion(
            id: "pair",
            prompt: "Bird is to nest as bee is to...",
            choices: ["Hive", "A tiny apartment with rent", "The sun", "A bee-sized parking lot"],
            correctIndex: 0,
            explanation: "A bird lives in a nest, and a bee lives in a hive."
        )
    ]
}
