import Foundation
import FirebaseFirestore

/// User role within a team
enum TeamRole: String, Codable {
    case coach
    case player
}

/// User membership status
enum MembershipStatus: String, Codable {
    case active
    case removed
}

/// Team membership model
struct Membership: Codable, Identifiable {
    let id: String // userId
    var role: TeamRole
    var displayNameOverride: String?
    var jerseyNumber: String?
    var status: MembershipStatus
    let createdAt: Timestamp
    var fcmToken: String? // For push notifications

    init(
        id: String,
        role: TeamRole,
        displayNameOverride: String? = nil,
        jerseyNumber: String? = nil,
        status: MembershipStatus = .active,
        createdAt: Timestamp = Timestamp(),
        fcmToken: String? = nil
    ) {
        self.id = id
        self.role = role
        self.displayNameOverride = displayNameOverride
        self.jerseyNumber = jerseyNumber
        self.status = status
        self.createdAt = createdAt
        self.fcmToken = fcmToken
    }
}
