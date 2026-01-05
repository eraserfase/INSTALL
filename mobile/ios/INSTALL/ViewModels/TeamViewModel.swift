import Foundation
import SwiftUI
import FirebaseFirestore

/// ViewModel for team management
@MainActor
class TeamViewModel: ObservableObject {

    @Published var currentTeam: Team?
    @Published var currentMembership: Membership?
    @Published var roster: [Membership] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let teamService: TeamService
    private var teamListener: ListenerRegistration?

    init(teamService: TeamService) {
        self.teamService = teamService
    }

    deinit {
        teamListener?.remove()
    }

    var isCoach: Bool {
        return currentMembership?.role == .coach
    }

    var isPlayer: Bool {
        return currentMembership?.role == .player
    }

    var currentTeamId: String? {
        return UserDefaults.standard.string(forKey: FirebaseConfig.UserDefaultsKeys.currentTeamId)
    }

    // MARK: - Create Team

    func createTeam(name: String, userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let team = try await teamService.createTeam(name: name, createdBy: userId)
            currentTeam = team

            // Save team ID
            UserDefaults.standard.set(team.id, forKey: FirebaseConfig.UserDefaultsKeys.currentTeamId)

            // Load membership
            await loadMembership(teamId: team.id, userId: userId)

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Join Team

    func joinTeam(joinCode: String, userId: String, displayName: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            // Find team by code
            guard let team = try await teamService.findTeam(byJoinCode: joinCode) else {
                errorMessage = "Team not found with code: \(joinCode)"
                isLoading = false
                return
            }

            // Join team
            try await teamService.joinTeam(teamId: team.id, userId: userId, displayName: displayName)
            currentTeam = team

            // Load membership
            await loadMembership(teamId: team.id, userId: userId)

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load Team

    func loadTeam(teamId: String, userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let team = try await teamService.getTeam(teamId: teamId)
            currentTeam = team

            await loadMembership(teamId: teamId, userId: userId)
            await loadRoster(teamId: teamId)

            // Listen to team updates
            listenToTeam(teamId: teamId)

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Publish Playbook

    func publishPlaybook() async {
        guard let teamId = currentTeam?.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await teamService.publishPlaybook(teamId: teamId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private Helpers

    private func loadMembership(teamId: String, userId: String) async {
        do {
            currentMembership = try await teamService.getMembership(teamId: teamId, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadRoster(teamId: String) async {
        do {
            roster = try await teamService.getRoster(teamId: teamId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenToTeam(teamId: String) {
        teamListener?.remove()
        teamListener = teamService.listenToTeam(teamId: teamId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let team):
                    self?.currentTeam = team
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
