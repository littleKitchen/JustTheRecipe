import SwiftUI

struct ContentView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    
    var body: some View {
        TabView {
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
            
            GroceryListView()
                .tabItem {
                    Label("Grocery", systemImage: "cart.fill")
                }
        }
    }
}

// MARK: - Recipe List View

struct RecipeListView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @State private var showingAddRecipe = false
    @State private var searchText = ""
    @State private var selectedCategory: RecipeCategory = .none
    
    var filteredRecipes: [Recipe] {
        var result = recipeStore.recipes
        
        if selectedCategory != .none {
            result = result.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            result = result.filter { recipe in
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                recipe.ingredients.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if recipeStore.recipes.isEmpty {
                    EmptyStateView(showingAddRecipe: $showingAddRecipe)
                } else {
                    VStack(spacing: 0) {
                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                CategoryChip(category: .none, isSelected: selectedCategory == .none) {
                                    selectedCategory = .none
                                }
                                ForEach(RecipeCategory.allCases.filter { $0 != .none }, id: \.self) { category in
                                    CategoryChip(category: category, isSelected: selectedCategory == category) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        .background(Color(.systemBackground))
                        
                        if filteredRecipes.isEmpty {
                            ContentUnavailableView {
                                Label("No Recipes", systemImage: "magnifyingglass")
                            } description: {
                                Text("No recipes match your search or filter.")
                            }
                        } else {
                            List {
                                ForEach(filteredRecipes) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        RecipeRowView(recipe: recipe)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            recipeStore.toggleFavorite(recipe)
                                        } label: {
                                            Label("Favorite", systemImage: recipe.isFavorite ? "heart.slash" : "heart")
                                        }
                                        .tint(.pink)
                                    }
                                }
                                .onDelete(perform: deleteRecipes)
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Pure Recipe")
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
    
    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            let recipe = filteredRecipes[index]
            recipeStore.delete(recipe)
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: RecipeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                Text(category == .none ? "All" : category.rawValue)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Favorites View

struct FavoritesView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    
    var body: some View {
        NavigationStack {
            Group {
                if recipeStore.favorites.isEmpty {
                    ContentUnavailableView {
                        Label("No Favorites", systemImage: "heart.slash")
                    } description: {
                        Text("Swipe right on a recipe to add it to favorites.")
                    }
                } else {
                    List {
                        ForEach(recipeStore.favorites) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeRowView(recipe: recipe)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    recipeStore.toggleFavorite(recipe)
                                } label: {
                                    Label("Unfavorite", systemImage: "heart.slash")
                                }
                                .tint(.gray)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favorites")
        }
    }
}

// MARK: - Grocery List View

struct GroceryListView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @State private var newItemText = ""
    
    var uncheckedItems: [GroceryItem] {
        recipeStore.groceryList.filter { !$0.isChecked }
    }
    
    var checkedItems: [GroceryItem] {
        recipeStore.groceryList.filter { $0.isChecked }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if recipeStore.groceryList.isEmpty {
                    ContentUnavailableView {
                        Label("Grocery List Empty", systemImage: "cart")
                    } description: {
                        Text("Add ingredients from recipes or type your own items.")
                    }
                } else {
                    List {
                        // Add new item
                        Section {
                            HStack {
                                TextField("Add item...", text: $newItemText)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        addItem()
                                    }
                                
                                if !newItemText.isEmpty {
                                    Button {
                                        addItem()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                        
                        // Unchecked items
                        if !uncheckedItems.isEmpty {
                            Section("To Buy") {
                                ForEach(uncheckedItems) { item in
                                    GroceryItemRow(item: item)
                                }
                            }
                        }
                        
                        // Checked items
                        if !checkedItems.isEmpty {
                            Section("Got It") {
                                ForEach(checkedItems) { item in
                                    GroceryItemRow(item: item)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Grocery List")
            .toolbar {
                if !recipeStore.groceryList.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) {
                                recipeStore.clearCheckedItems()
                            } label: {
                                Label("Clear Checked", systemImage: "checkmark.circle")
                            }
                            
                            Button(role: .destructive) {
                                recipeStore.clearAllGroceries()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
    
    private func addItem() {
        guard !newItemText.isEmpty else { return }
        recipeStore.groceryList.append(GroceryItem(name: newItemText))
        newItemText = ""
    }
}

struct GroceryItemRow: View {
    @EnvironmentObject var recipeStore: RecipeStore
    let item: GroceryItem
    
    var body: some View {
        Button {
            recipeStore.toggleGroceryItem(item)
        } label: {
            HStack {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
                
                VStack(alignment: .leading) {
                    Text(item.name)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                    
                    if let recipe = item.fromRecipe {
                        Text("from \(recipe)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                recipeStore.removeGroceryItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Recipe Row View

struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(recipe.title)
                    .font(.headline)
                
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 12) {
                if recipe.category != .none {
                    Label(recipe.category.rawValue, systemImage: recipe.category.icon)
                }
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
