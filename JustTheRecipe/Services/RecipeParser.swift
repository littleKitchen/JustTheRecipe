import Foundation

actor RecipeParser {
    enum ParserError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case parsingFailed
        case noRecipeFound
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .parsingFailed:
                return "Failed to parse the webpage"
            case .noRecipeFound:
                return "No recipe found on this page"
            }
        }
    }
    
    func parseRecipe(from urlString: String) async throws -> Recipe {
        guard let url = URL(string: urlString) else {
            throw ParserError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw ParserError.parsingFailed
        }
        
        // Try JSON-LD first (most recipe sites use this)
        if let recipe = try? parseJSONLD(from: html, sourceURL: urlString) {
            return recipe
        }
        
        // Fallback to basic HTML parsing
        if let recipe = try? parseHTML(from: html, sourceURL: urlString) {
            return recipe
        }
        
        throw ParserError.noRecipeFound
    }
    
    private func parseJSONLD(from html: String, sourceURL: String) throws -> Recipe {
        // Find JSON-LD script tags
        let pattern = #"<script[^>]*type\s*=\s*["\']application/ld\+json["\'][^>]*>([\s\S]*?)</script>"#
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(html.startIndex..., in: html)
        
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            if let jsonRange = Range(match.range(at: 1), in: html) {
                let jsonString = String(html[jsonRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let recipe = parseRecipeJSON(jsonString, sourceURL: sourceURL) {
                    return recipe
                }
            }
        }
        
        throw ParserError.noRecipeFound
    }
    
    private func parseRecipeJSON(_ jsonString: String, sourceURL: String) -> Recipe? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return extractRecipe(from: json, sourceURL: sourceURL)
            }
            
            // Handle array of JSON-LD objects
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for json in jsonArray {
                    if let recipe = extractRecipe(from: json, sourceURL: sourceURL) {
                        return recipe
                    }
                }
            }
        } catch {
            // Try to find recipe in @graph
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let graph = json["@graph"] as? [[String: Any]] {
                for item in graph {
                    if let recipe = extractRecipe(from: item, sourceURL: sourceURL) {
                        return recipe
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractRecipe(from json: [String: Any], sourceURL: String) -> Recipe? {
        // Check if this is a Recipe type
        let type = json["@type"]
        let isRecipe: Bool
        
        if let typeString = type as? String {
            isRecipe = typeString == "Recipe"
        } else if let typeArray = type as? [String] {
            isRecipe = typeArray.contains("Recipe")
        } else {
            isRecipe = false
        }
        
        guard isRecipe else { return nil }
        
        let title = json["name"] as? String ?? "Untitled Recipe"
        
        // Parse ingredients
        var ingredients: [String] = []
        if let ingredientList = json["recipeIngredient"] as? [String] {
            ingredients = ingredientList.map { cleanText($0) }
        }
        
        // Parse instructions
        var steps: [String] = []
        if let instructions = json["recipeInstructions"] {
            steps = parseInstructions(instructions)
        }
        
        // Parse times
        let prepTime = parseDuration(json["prepTime"])
        let cookTime = parseDuration(json["cookTime"])
        let totalTime = parseDuration(json["totalTime"])
        
        // Parse servings
        var servings: String? = nil
        if let yield = json["recipeYield"] as? String {
            servings = yield
        } else if let yieldArray = json["recipeYield"] as? [String], let first = yieldArray.first {
            servings = first
        }
        
        return Recipe(
            title: cleanText(title),
            ingredients: ingredients,
            steps: steps,
            servings: servings,
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            sourceURL: sourceURL
        )
    }
    
    private func parseInstructions(_ instructions: Any) -> [String] {
        var steps: [String] = []
        
        if let instructionString = instructions as? String {
            // Split by newlines or periods
            let split = instructionString.components(separatedBy: CharacterSet.newlines)
                .flatMap { $0.components(separatedBy: ". ") }
                .map { cleanText($0) }
                .filter { !$0.isEmpty }
            steps = split
        } else if let instructionArray = instructions as? [Any] {
            for instruction in instructionArray {
                if let text = instruction as? String {
                    steps.append(cleanText(text))
                } else if let dict = instruction as? [String: Any] {
                    if let text = dict["text"] as? String {
                        steps.append(cleanText(text))
                    } else if let name = dict["name"] as? String {
                        steps.append(cleanText(name))
                    }
                    
                    // Handle HowToSection with itemListElement
                    if let items = dict["itemListElement"] as? [[String: Any]] {
                        for item in items {
                            if let text = item["text"] as? String {
                                steps.append(cleanText(text))
                            }
                        }
                    }
                }
            }
        }
        
        return steps.filter { !$0.isEmpty }
    }
    
    private func parseDuration(_ duration: Any?) -> String? {
        guard let durationString = duration as? String else { return nil }
        
        // Parse ISO 8601 duration (e.g., "PT30M", "PT1H30M")
        var result = ""
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?"#
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: durationString, range: NSRange(durationString.startIndex..., in: durationString)) {
            
            if let hoursRange = Range(match.range(at: 1), in: durationString) {
                let hours = String(durationString[hoursRange])
                result += "\(hours) hr "
            }
            
            if let minutesRange = Range(match.range(at: 2), in: durationString) {
                let minutes = String(durationString[minutesRange])
                result += "\(minutes) min"
            }
        }
        
        return result.isEmpty ? nil : result.trimmingCharacters(in: .whitespaces)
    }
    
    private func parseHTML(from html: String, sourceURL: String) throws -> Recipe {
        // Basic fallback parsing - look for common patterns
        let title = extractTitle(from: html) ?? "Untitled Recipe"
        let ingredients = extractIngredients(from: html)
        let steps = extractSteps(from: html)
        
        guard !ingredients.isEmpty || !steps.isEmpty else {
            throw ParserError.noRecipeFound
        }
        
        return Recipe(
            title: title,
            ingredients: ingredients,
            steps: steps,
            sourceURL: sourceURL
        )
    }
    
    private func extractTitle(from html: String) -> String? {
        // Try to find h1 or title
        let patterns = [
            #"<h1[^>]*class="[^"]*recipe[^"]*"[^>]*>([^<]+)</h1>"#,
            #"<h1[^>]*>([^<]+)</h1>"#,
            #"<title>([^<]+)</title>"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return cleanText(String(html[range]))
            }
        }
        
        return nil
    }
    
    private func extractIngredients(from html: String) -> [String] {
        var ingredients: [String] = []
        
        // Look for ingredient list items
        let pattern = #"<li[^>]*class="[^"]*ingredient[^"]*"[^>]*>([^<]+)</li>"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if let range = Range(match.range(at: 1), in: html) {
                    ingredients.append(cleanText(String(html[range])))
                }
            }
        }
        
        return ingredients
    }
    
    private func extractSteps(from html: String) -> [String] {
        var steps: [String] = []
        
        // Look for instruction list items
        let pattern = #"<li[^>]*class="[^"]*instruction[^"]*"[^>]*>([^<]+)</li>"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            for match in matches {
                if let range = Range(match.range(at: 1), in: html) {
                    steps.append(cleanText(String(html[range])))
                }
            }
        }
        
        return steps
    }
    
    private func cleanText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
