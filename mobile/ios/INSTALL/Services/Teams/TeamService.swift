import Foundation
import FirebaseFirestore

/// Service for team management
class TeamService {

    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    // MARK: - Team CRUD

    /// Create a new team
    func createTeam(name: String, createdBy: String) async throws -> Team {
        let teamId = UUID().uuidString
        let joinCode = generateJoinCode()

        let team = Team(
            id: teamId,
            name: name,
            createdBy: createdBy,
            joinCode: joinCode,
            playbookVersion: 0
        )

        // Create team document
        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .setData(from: team)

        // Create creator's membership as coach
        let membership = Membership(
            id: createdBy,
            role: .coach,
            status: .active
        )

        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.members)
            .document(createdBy)
            .setData(from: membership)

        return team
    }

    /// Find team by join code
    func findTeam(byJoinCode joinCode: String) async throws -> Team? {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .whereField("joinCode", isEqualTo: joinCode.uppercased())
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            return nil
        }

        var team = try document.data(as: Team.self)
        team.id = document.documentID
        return team
    }

    /// Join a team
    func joinTeam(teamId: String, userId: String, displayName: String?) async throws {
        let membership = Membership(
            id: userId,
            role: .player,
            displayNameOverride: displayName,
            status: .active
        )

        try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.members)
            .document(userId)
            .setData(from: membership)

        // Save current team ID locally
        UserDefaults.standard.set(teamId, forKey: FirebaseConfig.UserDefaultsKeys.currentTeamId)
    }

    /// Get user's membership in a team
    func getMembership(teamId: String, userId: String) async throws -> Membership? {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.members)
            .document(userId)
            .getDocument()

        guard snapshot.exists else { return nil }

        var membership = try snapshot.data(as: Membership.self)
        membership.id = snapshot.documentID
        return membership
    }

    /// Get team
    func getTeam(teamId: String) async throws -> Team {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .getDocument()

        var team = try snapshot.data(as: Team.self)
        team.id = snapshot.documentID
        return team
    }

    /// Listen to team updates
    func listenToTeam(teamId: String, completion: @escaping (Result<Team, Error>) -> Void) -> ListenerRegistration {
        return firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let snapshot = snapshot, snapshot.exists else {
                    completion(.failure(NSError(domain: "TeamService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Team not found"])))
                    return
                }

                do {
                    var team = try snapshot.data(as: Team.self)
                    team.id = snapshot.documentID
                    completion(.success(team))
                } catch {
                    completion(.failure(error))
                }
            }
    }

    /// Get roster (all members)
    func getRoster(teamId: String) async throws -> [Membership] {
        let snapshot = try await firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)
            .collection(FirebaseConfig.Collections.members)
            .whereField("status", isEqualTo: "active")
            .order(by: "role", descending: false)
            .getDocuments()

        return try snapshot.documents.map { doc in
            var membership = try doc.data(as: Membership.self)
            membership.id = doc.documentID
            return membership
        }
    }

    // MARK: - Publishing

    /// Publish playbook (increment version)
    func publishPlaybook(teamId: String) async throws {
        let teamRef = firestoreService.db
            .collection(FirebaseConfig.Collections.teams)
            .document(teamId)

        try await firestoreService.db.runTransaction({ (transaction, errorPointer) -> Any? in
            let teamSnapshot: DocumentSnapshot
            do {
                try teamSnapshot = transaction.getDocument(teamRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let currentVersion = teamSnapshot.data()?["playbookVersion"] as? Int else {
                let error = NSError(domain: "TeamService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to read playbook version"])
                errorPointer?.pointee = error
                return nil
            }

            let newVersion = currentVersion + 1
            transaction.updateData([
                "playbookVersion": newVersion,
                "playbookPublishedAt": Timestamp()
            ], forDocument: teamRef)

            return nil
        })
    }

    // MARK: - Private Helpers

    private func generateJoinCode(length: Int = 6) -> String {
        // Use unambiguous characters (no O/0, I/1, etc.)
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
