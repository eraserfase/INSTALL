import SwiftUI

/// Create team sheet
struct CreateTeamView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var teamViewModel: TeamViewModel

    @State private var teamName: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Team Name", text: $teamName)
                        .autocapitalization(.words)
                } header: {
                    Text("Team Information")
                } footer: {
                    Text("Choose a name for your team. You can change this later.")
                }

                Section {
                    Button(action: {
                        Task {
                            guard let userId = authViewModel.currentUser?.uid else { return }
                            await teamViewModel.createTeam(name: teamName, userId: userId)
                            dismiss()
                        }
                    }) {
                        Text("Create Team")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(teamName.isEmpty ? .gray : .orange)
                    }
                    .disabled(teamName.isEmpty)
                }

                if let error = teamViewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if teamViewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}
