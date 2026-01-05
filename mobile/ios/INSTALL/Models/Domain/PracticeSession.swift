import Foundation
import FirebaseFirestore

/// Attachment reference for practice (sets/defense scenarios)
struct PracticeAttachment: Codable, Hashable {
    var setIds: [String]
    var defenseIds: [String]

    init(setIds: [String] = [], defenseIds: [String] = []) {
        self.setIds = setIds
        self.defenseIds = defenseIds
    }
}

/// A practice session (curriculum, not logistics)
struct PracticeSession: Codable, Identifiable {
    let id: String
    var title: String
    var startAt: Timestamp? // Optional date/time
    var location: String? // Optional
    var focusText: String? // Focus note for the practice
    var attachments: PracticeAttachment
    var publishedAt: Timestamp?
    var updatedAt: Timestamp

    init(
        id: String,
        title: String,
        startAt: Timestamp? = nil,
        location: String? = nil,
        focusText: String? = nil,
        attachments: PracticeAttachment = PracticeAttachment(),
        publishedAt: Timestamp? = nil,
        updatedAt: Timestamp = Timestamp()
    ) {
        self.id = id
        self.title = title
        self.startAt = startAt
        self.location = location
        self.focusText = focusText
        self.attachments = attachments
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
    }

    /// Check if practice is published
    var isPublished: Bool {
        return publishedAt != nil
    }

    /// Check if practice is in the future
    var isUpcoming: Bool {
        guard let start = startAt else { return true }
        return start.dateValue() > Date()
    }
}
