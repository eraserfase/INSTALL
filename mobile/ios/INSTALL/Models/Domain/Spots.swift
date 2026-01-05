import Foundation

/// Represents a named position on the basketball court (half-court)
struct Spot: Identifiable, Codable, Hashable {
    let id: String // spotId like "top", "wing_l", etc.
    let displayName: String
    let x: Double // Normalized [0..1] horizontal position (0 = left, 1 = right)
    let y: Double // Normalized [0..1] vertical position (0 = baseline, 1 = half court)

    init(id: String, displayName: String, x: Double, y: Double) {
        self.id = id
        self.displayName = displayName
        self.x = x
        self.y = y
    }
}

/// Canonical spot definitions for half-court basketball
/// Coordinate system: (0,0) = bottom-left corner, (1,1) = top-right at half court
struct Spots {

    // MARK: - All Spots (Static)

    static let all: [Spot] = [
        // Top of key
        Spot(id: "top", displayName: "Top", x: 0.5, y: 0.85),

        // Slots (extended top, between top and wings)
        Spot(id: "slot_l", displayName: "Left Slot", x: 0.25, y: 0.75),
        Spot(id: "slot_r", displayName: "Right Slot", x: 0.75, y: 0.75),

        // Wings
        Spot(id: "wing_l", displayName: "Left Wing", x: 0.15, y: 0.60),
        Spot(id: "wing_r", displayName: "Right Wing", x: 0.85, y: 0.60),

        // Corners
        Spot(id: "corner_l", displayName: "Left Corner", x: 0.05, y: 0.15),
        Spot(id: "corner_r", displayName: "Right Corner", x: 0.95, y: 0.15),

        // Short corners (between wing and corner)
        Spot(id: "shortcorner_l", displayName: "Left Short Corner", x: 0.10, y: 0.35),
        Spot(id: "shortcorner_r", displayName: "Right Short Corner", x: 0.90, y: 0.35),

        // Elbows (free throw line extended)
        Spot(id: "elbow_l", displayName: "Left Elbow", x: 0.28, y: 0.55),
        Spot(id: "elbow_r", displayName: "Right Elbow", x: 0.72, y: 0.55),

        // Low post
        Spot(id: "lowpost_l", displayName: "Left Low Post", x: 0.25, y: 0.25),
        Spot(id: "lowpost_r", displayName: "Right Low Post", x: 0.75, y: 0.25),

        // Dunker spots (below block)
        Spot(id: "dunker_l", displayName: "Left Dunker", x: 0.20, y: 0.12),
        Spot(id: "dunker_r", displayName: "Right Dunker", x: 0.80, y: 0.12),
    ]

    // MARK: - Lookup

    static func spot(for id: String) -> Spot? {
        return all.first { $0.id == id }
    }

    static var spotMap: [String: Spot] {
        return Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }

    // MARK: - Default/Fallback

    static let defaultSpot = Spot(id: "top", displayName: "Top", x: 0.5, y: 0.85)
}
