import SwiftUI

struct ContentView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @State private var showingAddRecipe = false
    @State private var searchText = ""
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipeStore.recipes
        }
        return recipeStore.recipes.filter { recipe in
            recipe.title.localizedCaseInsensitiveContains(searchText) ||
            recipe.ingredients.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if recipeStore.recipes.isEmpty {
                    EmptyStateView(showingAddRecipe: $showingAddRecipe)
                } else {
                    recipeList
                }
            }
            .navigationTitle("Just The Recipe")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddRecipe = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView()
            }
            .searchable(text: $searchText, prompt: "Search recipes...")
        }
    }
    
    private var recipeList: some View {
        List {
            ForEach(filteredRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeRowView(recipe: recipe)
                }
            }
            .onDelete(perform: deleteRecipes)
        }
        .listStyle(.plain)
    }
    
    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            let recipe = filteredRecipes[index]
            recipeStore.delete(recipe)
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.title)
                .font(.headline)
            
            HStack(spacing: 12) {
                Label("\(recipe.ingredients.count)", systemImage: "list.bullet")
                Label("\(recipe.steps.count) steps", systemImage: "checkmark.circle")
                if let time = recipe.totalTime {
                    Label(time, systemImage: "clock")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    @Binding var showingAddRecipe: Bool
    
    var body: some View {
        ContentUnavailableView {
            Label("No Recipes", systemImage: "fork.knife")
        } description: {
            Text("Add your first recipe by pasting a URL or entering it manually.")
        } actions: {
            Button("Add Recipe") {
                showingAddRecipe = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RecipeStore())
}
