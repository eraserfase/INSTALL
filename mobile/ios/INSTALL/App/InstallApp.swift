import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

@main
struct InstallApp: App {
    @StateObject private var appEnvironment = AppEnvironment()

    init() {
        // Configure Firebase
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()

        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appEnvironment)
                .onAppear {
                    // Request notification permissions
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }

                    // Set messaging delegate
                    Messaging.messaging().delegate = appEnvironment.messagingService
                }
        }
    }
}

/// Root view that handles authentication and team gate
struct RootView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.hasCompletedOnboarding {
                    TeamGateView()
                } else {
                    RoleSelectView()
                }
            } else {
                SignInView()
            }
        }
        .environmentObject(authViewModel)
    }
}
