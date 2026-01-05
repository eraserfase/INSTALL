import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

/// Service for handling user authentication
class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false

    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        // Listen to auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    var currentUserId: String? {
        return currentUser?.uid
    }

    var currentUserEmail: String? {
        return currentUser?.email
    }

    var currentUserDisplayName: String? {
        return currentUser?.displayName
    }

    // MARK: - Sign In with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.invalidAppleCredential
        }

        // Create nonce for security
        let nonce = randomNonceString()
        let appleCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )

        let authResult = try await Auth.auth().signIn(with: appleCredential)

        // Update display name if available
        if let fullName = credential.fullName {
            let displayName = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            if !displayName.isEmpty {
                try await updateDisplayName(displayName)
            }
        }

        // Create user document in Firestore
        try await createUserDocumentIfNeeded(userId: authResult.user.uid)
    }

    // MARK: - Sign In with Google

    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        try await createUserDocumentIfNeeded(userId: authResult.user.uid)
    }

    // MARK: - Email Link Sign In

    func sendSignInLink(to email: String) async throws {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://install.app/finishSignIn")
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier ?? "com.install.app")

        try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)

        // Save email for completion
        UserDefaults.standard.set(email, forKey: "emailForSignIn")
    }

    func signInWithEmailLink(email: String, link: String) async throws {
        guard Auth.auth().isSignIn(withEmailLink: link) else {
            throw AuthError.invalidEmailLink
        }

        let authResult = try await Auth.auth().signIn(withEmail: email, link: link)
        try await createUserDocumentIfNeeded(userId: authResult.user.uid)

        // Clear saved email
        UserDefaults.standard.removeObject(forKey: "emailForSignIn")
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()

        // Clear local state
        UserDefaults.standard.removeObject(forKey: FirebaseConfig.UserDefaultsKeys.currentTeamId)
    }

    // MARK: - User Profile

    func updateDisplayName(_ displayName: String) async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        // Update Firestore user document
        let db = Firestore.firestore()
        try await db.collection(FirebaseConfig.Collections.users)
            .document(user.uid)
            .updateData(["displayName": displayName, "updatedAt": Timestamp()])
    }

    // MARK: - Private Helpers

    private func createUserDocumentIfNeeded(userId: String) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection(FirebaseConfig.Collections.users).document(userId)

        let snapshot = try await userRef.getDocument()

        if !snapshot.exists {
            let userData: [String: Any] = [
                "displayName": currentUser?.displayName ?? "User",
                "createdAt": Timestamp(),
                "lastSeenAt": Timestamp()
            ]

            try await userRef.setData(userData)
        } else {
            // Update last seen
            try await userRef.updateData(["lastSeenAt": Timestamp()])
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidAppleCredential
    case invalidEmailLink
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidAppleCredential:
            return "Invalid Apple credential"
        case .invalidEmailLink:
            return "Invalid email sign-in link"
        case .notAuthenticated:
            return "User is not authenticated"
        }
    }
}
