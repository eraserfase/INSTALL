import Foundation
import FirebaseMessaging
import UserNotifications

/// Service for handling Firebase Cloud Messaging
class MessagingService: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {

    var fcmToken: String?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken

        // Update Firestore membership with token
        if let token = fcmToken {
            Task {
                await updateMembershipToken(token)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification tap
        if let type = userInfo["type"] as? String {
            switch type {
            case "PLAYBOOK_PUBLISHED":
                // Navigate to playbook
                print("Navigate to playbook")
            case "PRACTICE_PUBLISHED", "PRACTICE_UPDATED":
                // Navigate to practice
                if let practiceId = userInfo["practiceId"] as? String {
                    print("Navigate to practice: \(practiceId)")
                }
            default:
                break
            }
        }

        completionHandler()
    }

    // MARK: - Token Management

    private func updateMembershipToken(_ token: String) async {
        guard let userId = AuthService.shared.currentUserId,
              let teamId = UserDefaults.standard.string(forKey: FirebaseConfig.UserDefaultsKeys.currentTeamId) else {
            return
        }

        let db = FirestoreService().db
        let memberRef = db.collection("teams").document(teamId).collection("members").document(userId)

        do {
            try await memberRef.updateData(["fcmToken": token])
        } catch {
            print("Failed to update FCM token: \(error)")
        }
    }
}
