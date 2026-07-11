import Combine
import Foundation

@MainActor
final class YetiKitchenViewModel: ObservableObject {
    enum Phase: Equatable {
        case intro
        case cookingShow
        case recall
        case results
    }

    struct SlotResult: Equatable {
        let isCorrect: Bool
    }

    @Published private(set) var phase: Phase = .intro
    @Published private(set) var currentRecipe: KidRecipe?
    @Published private(set) var showIndex = 0
    @Published private(set) var pantryItems: [RecipeIngredient] = []
    @Published private(set) var playerSelections: [RecipeIngredient] = []
    @Published private(set) var failedAtIndex: Int?
    @Published private(set) var score = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var recipesMastered = 0
    @Published private(set) var rounds = 0
    @Published private(set) var perfectRounds = 0

    let showIngredientDuration: TimeInterval = 2.5
    let perfectRoundsToUnlockFourIngredients = 3

    private let recipeBank: [KidRecipe]
    private let statsStore: GameStatsStore
    private let fixedRecipe: KidRecipe?
    private var currentStreak = 0

    init(
        recipeBank: [KidRecipe] = KidRecipe.bank,
        fixedRecipe: KidRecipe? = nil,
        statsStore: GameStatsStore = GameStatsStore()
    ) {
        self.recipeBank = recipeBank
        self.fixedRecipe = fixedRecipe
        self.statsStore = statsStore
        self.bestStreak = statsStore.integer(forKey: "stats.yetiKitchen.bestStreak")
        self.recipesMastered = statsStore.integer(forKey: "stats.yetiKitchen.recipesMastered")
        self.rounds = statsStore.integer(forKey: "stats.yetiKitchen.rounds")
        self.perfectRounds = statsStore.integer(forKey: "stats.yetiKitchen.perfectRounds")
        prepareIntro()
    }

    var unlockedFourIngredientRecipes: Bool {
        perfectRounds >= perfectRoundsToUnlockFourIngredients
    }

    var currentShowIngredient: RecipeIngredient? {
        guard let recipe = currentRecipe, recipe.ingredients.indices.contains(showIndex) else {
            return nil
        }
        return recipe.ingredients[showIndex]
    }

    var slotResults: [SlotResult] {
        guard let recipe = currentRecipe else { return [] }
        return recipe.ingredients.indices.map { index in
            let isCorrect = playerSelections.indices.contains(index)
                && playerSelections[index].id == recipe.ingredients[index].id
            return SlotResult(isCorrect: isCorrect)
        }
    }

    var currentSpeech: String {
        guard let recipe = currentRecipe else {
            return "Welcome to Rainbow Chef Yeti's cooking show!"
        }

        switch phase {
        case .intro:
            return "Tap Start Show to watch today's recipe: \(recipe.title)!"
        case .cookingShow:
            if recipe.steps.indices.contains(showIndex) {
                return recipe.steps[showIndex]
            }
            return "Watch closely!"
        case .recall:
            return "Tap the pantry ingredients in the same order they appeared."
        case .results:
            if isPerfectRound {
                return "Perfect memory! You nailed every ingredient in order."
            }
            if let failedAtIndex {
                return "Oops! Ingredient \(failedAtIndex + 1) was out of order."
            }
            return "Nice try! Watch the show again to improve your score."
        }
    }

    var nextSelectionIndex: Int {
        playerSelections.count
    }

    var isRecallComplete: Bool {
        guard let recipe = currentRecipe else { return false }
        return playerSelections.count == recipe.ingredients.count || failedAtIndex != nil
    }

    var isPerfectRound: Bool {
        guard let recipe = currentRecipe, failedAtIndex == nil else { return false }
        return playerSelections == recipe.ingredients
    }

    var maxScore: Int {
        currentRecipe?.ingredients.count ?? 0
    }

    func prepareIntro() {
        currentRecipe = fixedRecipe ?? pickRecipe()
        showIndex = 0
        playerSelections = []
        failedAtIndex = nil
        score = 0
        phase = .intro
    }

    func startNewRound() {
        let recipe = fixedRecipe ?? pickRecipe()
        currentRecipe = recipe
        showIndex = 0
        pantryItems = makePantry(for: recipe)
        playerSelections = []
        failedAtIndex = nil
        score = 0
        phase = .cookingShow
    }

    func startShow() {
        guard let recipe = currentRecipe else {
            startNewRound()
            return
        }
        showIndex = 0
        pantryItems = makePantry(for: recipe)
        playerSelections = []
        failedAtIndex = nil
        score = 0
        phase = .cookingShow
    }

    func replayShow() {
        guard currentRecipe != nil else { return }
        showIndex = 0
        playerSelections = []
        failedAtIndex = nil
        score = 0
        phase = .cookingShow
    }

    func advanceShow() {
        guard phase == .cookingShow, let recipe = currentRecipe else { return }

        if showIndex + 1 < recipe.ingredients.count {
            showIndex += 1
        } else {
            phase = .recall
        }
    }

    func selectIngredient(_ ingredient: RecipeIngredient) {
        guard phase == .recall,
              let recipe = currentRecipe,
              failedAtIndex == nil,
              playerSelections.count < recipe.ingredients.count else {
            return
        }

        let expectedIndex = playerSelections.count
        let expectedIngredient = recipe.ingredients[expectedIndex]

        if ingredient.id == expectedIngredient.id {
            playerSelections.append(ingredient)
            score += 1

            if playerSelections.count == recipe.ingredients.count {
                completeRound()
            }
        } else {
            failedAtIndex = expectedIndex
            completeRound()
        }
    }

    func completeRound() {
        guard phase != .results else { return }

        phase = .results
        rounds += 1
        statsStore.set(rounds, forKey: "stats.yetiKitchen.rounds")

        if isPerfectRound {
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            perfectRounds += 1
            recipesMastered += 1
            statsStore.set(bestStreak, forKey: "stats.yetiKitchen.bestStreak")
            statsStore.set(perfectRounds, forKey: "stats.yetiKitchen.perfectRounds")
            statsStore.set(recipesMastered, forKey: "stats.yetiKitchen.recipesMastered")
        } else {
            currentStreak = 0
        }
    }

    func makePantry(for recipe: KidRecipe) -> [RecipeIngredient] {
        let recipeIDs = Set(recipe.ingredients.map(\.id))
        let decoys = RecipeIngredient.decoyPool
            .filter { !recipeIDs.contains($0.id) }
            .shuffled()
        let targetCount = max(6, min(9, recipe.ingredients.count + 3))
        let decoyCount = max(0, targetCount - recipe.ingredients.count)
        let chosenDecoys = Array(decoys.prefix(decoyCount))
        return (recipe.ingredients + chosenDecoys).shuffled()
    }

    private func pickRecipe() -> KidRecipe {
        let eligible = unlockedFourIngredientRecipes ? recipeBank : KidRecipe.threeIngredientRecipes
        return eligible.randomElement() ?? recipeBank[0]
    }

#if DEBUG
    func setPhaseForTesting(_ phase: Phase) {
        self.phase = phase
    }

    func setRecipeForTesting(_ recipe: KidRecipe, pantry: [RecipeIngredient]? = nil) {
        currentRecipe = recipe
        pantryItems = pantry ?? makePantry(for: recipe)
        showIndex = 0
        playerSelections = []
        failedAtIndex = nil
        score = 0
    }

    func setShowIndexForTesting(_ index: Int) {
        showIndex = index
    }
#endif
}
