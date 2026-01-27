import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject var recipeStore: RecipeStore
    @Environment(\.dismiss) private var dismiss
    
    let recipe: Recipe
    @State private var checkedIngredients: Set<Int> = []
    @State private var completedSteps: Set<Int> = []
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Quick Info
                    HStack(spacing: 16) {
                        if let servings = recipe.servings {
                            Label(servings, systemImage: "person.2")
                        }
                        if let prepTime = recipe.prepTime {
                            Label("Prep: \(prepTime)", systemImage: "timer")
                        }
                        if let cookTime = recipe.cookTime {
                            Label("Cook: \(cookTime)", systemImage: "flame")
                        }
                        if let totalTime = recipe.totalTime {
                            Label(totalTime, systemImage: "clock")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if let sourceURL = recipe.sourceURL {
                        Link(destination: URL(string: sourceURL)!) {
                            Label("View Original", systemImage: "link")
                                .font(.caption)
                        }
                    }
                }
                
                Divider()
                
                // Ingredients
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if !checkedIngredients.isEmpty {
                            Button("Clear") {
                                checkedIngredients.removeAll()
                            }
                            .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recipe.ingredients.indices, id: \.self) { index in
                            IngredientRow(
                                ingredient: recipe.ingredients[index],
                                isChecked: checkedIngredients.contains(index),
                                onToggle: {
                                    if checkedIngredients.contains(index) {
                                        checkedIngredients.remove(index)
                                    } else {
                                        checkedIngredients.insert(index)
                                    }
                                }
                            )
                        }
                    }
                }
                
                Divider()
                
                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Instructions")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(completedSteps.count)/\(recipe.steps.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(recipe.steps.indices, id: \.self) { index in
                            StepRow(
                                stepNumber: index + 1,
                                step: recipe.steps[index],
                                isCompleted: completedSteps.contains(index),
                                onToggle: {
                                    if completedSteps.contains(index) {
                                        completedSteps.remove(index)
                                    } else {
                                        completedSteps.insert(index)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Notes
                if let notes = recipe.notes, !notes.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    recipeStore.toggleFavorite(recipe)
                } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(recipe.isFavorite ? .pink : .primary)
                }
                
                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Menu {
                    Button {
                        recipeStore.addToGroceryList(from: recipe)
                    } label: {
                        Label("Add to Grocery List", systemImage: "cart.badge.plus")
                    }
                    
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Recipe", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecipeView(recipe: recipe)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [formatRecipeForSharing()])
        }
        .alert("Delete Recipe?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                recipeStore.delete(recipe)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func formatRecipeForSharing() -> String {
        var text = "# \(recipe.title)\n\n"
        
        if let servings = recipe.servings {
            text += "Servings: \(servings)\n"
        }
        if let totalTime = recipe.totalTime {
            text += "Time: \(totalTime)\n"
        }
        
        text += "\n## Ingredients\n"
        for ingredient in recipe.ingredients {
            text += "• \(ingredient)\n"
        }
        
        text += "\n## Instructions\n"
        for (index, step) in recipe.steps.enumerated() {
            text += "\(index + 1). \(step)\n"
        }
        
        if let sourceURL = recipe.sourceURL {
            text += "\nSource: \(sourceURL)"
        }
        
        return text
    }
}

struct IngredientRow: View {
    let ingredient: String
    let isChecked: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isChecked ? .green : .secondary)
                
                Text(ingredient)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct StepRow: View {
    let stepNumber: Int
    let step: String
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(stepNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(isCompleted ? Color.green : Color.accentColor)
                    .clipShape(Circle())
                
                Text(step)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct EditRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var recipeStore: RecipeStore
    
    let recipe: Recipe
    
    @State private var title: String
    @State private var ingredientsText: String
    @State private var stepsText: String
    @State private var servings: String
    @State private var totalTime: String
    @State private var notes: String
    @State private var category: RecipeCategory
    
    init(recipe: Recipe) {
        self.recipe = recipe
        self._title = State(initialValue: recipe.title)
        self._ingredientsText = State(initialValue: recipe.ingredients.joined(separator: "\n"))
        self._stepsText = State(initialValue: recipe.steps.joined(separator: "\n"))
        self._servings = State(initialValue: recipe.servings ?? "")
        self._totalTime = State(initialValue: recipe.totalTime ?? "")
        self._notes = State(initialValue: recipe.notes ?? "")
        self._category = State(initialValue: recipe.category)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe Info") {
                    TextField("Recipe Title", text: $title)
                    TextField("Servings", text: $servings)
                    TextField("Total Time", text: $totalTime)
                    
                    Picker("Category", selection: $category) {
                        ForEach(RecipeCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                
                Section("Ingredients") {
                    Text("One per line")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $ingredientsText)
                        .frame(minHeight: 120)
                }
                
                Section("Instructions") {
                    Text("One step per line")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $stepsText)
                        .frame(minHeight: 150)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveRecipe() {
        let ingredients = ingredientsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let steps = stepsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var updated = recipe
        updated.title = title
        updated.ingredients = ingredients
        updated.steps = steps
        updated.servings = servings.isEmpty ? nil : servings
        updated.totalTime = totalTime.isEmpty ? nil : totalTime
        updated.notes = notes.isEmpty ? nil : notes
        updated.category = category
        
        recipeStore.update(updated)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: .sample)
            .environmentObject(RecipeStore())
    }
}
