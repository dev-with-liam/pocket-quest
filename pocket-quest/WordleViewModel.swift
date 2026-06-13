import Combine
import Foundation

@MainActor
final class WordleViewModel: ObservableObject {
    @Published private(set) var guesses: [String] = []
    @Published private(set) var currentGuess = ""
    @Published private(set) var gameState: WordleGameState = .playing
    @Published private(set) var message = "Guess the five-letter word"
    @Published private(set) var wins = 0
    @Published private(set) var losses = 0

    let maxGuesses = 6
    let wordLength = 5

    private let answerProvider: () -> String
    private let allowedWords: Set<String>
    private let statsStore: GameStatsStore
    private var answer = ""

    init(
        answerProvider: @escaping () -> String = { WordleViewModel.answerWords.randomElement() ?? "QUEST" },
        allowedWords: Set<String> = WordleViewModel.defaultAllowedWords,
        statsStore: GameStatsStore = GameStatsStore()
    ) {
        self.answerProvider = answerProvider
        self.allowedWords = allowedWords
        self.statsStore = statsStore
        self.wins = statsStore.integer(forKey: "stats.guessTheWord.wins")
        self.losses = statsStore.integer(forKey: "stats.guessTheWord.losses")
        startNewGame()
    }

    var answerText: String {
        answer
    }

    var isShowingAnswer: Bool {
        gameState != .playing
    }

    var rows: [String] {
        var rows = guesses

        if gameState == .playing {
            rows.append(currentGuess)
        }

        while rows.count < maxGuesses {
            rows.append("")
        }

        return Array(rows.prefix(maxGuesses))
    }

    func enter(_ letter: Character) {
        guard gameState == .playing else {
            wordleDebugLog("enter(\(letter)) ignored; gameState=\(gameState)")
            return
        }

        guard currentGuess.count < wordLength else {
            wordleDebugLog("enter(\(letter)) ignored; currentGuess is already full")
            return
        }

        currentGuess.append(String(letter).uppercased())
        message = "Guess the five-letter word"
        wordleDebugLog("enter(\(letter)); currentGuess='\(currentGuess)'")
    }

    func deleteLetter() {
        guard gameState == .playing else {
            wordleDebugLog("deleteLetter ignored; gameState=\(gameState)")
            return
        }

        guard !currentGuess.isEmpty else {
            wordleDebugLog("deleteLetter ignored; currentGuess is empty")
            return
        }

        currentGuess.removeLast()
        wordleDebugLog("deleteLetter; currentGuess='\(currentGuess)'")
    }

    func submitGuess() {
        wordleDebugLog("submitGuess requested; currentGuess='\(currentGuess)', guesses=\(guesses.count), gameState=\(gameState)")

        guard gameState == .playing else {
            wordleDebugLog("submitGuess ignored; game is not playing")
            return
        }

        guard currentGuess.count == wordLength else {
            message = "Use five letters"
            wordleDebugLog("submitGuess rejected; expected \(wordLength) letters, got \(currentGuess.count)")
            return
        }

        guard currentGuess.allSatisfy(\.isLetter) else {
            message = "Use letters only"
            wordleDebugLog("submitGuess rejected; currentGuess contains non-letters")
            return
        }

        guard allowedWords.contains(currentGuess) else {
            message = "Not in word list"
            wordleDebugLog("submitGuess rejected; '\(currentGuess)' is not in allowedWords")
            return
        }

        guesses.append(currentGuess)
        wordleDebugLog("submitGuess accepted; submitted='\(currentGuess)'")

        if currentGuess == answer {
            gameState = .won
            wins += 1
            message = "You found \(answer)"
            wordleDebugLog("game won; answer='\(answer)'")
        } else if guesses.count == maxGuesses {
            gameState = .lost
            losses += 1
            message = "The word was \(answer)"
            wordleDebugLog("game lost; answer='\(answer)'")
        } else {
            message = "\(maxGuesses - guesses.count) guesses left"
            wordleDebugLog("guess submitted; \(maxGuesses - guesses.count) guesses left")
        }

        saveScore()
        currentGuess = ""
    }

    func startNewGame() {
        answer = normalized(answerProvider())
        guesses = []
        currentGuess = ""
        gameState = .playing
        message = "Guess the five-letter word"
        wordleDebugLog("startNewGame; answer='\(answer)'")
    }

    func evaluation(for guess: String) -> [LetterEvaluation] {
        let guessLetters = Array(guess.uppercased())
        let answerLetters = Array(answer)
        guard guessLetters.count == wordLength else { return [] }

        var result = Array(repeating: LetterEvaluation.absent, count: wordLength)
        var remainingCounts: [Character: Int] = [:]

        for index in 0..<wordLength {
            if guessLetters[index] == answerLetters[index] {
                result[index] = .correct
            } else {
                remainingCounts[answerLetters[index], default: 0] += 1
            }
        }

        for index in 0..<wordLength where result[index] != .correct {
            let letter = guessLetters[index]

            if let count = remainingCounts[letter], count > 0 {
                result[index] = .present
                remainingCounts[letter] = count - 1
            }
        }

        return result
    }

