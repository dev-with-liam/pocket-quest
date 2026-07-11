import Combine
import Foundation

@MainActor
final class HangmanViewModel: ObservableObject {
    @Published private(set) var guessedLetters: Set<Character> = []
    @Published private(set) var wrongGuesses: [Character] = []
    @Published private(set) var gameState: HangmanGameState = .playing
    @Published private(set) var wins = 0
    @Published private(set) var losses = 0

    let maxWrongGuesses = 6

    private let wordProvider: () -> String
    private var word = ""

    init(wordProvider: @escaping () -> String = { HangmanViewModel.words.randomElement() ?? "SWIFT" }) {
        self.wordProvider = wordProvider
        startNewGame()
    }

    var displayWord: String {
        guard gameState == .playing else {
            return word.map(String.init).joined(separator: " ")
        }

        return word.map { guessedLetters.contains($0) ? String($0) : "_" }.joined(separator: " ")
    }

    var wordText: String {
        word
    }

    var remainingGuesses: Int {
        max(0, maxWrongGuesses - wrongGuesses.count)
    }

    var statusText: String {
        switch gameState {
        case .playing:
            return "\(remainingGuesses) misses left"
        case .won:
            return "You saved \(word)"
        case .lost:
            return "The word was \(word)"
        }
    }

    func guess(_ letter: Character) {
        guard gameState == .playing else { return }

        let normalizedLetter = Character(String(letter).uppercased())
        guard normalizedLetter.isLetter, !guessedLetters.contains(normalizedLetter) else { return }

        guessedLetters.insert(normalizedLetter)

        if !word.contains(normalizedLetter) {
            wrongGuesses.append(normalizedLetter)
        }

        updateGameState()
    }

    func startNewGame() {
        word = normalized(wordProvider())
        guessedLetters = []
        wrongGuesses = []
        gameState = .playing
    }

    private func updateGameState() {
        if word.allSatisfy({ guessedLetters.contains($0) }) {
            gameState = .won
            wins += 1
        } else if wrongGuesses.count >= maxWrongGuesses {
            gameState = .lost
            losses += 1
        }
    }

    private func normalized(_ value: String) -> String {
        let uppercase = value.uppercased().filter(\.isLetter)
        return uppercase.isEmpty ? "SWIFT" : uppercase
    }
}

extension HangmanViewModel {
    nonisolated static let words = [
        "SWIFT", "PUZZLE", "ARCADE", "GALAXY", "CASTLE", "PLANET", "ROCKET",
        "BUTTON", "SCREEN", "PLAYER", "QUEST", "PIXEL", "DRAGON", "BRIDGE"
    ]
}
