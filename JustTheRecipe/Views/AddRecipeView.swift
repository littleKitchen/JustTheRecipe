import SwiftUI

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var recipeStore: RecipeStore
    
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingManualEntry = false
    @State private var parsedRecipe: Recipe?
    
    private let parser = RecipeParser()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // URL Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Paste Recipe URL")
                        .font(.headline)
                    
                    HStack {
                        TextField("https://example.com/recipe...", text: $urlText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        
                        Button {
                            if let pasteboardString = UIPasteboard.general.string {
                                urlText = pasteboardString
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button {
                        Task {
                            await fetchRecipe()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.down.doc")
                            }
                            Text("Extract Recipe")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(urlText.isEmpty || isLoading)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 1)
                    Text("or")
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 1)
                }
                
                // Manual Entry Button
                Button {
                    showingManualEntry = true
                } label: {
                    Label("Enter Recipe Manually", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                // How it works
                VStack(alignment: .leading, spacing: 8) {
                    Text("How it works")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Paste any recipe URL", systemImage: "1.circle.fill")
                        Label("We extract just the recipe", systemImage: "2.circle.fill")
                        Label("No life stories, no ads", systemImage: "3.circle.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualRecipeEntryView()
            }
            .sheet(item: $parsedRecipe) { recipe in
                RecipePreviewView(recipe: recipe)
            }
        }
    }
    
    private func fetchRecipe() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let recipe = try await parser.parseRecipe(from: urlText)
            await MainActor.run {
                parsedRecipe = recipe
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct RecipePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var recipeStore: RecipeStore
    
    let recipe: Recipe
    @State private var editedRecipe: Recipe
    
    init(recipe: Recipe) {
        self.recipe = recipe
        self._editedRecipe = State(initialValue: recipe)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    TextField("Recipe Title", text: $editedRecipe.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Quick Info
                    if editedRecipe.servings != nil || editedRecipe.totalTime != nil {
                        HStack(spacing: 16) {
                            if let servings = editedRecipe.servings {
                                Label(servings, systemImage: "person.2")
                            }
                            if let time = editedRecipe.totalTime {
                                Label(time, systemImage: "clock")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        ForEach(editedRecipe.ingredients.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("•")
                                Text(editedRecipe.ingredients[index])
                            }
                            .font(.body)
                        }
                    }
                    
                    Divider()
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.headline)
                        
                        ForEach(editedRecipe.steps.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                
                                Text(editedRecipe.steps[index])
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        recipeStore.add(editedRecipe)
                        dismiss()
                        // Dismiss parent sheet too
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .dismissAddRecipe, object: nil)
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

extension Notification.Name {
    static let dismissAddRecipe = Notification.Name("dismissAddRecipe")
}

struct ManualRecipeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var recipeStore: RecipeStore
    
    @State private var title = ""
    @State private var ingredientsText = ""
    @State private var stepsText = ""
    @State private var servings = ""
    @State private var totalTime = ""
    @State private var category: RecipeCategory = .none
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe Info") {
                    TextField("Recipe Title", text: $title)
                    TextField("Servings (e.g., 4 servings)", text: $servings)
                    TextField("Total Time (e.g., 30 min)", text: $totalTime)
                    
                    Picker("Category", selection: $category) {
                        ForEach(RecipeCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                
                Section("Ingredients") {
                    Text("One ingredient per line")
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
            }
            .navigationTitle("New Recipe")
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
                    .disabled(title.isEmpty || ingredientsText.isEmpty)
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
        
        let recipe = Recipe(
            title: title,
            ingredients: ingredients,
            steps: steps,
            servings: servings.isEmpty ? nil : servings,
            totalTime: totalTime.isEmpty ? nil : totalTime,
            category: category
        )
        
        recipeStore.add(recipe)
        dismiss()
    }
}

#Preview {
    AddRecipeView()
        .environmentObject(RecipeStore())
}
