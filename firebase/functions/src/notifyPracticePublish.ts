import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getPlayerTokensForTeam, sendNotificationToPlayers } from "./shared";

/**
 * Triggered when a practice document is created or updated
 * Sends push notification to all players when publishedAt is set or updated
 */
export const notifyPracticePublish = functions.firestore
  .document("teams/{teamId}/practices/{practiceId}")
  .onWrite(async (change, context) => {
    const teamId = context.params.teamId;
    const practiceId = context.params.practiceId;

    // For deletions, skip notification
    if (!change.after.exists) {
      return null;
    }

    const afterData = change.after.data();
    if (!afterData) {
      return null;
    }

    // Check if this is a new publish or an update to publishedAt
    const beforePublishedAt = change.before.exists
      ? change.before.data()?.publishedAt
      : null;
    const afterPublishedAt = afterData.publishedAt;

    // If publishedAt hasn't changed or doesn't exist, skip notification
    if (!afterPublishedAt) {
      console.log("Practice not published yet, skipping notification");
      return null;
    }

    // Check if publishedAt timestamp actually changed
    // (avoid sending notification on unrelated updates)
    if (
      beforePublishedAt &&
      afterPublishedAt.toMillis() === beforePublishedAt.toMillis()
    ) {
      console.log("publishedAt unchanged, skipping notification");
      return null;
    }

    const practiceTitle = afterData.title || "Practice session";
    const isUpdate = change.before.exists && beforePublishedAt !== null;

    console.log(
      `Practice ${isUpdate ? "updated" : "published"} for team ${teamId}: ${practiceId}`
    );

    // Get team name for better notification
    const teamDoc = await admin.firestore().collection("teams").doc(teamId).get();
    const teamName = teamDoc.data()?.name || "Your team";

    // Get all player FCM tokens
    const tokens = await getPlayerTokensForTeam(teamId);

    if (tokens.length === 0) {
      console.log("No player tokens found for team", teamId);
      return null;
    }

    // Send notification
    await sendNotificationToPlayers(
      tokens,
      {
        title: isUpdate ? "Practice Updated" : "New Practice",
        body: `${teamName}: ${practiceTitle}`,
      },
      {
        type: isUpdate ? "PRACTICE_UPDATED" : "PRACTICE_PUBLISHED",
        teamId,
        practiceId,
        timestamp: afterPublishedAt.toMillis().toString(),
      }
    );

    return null;
  });
