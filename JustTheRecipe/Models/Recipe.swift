import Foundation

enum RecipeCategory: String, Codable, CaseIterable {
    case none = "None"
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case dessert = "Dessert"
    case snack = "Snack"
    case drink = "Drink"
    case appetizer = "Appetizer"
    case side = "Side Dish"
    case soup = "Soup"
    case salad = "Salad"
    case baking = "Baking"
    
    var icon: String {
        switch self {
        case .none: return "fork.knife"
        case .breakfast: return "sun.rise"
        case .lunch: return "sun.max"
        case .dinner: return "moon.stars"
        case .dessert: return "birthday.cake"
        case .snack: return "carrot"
        case .drink: return "cup.and.saucer"
        case .appetizer: return "leaf"
        case .side: return "square.split.1x2"
        case .soup: return "flame"
        case .salad: return "leaf.circle"
        case .baking: return "oven"
        }
    }
}

struct Recipe: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var ingredients: [String]
    var steps: [String]
    var servings: String?
    var prepTime: String?
    var cookTime: String?
    var totalTime: String?
    var sourceURL: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var category: RecipeCategory
    
    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [String],
        steps: [String],
        servings: String? = nil,
        prepTime: String? = nil,
        cookTime: String? = nil,
        totalTime: String? = nil,
        sourceURL: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false,
        category: RecipeCategory = .none
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.steps = steps
        self.servings = servings
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.sourceURL = sourceURL
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.category = category
    }
}

// Sample recipe for previews
extension Recipe {
    static let sample = Recipe(
        title: "Simple Pancakes",
        ingredients: [
            "1 cup all-purpose flour",
            "2 tablespoons sugar",
            "2 teaspoons baking powder",
            "1/2 teaspoon salt",
            "1 cup milk",
            "1 large egg",
            "2 tablespoons melted butter"
        ],
        steps: [
            "Mix dry ingredients in a bowl.",
            "Add milk, egg, and melted butter. Stir until just combined.",
            "Heat a griddle over medium heat.",
            "Pour 1/4 cup batter per pancake.",
            "Flip when bubbles form on surface.",
            "Cook until golden brown on both sides."
        ],
        servings: "4 servings",
        prepTime: "5 min",
        cookTime: "15 min",
        totalTime: "20 min",
        isFavorite: true,
        category: .breakfast
    )
}
