import Foundation
import FirebaseFirestore
import AVFoundation

/// Service for managing notes (text + audio)
class NotesService {

    private let firestoreService: FirestoreService
    private let storageService: StorageService

    init(firestoreService: FirestoreService, storageService: StorageService) {
        self.firestoreService = firestoreService
        self.storageService = storageService
    }

    // MARK: - CRUD

    /// Get notes for a specific attachment
    func getNotes(
        teamId: String,
        attachmentType: NoteAttachmentType,
        attachmentId: String,
        stepIndex: Int? = nil
    ) async throws -> [Note] {
        var query = firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.notes)
            .whereField("attachmentType", isEqualTo: attachmentType.rawValue)
            .whereField("attachmentId", isEqualTo: attachmentId)

        if let stepIndex = stepIndex {
            query = query.whereField("stepIndex", isEqualTo: stepIndex)
        }

        let snapshot = try await query
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return try snapshot.documents.map { doc in
            var note = try doc.data(as: Note.self)
            note.id = doc.documentID
            return note
        }
    }

    /// Get relevant notes for a player
    func getRelevantNotes(
        teamId: String,
        attachmentType: NoteAttachmentType,
        attachmentId: String,
        position: Int?,
        userId: String
    ) async throws -> [Note] {
        let allNotes = try await getNotes(
            teamId: teamId,
            attachmentType: attachmentType,
            attachmentId: attachmentId
        )

        return allNotes.filter { note in
            note.isRelevant(for: position, userId: userId)
        }
    }

    /// Create a note
    func createNote(teamId: String, note: Note, audioURL: URL? = nil) async throws -> String {
        var newNote = note

        // Upload audio if provided
        if let audioURL = audioURL {
            let noteId = UUID().uuidString
            let storagePath = FirebaseConfig.Storage.notesAudioPath(teamId: teamId, noteId: noteId)

            _ = try await storageService.uploadAudio(from: audioURL, to: storagePath)

            // Get audio duration
            let asset = AVURLAsset(url: audioURL)
            let duration = try await asset.load(.duration)
            let durationMs = Int(CMTimeGetSeconds(duration) * 1000)

            newNote.audio = AudioMetadata(storagePath: storagePath, durationMs: durationMs)
            newNote.id = noteId
        }

        let noteRef = firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.notes)
            .document(newNote.id.isEmpty ? UUID().uuidString : newNote.id)

        try noteRef.setData(from: newNote)
        return noteRef.documentID
    }

    /// Update a note
    func updateNote(teamId: String, note: Note) async throws {
        var updatedNote = note
        updatedNote.updatedAt = Timestamp()

        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.notes)
            .document(note.id)
            .setData(from: updatedNote, merge: true)
    }

    /// Delete a note
    func deleteNote(teamId: String, noteId: String) async throws {
        // Get note to check for audio
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.notes)
            .document(noteId)
            .getDocument()

        if let note = try? snapshot.data(as: Note.self),
           let audioPath = note.audio?.storagePath {
            // Delete audio from storage
            try await storageService.deleteAudio(at: audioPath)
        }

        // Delete note document
        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.notes)
            .document(noteId)
            .delete()
    }

    // MARK: - Audio Playback

    /// Get audio download URL for playback
    func getAudioURL(for note: Note) async throws -> URL? {
        guard let audioPath = note.audio?.storagePath else { return nil }
        return try await storageService.getDownloadURL(for: audioPath)
    }
}
