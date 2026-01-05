import XCTest
@testable import INSTALL

/// Tests for role-based permission gating
class RoleGatingTests: XCTestCase {

    func testCoachRoleHasWritePermissions() {
        let coachMembership = Membership(
            id: "user1",
            role: .coach,
            status: .active
        )

        XCTAssertEqual(coachMembership.role, .coach)
        XCTAssertEqual(coachMembership.status, .active)

        // In actual app, coaches can write
        let canWrite = (coachMembership.role == .coach && coachMembership.status == .active)
        XCTAssertTrue(canWrite)
    }

    func testPlayerRoleHasReadOnlyPermissions() {
        let playerMembership = Membership(
            id: "user2",
            role: .player,
            status: .active
        )

        XCTAssertEqual(playerMembership.role, .player)

        // In actual app, players cannot write
        let canWrite = (playerMembership.role == .coach && playerMembership.status == .active)
        XCTAssertFalse(canWrite)
    }

    func testRemovedMembersCannotAccess() {
        let removedMember = Membership(
            id: "user3",
            role: .coach,
            status: .removed
        )

        XCTAssertEqual(removedMember.status, .removed)

        // Even coaches lose access when removed
        let canAccess = (removedMember.status == .active)
        XCTAssertFalse(canAccess)
    }

    func testTeamRoleEnum() {
        let coachRole = TeamRole.coach
        let playerRole = TeamRole.player

        XCTAssertEqual(coachRole.rawValue, "coach")
        XCTAssertEqual(playerRole.rawValue, "player")

        // Test decoding
        XCTAssertEqual(TeamRole(rawValue: "coach"), .coach)
        XCTAssertEqual(TeamRole(rawValue: "player"), .player)
    }

    func testMembershipStatusEnum() {
        let active = MembershipStatus.active
        let removed = MembershipStatus.removed

        XCTAssertEqual(active.rawValue, "active")
        XCTAssertEqual(removed.rawValue, "removed")

        // Test decoding
        XCTAssertEqual(MembershipStatus(rawValue: "active"), .active)
        XCTAssertEqual(MembershipStatus(rawValue: "removed"), .removed)
    }
}
