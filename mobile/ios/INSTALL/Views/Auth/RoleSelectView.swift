import SwiftUI

/// Role selection screen (Coach or Player)
struct RoleSelectView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var displayName: String = ""
    @State private var selectedRole: TeamRole = .player

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.orange)

                Text("Welcome to INSTALL")
                    .font(.title.bold())

                Text("Tell us about yourself")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Input fields
            VStack(spacing: 24) {
                // Display name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    TextField("Your name", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }

                // Role selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("I am a...")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        RoleButton(
                            icon: "whistle.fill",
                            title: "Coach",
                            isSelected: selectedRole == .coach
                        ) {
                            selectedRole = .coach
                        }

                        RoleButton(
                            icon: "basketball.fill",
                            title: "Player",
                            isSelected: selectedRole == .player
                        ) {
                            selectedRole = .player
                        }
                    }
                }
            }
            .padding(.horizontal, 32)

            // Continue button
            Button(action: {
                Task {
                    await authViewModel.completeOnboarding(displayName: displayName, role: selectedRole)
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(displayName.isEmpty ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(displayName.isEmpty)
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .overlay {
            if authViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
}

// MARK: - Role Button

struct RoleButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 48))

                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(isSelected ? Color.orange : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
    }
}
