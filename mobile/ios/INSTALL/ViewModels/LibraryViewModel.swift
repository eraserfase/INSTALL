import Foundation
import SwiftUI
import FirebaseFirestore

/// ViewModel for sets/defense library (both templates and team content)
@MainActor
class LibraryViewModel: ObservableObject {

    // Published state
    @Published var teamSets: [SetModel] = []
    @Published var teamDefense: [DefenseScenario] = []
    @Published var offenseTemplates: [SetModel] = []
    @Published var defenseTemplates: [DefenseScenario] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let setsService: SetsService
    private let defenseService: DefenseService
    private let templatesLoader = TemplatesLoader.shared

    private var setsListener: ListenerRegistration?
    private var defenseListener: ListenerRegistration?

    init(setsService: SetsService, defenseService: DefenseService) {
        self.setsService = setsService
        self.defenseService = defenseService

        // Load templates immediately
        loadTemplates()
    }

    deinit {
        setsListener?.remove()
        defenseListener?.remove()
    }

    // MARK: - Load Content

    func loadTeamContent(teamId: String) {
        isLoading = true

        // Listen to sets
        setsListener?.remove()
        setsListener = setsService.listenToSets(teamId: teamId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let sets):
                    self?.teamSets = sets
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }
        }

        // Listen to defense
        defenseListener?.remove()
        defenseListener = defenseService.listenToDefenseScenarios(teamId: teamId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let scenarios):
                    self?.teamDefense = scenarios
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func loadTemplates() {
        offenseTemplates = templatesLoader.loadOffenseTemplates()
        defenseTemplates = templatesLoader.loadDefenseTemplates()
    }

    // MARK: - Duplicate Template

    func duplicateOffenseTemplate(teamId: String, template: SetModel, newName: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await setsService.duplicateTemplate(teamId: teamId, template: template, newName: newName)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func duplicateDefenseTemplate(teamId: String, template: DefenseScenario, newName: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await defenseService.duplicateTemplate(teamId: teamId, template: template, newName: newName)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete

    func deleteSet(teamId: String, setId: String) async {
        do {
            try await setsService.deleteSet(teamId: teamId, setId: setId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteDefense(teamId: String, scenarioId: String) async {
        do {
            try await defenseService.deleteDefenseScenario(teamId: teamId, scenarioId: scenarioId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
