import Foundation
import SwiftUI
import FirebaseFirestore

/// ViewModel for editing sets/defense
@MainActor
class EditSetViewModel: ObservableObject {

    // Content being edited
    @Published var setModel: SetModel?
    @Published var defenseScenario: DefenseScenario?

    // Edit state
    @Published var name: String = ""
    @Published var category: String = ""
    @Published var steps: [Step] = []
    @Published var hasUnsavedChanges: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let setsService: SetsService
    private let defenseService: DefenseService
    private let teamId: String

    var isEditingSet: Bool { setModel != nil }
    var isEditingDefense: Bool { defenseScenario != nil }

    init(setsService: SetsService, defenseService: DefenseService, teamId: String) {
        self.setsService = setsService
        self.defenseService = defenseService
        self.teamId = teamId
    }

    // MARK: - Load Content

    func loadSet(_ set: SetModel) {
        self.setModel = set
        self.defenseScenario = nil
        self.name = set.name
        self.category = set.category.rawValue
        self.steps = set.steps
        self.hasUnsavedChanges = false
    }

    func loadDefense(_ defense: DefenseScenario) {
        self.defenseScenario = defense
        self.setModel = nil
        self.name = defense.name
        self.category = defense.category.rawValue
        self.steps = defense.steps
        self.hasUnsavedChanges = false
    }

    // MARK: - Edit Operations

    func updateName(_ newName: String) {
        name = newName
        hasUnsavedChanges = true
    }

    func updateStepLabel(stepIndex: Int, label: String) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].label = label
        hasUnsavedChanges = true
    }

    func updateStepNote(stepIndex: Int, note: String?) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].note = note
        hasUnsavedChanges = true
    }

    func toggleStepEnabled(stepIndex: Int) {
        guard stepIndex < steps.count else { return }
        steps[stepIndex].enabled.toggle()
        hasUnsavedChanges = true
    }

    func updatePlayerAction(stepIndex: Int, position: Int, action: PlayerAction) {
        guard stepIndex < steps.count else { return }

        if let actionIndex = steps[stepIndex].playerActions.firstIndex(where: { $0.position == position }) {
            steps[stepIndex].playerActions[actionIndex] = action
            hasUnsavedChanges = true
        }
    }

    func reorderSteps(from source: IndexSet, to destination: Int) {
        steps.move(fromOffsets: source, toOffset: destination)

        // Update step indices
        for (index, _) in steps.enumerated() {
            steps[index].index = index
        }

        hasUnsavedChanges = true
    }

    func deleteStep(at index: Int) {
        guard index < steps.count else { return }
        steps.remove(at: index)

        // Update step indices
        for (idx, _) in steps.enumerated() {
            steps[idx].index = idx
        }

        hasUnsavedChanges = true
    }

    // MARK: - Save

    func save() async {
        isLoading = true
        errorMessage = nil

        do {
            if var set = setModel {
                set.name = name
                if let cat = SetCategory(rawValue: category) {
                    set.category = cat
                }
                set.steps = steps

                try await setsService.updateSet(teamId: teamId, set: set)
            } else if var defense = defenseScenario {
                defense.name = name
                if let cat = DefenseCategory(rawValue: category) {
                    defense.category = cat
                }
                defense.steps = steps

                try await defenseService.updateDefenseScenario(teamId: teamId, scenario: defense)
            }

            hasUnsavedChanges = false
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Preview

    func getPreviewStep(index: Int) -> Step? {
        guard index < steps.count else { return nil }
        return steps[index]
    }
}
