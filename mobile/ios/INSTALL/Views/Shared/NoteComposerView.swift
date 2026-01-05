import SwiftUI

/// Note composer (text + optional audio)
struct NoteComposerView: View {
    @Environment(\.dismiss) var dismiss
    let attachmentType: NoteAttachmentType
    let attachmentId: String
    let stepIndex: Int?
    let onSave: (NoteTargetType, String?, String?, URL?) async -> Void

    @State private var targetType: NoteTargetType = .all
    @State private var targetPosition: Int = 1
    @State private var targetPlayerId: String = ""
    @State private var noteText: String = ""
    @State private var audioURL: URL?
    @State private var showAudioRecorder: Bool = false
    @State private var isSaving: Bool = false

    var body: some View {
        NavigationView {
            Form {
                // Target selection
                Section("Who is this note for?") {
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
                            .textContentType(.username)
                    }
                }

                // Text note
                Section {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
                } header: {
                    Text("Text Note")
                } footer: {
                    Text("\(noteText.count) characters")
                }

                // Audio note
                Section("Audio Note (Optional)") {
                    if let audioURL = audioURL {
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                                .foregroundColor(.orange)

                            Text("Audio recorded")
                                .foregroundColor(.secondary)

                            Spacer()

                            Button("Remove") {
                                self.audioURL = nil
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Button(action: {
                            showAudioRecorder = true
                        }) {
                            HStack {
                                Image(systemName: "mic.circle.fill")
                                Text("Record Audio")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.orange)
                        }
                    }
                }

                // Save button
                Section {
                    Button(action: {
                        Task {
                            await saveNote()
                        }
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }

                            Text(isSaving ? "Saving..." : "Save Note")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(canSave ? .orange : .gray)
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAudioRecorder) {
                AudioRecorderView { url in
                    audioURL = url
                    showAudioRecorder = false
                }
            }
        }
    }

    // MARK: - Validation

    private var canSave: Bool {
        // Must have text or audio
        guard !noteText.isEmpty || audioURL != nil else { return false }

        // If targeting player, must have player ID
        if targetType == .player && targetPlayerId.isEmpty {
            return false
        }

        return true
    }

    // MARK: - Save

    private func saveNote() async {
        isSaving = true

        let targetId: String? = {
            switch targetType {
            case .all:
                return nil
            case .position:
                return "\(targetPosition)"
            case .player:
                return targetPlayerId
            }
        }()

        await onSave(
            targetType,
            targetId,
            noteText.isEmpty ? nil : noteText,
            audioURL
        )

        isSaving = false
        dismiss()
    }
}
