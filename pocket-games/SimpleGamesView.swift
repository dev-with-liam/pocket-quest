import Combine
import SwiftUI
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct CoinFlipView: View {
    @State private var message = "Call it before the flip."
    @State private var coinSide = "questionmark.circle.fill"
    @State private var streak = 0
    @State private var isFlipping = false
    @AppStorage("stats.luckyToss.bestStreak") private var bestStreak = 0
    @AppStorage("stats.luckyToss.wins") private var wins = 0
    @AppStorage("stats.luckyToss.losses") private var losses = 0

    var body: some View {
        SimpleGameShell(
            title: "Lucky Toss",
            subtitle: message,
            tint: .yellow,
            statTitle: "Wins / Losses / Best",
            statValue: "\(wins) / \(losses) / \(bestStreak)",
            mascotHint: GameOption.coinFlip.mascotHint
        ) {
            VStack(spacing: 24) {
                Image(systemName: coinSide)
                    .font(.system(size: 96, weight: .black))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.yellow, .orange, .pink)
                    .rotation3DEffect(.degrees(isFlipping ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isFlipping)

                Text("Current Streak: \(streak)")
                    .font(.title3.weight(.heavy))

                HStack(spacing: 12) {
                    Button("Heads") {
                        flip(guess: "Heads")
                    }
                    .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .yellow))

                    Button("Tails") {
                        flip(guess: "Tails")
                    }
                    .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .yellow))
                }
            }
        }
    }

    private func flip(guess: String) {
        let result = Bool.random() ? "Heads" : "Tails"
        coinSide = result == "Heads" ? "h.circle.fill" : "t.circle.fill"
        isFlipping.toggle()

        if guess == result {
            streak += 1
            bestStreak = max(bestStreak, streak)
            wins += 1
            message = "\(result). You called it."
        } else {
            streak = 0
            losses += 1
            message = "\(result). Streak reset."
        }
    }
}

struct TargetTapView: View {
    @State private var score = 0
    @State private var timeLeft = 15
    @State private var targetPosition = CGPoint(x: 0.5, y: 0.5)
    @State private var isPlaying = false
    @AppStorage("stats.bullseyeBlitz.bestScore") private var bestScore = 0
    @AppStorage("stats.bullseyeBlitz.rounds") private var rounds = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        SimpleGameShell(
            title: "Bullseye Blitz",
            subtitle: isPlaying ? "Hit the target before time runs out." : "Start a round and tap every target.",
            tint: .pink,
            statTitle: "Best Hits / Rounds",
            statValue: "\(bestScore) / \(rounds)",
            mascotHint: GameOption.targetTap.mascotHint
        ) {
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    SimpleScoreTile(title: "Score", value: "\(score)", tint: .pink)
                    SimpleScoreTile(title: "Time", value: "\(timeLeft)", tint: .orange)
                }

                GeometryReader { proxy in
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.pink.opacity(0.16), .orange.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Button {
                            hitTarget()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.pink)
                                Circle()
                                    .strokeBorder(.white.opacity(0.75), lineWidth: 5)
                                    .padding(10)
                                Image(systemName: "scope")
                                    .font(.system(size: 30, weight: .black))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .yellow, .orange)
                            }
                            .frame(width: 74, height: 74)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isPlaying)
                        .opacity(isPlaying ? 1 : 0.35)
                        .position(
                            x: targetPosition.x * proxy.size.width,
                            y: targetPosition.y * proxy.size.height
                        )
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: targetPosition)
                    }
                }
                .frame(height: 320)

                Button(isPlaying ? "Restart" : "Start") {
                    startRound()
                }
                .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .pink))
            }
        }
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            timeLeft -= 1
            if timeLeft <= 0 {
                isPlaying = false
                bestScore = max(bestScore, score)
                rounds += 1
            }
        }
    }

    private func startRound() {
        score = 0
        timeLeft = 15
        isPlaying = true
        moveTarget()
    }

    private func hitTarget() {
        guard isPlaying else { return }
        score += 1
        moveTarget()
    }

    private func moveTarget() {
        targetPosition = CGPoint(
            x: Double.random(in: 0.14...0.86),
            y: Double.random(in: 0.16...0.84)
        )
    }
}

