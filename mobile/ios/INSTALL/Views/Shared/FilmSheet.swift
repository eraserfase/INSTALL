import SwiftUI

/// Sheet to display film references
struct FilmSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appEnvironment: AppEnvironment
    let teamId: String
    let attachmentType: FilmAttachmentType
    let attachmentId: String
    let position: Int?
    let userId: String?
    let isCoach: Bool

    @State private var filmRefs: [FilmRef] = []
    @State private var isLoading: Bool = true
    @State private var showAddFilm: Bool = false

    var body: some View {
        NavigationView {
            List {
                if filmRefs.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filmRefs) { filmRef in
                        FilmRefRow(
                            filmRef: filmRef,
                            onDelete: isCoach ? {
                                Task {
                                    await deleteFilm(filmRef.id)
                                }
                            } : nil
                        )
                    }
                }
            }
            .navigationTitle("Film")
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
                            showAddFilm = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .task {
                await loadFilmRefs()
            }
            .sheet(isPresented: $showAddFilm) {
                AddFilmLinkView(
                    teamId: teamId,
                    attachmentType: attachmentType,
                    attachmentId: attachmentId,
                    userId: userId ?? "",
                    onSave: {
                        await loadFilmRefs()
                    }
                )
                .environmentObject(appEnvironment)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "film")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No film references yet")
                .font(.headline)
                .foregroundColor(.secondary)

            if isCoach {
                Text("Tap + to add film")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func loadFilmRefs() async {
        isLoading = true

        do {
            if let position = position, let userId = userId {
                filmRefs = try await appEnvironment.filmService.getRelevantFilmReferences(
                    teamId: teamId,
                    attachmentType: attachmentType,
                    attachmentId: attachmentId,
                    position: position,
                    userId: userId
                )
            } else {
                filmRefs = try await appEnvironment.filmService.getFilmReferences(
                    teamId: teamId,
                    attachmentType: attachmentType,
                    attachmentId: attachmentId
                )
            }

            isLoading = false
        } catch {
            print("Failed to load film: \(error)")
            isLoading = false
        }
    }

    private func deleteFilm(_ filmId: String) async {
        do {
            try await appEnvironment.filmService.deleteFilmReference(teamId: teamId, filmRefId: filmId)
            await loadFilmRefs()
        } catch {
            print("Failed to delete film: \(error)")
        }
    }
}

// MARK: - Film Ref Row

struct FilmRefRow: View {
    let filmRef: FilmRef
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

            // Note text
            if let noteText = filmRef.noteText {
                Text(noteText)
                    .font(.headline)
            }

            // Film link
            Link(destination: URL(string: filmRef.urlWithTimecode)!) {
                HStack {
                    Image(systemName: "film.fill")
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(filmRef.url)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)

                        if let start = filmRef.startSeconds {
                            Text("Start: \(formatTime(start))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }

    var targetBadge: some View {
        Group {
            switch filmRef.targetType {
            case .all:
                Label("Everyone", systemImage: "person.3.fill")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)

            case .position:
                if let targetId = filmRef.targetId {
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

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
