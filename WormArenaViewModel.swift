import Combine
import Foundation

nonisolated struct WormArenaPoint: Hashable {
    let x: Int
    let y: Int

    func moved(_ direction: WormArenaDirection) -> WormArenaPoint {
        switch direction {
        case .up:
            WormArenaPoint(x: x, y: y - 1)
        case .down:
            WormArenaPoint(x: x, y: y + 1)
        case .left:
            WormArenaPoint(x: x - 1, y: y)
        case .right:
            WormArenaPoint(x: x + 1, y: y)
        }
    }
}

nonisolated enum WormArenaDirection: CaseIterable {
    case up
    case down
    case left
    case right

    func isOpposite(of other: WormArenaDirection) -> Bool {
        switch (self, other) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            true
        default:
            false
        }
    }
}

nonisolated struct ArenaWorm: Identifiable {
    let id: Int
    var segments: [WormArenaPoint]
    var direction: WormArenaDirection
}

nonisolated enum WormArenaDifficulty: Int, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        }
    }

    var summary: String {
        switch self {
        case .easy:
            return "Slower pace, one relaxed rival, and plenty of food."
        case .medium:
            return "Three rivals and balanced arena speed."
        case .hard:
            return "Fast pace, five focused rivals, and scarce food."
        }
    }
}

@MainActor
final class WormArenaViewModel: ObservableObject {
    enum Phase: Equatable {
        case ready
        case playing
        case won
        case lost
    }

    let objectWillChange = ObservableObjectPublisher()

    private(set) var phase: Phase = .ready
    private(set) var player = ArenaWorm(id: 0, segments: [], direction: .right)
    private(set) var rivals: [ArenaWorm] = []
    private(set) var food: Set<WormArenaPoint> = []
    private(set) var score = 0
    private(set) var bestScore = 0
    private(set) var wins = 0
    private(set) var losses = 0
    private(set) var attempts = 0
    private(set) var boostTicks = 0
    private(set) var difficulty: WormArenaDifficulty = .medium
    private(set) var previousPlayer = ArenaWorm(id: 0, segments: [], direction: .right)
    private(set) var previousRivals: [ArenaWorm] = []
    private(set) var lastTickDate = Date()

    let columns = 30
    let rows = 22

    var winningScore: Int {
        switch difficulty {
        case .easy: 15
        case .medium: 20
        case .hard: 25
        }
    }

    var tickInterval: TimeInterval {
        switch difficulty {
        case .easy: 0.19
        case .medium: 0.14
        case .hard: 0.10
        }
    }

    var rivalCount: Int {
        switch difficulty {
        case .easy: 1
        case .medium: 3
        case .hard: 5
        }
    }

    var foodTarget: Int {
        switch difficulty {
        case .easy: 16
        case .medium: 12
        case .hard: 8
        }
    }

    private let statsStore: GameStatsStore
    private var pendingDirection: WormArenaDirection = .right
    private var gameLoopTask: Task<Void, Never>?

    init(statsStore: GameStatsStore = GameStatsStore()) {
        self.statsStore = statsStore
        bestScore = statsStore.integer(forKey: "stats.wormArena.bestScore")
        wins = statsStore.integer(forKey: "stats.wormArena.wins")
        losses = statsStore.integer(forKey: "stats.wormArena.losses")
        attempts = statsStore.integer(forKey: "stats.wormArena.attempts")
        difficulty = statsStore.optionalInteger(forKey: "stats.wormArena.difficulty")
            .flatMap(WormArenaDifficulty.init(rawValue:)) ?? .medium
        prepareArena()
    }

    var statusText: String {
        switch phase {
        case .ready:
            return "Use arrow keys or WASD. Eat \(winningScore) treats to win."
        case .playing:
            return boostTicks > 0 ? "Boost active" : "Avoid walls, yourself, and rival worms."
        case .won:
            return "Garden champion. You reached \(winningScore) treats."
        case .lost:
            return "Your worm crashed. Start a new run."
        }
    }