struct MemoryMatchView: View {
    @State private var cards: [MemoryCard] = MemoryMatchView.newDeck()
    @State private var selectedIDs: [UUID] = []
    @State private var moves = 0
    @State private var message = "Match all pairs."
    @AppStorage("stats.pairFinder.bestMoves") private var bestMoves = 0
    @AppStorage("stats.pairFinder.clears") private var clears = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        SimpleGameShell(
            title: "Pair Finder",
            subtitle: message,
            tint: .indigo,
            statTitle: "Best Moves / Clears",
            statValue: "\(bestMoves == 0 ? "--" : String(bestMoves)) / \(clears)",
            mascotHint: GameOption.memoryMatch.mascotHint
        ) {
            VStack(spacing: 18) {
                SimpleScoreTile(title: "Moves", value: "\(moves)", tint: .indigo)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(cards) { card in
                        Button {
                            choose(card)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(card.isFaceUp || card.isMatched ? Color.indigo.opacity(0.92) : Color.pink.opacity(0.14))

                                if card.isFaceUp || card.isMatched {
                                    Image(systemName: card.symbol)
                                        .font(.system(size: 28, weight: .black))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .mint, .cyan)
                                } else {
                                    Image(systemName: "questionmark")
                                        .font(.system(size: 28, weight: .black))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.pink, .orange, .yellow)
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                        .disabled(card.isMatched)
                    }
                }

                Button("New Deck") {
                    reset()
                }
                .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .indigo))
            }
        }
    }

    private func choose(_ card: MemoryCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }),
              !cards[index].isFaceUp,
              selectedIDs.count < 2 else { return }

        cards[index].isFaceUp = true
        selectedIDs.append(card.id)

        guard selectedIDs.count == 2 else { return }
        moves += 1

        let selectedIndexes = selectedIDs.compactMap { id in
            cards.firstIndex { $0.id == id }
        }

        guard selectedIndexes.count == 2 else {
            selectedIDs = []
            return
        }

        if cards[selectedIndexes[0]].symbol == cards[selectedIndexes[1]].symbol {
            cards[selectedIndexes[0]].isMatched = true
            cards[selectedIndexes[1]].isMatched = true
            selectedIDs = []
            message = cards.allSatisfy(\.isMatched) ? "Board cleared." : "Nice match."

            if cards.allSatisfy(\.isMatched) {
                bestMoves = bestMoves == 0 ? moves : min(bestMoves, moves)
                clears += 1
            }
        } else {
            message = "Try another pair."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                for selectedIndex in selectedIndexes where cards.indices.contains(selectedIndex) {
                    cards[selectedIndex].isFaceUp = false
                }
                selectedIDs = []
            }
        }
    }

    private func reset() {
        cards = Self.newDeck()
        selectedIDs = []
        moves = 0
        message = "Match all pairs."
    }

    private static func newDeck() -> [MemoryCard] {
        let symbols = ["star.fill", "heart.fill", "bolt.fill", "moon.fill", "leaf.fill", "flame.fill"]
        return (symbols + symbols).map { MemoryCard(symbol: $0) }.shuffled()
    }
}

private struct MemoryCard: Identifiable {
    let id = UUID()
    let symbol: String
    var isFaceUp = false
    var isMatched = false
}

struct NumberGuessView: View {
    @State private var secret = Int.random(in: 1...20)
    @State private var guess = 10.0
    @State private var attempts = 0
    @State private var message = "Guess a number from 1 to 20."
    @State private var isSolved = false
    @AppStorage("stats.secretNumber.bestAttempts") private var bestAttempts = 0
    @AppStorage("stats.secretNumber.wins") private var wins = 0
    @AppStorage("stats.secretNumber.totalAttempts") private var totalAttempts = 0

