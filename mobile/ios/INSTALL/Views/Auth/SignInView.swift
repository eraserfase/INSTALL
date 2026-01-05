import SwiftUI
import AuthenticationServices

/// Sign in screen with Apple, Google, and Email options
struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var showEmailInput: Bool = false
    @State private var emailLinkSent: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App branding
            VStack(spacing: 8) {
                Image(systemName: "basketball.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)

                Text("INSTALL")
                    .font(.system(size: 42, weight: .heavy, design: .default))

                Text("Basketball Coaching & Study")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Sign in options
            VStack(spacing: 16) {
                // Sign in with Apple
                SignInWithAppleButton(
                    onRequest: authViewModel.handleSignInWithAppleRequest,
                    onCompletion: authViewModel.handleSignInWithAppleCompletion
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(8)

                // Email link sign in
                if !showEmailInput {
                    Button(action: {
                        showEmailInput = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Sign in with Email")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else if !emailLinkSent {
                    VStack(spacing: 12) {
                        TextField("Email address", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        Button(action: {
                            Task {
                                await authViewModel.sendEmailSignInLink(email: email)
                                emailLinkSent = true
                            }
                        }) {
                            Text("Send Sign In Link")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(email.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(email.isEmpty)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("Check your email")
                            .font(.headline)

                        Text("We sent a sign-in link to \(email)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .padding(.horizontal, 32)

            // Error message
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

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
