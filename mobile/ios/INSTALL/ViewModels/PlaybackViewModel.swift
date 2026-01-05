import Foundation
import SwiftUI

/// ViewModel for playback of sets/defense
@MainActor
class PlaybackViewModel: ObservableObject {

    // Set or Defense being played
    @Published var setModel: SetModel?
    @Published var defenseScenario: DefenseScenario?

    // Playback state
    @Published var currentStepIndex: Int = 0
    @Published var focusPosition: Int? = nil // 1-5, nil = no focus

    // Notes and film
    @Published var notes: [Note] = []
    @Published var filmRefs: [FilmRef] = []

    var steps: [Step] {
        if let set = setModel {
            return set.enabledSteps
        } else if let defense = defenseScenario {
            return defense.enabledSteps
        }
        return []
    }

    var currentStep: Step? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var canGoPrevious: Bool {
        return currentStepIndex > 0
    }

    var canGoNext: Bool {
        return currentStepIndex < steps.count - 1
    }

    var title: String {
        return setModel?.name ?? defenseScenario?.name ?? "Playback"
    }

    // MARK: - Navigation

    func goToPreviousStep() {
        guard canGoPrevious else { return }
        currentStepIndex -= 1
    }

    func goToNextStep() {
        guard canGoNext else { return }
        currentStepIndex += 1
    }

    func goToStep(index: Int) {
        guard index >= 0 && index < steps.count else { return }
        currentStepIndex = index
    }

    // MARK: - Focus

    func setFocus(position: Int?) {
        focusPosition = position
    }

    func toggleFocus(position: Int) {
        if focusPosition == position {
            focusPosition = nil
        } else {
            focusPosition = position
        }
    }

    // MARK: - Load Content

    func loadSet(_ set: SetModel) {
        self.setModel = set
        self.defenseScenario = nil
        self.currentStepIndex = 0
        self.focusPosition = nil
    }

    func loadDefense(_ defense: DefenseScenario) {
        self.defenseScenario = defense
        self.setModel = nil
        self.currentStepIndex = 0
        self.focusPosition = nil
    }

    func loadNotes(_ notes: [Note]) {
        self.notes = notes
    }

    func loadFilmRefs(_ filmRefs: [FilmRef]) {
        self.filmRefs = filmRefs
    }

    // MARK: - Relevant Notes/Film for Current Player

    func getRelevantNotes(for position: Int?, userId: String?) -> [Note] {
        return notes.filter { $0.isRelevant(for: position, userId: userId) }
    }

    func getRelevantFilmRefs(for position: Int?, userId: String?) -> [FilmRef] {
        return filmRefs.filter { $0.isRelevant(for: position, userId: userId) }
    }
}
