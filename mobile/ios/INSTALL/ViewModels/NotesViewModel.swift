import Foundation
import SwiftUI
import AVFoundation

/// ViewModel for notes management
@MainActor
class NotesViewModel: ObservableObject {

    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let notesService: NotesService
    private let teamId: String

    init(notesService: NotesService, teamId: String) {
        self.notesService = notesService
        self.teamId = teamId
    }

    // MARK: - Load Notes

    func loadNotes(
        attachmentType: NoteAttachmentType,
        attachmentId: String,
        position: Int? = nil,
        userId: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            if let position = position, let userId = userId {
                // Get relevant notes for this player/position
                notes = try await notesService.getRelevantNotes(
                    teamId: teamId,
                    attachmentType: attachmentType,
                    attachmentId: attachmentId,
                    position: position,
                    userId: userId
                )
            } else {
                // Get all notes (coach view)
                notes = try await notesService.getNotes(
                    teamId: teamId,
                    attachmentType: attachmentType,
                    attachmentId: attachmentId
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create Note

    func createNote(
        attachmentType: NoteAttachmentType,
        attachmentId: String,
        stepIndex: Int? = nil,
        targetType: NoteTargetType,
        targetId: String? = nil,
        text: String?,
        audioURL: URL? = nil,
        createdBy: String
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let note = Note(
                id: UUID().uuidString,
                attachmentType: attachmentType,
                attachmentId: attachmentId,
                stepIndex: stepIndex,
                targetType: targetType,
                targetId: targetId,
                text: text,
                createdBy: createdBy
            )

            _ = try await notesService.createNote(teamId: teamId, note: note, audioURL: audioURL)

            // Reload notes
            await loadNotes(attachmentType: attachmentType, attachmentId: attachmentId)

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Note

    func deleteNote(noteId: String, attachmentType: NoteAttachmentType, attachmentId: String) async {
        do {
            try await notesService.deleteNote(teamId: teamId, noteId: noteId)

            // Reload notes
            await loadNotes(attachmentType: attachmentType, attachmentId: attachmentId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Audio Playback

    func getAudioURL(for note: Note) async -> URL? {
        do {
            return try await notesService.getAudioURL(for: note)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