    var canBoost: Bool {
        phase == .playing && player.segments.count > boostCost + 3 && boostTicks == 0
    }

    var boostCost: Int {
        difficulty == .hard ? 2 : 1
    }

    func setDifficulty(_ difficulty: WormArenaDifficulty) {
        guard phase != .playing, self.difficulty != difficulty else { return }
        self.difficulty = difficulty
        statsStore.set(difficulty.rawValue, forKey: "stats.wormArena.difficulty")
        prepareArena()
        objectWillChange.send()
    }

    func startGame() {
        gameLoopTask?.cancel()
        prepareArena()
        phase = .playing
        attempts += 1
        statsStore.set(attempts, forKey: "stats.wormArena.attempts")
        objectWillChange.send()
        startGameLoop()
    }

    func changeDirection(_ direction: WormArenaDirection) {
        guard phase == .playing, !direction.isOpposite(of: player.direction) else { return }
        pendingDirection = direction
    }

    func activateBoost() {
        guard canBoost else { return }
        player.segments.removeLast(boostCost)
        boostTicks = difficulty == .hard ? 8 : 12
        previousPlayer = player
        objectWillChange.send()
    }

    func tick() {
        guard phase == .playing else { return }
        previousPlayer = player
        previousRivals = rivals
        lastTickDate = Date()
        movePlayer()
        guard phase == .playing else { return }

        if boostTicks > 0 {
            boostTicks -= 1
            movePlayer()
            guard phase == .playing else { return }
        }

        moveRivals()
        objectWillChange.send()
    }

    func stopGameLoop() {
        gameLoopTask?.cancel()
        gameLoopTask = nil
    }

    func resumeGameLoop() {
        guard phase == .playing, gameLoopTask == nil else { return }
        startGameLoop()
    }

#if DEBUG
    func setArenaForTesting(
        player: ArenaWorm,
        rivals: [ArenaWorm] = [],
        food: Set<WormArenaPoint> = []
    ) {
        self.player = player
        self.rivals = rivals
        self.food = food
        pendingDirection = player.direction
        score = 0
        boostTicks = 0
        phase = .playing
        previousPlayer = player
        previousRivals = rivals
        lastTickDate = Date()
        objectWillChange.send()
    }
#endif

    private func prepareArena() {
        player = ArenaWorm(
            id: 0,
            segments: (0..<5).map { WormArenaPoint(x: 8 - $0, y: 11) },
            direction: .right
        )
        pendingDirection = .right
        let availableRivals = [
            ArenaWorm(id: 1, segments: horizontalWorm(headX: 22, y: 5, direction: .left), direction: .left),
            ArenaWorm(id: 2, segments: verticalWorm(x: 23, headY: 17, direction: .up), direction: .up),
            ArenaWorm(id: 3, segments: horizontalWorm(headX: 15, y: 18, direction: .right), direction: .right),
            ArenaWorm(id: 4, segments: verticalWorm(x: 14, headY: 4, direction: .down), direction: .down),
            ArenaWorm(id: 5, segments: horizontalWorm(headX: 26, y: 12, direction: .left), direction: .left)
        ]
        rivals = Array(availableRivals.prefix(rivalCount))
        score = 0
        boostTicks = 0
        food = []
        refillFood()
        previousPlayer = player
        previousRivals = rivals
        lastTickDate = Date()
    }

