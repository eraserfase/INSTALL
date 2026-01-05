import SwiftUI
import FirebaseFirestore

/// Edit practice view (create/update practice curriculum)
struct EditPracticeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appEnvironment: AppEnvironment
    let teamId: String
    let practice: PracticeSession?

    @State private var title: String
    @State private var startAt: Date?
    @State private var location: String
    @State private var focusText: String
    @State private var selectedSetIds: Set<String>
    @State private var selectedDefenseIds: Set<String>

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var availableSets: [SetModel] = []
    @State private var availableDefense: [DefenseScenario] = []

    init(teamId: String, practice: PracticeSession? = nil) {
        self.teamId = teamId
        self.practice = practice

        _title = State(initialValue: practice?.title ?? "")
        _startAt = State(initialValue: practice?.startAt?.dateValue())
        _location = State(initialValue: practice?.location ?? "")
        _focusText = State(initialValue: practice?.focusText ?? "")
        _selectedSetIds = State(initialValue: Set(practice?.attachments.setIds ?? []))
        _selectedDefenseIds = State(initialValue: Set(practice?.attachments.defenseIds ?? []))
    }

    var body: some View {
        NavigationView {
            Form {
                // Basic info
                Section("Practice Information") {
                    TextField("Title", text: $title)

                    DatePicker(
                        "Date & Time",
                        selection: Binding(
                            get: { startAt ?? Date() },
                            set: { startAt = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    TextField("Location (Optional)", text: $location)
                }

                // Focus
                Section {
                    TextEditor(text: $focusText)
                        .frame(minHeight: 80)
                } header: {
                    Text("Focus Note (Optional)")
                } footer: {
                    Text("What should players focus on during this practice?")
                }

                // Attach sets
                Section("Offense Sets") {
                    ForEach(availableSets) { set in
                        Toggle(isOn: Binding(
                            get: { selectedSetIds.contains(set.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedSetIds.insert(set.id)
                                } else {
                                    selectedSetIds.remove(set.id)
                                }
                            }
                        )) {
                            Text(set.name)
                        }
                    }
                }

                // Attach defense
                Section("Defense") {
                    ForEach(availableDefense) { scenario in
                        Toggle(isOn: Binding(
                            get: { selectedDefenseIds.contains(scenario.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDefenseIds.insert(scenario.id)
                                } else {
                                    selectedDefenseIds.remove(scenario.id)
                                }
                            }
                        )) {
                            Text(scenario.name)
                        }
                    }
                }

                // Save and publish
                Section {
                    Button(action: {
                        Task {
                            await saveAndPublish()
                        }
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Save & Publish")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.orange)
                    }
                    .disabled(title.isEmpty)
                } footer: {
                    Text("Publishing will notify all players about this practice.")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(practice == nil ? "New Practice" : "Edit Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadAvailableContent()
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Actions

    private func loadAvailableContent() async {
        do {
            availableSets = try await appEnvironment.setsService.getSets(teamId: teamId)
            availableDefense = try await appEnvironment.defenseService.getDefenseScenarios(teamId: teamId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveAndPublish() async {
        isLoading = true
        errorMessage = nil

        do {
            let attachments = PracticeAttachment(
                setIds: Array(selectedSetIds),
                defenseIds: Array(selectedDefenseIds)
            )

            if let existingPractice = practice {
                // Update existing
                var updated = existingPractice
                updated.title = title
                updated.startAt = startAt.map { Timestamp(date: $0) }
                updated.location = location.isEmpty ? nil : location
                updated.focusText = focusText.isEmpty ? nil : focusText
                updated.attachments = attachments
                updated.publishedAt = Timestamp() // Republish

                try await appEnvironment.practicesService.updatePractice(teamId: teamId, practice: updated)
            } else {
                // Create new
                let newPractice = PracticeSession(
                    id: UUID().uuidString,
                    title: title,
                    startAt: startAt.map { Timestamp(date: $0) },
                    location: location.isEmpty ? nil : location,
                    focusText: focusText.isEmpty ? nil : focusText,
                    attachments: attachments,
                    publishedAt: Timestamp()
                )

                _ = try await appEnvironment.practicesService.createPractice(teamId: teamId, practice: newPractice)
            }

            isLoading = false
            dismiss()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
