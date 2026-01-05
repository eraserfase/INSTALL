import XCTest
@testable import INSTALL

/// Tests for template JSON decoding
class TemplateDecodeTests: XCTestCase {

    func testOffenseTemplatesLoadSuccessfully() {
        let templates = TemplatesLoader.shared.loadOffenseTemplates()

        XCTAssertGreaterThanOrEqual(templates.count, 12, "Should have at least 12 offense templates")

        for template in templates {
            XCTAssertTrue(template.isTemplate, "\(template.name) should be marked as template")
            XCTAssertFalse(template.name.isEmpty, "Template name should not be empty")
            XCTAssertFalse(template.steps.isEmpty, "\(template.name) should have steps")

            // Validate steps
            for step in template.steps {
                XCTAssertEqual(step.playerActions.count, 5, "\(template.name) step \(step.index) should have 5 player actions")

                // Validate each action has valid spots
                for action in step.playerActions {
                    XCTAssertNotNil(Spots.spot(for: action.fromSpotId), "\(template.name) has invalid fromSpotId: \(action.fromSpotId)")

                    if let toSpotId = action.toSpotId {
                        XCTAssertNotNil(Spots.spot(for: toSpotId), "\(template.name) has invalid toSpotId: \(toSpotId)")
                    }
                }
            }
        }
    }

    func testDefenseTemplatesLoadSuccessfully() {
        let templates = TemplatesLoader.shared.loadDefenseTemplates()

        XCTAssertGreaterThanOrEqual(templates.count, 3, "Should have at least 3 defense templates")

        for template in templates {
            XCTAssertTrue(template.isTemplate, "\(template.name) should be marked as template")
            XCTAssertFalse(template.name.isEmpty, "Template name should not be empty")
            XCTAssertFalse(template.steps.isEmpty, "\(template.name) should have steps")

            // Validate steps
            for step in template.steps {
                XCTAssertEqual(step.playerActions.count, 5, "\(template.name) step \(step.index) should have 5 player actions")
            }
        }
    }

    func testSpecificTemplateExists() {
        let templates = TemplatesLoader.shared.loadOffenseTemplates()

        let hornsBasic = templates.first { $0.id == "template_horns_basic" }
        XCTAssertNotNil(hornsBasic, "Horns (Basic) template should exist")
        XCTAssertEqual(hornsBasic?.name, "Horns (Basic)")
        XCTAssertEqual(hornsBasic?.category, .horns)
    }

    func testTemplateById() {
        let template = TemplatesLoader.shared.offenseTemplate(byId: "template_horns_basic")
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.name, "Horns (Basic)")
    }

    func testActionTypesAreValid() {
        let templates = TemplatesLoader.shared.loadOffenseTemplates()

        for template in templates {
            for step in template.steps {
                for action in step.playerActions {
                    // Action type should be in the enum
                    XCTAssertNotNil(ActionType(rawValue: action.actionType.rawValue), "Invalid action type: \(action.actionType.rawValue)")
                }
            }
        }
    }

    func testPositionsAreValid() {
        let templates = TemplatesLoader.shared.loadOffenseTemplates()

        for template in templates {
            for step in template.steps {
                // Should have exactly positions 1-5
                let positions = Set(step.playerActions.map { $0.position })
                XCTAssertEqual(positions, Set(1...5), "\(template.name) step \(step.index) should have positions 1-5")
            }
        }
    }

    func testEnabledStepsByDefault() {
        let templates = TemplatesLoader.shared.loadOffenseTemplates()

        for template in templates {
            for step in template.steps {
                XCTAssertTrue(step.enabled, "\(template.name) step \(step.index) should be enabled by default")
            }
        }
    }
}
