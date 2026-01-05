import SwiftUI
import FirebaseFirestore

/// Add film link view
struct AddFilmLinkView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appEnvironment: AppEnvironment

    let teamId: String
    let attachmentType: FilmAttachmentType
    let attachmentId: String
    let userId: String
    let onSave: () async -> Void

    @State private var url: String = ""
    @State private var noteText: String = ""
    @State private var startSeconds: String = ""
    @State private var endSeconds: String = ""
    @State private var targetType: NoteTargetType = .all
    @State private var targetPosition: Int = 1
    @State private var targetPlayerId: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                // URL
                Section {
                    TextField("https://youtube.com/watch?v=...", text: $url)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                } header: {
                    Text("Film URL")
                } footer: {
                    Text("YouTube, Vimeo, Hudl, or any video link")
                }

                // Timecodes
                Section("Timecodes (Optional)") {
                    HStack {
                        Text("Start")
                            .frame(width: 60, alignment: .leading)

                        TextField("0:00", text: $startSeconds)
                            .keyboardType(.numbersAndPunctuation)
                    }

                    HStack {
                        Text("End")
                            .frame(width: 60, alignment: .leading)

                        TextField("0:00", text: $endSeconds)
                            .keyboardType(.numbersAndPunctuation)
                    }
                }

                // Note
                Section("Note (Optional)") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 80)
                }

                // Target
                Section("Who should see this?") {
                    Picker("Target", selection: $targetType) {
                        Text("Everyone").tag(NoteTargetType.all)
                        Text("Specific Position").tag(NoteTargetType.position)
                        Text("Specific Player").tag(NoteTargetType.player)
                    }
                    .pickerStyle(.segmented)

                    if targetType == .position {
                        Picker("Position", selection: $targetPosition) {
                            ForEach(1...5, id: \.self) { position in
                                Text("Position \(position)").tag(position)
                            }
                        }
                    } else if targetType == .player {
                        TextField("Player ID", text: $targetPlayerId)
                    }
                }

                // Save
                Section {
                    Button(action: {
                        Task {
                            await saveFilmRef()
                        }
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                            }

                            Text(isSaving ? "Saving..." : "Save Film")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(canSave ? .orange : .gray)
                    }
                    .disabled(!canSave || isSaving)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Film")
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

    // MARK: - Validation

    private var canSave: Bool {
        guard !url.isEmpty else { return false }

        if targetType == .player && targetPlayerId.isEmpty {
            return false
        }

        return true
    }

    // MARK: - Save

    private func saveFilmRef() async {
        isSaving = true
        errorMessage = nil

        let targetId: String? = {
            switch targetType {
            case .all: return nil
            case .position: return "\(targetPosition)"
            case .player: return targetPlayerId
            }
        }()

        let filmRef = FilmRef(
            id: UUID().uuidString,
            attachmentType: attachmentType,
            attachmentId: attachmentId,
            targetType: targetType,
            targetId: targetId,
            url: url,
            startSeconds: parseTime(startSeconds),
            endSeconds: parseTime(endSeconds),
            noteText: noteText.isEmpty ? nil : noteText,
            createdBy: userId
        )

        do {
            _ = try await appEnvironment.filmService.createFilmReference(teamId: teamId, filmRef: filmRef)
            await onSave()
            isSaving = false
            dismiss()
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    private func parseTime(_ timeString: String) -> Double? {
        guard !timeString.isEmpty else { return nil }

        let components = timeString.split(separator: ":")
        guard components.count <= 2 else { return nil }

        if components.count == 1 {
            // Just seconds
            return Double(components[0])
        } else {
            // Minutes:seconds
            guard let minutes = Double(components[0]),
                  let seconds = Double(components[1]) else {
                return nil
            }
            return minutes * 60 + seconds
        }
    }
}
