import Foundation
import Testing
@testable import pocket_games

@MainActor
struct WormArenaViewModelTests {
    @Test
    func difficultyChangesArenaBalanceAndPersists() {
        let defaults = UserDefaults(suiteName: "WormArenaDifficultyTests.\(UUID().uuidString)")!
        let first = WormArenaViewModel(statsStore: GameStatsStore(defaults: defaults))

        first.setDifficulty(.hard)

        #expect(first.difficulty == .hard)
        #expect(first.rivals.count == 5)
        #expect(first.food.count == 8)
        #expect(first.winningScore == 25)
        #expect(first.tickInterval == 0.10)
        #expect(first.boostCost == 2)

        let restored = WormArenaViewModel(statsStore: GameStatsStore(defaults: defaults))
        #expect(restored.difficulty == .hard)
    }

    @Test
    func startingARunAutomaticallyMovesTheWorms() async throws {
        let viewModel = WormArenaViewModel(statsStore: GameStatsStore(defaults: nil))
        viewModel.startGame()
        let startingHead = viewModel.player.segments[0]

        try await Task.sleep(nanoseconds: 200_000_000)

        viewModel.stopGameLoop()
        #expect(viewModel.player.segments[0] != startingHead)
    }

    @Test
    func steeringMovesTheWormAndRejectsReverseTurns() {
        let viewModel = WormArenaViewModel(statsStore: GameStatsStore(defaults: nil))
        viewModel.setArenaForTesting(
            player: ArenaWorm(
                id: 0,
                segments: [
                    WormArenaPoint(x: 8, y: 11),
                    WormArenaPoint(x: 7, y: 11),
                    WormArenaPoint(x: 6, y: 11)
                ],
                direction: .right
            )
        )

        viewModel.changeDirection(.left)
        viewModel.tick()
        #expect(viewModel.player.segments[0] == WormArenaPoint(x: 9, y: 11))

        viewModel.changeDirection(.up)
        viewModel.tick()
        #expect(viewModel.player.segments[0] == WormArenaPoint(x: 9, y: 10))
    }

    @Test
    func wallCollisionRecordsAndRestoresALoss() {
        let defaults = UserDefaults(suiteName: "WormArenaTests.\(UUID().uuidString)")!
        let first = WormArenaViewModel(statsStore: GameStatsStore(defaults: defaults))
        first.setArenaForTesting(
            player: ArenaWorm(
                id: 0,
                segments: [WormArenaPoint(x: 0, y: 4)],
                direction: .left
            )
        )

        first.tick()
        #expect(first.phase == .lost)
        #expect(first.losses == 1)

        let restored = WormArenaViewModel(statsStore: GameStatsStore(defaults: defaults))
        #expect(restored.losses == 1)
    }

    @Test
    func eatingFoodGrowsTheWormAndUpdatesScore() {
        let viewModel = WormArenaViewModel(statsStore: GameStatsStore(defaults: nil))
        viewModel.setArenaForTesting(
            player: ArenaWorm(
                id: 0,
                segments: [
                    WormArenaPoint(x: 8, y: 11),
                    WormArenaPoint(x: 7, y: 11)
                ],
                direction: .right
            ),
            food: [WormArenaPoint(x: 9, y: 11)]
        )

        viewModel.tick()
        #expect(viewModel.score == 1)
        #expect(viewModel.player.segments.count == 3)
        #expect(viewModel.bestScore == 1)
    }
}
