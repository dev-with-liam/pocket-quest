import Foundation

struct RecipeIngredient: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
}

struct KidRecipe: Identifiable, Equatable {
    let id: String
    let title: String
    let steps: [String]
    let ingredients: [RecipeIngredient]
}

extension KidRecipe {
    nonisolated static let bank: [KidRecipe] = [
        KidRecipe(
            id: "berry-smoothie",
            title: "Berry Smoothie",
            steps: [
                "Let's make a Berry Smoothie!",
                "First we add a banana.",
                "Next comes a strawberry.",
                "Pour in the milk and blend!"
            ],
            ingredients: [
                RecipeIngredient(id: "banana", name: "Banana", emoji: "🍌"),
                RecipeIngredient(id: "strawberry", name: "Strawberry", emoji: "🍓"),
                RecipeIngredient(id: "milk", name: "Milk", emoji: "🥛")
            ]
        ),
        KidRecipe(
            id: "pb-snack",
            title: "PB Snack",
            steps: [
                "Time for a PB Snack!",
                "Start with a slice of bread.",
                "Spread on peanut butter.",
                "Add some grapes on top!"
            ],
            ingredients: [
                RecipeIngredient(id: "bread", name: "Bread", emoji: "🍞"),
                RecipeIngredient(id: "peanut-butter", name: "Peanut Butter", emoji: "🥜"),
                RecipeIngredient(id: "grapes", name: "Grapes", emoji: "🍇")
            ]
        ),
        KidRecipe(
            id: "mini-pizza",
            title: "Mini Pizza",
            steps: [
                "Let's bake a Mini Pizza!",
                "Lay down the flatbread.",
                "Spread tomato on top.",
                "Sprinkle cheese and bake!"
            ],
            ingredients: [
                RecipeIngredient(id: "flatbread", name: "Flatbread", emoji: "🫓"),
                RecipeIngredient(id: "tomato", name: "Tomato", emoji: "🍅"),
                RecipeIngredient(id: "cheese", name: "Cheese", emoji: "🧀")
            ]
        ),
        KidRecipe(
            id: "fruit-bowl",
            title: "Fruit Bowl",
            steps: [
                "A colorful Fruit Bowl!",
                "Chop an apple first.",
                "Slice an orange next.",
                "Toss in grapes and banana!"
            ],
            ingredients: [
                RecipeIngredient(id: "apple", name: "Apple", emoji: "🍎"),
                RecipeIngredient(id: "orange", name: "Orange", emoji: "🍊"),
                RecipeIngredient(id: "grapes", name: "Grapes", emoji: "🍇"),
                RecipeIngredient(id: "banana", name: "Banana", emoji: "🍌")
            ]
        ),
        KidRecipe(
            id: "yogurt-parfait",
            title: "Yogurt Parfait",
            steps: [
                "Layer a Yogurt Parfait!",
                "Scoop yogurt in a cup.",
                "Sprinkle blueberries.",
                "Drizzle honey on top!"
            ],
            ingredients: [
                RecipeIngredient(id: "yogurt", name: "Yogurt", emoji: "🥣"),
                RecipeIngredient(id: "blueberries", name: "Blueberries", emoji: "🫐"),
                RecipeIngredient(id: "honey", name: "Honey", emoji: "🍯")
            ]
        ),
        KidRecipe(
            id: "veggie-wrap",
            title: "Veggie Wrap",
            steps: [
                "Roll a Veggie Wrap!",
                "Place a tortilla flat.",
                "Grate a carrot inside.",
                "Add fresh lettuce!"
            ],
            ingredients: [
                RecipeIngredient(id: "tortilla", name: "Tortilla", emoji: "🫓"),
                RecipeIngredient(id: "carrot", name: "Carrot", emoji: "🥕"),
                RecipeIngredient(id: "lettuce", name: "Lettuce", emoji: "🥬")
            ]
        ),
        KidRecipe(
            id: "pancake-stack",
            title: "Pancake Stack",
            steps: [
                "Stack some Pancakes!",
                "Cook a fluffy pancake.",
                "Top with strawberries.",
                "Pour syrup and serve!"
            ],
            ingredients: [
                RecipeIngredient(id: "pancake", name: "Pancake", emoji: "🥞"),
                RecipeIngredient(id: "strawberry", name: "Strawberry", emoji: "🍓"),
                RecipeIngredient(id: "syrup", name: "Syrup", emoji: "🍯")
            ]
        ),
        KidRecipe(
            id: "trail-mix",
            title: "Trail Mix",
            steps: [
                "Mix up Trail Mix!",
                "Toss in nuts first.",
                "Add raisins next.",
                "Sprinkle chocolate and popcorn!"
            ],
            ingredients: [
                RecipeIngredient(id: "nuts", name: "Nuts", emoji: "🥜"),
                RecipeIngredient(id: "raisins", name: "Raisins", emoji: "🍇"),
                RecipeIngredient(id: "chocolate", name: "Chocolate", emoji: "🍫"),
                RecipeIngredient(id: "popcorn", name: "Popcorn", emoji: "🍿")
            ]
        )
    ]

    nonisolated static var threeIngredientRecipes: [KidRecipe] {
        bank.filter { $0.ingredients.count == 3 }
    }

    nonisolated static var fourIngredientRecipes: [KidRecipe] {
        bank.filter { $0.ingredients.count == 4 }
    }
}

extension RecipeIngredient {
    nonisolated static let decoyPool: [RecipeIngredient] = [
        RecipeIngredient(id: "egg", name: "Egg", emoji: "🥚"),
        RecipeIngredient(id: "butter", name: "Butter", emoji: "🧈"),
        RecipeIngredient(id: "lemon", name: "Lemon", emoji: "🍋"),
        RecipeIngredient(id: "cucumber", name: "Cucumber", emoji: "🥒"),
        RecipeIngredient(id: "avocado", name: "Avocado", emoji: "🥑"),
        RecipeIngredient(id: "corn", name: "Corn", emoji: "🌽"),
        RecipeIngredient(id: "watermelon", name: "Watermelon", emoji: "🍉"),
        RecipeIngredient(id: "cookie", name: "Cookie", emoji: "🍪")
    ]
}
