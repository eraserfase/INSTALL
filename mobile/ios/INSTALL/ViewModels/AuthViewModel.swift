import Foundation
import SwiftUI
import AuthenticationServices
import FirebaseAuth

/// ViewModel for authentication flows
@MainActor
class AuthViewModel: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let authService = AuthService.shared

    init() {
        // Check auth state
        self.currentUser = Auth.auth().currentUser
        self.isAuthenticated = currentUser != nil
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: FirebaseConfig.UserDefaultsKeys.hasCompletedOnboarding)

        // Listen to auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    // MARK: - Sign In with Apple

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                switch result {
                case .success(let authorization):
                    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        throw AuthError.invalidAppleCredential
                    }

                    try await authService.signInWithApple(credential: appleIDCredential)
                    isLoading = false

                case .failure(let error):
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Email Link Sign In

    func sendEmailSignInLink(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.sendSignInLink(to: email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func completeEmailSignIn(email: String, link: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.signInWithEmailLink(email: email, link: link)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Onboarding

    func completeOnboarding(displayName: String, role: TeamRole) async {
        isLoading = true
        errorMessage = nil

        do {
            // Update display name
            try await authService.updateDisplayName(displayName)

            // Save role preference
            UserDefaults.standard.set(role.rawValue, forKey: FirebaseConfig.UserDefaultsKeys.userRole)

            // Mark onboarding complete
            UserDefaults.standard.set(true, forKey: FirebaseConfig.UserDefaultsKeys.hasCompletedOnboarding)
            hasCompletedOnboarding = true

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try authService.signOut()
            hasCompletedOnboarding = false
            UserDefaults.standard.set(false, forKey: FirebaseConfig.UserDefaultsKeys.hasCompletedOnboarding)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
