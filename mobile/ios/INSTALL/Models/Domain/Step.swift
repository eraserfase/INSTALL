import Foundation
import FirebaseFirestore

/// A single step in a set or defense scenario
/// Contains 5 player actions (positions 1-5)
struct Step: Codable, Identifiable, Hashable {
    var id: String { "\(index)" }

    let index: Int
    var label: String // e.g., "Initial alignment", "1 pins for 4"
    var note: String? // Optional coach note for this step
    var enabled: Bool
    var emphasisPosition: Int? // Optional: which position to emphasize in rendering (1-5)
    var playerActions: [PlayerAction] // Always 5 items

    init(
        index: Int,
        label: String,
        note: String? = nil,
        enabled: Bool = true,
        emphasisPosition: Int? = nil,
        playerActions: [PlayerAction]
    ) {
        self.index = index
        self.label = label
        self.note = note
        self.enabled = enabled
        self.emphasisPosition = emphasisPosition
        self.playerActions = playerActions
    }

    /// Get action for a specific position
    func action(for position: Int) -> PlayerAction? {
        return playerActions.first { $0.position == position }
    }

    /// Get all positions that have the ball in this step
    var ballCarriers: [Int] {
        return playerActions.filter { $0.hasBall }.map { $0.position }
    }
}

// MARK: - Firestore Codable Extensions

extension Step {
    enum CodingKeys: String, CodingKey {
        case index
        case label
        case note
        case enabled
        case emphasisPosition
        case playerActions
    }
}
