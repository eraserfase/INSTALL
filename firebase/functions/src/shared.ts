import * as admin from "firebase-admin";

/**
 * Shared utilities for Cloud Functions
 */

export interface TeamMember {
  role: "coach" | "player";
  displayNameOverride?: string;
  jerseyNumber?: string;
  status: "active" | "removed";
  createdAt: admin.firestore.Timestamp;
  fcmToken?: string; // Optional: store FCM token for targeted messaging
}

/**
 * Get all active player FCM tokens for a team
 */
export async function getPlayerTokensForTeam(
  teamId: string
): Promise<string[]> {
  const db = admin.firestore();
  const membersSnapshot = await db
    .collection(`teams/${teamId}/members`)
    .where("role", "==", "player")
    .where("status", "==", "active")
    .get();

  const tokens: string[] = [];

  membersSnapshot.forEach((doc) => {
    const member = doc.data() as TeamMember;
    if (member.fcmToken) {
      tokens.push(member.fcmToken);
    }
  });

  return tokens;
}

/**
 * Send multicast notification to player tokens
 */
export async function sendNotificationToPlayers(
  tokens: string[],
  notification: {
    title: string;
    body: string;
  },
  data?: { [key: string]: string }
): Promise<void> {
  if (tokens.length === 0) {
    console.log("No tokens to send notification to");
    return;
  }

  const messaging = admin.messaging();

  try {
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification,
      data,
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "playbook_updates",
        },
      },
    });

    console.log(`Successfully sent ${response.successCount} messages`);
    if (response.failureCount > 0) {
      console.log(`Failed to send ${response.failureCount} messages`);
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`Error for token ${tokens[idx]}:`, resp.error);
        }
      });
    }
  } catch (error) {
    console.error("Error sending notification:", error);
    throw error;
  }
}
