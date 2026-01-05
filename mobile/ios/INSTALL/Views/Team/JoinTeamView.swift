import SwiftUI

/// Join team sheet
struct JoinTeamView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var teamViewModel: TeamViewModel

    @State private var joinCode: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Join Code", text: $joinCode)
                        .autocapitalization(.allCharacters)
                        .textCase(.uppercase)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Team Join Code")
                } footer: {
                    Text("Enter the 6-character code provided by your coach")
                }

                Section {
                    Button(action: {
                        Task {
                            guard let userId = authViewModel.currentUser?.uid else { return }
                            let displayName = authViewModel.currentUser?.displayName
                            await teamViewModel.joinTeam(joinCode: joinCode.uppercased(), userId: userId, displayName: displayName)

                            if teamViewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Join Team")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(joinCode.count < 6 ? .gray : .blue)
                    }
                    .disabled(joinCode.count < 6)
                }

                if let error = teamViewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Join Team")
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
