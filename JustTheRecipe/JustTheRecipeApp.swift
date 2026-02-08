import SwiftUI

@main
struct JustTheRecipeApp: App {
    @StateObject private var recipeStore = RecipeStore()
    
    init() {
        // Load sample data for screenshots
        if CommandLine.arguments.contains("-screenshots") {
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        // Will be loaded via environment object
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recipeStore)
                .onAppear {
                    if CommandLine.arguments.contains("-screenshots") {
                        recipeStore.addSampleRecipes()
                    }
                }
        }
    }
}
