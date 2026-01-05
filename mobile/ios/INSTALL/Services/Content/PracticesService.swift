import Foundation
import FirebaseFirestore

/// Service for managing practice sessions
class PracticesService {

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    // MARK: - CRUD

    /// Get all practices for a team
    func getPractices(teamId: String) async throws -> [PracticeSession] {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.practices)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return try snapshot.documents.map { doc in
            var practice = try doc.data(as: PracticeSession.self)
            practice.id = doc.documentID
            return practice
        }
    }

    /// Get upcoming practices
    func getUpcomingPractices(teamId: String) async throws -> [PracticeSession] {
        let now = Timestamp()

        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.practices)
            .whereField("startAt", isGreaterThan: now)
            .order(by: "startAt", descending: false)
            .getDocuments()

        return try snapshot.documents.map { doc in
            var practice = try doc.data(as: PracticeSession.self)
            practice.id = doc.documentID
            return practice
        }
    }

    /// Get a single practice
    func getPractice(teamId: String, practiceId: String) async throws -> PracticeSession {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.practices)
            .document(practiceId)
            .getDocument()

        var practice = try snapshot.data(as: PracticeSession.self)
        practice.id = snapshot.documentID
        return practice
    }

    /// Create a practice
    func createPractice(teamId: String, practice: PracticeSession) async throws -> String {
        let practiceRef = firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.practices)
            .document()

        try practiceRef.setData(from: practice)
        return practiceRef.documentID
    }

    /// Update a practice
    func updatePractice(teamId: String, practice: PracticeSession) async throws {
        var updatedPractice = practice
        updatedPractice.updatedAt = Timestamp()

        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.practices)
            .document(practice.id)
            .setData(from: updatedPractice, merge: true)
    }

    /// Delete a practice
    func deletePractice(teamId: String, practiceId: String) async throws {
        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.practices)
            .document(practiceId)
            .delete()
    }

    /// Publish a practice (set publishedAt timestamp)
    func publishPractice(teamId: String, practiceId: String) async throws {
        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.practices)
            .document(practiceId)
            .updateData([
                "publishedAt": Timestamp(),
                "updatedAt": Timestamp()
            ])
    }

    /// Listen to practices (real-time)
    func listenToPractices(teamId: String, completion: @escaping (Result<[PracticeSession], Error>) -> Void) -> ListenerRegistration {
        return firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.practices)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(NSError(domain: "PracticesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                    return
                }

                do {
                    let practices = try snapshot.documents.map { doc -> PracticeSession in
                        var practice = try doc.data(as: PracticeSession.self)
                        practice.id = doc.documentID
                        return practice
                    }
                    completion(.success(practices))
                } catch {
                    completion(.failure(error))
                }
            }
    }
}
