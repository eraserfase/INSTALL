import XCTest
import FirebaseFirestore
@testable import INSTALL

/// Tests for note targeting composition logic
class NotesTargetingTests: XCTestCase {

    func testAllTargetIsRelevantToEveryone() {
        let note = Note(
            id: "note1",
            attachmentType: .set,
            attachmentId: "set1",
            targetType: .all,
            targetId: nil,
            text: "Team note",
            createdBy: "coach1"
        )

        XCTAssertTrue(note.isRelevant(for: 1, userId: "player1"))
        XCTAssertTrue(note.isRelevant(for: 2, userId: "player2"))
        XCTAssertTrue(note.isRelevant(for: nil, userId: "player3"))
    }

    func testPositionTargetIsRelevantToCorrectPosition() {
        let note = Note(
            id: "note2",
            attachmentType: .set,
            attachmentId: "set1",
            targetType: .position,
            targetId: "1", // Position 1
            text: "Point guard note",
            createdBy: "coach1"
        )

        XCTAssertTrue(note.isRelevant(for: 1, userId: "player1"))
        XCTAssertFalse(note.isRelevant(for: 2, userId: "player1"))
        XCTAssertFalse(note.isRelevant(for: nil, userId: "player1"))
    }

    func testPlayerTargetIsRelevantToCorrectPlayer() {
        let note = Note(
            id: "note3",
            attachmentType: .set,
            attachmentId: "set1",
            targetType: .player,
            targetId: "player123",
            text: "Personal note",
            createdBy: "coach1"
        )

        XCTAssertTrue(note.isRelevant(for: 1, userId: "player123"))
        XCTAssertTrue(note.isRelevant(for: nil, userId: "player123"))
        XCTAssertFalse(note.isRelevant(for: 1, userId: "player456"))
    }

    func testNoteComposition() {
        let allNote = Note(
            id: "note1",
            attachmentType: .set,
            attachmentId: "set1",
            targetType: .all,
            text: "Team note",
            createdBy: "coach1"
        )

        let positionNote = Note(
            id: "note2",
            attachmentType: .set,
            attachmentId: "set1",
            targetType: .position,
            targetId: "1",
            text: "PG note",
            createdBy: "coach1"
        )

        let playerNote = Note(
            id: "note3",
            attachmentType: .set,
            attachmentId: "set1",
            targetType: .player,
            targetId: "player1",
            text: "Personal note",
            createdBy: "coach1"
        )

        let allNotes = [allNote, positionNote, playerNote]

        // Player 1 playing position 1 should see all three
        let relevantToPlayer1Pos1 = allNotes.filter { $0.isRelevant(for: 1, userId: "player1") }
        XCTAssertEqual(relevantToPlayer1Pos1.count, 3)

        // Player 1 playing position 2 should see two (team + personal)
        let relevantToPlayer1Pos2 = allNotes.filter { $0.isRelevant(for: 2, userId: "player1") }
        XCTAssertEqual(relevantToPlayer1Pos2.count, 2)

        // Player 2 playing position 1 should see two (team + position)
        let relevantToPlayer2Pos1 = allNotes.filter { $0.isRelevant(for: 1, userId: "player2") }
        XCTAssertEqual(relevantToPlayer2Pos1.count, 2)

        // Player 2 playing position 2 should see one (team only)
        let relevantToPlayer2Pos2 = allNotes.filter { $0.isRelevant(for: 2, userId: "player2") }
        XCTAssertEqual(relevantToPlayer2Pos2.count, 1)
    }

    func testFilmRefTargetingSameLogic() {
        let filmRef = FilmRef(
            id: "film1",
            attachmentType: .set,
            attachmentId: "set1",
            targetType: .position,
            targetId: "3",
            url: "https://youtube.com/watch?v=123",
            createdBy: "coach1"
        )

        XCTAssertTrue(filmRef.isRelevant(for: 3, userId: "player1"))
        XCTAssertFalse(filmRef.isRelevant(for: 1, userId: "player1"))
    }
}
