import Combine
import Foundation

@MainActor
final class ClicksPerSecondViewModel: ObservableObject {
    enum Phase {
        case ready
        case running
        case finished
    }

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var clickCount = 0
    @Published private(set) var remainingSeconds: Double
    @Published private(set) var bestClicksPerSecond = 0.0

    let duration: Double
    private var timerTask: Task<Void, Never>?

    init(duration: Double = 5) {
        self.duration = duration
        self.remainingSeconds = duration
    }

    var clicksPerSecond: Double {
        guard phase != .ready else { return 0 }
        let elapsed = max(0.001, duration - remainingSeconds)
        return Double(clickCount) / elapsed
    }

    var statusText: String {
        switch phase {
        case .ready:
            return "Tap start, then tap as fast as you can."
        case .running:
            return "Keep tapping"
        case .finished:
            return "Time is up"
        }
    }

    func start() {
        timerTask?.cancel()
        clickCount = 0
        remainingSeconds = duration
        phase = .running

        timerTask = Task { [weak self] in
            while let self, self.remainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                self.tick()
            }
        }
    }

    func tapTarget() {
        switch phase {
        case .ready, .finished:
            start()
        case .running:
            clickCount += 1
        }
    }

    func resetBest() {
        bestClicksPerSecond = 0
    }

#if DEBUG
    func advanceForTesting(seconds: Double) {
        let ticks = Int((seconds * 10).rounded())
        for _ in 0..<ticks {
            tick()
        }
    }
#endif

    private func tick() {
        guard phase == .running else { return }
        remainingSeconds = max(0, remainingSeconds - 0.1)

        if remainingSeconds == 0 {
            phase = .finished
            bestClicksPerSecond = max(bestClicksPerSecond, clicksPerSecond)
            timerTask?.cancel()
            timerTask = nil
        }
    }
}
