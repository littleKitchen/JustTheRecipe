import SwiftUI

@main
struct JustTheRecipeApp: App {
    @StateObject private var recipeStore = RecipeStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recipeStore)
        }
    }
}