    var body: some View {
        SimpleGameShell(
            title: "Secret Number",
            subtitle: message,
            tint: .teal,
            statTitle: "Wins / Guesses / Best",
            statValue: "\(wins) / \(totalAttempts) / \(bestAttempts == 0 ? "--" : String(bestAttempts))",
            mascotHint: GameOption.numberGuess.mascotHint
        ) {
            VStack(spacing: 24) {
                Text("\(Int(guess))")
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .foregroundStyle(.teal)

                Slider(value: $guess, in: 1...20, step: 1)
                    .tint(.teal)

                HStack(spacing: 12) {
                    Button("Guess") {
                        submitGuess()
                    }
                    .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .teal))
                    .disabled(isSolved)

                    Button("New") {
                        reset()
                    }
                    .buttonStyle(SimpleGameSecondaryButtonStyle())
                }

                Text("Attempts: \(attempts)")
                    .font(.headline)
                    .foregroundStyle(BrandPalette.textGradient)
            }
        }
    }

    private func submitGuess() {
        attempts += 1
        totalAttempts += 1
        let value = Int(guess)

        if value == secret {
            message = "Correct in \(attempts) attempts."
            bestAttempts = bestAttempts == 0 ? attempts : min(bestAttempts, attempts)
            wins += 1
            isSolved = true
        } else if value < secret {
            message = "Too low."
        } else {
            message = "Too high."
        }
    }

    private func reset() {
        secret = Int.random(in: 1...20)
        guess = 10
        attempts = 0
        message = "Guess a number from 1 to 20."
        isSolved = false
    }
}

struct NimDuelView: View {
    @State private var stones = 21
    @State private var message = "Take 1 to 3 stones. Leave the computer the last stone."
    @State private var isGameOver = false
    @AppStorage("stats.stoneStrategy.wins") private var wins = 0
    @AppStorage("stats.stoneStrategy.losses") private var losses = 0

    var body: some View {
        SimpleGameShell(
            title: "Stone Strategy",
            subtitle: message,
            tint: .purple,
            statTitle: "Wins / Losses",
            statValue: "\(wins) / \(losses)",
            mascotHint: GameOption.nimDuel.mascotHint
        ) {
            VStack(spacing: 22) {
                Text("\(stones)")
                    .font(.system(size: 82, weight: .black, design: .rounded))
                    .foregroundStyle(.purple)

                Text("stones left")
                    .font(.headline)
                    .foregroundStyle(BrandPalette.textGradient)

                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { amount in
                        Button("Take \(amount)") {
                            playerTakes(amount)
                        }
                        .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .purple))
                        .disabled(isGameOver || stones < amount)
                    }
                }

                Button("New Duel") {
                    reset()
                }
                .buttonStyle(SimpleGameSecondaryButtonStyle())
            }
        }
    }

    private func playerTakes(_ amount: Int) {
        guard !isGameOver else { return }
        stones -= amount

        if stones <= 0 {
            message = "You took the last stone. Computer wins."
            losses += 1
            isGameOver = true
            return
        }

        let computerTake = min(max((stones - 1) % 4, 1), min(3, stones))
        stones -= computerTake

        if stones <= 0 {
            message = "Computer took the last stone. You win."
            wins += 1
            isGameOver = true
        } else {
            message = "Computer took \(computerTake). Your move."
        }
    }

    private func reset() {
        stones = 21
        message = "Take 1 to 3 stones. Leave the computer the last stone."
        isGameOver = false
    }
}

struct CodeBreakerView: View {
    private let colors: [CodeColor] = [.red, .blue, .green, .yellow]

    @State private var secret: [CodeColor] = CodeBreakerView.newSecret()
    @State private var guess: [CodeColor] = [.red, .red, .red]
    @State private var attempts = 0
    @State private var message = "Crack the three-color code."
    @State private var isSolved = false
    @AppStorage("stats.patternLock.bestAttempts") private var bestAttempts = 0
    @AppStorage("stats.patternLock.solves") private var solves = 0
    @AppStorage("stats.patternLock.totalAttempts") private var totalAttempts = 0

