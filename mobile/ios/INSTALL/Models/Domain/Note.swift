import Foundation
import FirebaseFirestore

/// Type of content the note is attached to
enum NoteAttachmentType: String, Codable {
    case set
    case step
    case defense
    case practice
    case film
}

/// Who the note targets
enum NoteTargetType: String, Codable {
    case all = "ALL"
    case position = "POSITION"
    case player = "PLAYER"
}

/// Audio metadata for a note
struct AudioMetadata: Codable, Hashable {
    let storagePath: String
    let durationMs: Int
}

/// A note attached to content (text and/or audio)
struct Note: Codable, Identifiable {
    let id: String
    var attachmentType: NoteAttachmentType
    var attachmentId: String
    var stepIndex: Int? // Optional: for step-level notes
    var targetType: NoteTargetType
    var targetId: String? // nil for ALL, "1"-"5" for POSITION, userId for PLAYER
    var text: String?
    var audio: AudioMetadata?
    let createdBy: String
    let createdAt: Timestamp
    var updatedAt: Timestamp

    init(
        id: String,
        attachmentType: NoteAttachmentType,
        attachmentId: String,
        stepIndex: Int? = nil,
        targetType: NoteTargetType,
        targetId: String? = nil,
        text: String? = nil,
        audio: AudioMetadata? = nil,
        createdBy: String,
        createdAt: Timestamp = Timestamp(),
        updatedAt: Timestamp = Timestamp()
    ) {
        self.id = id
        self.attachmentType = attachmentType
        self.attachmentId = attachmentId
        self.stepIndex = stepIndex
        self.targetType = targetType
        self.targetId = targetId
        self.text = text
        self.audio = audio
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Check if this note is relevant to a specific player position
    func isRelevant(for position: Int?, userId: String?) -> Bool {
        switch targetType {
        case .all:
            return true
        case .position:
            guard let pos = position, let targetPos = targetId, let targetPosInt = Int(targetPos) else {
                return false
            }
            return pos == targetPosInt
        case .player:
            guard let uid = userId, let targetUid = targetId else {
                return false
            }
            return uid == targetUid
        }
    }
}