    private func startGameLoop() {
        gameLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                let interval = self?.tickInterval ?? 0.14
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled, let self else { return }
                self.tick()
            }
        }
    }

    private func movePlayer() {
        player.direction = pendingDirection
        let nextHead = player.segments[0].moved(player.direction)
        let willEat = food.contains(nextHead)
        var collisionPoints = Set(player.segments.dropLast(willEat ? 0 : 1))
        collisionPoints.formUnion(rivals.flatMap(\.segments))

        guard isInside(nextHead), !collisionPoints.contains(nextHead) else {
            finish(won: false)
            return
        }

        player.segments.insert(nextHead, at: 0)
        if willEat {
            food.remove(nextHead)
            score += 1
            bestScore = max(bestScore, score)
            statsStore.set(bestScore, forKey: "stats.wormArena.bestScore")

            if score >= winningScore {
                finish(won: true)
                return
            }
            refillFood()
        } else {
            player.segments.removeLast()
        }
    }

    private func moveRivals() {
        for index in rivals.indices {
            var occupied = Set(player.segments + rivals.enumerated().flatMap { rivalIndex, rival in
                rivalIndex == index ? [] : rival.segments
            })
            occupied.formUnion(rivals[index].segments.dropLast())
            let direction = rivalDirection(for: rivals[index], avoiding: occupied)
            let nextHead = rivals[index].segments[0].moved(direction)

            guard isInside(nextHead), !occupied.contains(nextHead) else {
                respawnRival(at: index)
                continue
            }

            rivals[index].direction = direction
            rivals[index].segments.insert(nextHead, at: 0)
            if food.remove(nextHead) != nil {
                refillFood()
            } else {
                rivals[index].segments.removeLast()
            }
        }
    }

    private func rivalDirection(for rival: ArenaWorm, avoiding occupied: Set<WormArenaPoint>) -> WormArenaDirection {
        let target = food.min { first, second in
            distance(from: rival.segments[0], to: first) < distance(from: rival.segments[0], to: second)
        }
        let choices = WormArenaDirection.allCases
            .filter { !$0.isOpposite(of: rival.direction) }
            .filter {
                let point = rival.segments[0].moved($0)
                return isInside(point) && !occupied.contains(point)
            }

        guard let target else { return choices.randomElement() ?? rival.direction }
        let randomTurnChance: Double = switch difficulty {
        case .easy: 0.55
        case .medium: 0.18
        case .hard: 0
        }
        if Double.random(in: 0...1) < randomTurnChance {
            return choices.randomElement() ?? rival.direction
        }
        return choices.min {
            distance(from: rival.segments[0].moved($0), to: target)
                < distance(from: rival.segments[0].moved($1), to: target)
        } ?? rival.direction
    }

    private func respawnRival(at index: Int) {
        let spawn = randomFreePoint()
        rivals[index] = ArenaWorm(id: rivals[index].id, segments: [spawn], direction: .right)
    }

    private func refillFood() {
        while food.count < foodTarget {
            food.insert(randomFreePoint())
        }
    }

    private func randomFreePoint() -> WormArenaPoint {
        let occupied = Set(player.segments + rivals.flatMap(\.segments)).union(food)
        for _ in 0..<200 {
            let point = WormArenaPoint(
                x: Int.random(in: 1..<(columns - 1)),
                y: Int.random(in: 1..<(rows - 1))
            )
            if !occupied.contains(point) {
                return point
            }
        }
        return WormArenaPoint(x: columns / 2, y: rows / 2)
    }

    private func finish(won: Bool) {
        stopGameLoop()
        if won {
            phase = .won
            wins += 1
            statsStore.set(wins, forKey: "stats.wormArena.wins")
        } else {
            phase = .lost
            losses += 1
            statsStore.set(losses, forKey: "stats.wormArena.losses")
        }
        objectWillChange.send()
    }

    private func isInside(_ point: WormArenaPoint) -> Bool {
        (0..<columns).contains(point.x) && (0..<rows).contains(point.y)
    }

    private func distance(from first: WormArenaPoint, to second: WormArenaPoint) -> Int {
        abs(first.x - second.x) + abs(first.y - second.y)
    }

    private func horizontalWorm(headX: Int, y: Int, direction: WormArenaDirection) -> [WormArenaPoint] {
        (0..<4).map { offset in
            WormArenaPoint(x: headX + (direction == .left ? offset : -offset), y: y)
        }
    }

    private func verticalWorm(x: Int, headY: Int, direction: WormArenaDirection) -> [WormArenaPoint] {
        (0..<4).map { offset in
            WormArenaPoint(x: x, y: headY + (direction == .up ? offset : -offset))
        }
    }
}