    var body: some View {
        SimpleGameShell(
            title: "Pattern Lock",
            subtitle: message,
            tint: .red,
            statTitle: "Solves / Tries / Best",
            statValue: "\(solves) / \(totalAttempts) / \(bestAttempts == 0 ? "--" : String(bestAttempts))",
            mascotHint: GameOption.codeBreaker.mascotHint
        ) {
            VStack(spacing: 24) {
                HStack(spacing: 14) {
                    ForEach(guess.indices, id: \.self) { index in
                        Button {
                            cycleColor(at: index)
                        } label: {
                            Circle()
                                .fill(guess[index].color)
                                .frame(width: 70, height: 70)
                                .overlay {
                                    Circle().strokeBorder(.white.opacity(0.8), lineWidth: 4)
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(isSolved)
                    }
                }

                HStack(spacing: 12) {
                    Button("Check") {
                        checkGuess()
                    }
                    .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .red))
                    .disabled(isSolved)

                    Button("New Code") {
                        reset()
                    }
                    .buttonStyle(SimpleGameSecondaryButtonStyle())
                }
            }
        }
    }

    private func cycleColor(at index: Int) {
        guard let currentIndex = colors.firstIndex(of: guess[index]) else { return }
        guess[index] = colors[(currentIndex + 1) % colors.count]
    }

    private func checkGuess() {
        attempts += 1
        totalAttempts += 1
        let exact = zip(guess, secret).filter { $0 == $1 }.count

        if exact == secret.count {
            message = "Code cracked in \(attempts) attempts."
            isSolved = true
            solves += 1
            bestAttempts = bestAttempts == 0 ? attempts : min(bestAttempts, attempts)
        } else {
            message = "\(exact) exact match\(exact == 1 ? "" : "es"). Keep trying."
        }
    }

    private func reset() {
        secret = Self.newSecret()
        guess = [.red, .red, .red]
        attempts = 0
        message = "Crack the three-color code."
        isSolved = false
    }

    private static func newSecret() -> [CodeColor] {
        (0..<3).map { _ in CodeColor.allCases.randomElement() ?? .red }
    }
}

private enum CodeColor: CaseIterable, Equatable {
    case red
    case blue
    case green
    case yellow

    var color: Color {
        switch self {
        case .red:
            return .red
        case .blue:
            return .blue
        case .green:
            return .green
        case .yellow:
            return .yellow
        }
    }
}

struct StopTimerView: View {
    @State private var startDate: Date?
    @State private var elapsed = 0.0
    @State private var message = "Stop as close to 5.00 seconds as you can."
    @State private var isRunning = false
    @AppStorage("stats.timeFreeze.bestMiss") private var bestMiss = -1.0
    @AppStorage("stats.timeFreeze.attempts") private var attempts = 0

    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        SimpleGameShell(
            title: "Time Freeze",
            subtitle: message,
            tint: .blue,
            statTitle: "Best Miss / Tries",
            statValue: "\(bestMiss < 0 ? "--" : String(format: "%.2fs", bestMiss)) / \(attempts)",
            mascotHint: GameOption.stopTimer.mascotHint
        ) {
            VStack(spacing: 26) {
                Text(String(format: "%.2f", elapsed))
                    .font(.system(size: 82, weight: .black, design: .rounded))
                    .foregroundStyle(.blue)

                Button(isRunning ? "Stop" : "Start") {
                    isRunning ? stop() : start()
                }
                .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .blue))
            }
        }
        .onReceive(timer) { now in
            guard isRunning, let startDate else { return }
            elapsed = now.timeIntervalSince(startDate)
        }
    }

    private func start() {
        elapsed = 0
        startDate = Date()
        isRunning = true
        message = "Stop at exactly 5.00."
    }

    private func stop() {
        isRunning = false
        let miss = abs(elapsed - 5)
        bestMiss = bestMiss < 0 ? miss : min(bestMiss, miss)
        attempts += 1
        message = "Missed by \(String(format: "%.2f", miss)) seconds."
    }
}

struct ColorRushView: View {
    private let colors: [RushColor] = [.red, .blue, .green, .yellow]

