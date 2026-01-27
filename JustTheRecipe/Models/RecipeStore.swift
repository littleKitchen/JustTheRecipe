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
}

struct GroceryItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var isChecked: Bool = false
    var fromRecipe: String?
}
