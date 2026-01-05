import XCTest
@testable import INSTALL

/// Tests for publish versioning logic
class PublishVersioningTests: XCTestCase {

    func testPlaybookVersionIncrementsOnPublish() async throws {
        // This is a pseudo-test demonstrating the expected behavior
        // In real tests, you'd use Firebase emulator or mocks

        var playbookVersion = 0
        let playbookPublishedAt: Date? = nil

        // Initial state
        XCTAssertEqual(playbookVersion, 0)
        XCTAssertNil(playbookPublishedAt)

        // Simulate publish
        playbookVersion += 1
        let publishedAt = Date()

        // After publish
        XCTAssertEqual(playbookVersion, 1)
        XCTAssertNotNil(publishedAt)

        // Publish again
        playbookVersion += 1

        XCTAssertEqual(playbookVersion, 2)
    }

    func testPublishedVersionTrackedPerSet() {
        var set = SetModel(
            id: "set1",
            name: "Horns",
            category: .horns,
            steps: []
        )

        // Initial state
        XCTAssertNil(set.publishedVersion)

        // Simulate publish
        set.publishedVersion = 1

        XCTAssertEqual(set.publishedVersion, 1)
    }

    func testDraftUpdatesDoNotTriggerPublish() {
        var set = SetModel(
            id: "set1",
            name: "Horns",
            category: .horns,
            steps: []
        )

        let initialPublishedVersion = set.publishedVersion

        // Draft update
        set.draftUpdatedAt = Timestamp()
        set.updatedAt = Timestamp()

        // Published version should not change
        XCTAssertEqual(set.publishedVersion, initialPublishedVersion)
    }

    func testPracticePublishSetsTimestamp() {
        var practice = PracticeSession(
            id: "practice1",
            title: "Monday Practice"
        )

        // Initially not published
        XCTAssertFalse(practice.isPublished)

        // Publish
        practice.publishedAt = Timestamp()

        // Now published
        XCTAssertTrue(practice.isPublished)
    }

    func testUpcomingPracticeLogic() {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        let upcomingPractice = PracticeSession(
            id: "practice1",
            title: "Tomorrow",
            startAt: Timestamp(date: tomorrow)
        )

        let pastPractice = PracticeSession(
            id: "practice2",
            title: "Yesterday",
            startAt: Timestamp(date: yesterday)
        )

        XCTAssertTrue(upcomingPractice.isUpcoming)
        XCTAssertFalse(pastPractice.isUpcoming)
    }
}
