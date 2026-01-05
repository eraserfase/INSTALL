import Foundation

/// Service for loading preloaded templates from JSON files
class TemplatesLoader {

    static let shared = TemplatesLoader()

    private init() {}

    // MARK: - Offense Templates

    func loadOffenseTemplates() -> [SetModel] {
        guard let url = Bundle.main.url(forResource: "offense_templates", withExtension: "json", subdirectory: "templates") else {
            print("⚠️ offense_templates.json not found in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970

            let templates = try decoder.decode([SetModel].self, from: data)
            print("✅ Loaded \(templates.count) offense templates")
            return templates
        } catch {
            print("❌ Failed to load offense templates: \(error)")
            return []
        }
    }

    // MARK: - Defense Templates

    func loadDefenseTemplates() -> [DefenseScenario] {
        guard let url = Bundle.main.url(forResource: "defense_templates", withExtension: "json", subdirectory: "templates") else {
            print("⚠️ defense_templates.json not found in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970

            let templates = try decoder.decode([DefenseScenario].self, from: data)
            print("✅ Loaded \(templates.count) defense templates")
            return templates
        } catch {
            print("❌ Failed to load defense templates: \(error)")
            return []
        }
    }

    // MARK: - Template by ID

    func offenseTemplate(byId id: String) -> SetModel? {
        return loadOffenseTemplates().first { $0.id == id }
    }

    func defenseTemplate(byId id: String) -> DefenseScenario? {
        return loadDefenseTemplates().first { $0.id == id }
    }
}
