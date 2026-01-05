import XCTest
@testable import INSTALL

/// Tests for spot coordinate mapping
class SpotMappingTests: XCTestCase {

    func testAllSpotsHaveValidCoordinates() {
        for spot in Spots.all {
            XCTAssertGreaterThanOrEqual(spot.x, 0.0, "\(spot.id) x coordinate should be >= 0")
            XCTAssertLessThanOrEqual(spot.x, 1.0, "\(spot.id) x coordinate should be <= 1")
            XCTAssertGreaterThanOrEqual(spot.y, 0.0, "\(spot.id) y coordinate should be >= 0")
            XCTAssertLessThanOrEqual(spot.y, 1.0, "\(spot.id) y coordinate should be <= 1")
        }
    }

    func testSpotLookup() {
        XCTAssertNotNil(Spots.spot(for: "top"))
        XCTAssertNotNil(Spots.spot(for: "wing_l"))
        XCTAssertNotNil(Spots.spot(for: "corner_r"))
        XCTAssertNil(Spots.spot(for: "invalid_spot"))
    }

    func testSpotMapContainsAllSpots() {
        let spotMap = Spots.spotMap
        XCTAssertEqual(spotMap.count, Spots.all.count)

        for spot in Spots.all {
            XCTAssertNotNil(spotMap[spot.id])
        }
    }

    func testCoordinateTransformationIsDeterministic() {
        let canvasSize = CGSize(width: 400, height: 400)
        let spot = Spots.spot(for: "top")!
        let normalized = CGPoint(x: spot.x, y: spot.y)

        // Transform twice
        let point1 = CourtGeometry.toCanvasCoordinates(normalized: normalized, canvasSize: canvasSize)
        let point2 = CourtGeometry.toCanvasCoordinates(normalized: normalized, canvasSize: canvasSize)

        XCTAssertEqual(point1.x, point2.x, accuracy: 0.001)
        XCTAssertEqual(point1.y, point2.y, accuracy: 0.001)
    }

    func testCornerCoordinates() {
        let canvasSize = CGSize(width: 400, height: 400)

        // Bottom-left should be near left edge and bottom
        let bottomLeft = CGPoint(x: 0.0, y: 0.0)
        let blCanvas = CourtGeometry.toCanvasCoordinates(normalized: bottomLeft, canvasSize: canvasSize)
        XCTAssertLessThan(blCanvas.x, 60) // Near left edge (padding 40)
        XCTAssertGreaterThan(blCanvas.y, 340) // Near bottom (accounting for inverted Y)

        // Top-right should be near right edge and top
        let topRight = CGPoint(x: 1.0, y: 1.0)
        let trCanvas = CourtGeometry.toCanvasCoordinates(normalized: topRight, canvasSize: canvasSize)
        XCTAssertGreaterThan(trCanvas.x, 340)
        XCTAssertLessThan(trCanvas.y, 60)
    }

    func testCenterCoordinates() {
        let canvasSize = CGSize(width: 400, height: 400)
        let center = CGPoint(x: 0.5, y: 0.5)
        let centerCanvas = CourtGeometry.toCanvasCoordinates(normalized: center, canvasSize: canvasSize)

        // Should be near canvas center
        XCTAssertEqual(centerCanvas.x, 200, accuracy: 5)
        XCTAssertEqual(centerCanvas.y, 200, accuracy: 5)
    }
}