    func keyboardEvaluation(for letter: Character) -> LetterEvaluation? {
        var best: LetterEvaluation?

        for guess in guesses {
            let evaluations = evaluation(for: guess)
            let letters = Array(guess)

            for index in letters.indices where letters[index] == letter {
                best = stronger(best, evaluations[index])
            }
        }

        return best
    }

    private func normalized(_ word: String) -> String {
        let uppercase = word.uppercased().filter(\.isLetter)
        return uppercase.count == wordLength ? uppercase : "QUEST"
    }

    private func stronger(_ current: LetterEvaluation?, _ next: LetterEvaluation) -> LetterEvaluation {
        guard let current else { return next }
        return rank(next) > rank(current) ? next : current
    }

    private func rank(_ evaluation: LetterEvaluation) -> Int {
        switch evaluation {
        case .absent:
            return 0
        case .present:
            return 1
        case .correct:
            return 2
        }
    }

    private func saveScore() {
        statsStore.set(wins, forKey: "stats.guessTheWord.wins")
        statsStore.set(losses, forKey: "stats.guessTheWord.losses")
    }
}

nonisolated private func wordleDebugLog(_ message: String) {
#if DEBUG
    print("[WordleDebug] \(message)")
#endif
}

extension WordleViewModel {
    nonisolated static let answerWords = [
        "APPLE", "BRAVE", "CRANE", "DREAM", "FLAME", "GHOST", "HOUSE", "LIGHT",
        "MUSIC", "PLANT", "QUEST", "RIVER", "SHINE", "STONE", "TIGER", "WORLD"
    ]

    nonisolated static let defaultAllowedWords: Set<String> = {
        let bundledWords = loadBundledFiveLetterWords()
        guard !bundledWords.isEmpty else {
            wordleDebugLog("Bundled dictionary failed to load; using fallback Wordle list")
            return fallbackAllowedWords
        }

        wordleDebugLog("Loaded \(bundledWords.count) five-letter words from bundled dictionary")
        return bundledWords.union(answerWords)
    }()

