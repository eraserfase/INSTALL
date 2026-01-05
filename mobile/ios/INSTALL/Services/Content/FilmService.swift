import Foundation
import FirebaseFirestore

/// Service for managing film references
class FilmService {

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    // MARK: - CRUD

    /// Get film references for a specific attachment
    func getFilmReferences(
        teamId: String,
        attachmentType: FilmAttachmentType,
        attachmentId: String
    ) async throws -> [FilmRef] {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.film)
            .whereField("attachmentType", isEqualTo: attachmentType.rawValue)
            .whereField("attachmentId", isEqualTo: attachmentId)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return try snapshot.documents.map { doc in
            var filmRef = try doc.data(as: FilmRef.self)
            filmRef.id = doc.documentID
            return filmRef
        }
    }

    /// Get relevant film references for a player
    func getRelevantFilmReferences(
        teamId: String,
        attachmentType: FilmAttachmentType,
        attachmentId: String,
        position: Int?,
        userId: String
    ) async throws -> [FilmRef] {
        let allFilmRefs = try await getFilmReferences(
            teamId: teamId,
            attachmentType: attachmentType,
            attachmentId: attachmentId
        )

        return allFilmRefs.filter { filmRef in
            filmRef.isRelevant(for: position, userId: userId)
        }
    }

    /// Create a film reference
    func createFilmReference(teamId: String, filmRef: FilmRef) async throws -> String {
        let filmRefDoc = firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.film)
            .document()

        try filmRefDoc.setData(from: filmRef)
        return filmRefDoc.documentID
    }

    /// Update a film reference
    func updateFilmReference(teamId: String, filmRef: FilmRef) async throws {
        var updatedFilmRef = filmRef
        updatedFilmRef.updatedAt = Timestamp()

        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.film)
            .document(filmRef.id)
            .setData(from: updatedFilmRef, merge: true)
    }

    /// Delete a film reference
    func deleteFilmReference(teamId: String, filmRefId: String) async throws {
        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.film)
            .document(filmRefId)
            .delete()
    }
}
