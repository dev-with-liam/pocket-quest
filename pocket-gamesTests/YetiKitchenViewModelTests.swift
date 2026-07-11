import Foundation
import Testing
@testable import pocket_games

@MainActor
struct YetiKitchenViewModelTests {
    private let berrySmoothie = KidRecipe.bank[0]

    @Test
    func correctOrderScoresFullPoints() {
        let viewModel = YetiKitchenViewModel(
            fixedRecipe: berrySmoothie,
            statsStore: GameStatsStore(defaults: nil)
        )

        viewModel.startShow()
        advanceThroughShow(viewModel, ingredientCount: berrySmoothie.ingredients.count)

        for ingredient in berrySmoothie.ingredients {
            viewModel.selectIngredient(ingredient)
        }

        #expect(viewModel.score == berrySmoothie.ingredients.count)
        #expect(viewModel.isPerfectRound)
        #expect(viewModel.phase == .results)
    }

    @Test
    func wrongOrderAtPositionFailsThatSlot() {
        let viewModel = YetiKitchenViewModel(
            fixedRecipe: berrySmoothie,
            statsStore: GameStatsStore(defaults: nil)
        )

        viewModel.startShow()
        advanceThroughShow(viewModel, ingredientCount: berrySmoothie.ingredients.count)

        viewModel.selectIngredient(berrySmoothie.ingredients[1])

        #expect(viewModel.score == 0)
        #expect(viewModel.failedAtIndex == 0)
        #expect(viewModel.isPerfectRound == false)
        #expect(viewModel.phase == .results)
    }

    @Test
    func advanceShowReachesRecallAfterFinalIngredient() {
        let viewModel = YetiKitchenViewModel(
            fixedRecipe: berrySmoothie,
            statsStore: GameStatsStore(defaults: nil)
        )

        viewModel.startShow()
        #expect(viewModel.phase == .cookingShow)

        advanceThroughShow(viewModel, ingredientCount: berrySmoothie.ingredients.count)

        #expect(viewModel.phase == .recall)
    }

    @Test
    func statsPersistAcrossViewModelReinit() {
        let defaults = UserDefaults(suiteName: "YetiKitchenTests.\(UUID().uuidString)")!
        let first = YetiKitchenViewModel(
            fixedRecipe: berrySmoothie,
            statsStore: GameStatsStore(defaults: defaults)
        )

        first.startShow()
        advanceThroughShow(first, ingredientCount: berrySmoothie.ingredients.count)

        for ingredient in berrySmoothie.ingredients {
            first.selectIngredient(ingredient)
        }

        #expect(first.bestStreak == 1)
        #expect(first.recipesMastered == 1)
        #expect(first.rounds == 1)
        #expect(first.perfectRounds == 1)

        let restored = YetiKitchenViewModel(
            fixedRecipe: berrySmoothie,
            statsStore: GameStatsStore(defaults: defaults)
        )

        #expect(restored.bestStreak == 1)
        #expect(restored.recipesMastered == 1)
        #expect(restored.rounds == 1)
        #expect(restored.perfectRounds == 1)
        #expect(restored.unlockedFourIngredientRecipes == false)
    }

    @Test
    func pantryIncludesAllRequiredIngredientsPlusDecoys() {
        let viewModel = YetiKitchenViewModel(
            fixedRecipe: berrySmoothie,
            statsStore: GameStatsStore(defaults: nil)
        )

        viewModel.startShow()

        let pantryIDs = Set(viewModel.pantryItems.map(\.id))
        let recipeIDs = Set(berrySmoothie.ingredients.map(\.id))

        #expect(recipeIDs.isSubset(of: pantryIDs))
        #expect(viewModel.pantryItems.count >= 6)
    }

    @Test
    func fourIngredientRecipesUnlockAfterThreePerfectRounds() {
        let defaults = UserDefaults(suiteName: "YetiKitchenUnlockTests.\(UUID().uuidString)")!
        defaults.set(3, forKey: "stats.yetiKitchen.perfectRounds")

        let viewModel = YetiKitchenViewModel(statsStore: GameStatsStore(defaults: defaults))
        #expect(viewModel.unlockedFourIngredientRecipes)
    }

    private func advanceThroughShow(_ viewModel: YetiKitchenViewModel, ingredientCount: Int) {
        for _ in 1..<ingredientCount {
            viewModel.advanceShow()
        }
        viewModel.advanceShow()
    }
}
