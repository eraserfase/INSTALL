import SwiftUI

/// Court geometry and coordinate transformation utilities
struct CourtGeometry {

    /// Aspect ratio for half-court (width : length from baseline to half court)
    /// Standard court: 50 ft wide x 47 ft (baseline to half court)
    static let aspectRatio: CGFloat = 50.0 / 47.0 // ~1.064

    /// Convert normalized spot coordinates [0..1] to canvas coordinates
    /// - Parameters:
    ///   - normalized: Normalized position (0,0) = bottom-left, (1,1) = top-right
    ///   - canvasSize: Size of the canvas in points
    /// - Returns: Canvas coordinates in points
    static func toCanvasCoordinates(normalized: CGPoint, canvasSize: CGSize) -> CGPoint {
        // Court has some padding for player tokens
        let padding: CGFloat = 40
        let courtWidth = canvasSize.width - (padding * 2)
        let courtHeight = canvasSize.height - (padding * 2)

        // Map normalized [0..1] to canvas coordinates
        // Note: Canvas origin is top-left, so invert Y
        let x = padding + (normalized.x * courtWidth)
        let y = padding + ((1.0 - normalized.y) * courtHeight)

        return CGPoint(x: x, y: y)
    }

    /// Get court bounds for drawing (baseline, sidelines, key, three-point line)
    /// - Parameter canvasSize: Size of the canvas
    /// - Returns: Path representing court lines
    static func courtPath(for canvasSize: CGSize) -> Path {
        var path = Path()

        let padding: CGFloat = 40
        let courtWidth = canvasSize.width - (padding * 2)
        let courtHeight = canvasSize.height - (padding * 2)

        // Baseline (bottom)
        path.move(to: CGPoint(x: padding, y: canvasSize.height - padding))
        path.addLine(to: CGPoint(x: canvasSize.width - padding, y: canvasSize.height - padding))

        // Sidelines
        path.move(to: CGPoint(x: padding, y: padding))
        path.addLine(to: CGPoint(x: padding, y: canvasSize.height - padding))

        path.move(to: CGPoint(x: canvasSize.width - padding, y: padding))
        path.addLine(to: CGPoint(x: canvasSize.width - padding, y: canvasSize.height - padding))

        // Half court line (top)
        path.move(to: CGPoint(x: padding, y: padding))
        path.addLine(to: CGPoint(x: canvasSize.width - padding, y: padding))

        // Paint / key (simplified)
        let keyWidth = courtWidth * 0.32 // ~16ft on 50ft court
        let keyHeight = courtHeight * 0.4 // ~19ft from baseline
        let keyX = (canvasSize.width - keyWidth) / 2

        path.addRect(CGRect(
            x: keyX,
            y: canvasSize.height - padding - keyHeight,
            width: keyWidth,
            height: keyHeight
        ))

        // Free throw circle (simplified as arc)
        let ftCircleRadius = keyWidth / 2
        let ftCircleCenter = CGPoint(
            x: canvasSize.width / 2,
            y: canvasSize.height - padding - keyHeight
        )
        path.addArc(
            center: ftCircleCenter,
            radius: ftCircleRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Three-point line (simplified arc)
        let threePointRadius = courtWidth * 0.42 // ~23.75ft corner
        let threePointCenter = CGPoint(x: canvasSize.width / 2, y: canvasSize.height - padding)

        // Arc portion
        path.addArc(
            center: threePointCenter,
            radius: threePointRadius,
            startAngle: .degrees(200),
            endAngle: .degrees(340),
            clockwise: false
        )

        // Straight lines to corners
        let cornerY = canvasSize.height - padding - (courtHeight * 0.15) // ~7ft from baseline

        path.move(to: CGPoint(x: padding, y: cornerY))
        path.addLine(to: CGPoint(x: padding, y: canvasSize.height - padding))

        path.move(to: CGPoint(x: canvasSize.width - padding, y: cornerY))
        path.addLine(to: CGPoint(x: canvasSize.width - padding, y: canvasSize.height - padding))

        return path
    }

    /// Get ideal canvas size for a given container width (maintains aspect ratio)
    /// - Parameter containerWidth: Width of the container
    /// - Returns: Ideal canvas size
    static func idealCanvasSize(for containerWidth: CGFloat) -> CGSize {
        let width = containerWidth
        let height = width / aspectRatio
        return CGSize(width: width, height: height)
    }
}
