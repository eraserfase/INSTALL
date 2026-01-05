import Foundation
import FirebaseFirestore

/// Category for organizing defense scenarios
enum DefenseCategory: String, Codable, CaseIterable {
    case pickAndRoll = "Pick & Roll"
    case zone = "Zone"
    case manToMan = "Man to Man"
    case press = "Press"
    case transition = "Transition"
    case other = "Other"
}

/// A defensive coverage scenario (uses same step engine as sets)
struct DefenseScenario: Codable, Identifiable {
    let id: String
    var name: String
    var category: DefenseCategory
    var isTemplate: Bool
    var sourceTemplateId: String?
    var updatedAt: Timestamp
    var draftUpdatedAt: Timestamp?
    var publishedVersion: Int?
    var steps: [Step] // alignment, trigger, rotation steps

    init(
        id: String,
        name: String,
        category: DefenseCategory,
        isTemplate: Bool = false,
        sourceTemplateId: String? = nil,
        updatedAt: Timestamp = Timestamp(),
        draftUpdatedAt: Timestamp? = nil,
        publishedVersion: Int? = nil,
        steps: [Step]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isTemplate = isTemplate
        self.sourceTemplateId = sourceTemplateId
        self.updatedAt = updatedAt
        self.draftUpdatedAt = draftUpdatedAt
        self.publishedVersion = publishedVersion
        self.steps = steps
    }

    var enabledSteps: [Step] {
        return steps.filter { $0.enabled }
    }
}
