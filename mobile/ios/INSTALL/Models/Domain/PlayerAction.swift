import Foundation

/// Type of action a player can take (coach-native terminology)
enum ActionType: String, Codable, CaseIterable, Identifiable {
    case spotUp = "spot_up"
    case cut = "cut"
    case replace = "replace"
    case lift = "lift"
    case drift = "drift"
    case screen = "screen"
    case downScreen = "down_screen"
    case flareScreen = "flare_screen"
    case ballScreen = "ball_screen"
    case handoff = "handoff"
    case roll = "roll"
    case pop = "pop"
    case slip = "slip"
    case postUp = "post_up"
    case duckIn = "duck_in"
    case flash = "flash"
    case seal = "seal"
    case decoy = "decoy"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spotUp: return "Spot Up"
        case .cut: return "Cut"
        case .replace: return "Replace"
        case .lift: return "Lift"
        case .drift: return "Drift"
        case .screen: return "Screen"
        case .downScreen: return "Down Screen"
        case .flareScreen: return "Flare Screen"
        case .ballScreen: return "Ball Screen"
        case .handoff: return "Handoff"
        case .roll: return "Roll"
        case .pop: return "Pop"
        case .slip: return "Slip"
        case .postUp: return "Post Up"
        case .duckIn: return "Duck In"
        case .flash: return "Flash"
        case .seal: return "Seal"
        case .decoy: return "Decoy"
        }
    }

    /// Whether this action requires a target position
    var requiresTarget: Bool {
        switch self {
        case .screen, .downScreen, .flareScreen, .ballScreen, .handoff:
            return true
        default:
            return false
        }
    }

    /// Whether this action typically involves movement
    var involvesMovement: Bool {
        switch self {
        case .spotUp, .decoy:
            return false
        default:
            return true
        }
    }
}

/// A single player's action within a step
struct PlayerAction: Codable, Identifiable, Hashable {
    var id: String { "\(position)-\(actionType.rawValue)" }

    let position: Int // 1-5
    var actionType: ActionType
    var fromSpotId: String
    var toSpotId: String? // Optional for stationary actions
    var targetPosition: Int? // Optional: for screens/handoffs (1-5)
    var hasBall: Bool

    init(
        position: Int,
        actionType: ActionType,
        fromSpotId: String,
        toSpotId: String? = nil,
        targetPosition: Int? = nil,
        hasBall: Bool = false
    ) {
        self.position = position
        self.actionType = actionType
        self.fromSpotId = fromSpotId
        self.toSpotId = toSpotId
        self.targetPosition = targetPosition
        self.hasBall = hasBall
    }

    /// Get the from spot
    var fromSpot: Spot {
        return Spots.spot(for: fromSpotId) ?? Spots.defaultSpot
    }

    /// Get the to spot (fallback to from spot if not set)
    var toSpot: Spot {
        guard let toSpotId = toSpotId else { return fromSpot }
        return Spots.spot(for: toSpotId) ?? fromSpot
    }

    /// Display description for coach/player
    var description: String {
        var desc = actionType.displayName
        if let target = targetPosition {
            desc += " for \(target)"
        }
        return desc
    }
}
