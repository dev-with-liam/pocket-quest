import Combine
import SwiftUI

struct CoinFlipView: View {
    @State private var message = "Call it before the flip."
    @State private var coinSide = "questionmark.circle.fill"
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var isFlipping = false

    var body: some View {
        SimpleGameShell(
            title: "Coin Flip",
            subtitle: message,
            tint: .yellow,
            statTitle: "Best Streak",
            statValue: "\(bestStreak)"
        ) {
            VStack(spacing: 24) {
                Image(systemName: coinSide)
                    .font(.system(size: 96, weight: .black))
                    .foregroundStyle(.yellow)
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
            message = "\(result). You called it."
        } else {
            streak = 0
            message = "\(result). Streak reset."
        }
    }
}

struct TargetTapView: View {
    @State private var score = 0
    @State private var bestScore = 0
    @State private var timeLeft = 15
    @State private var targetPosition = CGPoint(x: 0.5, y: 0.5)
    @State private var isPlaying = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        SimpleGameShell(
            title: "Target Tap",
            subtitle: isPlaying ? "Hit the target before time runs out." : "Start a round and tap every target.",
            tint: .pink,
            statTitle: "Best Hits",
            statValue: "\(bestScore)"
        ) {
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    SimpleScoreTile(title: "Score", value: "\(score)", tint: .pink)
                    SimpleScoreTile(title: "Time", value: "\(timeLeft)", tint: .orange)
                }

                GeometryReader { proxy in
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.primary.opacity(0.06))

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
                                    .foregroundStyle(.white)
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
    @State private var bestMoves: Int?
    @State private var message = "Match all pairs."

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        SimpleGameShell(
            title: "Memory Match",
            subtitle: message,
            tint: .indigo,
            statTitle: "Best Moves",
            statValue: bestMoves.map(String.init) ?? "--"
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
                                    .fill(card.isFaceUp || card.isMatched ? Color.indigo : Color.primary.opacity(0.12))

                                Image(systemName: card.isFaceUp || card.isMatched ? card.symbol : "questionmark")
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundStyle(card.isFaceUp || card.isMatched ? .white : .secondary)
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
                bestMoves = min(bestMoves ?? moves, moves)
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
    @State private var bestAttempts: Int?
    @State private var message = "Guess a number from 1 to 20."

    var body: some View {
        SimpleGameShell(
            title: "Number Guess",
            subtitle: message,
            tint: .teal,
            statTitle: "Best Guess",
            statValue: bestAttempts.map(String.init) ?? "--"
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

                    Button("New") {
                        reset()
                    }
                    .buttonStyle(SimpleGameSecondaryButtonStyle())
                }

                Text("Attempts: \(attempts)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func submitGuess() {
        attempts += 1
        let value = Int(guess)

        if value == secret {
            message = "Correct in \(attempts) attempts."
            bestAttempts = min(bestAttempts ?? attempts, attempts)
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
    }
}

struct NimDuelView: View {
    @State private var stones = 21
    @State private var message = "Take 1 to 3 stones. Leave the computer the last stone."
    @State private var wins = 0
    @State private var isGameOver = false

    var body: some View {
        SimpleGameShell(
            title: "Nim Duel",
            subtitle: message,
            tint: .purple,
            statTitle: "Wins",
            statValue: "\(wins)"
        ) {
            VStack(spacing: 22) {
                Text("\(stones)")
                    .font(.system(size: 82, weight: .black, design: .rounded))
                    .foregroundStyle(.purple)

                Text("stones left")
                    .font(.headline)
                    .foregroundStyle(.secondary)

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

    var body: some View {
        SimpleGameShell(
            title: "Code Breaker",
            subtitle: message,
            tint: .red,
            statTitle: "Attempts",
            statValue: "\(attempts)"
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
        let exact = zip(guess, secret).filter { $0 == $1 }.count

        if exact == secret.count {
            message = "Code cracked in \(attempts) attempts."
            isSolved = true
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
    @State private var bestMiss: Double?
    @State private var message = "Stop as close to 5.00 seconds as you can."
    @State private var isRunning = false

    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        SimpleGameShell(
            title: "Stop Timer",
            subtitle: message,
            tint: .blue,
            statTitle: "Best Miss",
            statValue: bestMiss.map { String(format: "%.2fs", $0) } ?? "--"
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
        bestMiss = min(bestMiss ?? miss, miss)
        message = "Missed by \(String(format: "%.2f", miss)) seconds."
    }
}

struct ColorRushView: View {
    private let colors: [RushColor] = [.red, .blue, .green, .yellow]

    @State private var target: RushColor = .red
    @State private var shown: RushColor = .blue
    @State private var score = 0
    @State private var bestScore = 0
    @State private var timeLeft = 20
    @State private var isPlaying = false
    @State private var message = "Tap only when the colors match."

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        SimpleGameShell(
            title: "Color Rush",
            subtitle: message,
            tint: .orange,
            statTitle: "Best Score",
            statValue: "\(bestScore)"
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
                                    .foregroundStyle(.white)
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

private struct SimpleGameShell<Content: View>: View {
    let title: String
    let subtitle: String
    let tint: Color
    let statTitle: String
    let statValue: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, tint.opacity(0.16), Color.secondary.opacity(0.10)],
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
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.75)

                                Text(subtitle)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 12)
                        }

                        SimpleScoreTile(title: statTitle, value: statValue, tint: tint)
                    }
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                    content
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.black))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SimpleGamePrimaryButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

private struct SimpleGameSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
