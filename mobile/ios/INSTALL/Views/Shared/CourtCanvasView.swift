import SwiftUI

/// Court canvas rendering view
struct CourtCanvasView: View {
    let step: Step
    let focusPosition: Int? // 1-5, nil = no focus
    let canvasSize: CGSize

    var body: some View {
        Canvas { context, size in
            // Draw court lines
            let courtPath = CourtGeometry.courtPath(for: size)
            context.stroke(courtPath, with: .color(.gray.opacity(0.3)), lineWidth: 2)

            // Draw player tokens
            for action in step.playerActions {
                drawPlayerToken(context: context, action: action, size: size)
            }

            // Draw movement arrows
            for action in step.playerActions {
                if let toSpotId = action.toSpotId {
                    drawMovementArrow(context: context, action: action, toSpotId: toSpotId, size: size)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    // MARK: - Drawing Helpers

    private func drawPlayerToken(context: GraphicsContext, action: PlayerAction, size: CGSize) {
        let spot = action.fromSpot
        let normalizedPoint = CGPoint(x: spot.x, y: spot.y)
        let canvasPoint = CourtGeometry.toCanvasCoordinates(normalized: normalizedPoint, canvasSize: size)

        // Token appearance based on focus
        let opacity = POVCamera.opacity(for: action.position, focusPosition: focusPosition)
        let scale = POVCamera.scale(for: action.position, focusPosition: focusPosition)

        let tokenRadius: CGFloat = 18 * scale
        let tokenColor = action.hasBall ? Color.orange : Color.blue

        // Draw circle
        let circlePath = Path { path in
            path.addEllipse(in: CGRect(
                x: canvasPoint.x - tokenRadius,
                y: canvasPoint.y - tokenRadius,
                width: tokenRadius * 2,
                height: tokenRadius * 2
            ))
        }

        context.fill(circlePath, with: .color(tokenColor.opacity(opacity)))
        context.stroke(circlePath, with: .color(.white.opacity(opacity)), lineWidth: 2)

        // Draw position number
        let text = Text("\(action.position)")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white.opacity(opacity))

        context.draw(text, at: canvasPoint, anchor: .center)
    }

    private func drawMovementArrow(context: GraphicsContext, action: PlayerAction, toSpotId: String, size: CGSize) {
        let fromSpot = action.fromSpot
        guard let toSpot = Spots.spot(for: toSpotId) else { return }

        let fromPoint = CourtGeometry.toCanvasCoordinates(
            normalized: CGPoint(x: fromSpot.x, y: fromSpot.y),
            canvasSize: size
        )

        let toPoint = CourtGeometry.toCanvasCoordinates(
            normalized: CGPoint(x: toSpot.x, y: toSpot.y),
            canvasSize: size
        )

        // Adjust endpoints to avoid overlapping with tokens
        let tokenRadius: CGFloat = 18
        let direction = CGPoint(
            x: toPoint.x - fromPoint.x,
            y: toPoint.y - fromPoint.y
        )
        let distance = sqrt(direction.x * direction.x + direction.y * direction.y)
        let normalized = CGPoint(x: direction.x / distance, y: direction.y / distance)

        let adjustedFrom = CGPoint(
            x: fromPoint.x + normalized.x * tokenRadius,
            y: fromPoint.y + normalized.y * tokenRadius
        )

        let adjustedTo = CGPoint(
            x: toPoint.x - normalized.x * tokenRadius,
            y: toPoint.y - normalized.y * tokenRadius
        )

        // Draw arrow line
        var arrowPath = Path()
        arrowPath.move(to: adjustedFrom)
        arrowPath.addLine(to: adjustedTo)

        let opacity = POVCamera.opacity(for: action.position, focusPosition: focusPosition)
        context.stroke(arrowPath, with: .color(.gray.opacity(opacity * 0.8)), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        // Draw arrowhead
        let arrowHeadLength: CGFloat = 10
        let arrowHeadAngle: CGFloat = .pi / 6 // 30 degrees

        let angle = atan2(direction.y, direction.x)

        let arrowHead1 = CGPoint(
            x: adjustedTo.x - arrowHeadLength * cos(angle - arrowHeadAngle),
            y: adjustedTo.y - arrowHeadLength * sin(angle - arrowHeadAngle)
        )

        let arrowHead2 = CGPoint(
            x: adjustedTo.x - arrowHeadLength * cos(angle + arrowHeadAngle),
            y: adjustedTo.y - arrowHeadLength * sin(angle + arrowHeadAngle)
        )

        var arrowHeadPath = Path()
        arrowHeadPath.move(to: arrowHead1)
        arrowHeadPath.addLine(to: adjustedTo)
        arrowHeadPath.addLine(to: arrowHead2)

        context.stroke(arrowHeadPath, with: .color(.gray.opacity(opacity * 0.8)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}
