import SwiftUI

/// Template picker for duplicating offense/defense templates
struct TemplatePickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var libraryViewModel: LibraryViewModel
    let teamId: String
    let isOffense: Bool

    @State private var searchText: String = ""
    @State private var selectedTemplate: Any?
    @State private var showRenameSheet: Bool = false

    var filteredOffenseTemplates: [SetModel] {
        if searchText.isEmpty {
            return libraryViewModel.offenseTemplates
        }
        return libraryViewModel.offenseTemplates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredDefenseTemplates: [DefenseScenario] {
        if searchText.isEmpty {
            return libraryViewModel.defenseTemplates
        }
        return libraryViewModel.defenseTemplates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                if isOffense {
                    offenseTemplatesSection
                } else {
                    defenseTemplatesSection
                }
            }
            .searchable(text: $searchText, prompt: "Search templates")
            .navigationTitle(isOffense ? "Offense Templates" : "Defense Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRenameSheet) {
                if let template = selectedTemplate {
                    if let setTemplate = template as? SetModel {
                        RenameTemplateSheet(
                            originalName: setTemplate.name,
                            onConfirm: { newName in
                                Task {
                                    await libraryViewModel.duplicateOffenseTemplate(
                                        teamId: teamId,
                                        template: setTemplate,
                                        newName: newName
                                    )
                                    dismiss()
                                }
                            }
                        )
                    } else if let defenseTemplate = template as? DefenseScenario {
                        RenameTemplateSheet(
                            originalName: defenseTemplate.name,
                            onConfirm: { newName in
                                Task {
                                    await libraryViewModel.duplicateDefenseTemplate(
                                        teamId: teamId,
                                        template: defenseTemplate,
                                        newName: newName
                                    )
                                    dismiss()
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Sections

    var offenseTemplatesSection: some View {
        ForEach(SetCategory.allCases, id: \.self) { category in
            let templates = filteredOffenseTemplates.filter { $0.category == category }

            if !templates.isEmpty {
                Section(category.rawValue) {
                    ForEach(templates) { template in
                        TemplateRow(
                            name: template.name,
                            stepCount: template.steps.count,
                            onTap: {
                                selectedTemplate = template
                                showRenameSheet = true
                            }
                        )
                    }
                }
            }
        }
    }

    var defenseTemplatesSection: some View {
        ForEach(DefenseCategory.allCases, id: \.self) { category in
            let templates = filteredDefenseTemplates.filter { $0.category == category }

            if !templates.isEmpty {
                Section(category.rawValue) {
                    ForEach(templates) { template in
                        TemplateRow(
                            name: template.name,
                            stepCount: template.steps.count,
                            onTap: {
                                selectedTemplate = template
                                showRenameSheet = true
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let name: String
    let stepCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)

                    Text("\(stepCount) steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.orange)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rename Sheet

struct RenameTemplateSheet: View {
    @Environment(\.dismiss) var dismiss
    let originalName: String
    let onConfirm: (String) -> Void

    @State private var newName: String

    init(originalName: String, onConfirm: @escaping (String) -> Void) {
        self.originalName = originalName
        self.onConfirm = onConfirm
        _newName = State(initialValue: originalName)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $newName)
                } header: {
                    Text("Template Name")
                } footer: {
                    Text("This will create a copy of '\(originalName)' that you can customize for your team.")
                }

                Section {
                    Button(action: {
                        onConfirm(newName)
                    }) {
                        Text("Add to Playbook")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.orange)
                    }
                    .disabled(newName.isEmpty)
                }
            }
            .navigationTitle("Add Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
