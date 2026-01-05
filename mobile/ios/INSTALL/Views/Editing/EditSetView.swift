import SwiftUI

/// Main editing view for sets/defense
struct EditSetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EditSetViewModel
    @State private var showSaveConfirmation: Bool = false
    @State private var showDiscardAlert: Bool = false
    @State private var selectedStepIndex: Int?

    var body: some View {
        NavigationView {
            List {
                // Name section
                Section("Name") {
                    TextField("Set Name", text: $viewModel.name)
                        .onChange(of: viewModel.name) { _ in
                            viewModel.hasUnsavedChanges = true
                        }
                }

                // Steps section
                Section {
                    ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                        StepRowView(
                            step: step,
                            stepNumber: index + 1,
                            onTap: {
                                selectedStepIndex = index
                            },
                            onToggleEnabled: {
                                viewModel.toggleStepEnabled(stepIndex: index)
                            }
                        )
                    }
                    .onMove { source, destination in
                        viewModel.reorderSteps(from: source, to: destination)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { viewModel.deleteStep(at: $0) }
                    }
                } header: {
                    HStack {
                        Text("Steps (\(viewModel.steps.count))")
                        Spacer()
                        EditButton()
                    }
                }

                // Save section
                if viewModel.hasUnsavedChanges {
                    Section {
                        Button(action: {
                            showSaveConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Changes")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditingSet ? "Edit Set" : "Edit Defense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.hasUnsavedChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Save Changes?", isPresented: $showSaveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    Task {
                        await viewModel.save()
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("This will update the draft. Players won't see changes until you publish.")
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .sheet(item: $selectedStepIndex.map { Binding(get: { $0 }, set: { selectedStepIndex = $0 }) }) { index in
                if let step = viewModel.getPreviewStep(index: index) {
                    EditStepView(
                        viewModel: viewModel,
                        stepIndex: index,
                        step: step
                    )
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

// MARK: - Step Row

struct StepRowView: View {
    let step: Step
    let stepNumber: Int
    let onTap: () -> Void
    let onToggleEnabled: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Step number badge
                Text("\(stepNumber)")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(step.enabled ? Color.orange : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(Circle())

                // Step info
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.label)
                        .font(.headline)
                        .foregroundColor(step.enabled ? .primary : .secondary)

                    if let note = step.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Enabled toggle
                Image(systemName: step.enabled ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(step.enabled ? .green : .gray)
                    .onTapGesture {
                        onToggleEnabled()
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Helper for binding Int? to Identifiable
extension Int: Identifiable {
    public var id: Int { self }
}
