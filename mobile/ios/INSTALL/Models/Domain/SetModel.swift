import Foundation
import FirebaseFirestore

/// Category for organizing sets
enum SetCategory: String, Codable, CaseIterable {
    case horns = "Horns"
    case motion = "Motion"
    case flex = "Flex"
    case quick = "Quick Hitter"
    case blob = "BLOB"
    case slob = "SLOB"
    case transition = "Transition"
    case other = "Other"
}

/// A basketball set (offensive play)
struct SetModel: Codable, Identifiable {
    let id: String
    var name: String
    var category: SetCategory
    var isTemplate: Bool
    var sourceTemplateId: String? // If duplicated from a template
    var updatedAt: Timestamp
    var draftUpdatedAt: Timestamp?
    var publishedVersion: Int?
    var steps: [Step]

    init(
        id: String,
        name: String,
        category: SetCategory,
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

    /// Get enabled steps only
    var enabledSteps: [Step] {
        return steps.filter { $0.enabled }
    }
}
