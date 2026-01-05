import SwiftUI

/// POV (Point of View) camera utilities for emphasizing focus position
struct POVCamera {

    /// Calculate camera offset to bias view toward focus position
    /// - Parameters:
    ///   - focusPosition: Position to emphasize (1-5), or nil for default
    ///   - step: Current step with player actions
    ///   - canvasSize: Size of the canvas
    /// - Returns: Camera offset (bounded)
    static func cameraOffset(
        for focusPosition: Int?,
        in step: Step,
        canvasSize: CGSize
    ) -> CGSize {
        guard let focus = focusPosition,
              let action = step.action(for: focus) else {
            return .zero
        }

        // Get focus player's current spot
        let spot = action.fromSpot
        let normalized = CGPoint(x: spot.x, y: spot.y)
        let canvasPoint = CourtGeometry.toCanvasCoordinates(normalized: normalized, canvasSize: canvasSize)

        // Calculate offset to center focus player (bounded to avoid extreme panning)
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2

        let offsetX = centerX - canvasPoint.x
        let offsetY = centerY - canvasPoint.y

        // Bound offset to max 20% of canvas dimensions (subtle bias, not full pan)
        let maxOffsetX = canvasSize.width * 0.2
        let maxOffsetY = canvasSize.height * 0.2

        let boundedOffsetX = max(-maxOffsetX, min(maxOffsetX, offsetX))
        let boundedOffsetY = max(-maxOffsetY, min(maxOffsetY, offsetY))

        return CGSize(width: boundedOffsetX, height: boundedOffsetY)
    }

    /// Get opacity for a player based on focus
    /// - Parameters:
    ///   - position: Player position (1-5)
    ///   - focusPosition: Focus position (1-5), or nil for default
    /// - Returns: Opacity value (0.0 - 1.0)
    static func opacity(for position: Int, focusPosition: Int?) -> Double {
        guard let focus = focusPosition else {
            return 1.0 // No focus, all players full opacity
        }

        return position == focus ? 1.0 : 0.4
    }

    /// Get scale for a player based on focus
    /// - Parameters:
    ///   - position: Player position (1-5)
    ///   - focusPosition: Focus position (1-5), or nil for default
    /// - Returns: Scale value
    static func scale(for position: Int, focusPosition: Int?) -> CGFloat {
        guard let focus = focusPosition else {
            return 1.0
        }

        return position == focus ? 1.15 : 0.95
    }
}
