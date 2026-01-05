import Foundation
import FirebaseFirestore

/// Service for managing sets (offense)
class SetsService {

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    // MARK: - CRUD

    /// Get all sets for a team
    func getSets(teamId: String) async throws -> [SetModel] {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.sets)
            .whereField("isTemplate", isEqualTo: false)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return try snapshot.documents.map { doc in
            var set = try doc.data(as: SetModel.self)
            set.id = doc.documentID
            return set
        }
    }

    /// Get a single set
    func getSet(teamId: String, setId: String) async throws -> SetModel {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.sets)
            .document(setId)
            .getDocument()

        var set = try snapshot.data(as: SetModel.self)
        set.id = snapshot.documentID
        return set
    }

    /// Create a new set
    func createSet(teamId: String, set: SetModel) async throws -> String {
        let setRef = firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.sets)
            .document()

        try setRef.setData(from: set)
        return setRef.documentID
    }

    /// Update a set
    func updateSet(teamId: String, set: SetModel) async throws {
        var updatedSet = set
        updatedSet.updatedAt = Timestamp()
        updatedSet.draftUpdatedAt = Timestamp()

        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.sets)
            .document(set.id)
            .setData(from: updatedSet, merge: true)
    }

    /// Delete a set
    func deleteSet(teamId: String, setId: String) async throws {
        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.sets)
            .document(setId)
            .delete()
    }

    /// Listen to sets (real-time)
    func listenToSets(teamId: String, completion: @escaping (Result<[SetModel], Error>) -> Void) -> ListenerRegistration {
        return firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.sets)
            .whereField("isTemplate", isEqualTo: false)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(NSError(domain: "SetsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                    return
                }

                do {
                    let sets = try snapshot.documents.map { doc -> SetModel in
                        var set = try doc.data(as: SetModel.self)
                        set.id = doc.documentID
                        return set
                    }
                    completion(.success(sets))
                } catch {
                    completion(.failure(error))
                }
            }
    }

    // MARK: - Templates

    /// Duplicate a template to team playbook
    func duplicateTemplate(teamId: String, template: SetModel, newName: String?) async throws -> String {
        var newSet = template
        newSet.id = UUID().uuidString
        newSet.name = newName ?? "\(template.name) (Copy)"
        newSet.isTemplate = false
        newSet.sourceTemplateId = template.id
        newSet.updatedAt = Timestamp()
        newSet.draftUpdatedAt = nil
        newSet.publishedVersion = nil

        return try await createSet(teamId: teamId, set: newSet)
    }
}
