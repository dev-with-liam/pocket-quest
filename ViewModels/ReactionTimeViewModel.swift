import Combine
import Foundation

@MainActor
final class ReactionTimeViewModel: ObservableObject {
    @Published private(set) var phase: ReactionPhase = .ready
    @Published private(set) var lastReactionMilliseconds: Int?
    @Published private(set) var bestReactionMilliseconds: Int?

    private let delayProvider: () -> UInt64
    private let nowProvider: () -> Date
    private var startTime: Date?
    private var pendingTask: Task<Void, Never>?

    init(
        delayProvider: @escaping () -> UInt64 = { UInt64.random(in: 1_500_000_000...4_000_000_000) },
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.delayProvider = delayProvider
        self.nowProvider = nowProvider
    }

    var titleText: String {
        switch phase {
        case .ready:
            return "Reaction Time"
        case .waiting:
            return "Wait..."
        case .tapNow:
            return "Tap Now"
        case .result:
            return "Result"
        case .early:
            return "Too Soon"
        }
    }

    var instructionText: String {
        switch phase {
        case .ready:
            return "Tap start, then wait for the screen to change."
        case .waiting:
            return "Do not tap until it turns green."
        case .tapNow:
            return "Tap as fast as you can."
        case .result:
            return "Tap start to try again."
        case .early:
            return "Wait for green before tapping."
        }
    }

    func start() {
        pendingTask?.cancel()
        startTime = nil
        lastReactionMilliseconds = nil
        phase = .waiting

        let delay = delayProvider()
        pendingTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            self?.beginReactionWindow()
        }
    }

    func tapTarget() {
        switch phase {
        case .waiting:
            pendingTask?.cancel()
            pendingTask = nil
            phase = .early
        case .tapNow:
            guard let startTime else { return }
            let milliseconds = max(0, Int(nowProvider().timeIntervalSince(startTime) * 1000))
            lastReactionMilliseconds = milliseconds

            if let bestReactionMilliseconds {
                self.bestReactionMilliseconds = min(bestReactionMilliseconds, milliseconds)
            } else {
                bestReactionMilliseconds = milliseconds
            }

            phase = .result
        case .ready, .result, .early:
            start()
        }
    }

    func resetBest() {
        bestReactionMilliseconds = nil
    }

    private func beginReactionWindow() {
        guard phase == .waiting else { return }
        startTime = nowProvider()
        phase = .tapNow
    }
}
