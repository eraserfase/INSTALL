import SwiftUI

/// Edit individual step (label, note, player actions)
struct EditStepView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EditSetViewModel
    let stepIndex: Int
    @State var step: Step

    @State private var label: String
    @State private var note: String

    init(viewModel: EditSetViewModel, stepIndex: Int, step: Step) {
        self.viewModel = viewModel
        self.stepIndex = stepIndex
        self.step = step
        _label = State(initialValue: step.label)
        _note = State(initialValue: step.note ?? "")
    }

    var body: some View {
        NavigationView {
            List {
                // Step metadata
                Section("Step Information") {
                    TextField("Step Label", text: $label)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coach Note")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $note)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }

                // Player actions
                Section("Player Actions") {
                    ForEach(step.playerActions) { action in
                        NavigationLink(destination: EditPlayerActionView(
                            viewModel: viewModel,
                            stepIndex: stepIndex,
                            action: action
                        )) {
                            PlayerActionRow(action: action)
                        }
                    }
                }

                // Preview
                Section("Preview") {
                    GeometryReader { geometry in
                        let canvasSize = CourtGeometry.idealCanvasSize(for: geometry.size.width)
                        CourtCanvasView(
                            step: step,
                            focusPosition: nil,
                            canvasSize: canvasSize
                        )
                        .frame(width: canvasSize.width, height: canvasSize.height)
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Edit Step \(stepIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateStepLabel(stepIndex: stepIndex, label: label)
                        viewModel.updateStepNote(stepIndex: stepIndex, note: note.isEmpty ? nil : note)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Player Action Row

struct PlayerActionRow: View {
    let action: PlayerAction

    var body: some View {
        HStack(spacing: 12) {
            // Position badge
            Text("\(action.position)")
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(action.hasBall ? Color.orange : Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())

            // Action details
            VStack(alignment: .leading, spacing: 4) {
                Text(action.actionType.displayName)
                    .font(.headline)

                HStack(spacing: 4) {
                    Text(action.fromSpot.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let toSpotId = action.toSpotId,
                       let toSpot = Spots.spot(for: toSpotId) {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(toSpot.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