    @State private var target: RushColor = .red
    @State private var shown: RushColor = .blue
    @State private var score = 0
    @State private var timeLeft = 20
    @State private var isPlaying = false
    @State private var message = "Tap only when the colors match."
    @AppStorage("stats.hueMatch.bestScore") private var bestScore = 0
    @AppStorage("stats.hueMatch.rounds") private var rounds = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        SimpleGameShell(
            title: "Hue Match",
            subtitle: message,
            tint: .orange,
            statTitle: "Best Score / Rounds",
            statValue: "\(bestScore) / \(rounds)",
            mascotHint: GameOption.colorRush.mascotHint
        ) {
            VStack(spacing: 22) {
                HStack(spacing: 12) {
                    SimpleScoreTile(title: "Score", value: "\(score)", tint: .orange)
                    SimpleScoreTile(title: "Time", value: "\(timeLeft)", tint: .red)
                }

                VStack(spacing: 12) {
                    Text("Target: \(target.name)")
                        .font(.title3.weight(.heavy))

                    Button {
                        tapColor()
                    } label: {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(shown.color)
                            .frame(height: 180)
                            .overlay {
                                Text(shown.name)
                                    .font(.largeTitle.weight(.black))
                                    .foregroundStyle(BrandPalette.paperElevated)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(!isPlaying)
                }

                Button(isPlaying ? "Restart" : "Start") {
                    startRound()
                }
                .buttonStyle(SimpleGamePrimaryButtonStyle(tint: .orange))
            }
        }
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            timeLeft -= 1
            shown = colors.randomElement() ?? .red

            if timeLeft <= 0 {
                isPlaying = false
                bestScore = max(bestScore, score)
                rounds += 1
                message = "Round over."
            }
        }
    }

    private func startRound() {
        score = 0
        timeLeft = 20
        target = colors.randomElement() ?? .red
        shown = colors.randomElement() ?? .blue
        message = "Tap only when the colors match."
        isPlaying = true
    }

    private func tapColor() {
        guard isPlaying else { return }

        if shown == target {
            score += 1
            target = colors.randomElement() ?? .red
            message = "Nice. New target."
        } else {
            score = max(0, score - 1)
            message = "Wrong color. -1 point."
        }

        shown = colors.randomElement() ?? .blue
    }
}

private enum RushColor: CaseIterable, Equatable {
    case red
    case blue
    case green
    case yellow

    var name: String {
        switch self {
        case .red:
            return "Red"
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        case .yellow:
            return "Yellow"
        }
    }

    var color: Color {
        switch self {
        case .red:
            return .red
        case .blue:
            return .blue
        case .green:
            return .green
        case .yellow:
            return .yellow
        }
    }
}

struct GameMascotCard: View {
    let hint: String
    let tint: Color
    @AppStorage("pocketQuestYetiSkin") private var yetiSkinRaw = YetiSkin.artist.rawValue

    private var skin: YetiSkin {
        YetiSkin(rawValue: yetiSkinRaw) ?? .artist
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            YetiMascotView(tint: tint)
                .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(skin.label) says 🎨✨")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BrandPalette.textGradient)

                Text(hint)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandPalette.textGradient)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [tint.opacity(0.18), BrandPalette.paperElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(tint.opacity(0.22), lineWidth: 1)
        )
    }
}

struct YetiMascotView: View {
    let tint: Color
    let skinOverride: YetiSkin?
    @AppStorage("pocketQuestYetiSkin") private var yetiSkinRaw = YetiSkin.artist.rawValue

    init(tint: Color, skinOverride: YetiSkin? = nil) {
        self.tint = tint
        self.skinOverride = skinOverride
    }

    private var skin: YetiSkin {
        skinOverride ?? YetiSkin(rawValue: yetiSkinRaw) ?? .artist
    }

    var body: some View {
        fallbackYeti
        .accessibilityHidden(true)
    }

