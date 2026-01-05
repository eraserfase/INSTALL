import SwiftUI

/// Edit individual player action (spot, action type, etc.)
struct EditPlayerActionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EditSetViewModel
    let stepIndex: Int

    @State var action: PlayerAction
    @State private var selectedActionType: ActionType
    @State private var selectedFromSpotId: String
    @State private var selectedToSpotId: String?
    @State private var selectedTargetPosition: Int?
    @State private var hasBall: Bool

    init(viewModel: EditSetViewModel, stepIndex: Int, action: PlayerAction) {
        self.viewModel = viewModel
        self.stepIndex = stepIndex
        self.action = action

        _selectedActionType = State(initialValue: action.actionType)
        _selectedFromSpotId = State(initialValue: action.fromSpotId)
        _selectedToSpotId = State(initialValue: action.toSpotId)
        _selectedTargetPosition = State(initialValue: action.targetPosition)
        _hasBall = State(initialValue: action.hasBall)
    }

    var body: some View {
        Form {
            // Action type
            Section("Action Type") {
                Picker("Action", selection: $selectedActionType) {
                    ForEach(ActionType.allCases) { actionType in
                        Text(actionType.displayName)
                            .tag(actionType)
                    }
                }
            }

            // From spot
            Section("Starting Position") {
                Picker("From Spot", selection: $selectedFromSpotId) {
                    ForEach(Spots.all) { spot in
                        Text(spot.displayName)
                            .tag(spot.id)
                    }
                }
            }

            // To spot (if action involves movement)
            if selectedActionType.involvesMovement {
                Section("Ending Position") {
                    Picker("To Spot", selection: Binding(
                        get: { selectedToSpotId ?? selectedFromSpotId },
                        set: { selectedToSpotId = $0 }
                    )) {
                        ForEach(Spots.all) { spot in
                            Text(spot.displayName)
                                .tag(spot.id)
                        }
                    }
                }
            }

            // Target position (if action requires target)
            if selectedActionType.requiresTarget {
                Section("Target Player") {
                    Picker("Target", selection: Binding(
                        get: { selectedTargetPosition ?? 1 },
                        set: { selectedTargetPosition = $0 }
                    )) {
                        ForEach(1...5, id: \.self) { position in
                            Text("Position \(position)")
                                .tag(position)
                        }
                    }
                }
            }

            // Has ball
            Section {
                Toggle("Has Ball", isOn: $hasBall)
            }

            // Save button
            Section {
                Button(action: {
                    let updatedAction = PlayerAction(
                        position: action.position,
                        actionType: selectedActionType,
                        fromSpotId: selectedFromSpotId,
                        toSpotId: selectedActionType.involvesMovement ? selectedToSpotId : nil,
                        targetPosition: selectedActionType.requiresTarget ? selectedTargetPosition : nil,
                        hasBall: hasBall
                    )

                    viewModel.updatePlayerAction(
                        stepIndex: stepIndex,
                        position: action.position,
                        action: updatedAction
                    )

                    dismiss()
                }) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("Edit Position \(action.position)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
