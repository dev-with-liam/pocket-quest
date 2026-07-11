import XCTest
@testable import pocket_games

final class XPStatusTests: XCTestCase {
    func testLevelRewardsIncreaseWithProgress() {
        let rookie = XPStatus(xp: 0)
        XCTAssertEqual(rookie.level, 1)
        XCTAssertEqual(rookie.rankTitle, "Rookie")
        XCTAssertEqual(rookie.levelBonus, 0)
        XCTAssertEqual(rookie.reward(for: .coinFlip), 20)
        XCTAssertEqual(rookie.reward(for: .wordle), 30)
        XCTAssertEqual(rookie.reward(for: .hangman), 45)
        XCTAssertEqual(rookie.dailyReward, 500)

        let adventurer = XPStatus(xp: 2_100)
        XCTAssertEqual(adventurer.level, 5)
        XCTAssertEqual(adventurer.rankTitle, "Adventurer")
        XCTAssertEqual(adventurer.levelBonus, 10)
        XCTAssertEqual(adventurer.reward(for: .coinFlip), 30)
        XCTAssertEqual(adventurer.reward(for: .wordle), 40)
        XCTAssertEqual(adventurer.reward(for: .hangman), 55)
        XCTAssertEqual(adventurer.dailyReward, 600)
    }

    func testProgressAndNextPerk() {
        let status = XPStatus(xp: 1_250)

        XCTAssertEqual(status.level, 3)
        XCTAssertEqual(status.xpIntoLevel, 500)
        XCTAssertEqual(status.xpRequiredForNextLevel, 600)
        XCTAssertEqual(status.remainingXP, 100)
        XCTAssertEqual(status.progress, 0.833, accuracy: 0.001)
        XCTAssertEqual(status.nextPerk?.level, 5)
        XCTAssertEqual(status.nextPerk?.bonus, 10)
    }
}