    private nonisolated static let fallbackAllowedWords: Set<String> = Set(answerWords + [
        "ABOUT", "ABOVE", "ABUSE", "ACTOR", "ACUTE", "ADMIT", "ADOPT", "ADORE",
        "ADULT", "AFTER", "AGAIN", "AGENT", "AGILE", "AGREE", "AHEAD", "ALARM",
        "ALBUM", "ALERT", "ALIEN", "ALIKE", "ALIVE", "ALLOW", "ALONE", "ALONG",
        "ALTER", "AMBER", "AMONG", "ANGER", "ANGLE", "ANGRY", "APART", "ARGUE",
        "ARISE", "ARROW", "ASIDE", "ASSET", "AUDIO", "AVOID", "AWAKE", "AWARD",
        "AWARE", "BADGE", "BASIC", "BATCH", "BEACH", "BEARD", "BEAST", "BEGIN",
        "BEING", "BELLY", "BENCH", "BIRTH", "BLACK", "BLADE", "BLAME", "BLANK",
        "BLAST", "BLEND", "BLESS", "BLIND", "BLOCK", "BLOOD", "BOARD", "BOOST",
        "BRAIN", "BRAND", "BREAD", "BREAK", "BRICK", "BRIDE", "BRIEF", "BRING",
        "BROAD", "BROWN", "BUILD", "CABLE", "CANDY", "CARRY", "CAUSE", "CHAIR",
        "CHART", "CHASE", "CHEAP", "CHECK", "CHEST", "CHIEF", "CHILD", "CHOIR",
        "CIVIL", "CLAIM", "CLASS", "CLEAN", "CLEAR", "CLERK", "CLICK", "CLIFF",
        "CLIMB", "CLOCK", "CLOSE", "CLOUD", "COACH", "COAST", "COLOR", "COUNT",
        "COURT", "COVER", "CRAFT", "CRASH", "CREAM", "CROSS", "CROWD", "CROWN",
        "DAILY", "DANCE", "DEALT", "DEATH", "DEBUT", "DELAY", "DEPTH", "DOUBT",
        "DOZEN", "DRAFT", "DRAMA", "DRINK", "DRIVE", "EARLY", "EARTH", "EMPTY",
        "ENEMY", "ENJOY", "ENTER", "ENTRY", "EQUAL", "ERROR", "EVENT", "EVERY",
        "EXACT", "EXIST", "EXTRA", "FAITH", "FALSE", "FAULT", "FAVOR", "FEAST",
        "FENCE", "FEWER", "FIELD", "FIFTH", "FIGHT", "FINAL", "FIRST", "FIXED",
        "FLASH", "FLEET", "FLOOR", "FOCUS", "FORCE", "FORTH", "FORTY", "FOUND",
        "FRAME", "FRESH", "FRONT", "FRUIT", "GIANT", "GIVEN", "GLASS", "GLOBE",
        "GLORY", "GRACE", "GRADE", "GRAIN", "GRAND", "GRAPE", "GRAPH", "GRASS",
        "GREAT", "GREEN", "GROUP", "GUARD", "GUESS", "GUEST", "GUIDE", "HABIT",
        "HAPPY", "HEARD", "HEART", "HEAVY", "HELLO", "HONEY", "HONOR", "HORSE",
        "HOTEL", "HUMAN", "IDEAL", "IMAGE", "INDEX", "INNER", "INPUT", "ISSUE",
        "JOINT", "JUDGE", "JUICE", "KNOWN",
        "LABEL", "LARGE", "LATER", "LAUGH", "LAYER", "LEARN", "LEASE", "LEAST",
        "LEAVE", "LEGAL", "LEVEL", "LIMIT", "LOCAL", "LOGIC", "LOOSE", "LUCKY",
        "LUNCH", "MAGIC", "MAJOR", "MARCH", "MATCH", "MAYBE", "METAL", "MIGHT",
        "MINOR", "MODEL", "MONEY", "MONTH", "MOUSE", "MOUTH", "MOVIE", "NERVE",
        "NEVER", "NIGHT", "NOBLE", "NOISE", "NORTH", "NOVEL", "NURSE", "OCEAN",
        "OFFER", "OFTEN", "ORDER", "OTHER", "OWNER", "PAINT", "PANEL", "PAPER",
        "PARTY", "PEACE", "PHONE", "PHOTO", "PIANO", "PITCH", "PIZZA", "PLACE",
        "PLAIN", "PLANE", "PRICE", "PRIDE", "PRIME", "PRINT", "PRIZE", "PROOF",
        "PROUD", "QUICK", "QUIET", "RADIO", "RAISE", "RANGE", "RAPID", "REACH",
        "READY", "RIGHT", "RIVAL", "ROUGH", "ROUND", "ROUTE", "ROYAL", "RURAL",
        "SCALE", "SCENE", "SCOPE", "SCORE", "SENSE", "SERVE", "SEVEN", "SHAKE",
        "SHALL", "SHAPE", "SHARE", "SHARP", "SHEEP", "SHEET", "SHELF", "SHELL",
        "SHIFT", "SHIRT", "SHOCK", "SHORT", "SKILL", "SLEEP", "SLIDE", "SMALL",
        "SMART", "SMILE", "SMOKE", "SOLID", "SOLVE", "SOUND", "SOUTH", "SPACE",
        "SPARE", "SPEAK", "SPEED", "SPEND", "SPICE", "SPLIT", "SPORT", "STAFF",
        "STAGE", "STAKE", "STAND", "START", "STATE", "STEAM", "STEEL", "STICK",
        "STILL", "STOCK", "STORE", "STORM", "STORY", "STRIP", "STUDY", "STYLE",
        "SUGAR", "SUPER", "TABLE", "TAKEN", "TASTE", "TEACH", "THANK", "THEIR",
        "THEME", "THERE", "THICK", "THING", "THINK", "THIRD", "THOSE", "THREE",
        "THROW", "TIGHT", "TITLE", "TODAY", "TOPIC", "TOTAL", "TOUCH", "TOUGH",
        "TOWER", "TRACK", "TRADE", "TRAIL", "TRAIN", "TREAT", "TREND", "TRIAL",
        "TRUST", "TRUTH", "TWICE", "UNDER", "UNION", "UNITY", "UNTIL", "UPPER",
        "UPSET", "URBAN", "USAGE", "USUAL", "VALUE", "VIDEO", "VISIT", "VOICE",
        "WASTE", "WATCH", "WATER", "WHEEL", "WHERE", "WHILE", "WHITE", "WHOLE",
        "WHOSE", "WOMAN", "WORRY", "WORTH", "WOULD", "WRITE", "WRONG", "YIELD",
        "YOUNG"
    ])

    private nonisolated static func loadBundledFiveLetterWords() -> Set<String> {
        guard let dictionaryURL = Bundle.main.url(forResource: "english_words", withExtension: "txt")
            ?? Bundle.main.url(forResource: "english_words", withExtension: "txt", subdirectory: "Resources"),
            let contents = try? String(contentsOf: dictionaryURL, encoding: .utf8) else {
            return []
        }

        return Set(
            contents
                .components(separatedBy: .newlines)
                .lazy
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                .filter { word in
                    word.count == 5 && word.allSatisfy(\.isLetter)
                }
        )
    }
}
