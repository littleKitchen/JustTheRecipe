import Foundation
import SwiftUI

@MainActor
class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var groceryList: [GroceryItem] = []
    
    private let saveKey = "SavedRecipes"
    private let groceryKey = "GroceryList"
    
    var favorites: [Recipe] {
        recipes.filter { $0.isFavorite }
    }
    
    func recipes(in category: RecipeCategory) -> [Recipe] {
        if category == .none {
            return recipes
        }
        return recipes.filter { $0.category == category }
    }
    
    init() {
        loadRecipes()
        loadGroceryList()
    }
    
    func add(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0)
        saveRecipes()
    }
    
    func update(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            var updated = recipe
            updated.updatedAt = Date()
            recipes[index] = updated
            saveRecipes()
        }
    }
    
    func delete(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        saveRecipes()
    }
    
    func toggleFavorite(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index].isFavorite.toggle()
            saveRecipes()
        }
    }
    
    // MARK: - Grocery List
    
    func addToGroceryList(from recipe: Recipe) {
        for ingredient in recipe.ingredients {
            if !groceryList.contains(where: { $0.name.lowercased() == ingredient.lowercased() }) {
                groceryList.append(GroceryItem(name: ingredient, fromRecipe: recipe.title))
            }
        }
        saveGroceryList()
    }
    
    func toggleGroceryItem(_ item: GroceryItem) {
        if let index = groceryList.firstIndex(where: { $0.id == item.id }) {
            groceryList[index].isChecked.toggle()
            saveGroceryList()
        }
    }
    
    func removeGroceryItem(_ item: GroceryItem) {
        groceryList.removeAll { $0.id == item.id }
        saveGroceryList()
    }
    
    func clearCheckedItems() {
        groceryList.removeAll { $0.isChecked }
        saveGroceryList()
    }
    
    func clearAllGroceries() {
        groceryList.removeAll()
        saveGroceryList()
    }
    
    // MARK: - Persistence
    
    private func saveRecipes() {
        if let encoded = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadRecipes() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = decoded
        }
    }
    
    private func saveGroceryList() {
        if let encoded = try? JSONEncoder().encode(groceryList) {
            UserDefaults.standard.set(encoded, forKey: groceryKey)
        }
    }
    
    private func loadGroceryList() {
        if let data = UserDefaults.standard.data(forKey: groceryKey),
           let decoded = try? JSONDecoder().decode([GroceryItem].self, from: data) {
            groceryList = decoded
        }
    }
    
    // MARK: - Screenshot Mode
    
    func addSampleRecipes() {
        guard recipes.isEmpty else { return }
        
        let samples = [
            Recipe(
                title: "Simple Pancakes",
                ingredients: ["1 cup flour", "2 tbsp sugar", "1 cup milk", "1 egg", "2 tbsp butter"],
                steps: ["Mix dry ingredients", "Add wet ingredients", "Cook on griddle until golden"],
                servings: "4 servings", prepTime: "5 min", cookTime: "15 min", totalTime: "20 min",
                isFavorite: true, category: .breakfast
            ),
            Recipe(
                title: "Garlic Butter Pasta",
                ingredients: ["8 oz spaghetti", "4 cloves garlic", "4 tbsp butter", "Parmesan cheese", "Fresh parsley"],
                steps: ["Cook pasta al dente", "Sauté garlic in butter", "Toss pasta with garlic butter", "Top with cheese and parsley"],
                servings: "2 servings", prepTime: "5 min", cookTime: "12 min", totalTime: "17 min",
                isFavorite: false, category: .dinner
            ),
            Recipe(
                title: "Classic Caesar Salad",
                ingredients: ["Romaine lettuce", "Caesar dressing", "Croutons", "Parmesan", "Lemon"],
                steps: ["Chop lettuce", "Toss with dressing", "Add croutons and cheese", "Squeeze lemon on top"],
                servings: "2 servings", prepTime: "10 min", cookTime: "0 min", totalTime: "10 min",
                isFavorite: true, category: .lunch
            )
        ]
        
        recipes = samples
    }
}

struct GroceryItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var isChecked: Bool = false
    var fromRecipe: String?
}