    private var fallbackYeti: some View {
        ZStack {
            // Soft halo
            Circle()
                .fill(
                    LinearGradient(
                        colors: skin.bodyGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 82, height: 82)

            // Beret
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: skin.accentGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 28)
                .offset(x: -5, y: -25)
                .rotationEffect(.degrees(-10))

            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 12, height: 12)
                .offset(x: -16, y: -35)

            // Head
            Circle()
                .fill(
                    LinearGradient(
                        colors: skin.bodyGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .offset(y: -1)

            Circle()
                .fill(Color(red: 0.18, green: 0.28, blue: 0.36))
                .frame(width: 6, height: 6)
                .offset(x: -8, y: -4)

            Circle()
                .fill(Color(red: 0.18, green: 0.28, blue: 0.36))
                .frame(width: 6, height: 6)
                .offset(x: 8, y: -4)

            Capsule()
                .fill(Color(red: 0.18, green: 0.28, blue: 0.36))
                .frame(width: 14, height: 5)
                .offset(y: 8)

            // Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: skin.bodyGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 50)
                .offset(y: 18)

            // Arms
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [skin.propColor, tint.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 10, height: 30)
                .rotationEffect(.degrees(-24))
                .offset(x: -26, y: 15)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [skin.propColor, tint.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 10, height: 30)
                .rotationEffect(.degrees(24))
                .offset(x: 26, y: 15)

            // Palette
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: skin.accentGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 28)
                .rotationEffect(.degrees(14))
                .offset(x: 27, y: 18)

            Circle().fill(.white).frame(width: 4, height: 4).offset(x: 20, y: 12)
            Circle().fill(.white).frame(width: 4, height: 4).offset(x: 28, y: 18)
            Circle().fill(.white).frame(width: 4, height: 4).offset(x: 22, y: 24)

            // Brush
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.92, blue: 0.86), Color(red: 0.72, green: 0.64, blue: 0.54)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 6, height: 24)
                .rotationEffect(.degrees(-30))
                .offset(x: -30, y: 24)

            Circle()
                .fill(skin.propColor)
                .frame(width: 10, height: 10)
                .offset(x: -37, y: 32)
        }
        .shadow(color: tint.opacity(0.16), radius: 6, y: 3)
    }
}

private struct SimpleGameShell<Content: View>: View {
    let title: String
    let subtitle: String
    let tint: Color
    let statTitle: String
    let statValue: String
    let mascotHint: String
    @ViewBuilder let content: Content
    @AppStorage("pocketQuestThemeTextColor") private var themeTextColor = ThemeTextColor.gradientGreenBlue.rawValue
    @AppStorage("pocketQuestThemeBackground") private var themeBackground = ThemeBackground.retroSky.rawValue

    private var selectedTextColor: Color {
        ThemeTextColor(rawValue: themeTextColor)?.accentColor ?? .primary
    }

    private var selectedTextStyle: AnyShapeStyle {
        ThemeTextColor(rawValue: themeTextColor)?.foregroundStyle ?? AnyShapeStyle(Color.primary)
    }

    private var selectedBackground: ThemeBackground {
        ThemeBackground(rawValue: themeBackground) ?? .candy
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: selectedBackground.colors + [tint.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(.largeTitle, design: .rounded, weight: .black))
                                .foregroundStyle(selectedTextStyle)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)

                            Text(subtitle)
                                .font(.headline)
                                .foregroundStyle(selectedTextColor.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                            Spacer(minLength: 12)
                        }

                        SimpleScoreTile(title: statTitle, value: statValue, tint: tint)
                    }
                    .padding(18)
                    .background(
                        LinearGradient(
                            colors: [tint.opacity(0.22), BrandPalette.paperElevated],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )

                    GameMascotCard(hint: mascotHint, tint: tint)

                    content
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [BrandPalette.paperElevated, tint.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct SimpleScoreTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(BrandPalette.navy.opacity(0.72))
            Text(value)
                .font(.title2.weight(.black))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            LinearGradient(
                colors: [tint.opacity(0.18), BrandPalette.paperElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

private struct SimpleGamePrimaryButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(BrandPalette.paperElevated)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [tint, tint.opacity(0.82), BrandPalette.plum.opacity(0.90)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

private struct SimpleGameSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(BrandPalette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.18), Color.pink.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
