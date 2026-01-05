import Foundation
import FirebaseFirestore

/// Team model
struct Team: Codable, Identifiable {
    let id: String
    var name: String
    let createdAt: Timestamp
    let createdBy: String // userId
    var joinCode: String
    var playbookVersion: Int
    var playbookPublishedAt: Timestamp?

    init(
        id: String,
        name: String,
        createdAt: Timestamp = Timestamp(),
        createdBy: String,
        joinCode: String,
        playbookVersion: Int = 0,
        playbookPublishedAt: Timestamp? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.joinCode = joinCode
        self.playbookVersion = playbookVersion
        self.playbookPublishedAt = playbookPublishedAt
    }
}

// MARK: - Firestore Document Mapping

extension Team {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case createdBy
        case joinCode
        case playbookVersion
        case playbookPublishedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        joinCode = try container.decode(String.self, forKey: .joinCode)
        playbookVersion = try container.decode(Int.self, forKey: .playbookVersion)
        playbookPublishedAt = try container.decodeIfPresent(Timestamp.self, forKey: .playbookPublishedAt)
    }
}
