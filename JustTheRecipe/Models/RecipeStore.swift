import Foundation
import SwiftUI

@MainActor
class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    
    private let saveKey = "SavedRecipes"
    
    init() {
        loadRecipes()
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
}
