import Foundation
import FirebaseFirestore

/// Type of content the film reference is attached to
enum FilmAttachmentType: String, Codable {
    case set
    case defense
    case practice
}

/// A film reference (external link with optional timecodes and notes)
struct FilmRef: Codable, Identifiable {
    let id: String
    var attachmentType: FilmAttachmentType
    var attachmentId: String
    var targetType: NoteTargetType
    var targetId: String? // nil for ALL, "1"-"5" for POSITION, userId for PLAYER
    var url: String
    var startSeconds: Double?
    var endSeconds: Double?
    var noteText: String?
    var noteAudioStoragePath: String?
    let createdBy: String
    let createdAt: Timestamp
    var updatedAt: Timestamp

    init(
        id: String,
        attachmentType: FilmAttachmentType,
        attachmentId: String,
        targetType: NoteTargetType,
        targetId: String? = nil,
        url: String,
        startSeconds: Double? = nil,
        endSeconds: Double? = nil,
        noteText: String? = nil,
        noteAudioStoragePath: String? = nil,
        createdBy: String,
        createdAt: Timestamp = Timestamp(),
        updatedAt: Timestamp = Timestamp()
    ) {
        self.id = id
        self.attachmentType = attachmentType
        self.attachmentId = attachmentId
        self.targetType = targetType
        self.targetId = targetId
        self.url = url
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
        self.noteText = noteText
        self.noteAudioStoragePath = noteAudioStoragePath
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Check if this film reference is relevant to a specific player position
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

    /// Full URL with timecode fragment if start time is set
    var urlWithTimecode: String {
        guard let start = startSeconds else { return url }
        // YouTube format: &t=123s or #t=123
        // Vimeo format: #t=2m3s
        // Generic fragment: #t=123
        return url + "#t=\(Int(start))"
    }
}
