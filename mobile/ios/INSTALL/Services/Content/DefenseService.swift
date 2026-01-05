import Foundation
import FirebaseFirestore

/// Service for managing defense scenarios
class DefenseService {

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    // MARK: - CRUD

    /// Get all defense scenarios for a team
    func getDefenseScenarios(teamId: String) async throws -> [DefenseScenario] {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.defense)
            .whereField("isTemplate", isEqualTo: false)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return try snapshot.documents.map { doc in
            var scenario = try doc.data(as: DefenseScenario.self)
            scenario.id = doc.documentID
            return scenario
        }
    }

    /// Get a single defense scenario
    func getDefenseScenario(teamId: String, scenarioId: String) async throws -> DefenseScenario {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.defense)
            .document(scenarioId)
            .getDocument()

        var scenario = try snapshot.data(as: DefenseScenario.self)
        scenario.id = snapshot.documentID
        return scenario
    }

    /// Create a new defense scenario
    func createDefenseScenario(teamId: String, scenario: DefenseScenario) async throws -> String {
        let scenarioRef = firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.defense)
            .document()

        try scenarioRef.setData(from: scenario)
        return scenarioRef.documentID
    }

    /// Update a defense scenario
    func updateDefenseScenario(teamId: String, scenario: DefenseScenario) async throws {
        var updatedScenario = scenario
        updatedScenario.updatedAt = Timestamp()
        updatedScenario.draftUpdatedAt = Timestamp()

        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.defense)
            .document(scenario.id)
            .setData(from: updatedScenario, merge: true)
    }

    /// Delete a defense scenario
    func deleteDefenseScenario(teamId: String, scenarioId: String) async throws {
        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.defense)
            .document(scenarioId)
            .delete()
    }

    /// Listen to defense scenarios (real-time)
    func listenToDefenseScenarios(teamId: String, completion: @escaping (Result<[DefenseScenario], Error>) -> Void) -> ListenerRegistration {
        return firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.defense)
            .whereField("isTemplate", isEqualTo: false)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot else {
                    completion(.failure(NSError(domain: "DefenseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                    return
                }

                do {
                    let scenarios = try snapshot.documents.map { doc -> DefenseScenario in
                        var scenario = try doc.data(as: DefenseScenario.self)
                        scenario.id = doc.documentID
                        return scenario
                    }
                    completion(.success(scenarios))
                } catch {
                    completion(.failure(error))
                }
            }
    }

    // MARK: - Templates

    /// Duplicate a template to team playbook
    func duplicateTemplate(teamId: String, template: DefenseScenario, newName: String?) async throws -> String {
        var newScenario = template
        newScenario.id = UUID().uuidString
        newScenario.name = newName ?? "\(template.name) (Copy)"
        newScenario.isTemplate = false
        newScenario.sourceTemplateId = template.id
        newScenario.updatedAt = Timestamp()
        newScenario.draftUpdatedAt = nil
        newScenario.publishedVersion = nil

        return try await createDefenseScenario(teamId: teamId, scenario: newScenario)
    }
}
