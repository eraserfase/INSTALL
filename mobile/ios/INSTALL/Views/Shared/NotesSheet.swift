import SwiftUI
import AVFoundation

/// Sheet to display notes for a set/defense/practice
struct NotesSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: NotesViewModel
    let attachmentType: NoteAttachmentType
    let attachmentId: String
    let position: Int?
    let userId: String?
    let isCoach: Bool

    @State private var showNoteComposer: Bool = false
    @State private var playingNoteId: String?
    @State private var audioPlayer: AVPlayer?

    var body: some View {
        NavigationView {
            List {
                if viewModel.notes.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.notes) { note in
                        NoteRow(
                            note: note,
                            isPlaying: playingNoteId == note.id,
                            onPlayAudio: {
                                Task {
                                    await playAudio(for: note)
                                }
                            },
                            onStopAudio: {
                                stopAudio()
                            },
                            onDelete: isCoach ? {
                                Task {
                                    await viewModel.deleteNote(
                                        noteId: note.id,
                                        attachmentType: attachmentType,
                                        attachmentId: attachmentId
                                    )
                                }
                            } : nil
                        )
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if isCoach {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            showNoteComposer = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadNotes(
                    attachmentType: attachmentType,
                    attachmentId: attachmentId,
                    position: position,
                    userId: userId
                )
            }
            .sheet(isPresented: $showNoteComposer) {
                NoteComposerView(
                    attachmentType: attachmentType,
                    attachmentId: attachmentId,
                    stepIndex: nil,
                    onSave: { targetType, targetId, text, audioURL in
                        guard let userId = userId else { return }

                        await viewModel.createNote(
                            attachmentType: attachmentType,
                            attachmentId: attachmentId,
                            targetType: targetType,
                            targetId: targetId,
                            text: text,
                            audioURL: audioURL,
                            createdBy: userId
                        )
                    }
                )
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No notes yet")
                .font(.headline)
                .foregroundColor(.secondary)

            if isCoach {
                Text("Tap + to add a note")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Audio Playback

    private func playAudio(for note: Note) async {
        guard let audioURL = await viewModel.getAudioURL(for: note) else { return }

        stopAudio() // Stop any existing playback

        audioPlayer = AVPlayer(url: audioURL)
        audioPlayer?.play()
        playingNoteId = note.id

        // Listen for playback completion
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: audioPlayer?.currentItem,
            queue: .main
        ) { _ in
            stopAudio()
        }
    }

    private func stopAudio() {
        audioPlayer?.pause()
        audioPlayer = nil
        playingNoteId = nil
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: Note
    let isPlaying: Bool
    let onPlayAudio: () -> Void
    let onStopAudio: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Target badge
            HStack {
                targetBadge

                Spacer()

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }

            // Text content
            if let text = note.text {
                Text(text)
                    .font(.body)
            }

            // Audio player
            if note.audio != nil {
                Button(action: {
                    if isPlaying {
                        onStopAudio()
                    } else {
                        onPlayAudio()
                    }
                }) {
                    HStack {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .foregroundColor(.orange)

                        if let duration = note.audio?.durationMs {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Timestamp
            Text(note.createdAt.dateValue(), style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    var targetBadge: some View {
        Group {
            switch note.targetType {
            case .all:
                Label("Everyone", systemImage: "person.3.fill")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)

            case .position:
                if let targetId = note.targetId {
                    Label("Position \(targetId)", systemImage: "number.circle.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }

            case .player:
                Label("Personal", systemImage: "person.fill")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
            }
        }
    }

    private func formatDuration(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
