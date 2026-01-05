import SwiftUI

/// Practice detail view showing attached sets, defense, and film
struct PracticeDetailView: View {
    let practice: PracticeSession
    let teamId: String
    @EnvironmentObject var appEnvironment: AppEnvironment

    @State private var attachedSets: [SetModel] = []
    @State private var attachedDefense: [DefenseScenario] = []
    @State private var filmRefs: [FilmRef] = []
    @State private var isLoading: Bool = true

    var body: some View {
        List {
            // Practice info
            Section {
                if let startAt = practice.startAt {
                    LabeledContent("Date", value: startAt.dateValue(), format: .dateTime)
                }

                if let location = practice.location {
                    LabeledContent("Location", value: location)
                }

                if let focus = practice.focusText {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focus")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(focus)
                            .font(.body)
                    }
                }
            }

            // Attached sets
            if !attachedSets.isEmpty {
                Section("Sets to Study") {
                    ForEach(attachedSets) { set in
                        NavigationLink(destination: PlaybackView(
                            viewModel: {
                                let vm = PlaybackViewModel()
                                vm.loadSet(set)
                                return vm
                            }()
                        )) {
                            HStack {
                                Image(systemName: "basketball.fill")
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(set.name)
                                        .font(.headline)

                                    Text("\(set.enabledSteps.count) steps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // Attached defense
            if !attachedDefense.isEmpty {
                Section("Defense to Study") {
                    ForEach(attachedDefense) { scenario in
                        NavigationLink(destination: PlaybackView(
                            viewModel: {
                                let vm = PlaybackViewModel()
                                vm.loadDefense(scenario)
                                return vm
                            }()
                        )) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(scenario.name)
                                        .font(.headline)

                                    Text("\(scenario.enabledSteps.count) steps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // Film references
            if !filmRefs.isEmpty {
                Section("Film") {
                    ForEach(filmRefs) { filmRef in
                        Link(destination: URL(string: filmRef.urlWithTimecode)!) {
                            HStack {
                                Image(systemName: "film.fill")
                                    .foregroundColor(.purple)

                                VStack(alignment: .leading, spacing: 4) {
                                    if let note = filmRef.noteText {
                                        Text(note)
                                            .font(.headline)
                                    } else {
                                        Text("Film Reference")
                                            .font(.headline)
                                    }

                                    Text(filmRef.url)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }

            // Empty state
            if attachedSets.isEmpty && attachedDefense.isEmpty && filmRefs.isEmpty && !isLoading {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("No study materials attached")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .navigationTitle(practice.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadAttachedContent()
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    // MARK: - Load Content

    private func loadAttachedContent() async {
        isLoading = true

        // Load sets
        if !practice.attachments.setIds.isEmpty {
            for setId in practice.attachments.setIds {
                do {
                    let set = try await appEnvironment.setsService.getSet(teamId: teamId, setId: setId)
                    attachedSets.append(set)
                } catch {
                    print("Failed to load set \(setId): \(error)")
                }
            }
        }

        // Load defense
        if !practice.attachments.defenseIds.isEmpty {
            for defenseId in practice.attachments.defenseIds {
                do {
                    let defense = try await appEnvironment.defenseService.getDefenseScenario(teamId: teamId, scenarioId: defenseId)
                    attachedDefense.append(defense)
                } catch {
                    print("Failed to load defense \(defenseId): \(error)")
                }
            }
        }

        // Load film references
        do {
            filmRefs = try await appEnvironment.filmService.getFilmReferences(
                teamId: teamId,
                attachmentType: .practice,
                attachmentId: practice.id
            )
        } catch {
            print("Failed to load film: \(error)")
        }

        isLoading = false
    }
}
