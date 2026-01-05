import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getPlayerTokensForTeam, sendNotificationToPlayers } from "./shared";

/**
 * Triggered when a team document is updated
 * Sends push notification to all players when playbookVersion increments
 */
export const notifyPlaybookPublish = functions.firestore
  .document("teams/{teamId}")
  .onUpdate(async (change, context) => {
    const teamId = context.params.teamId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if playbookVersion has incremented
    const beforeVersion = beforeData?.playbookVersion || 0;
    const afterVersion = afterData?.playbookVersion || 0;

    if (afterVersion <= beforeVersion) {
      // Version did not increment, no notification needed
      return null;
    }

    // Check if playbookPublishedAt was updated
    const publishedAt = afterData?.playbookPublishedAt;
    if (!publishedAt) {
      console.log("No publishedAt timestamp, skipping notification");
      return null;
    }

    const teamName = afterData?.name || "Your team";

    console.log(
      `Playbook published for team ${teamId}: v${beforeVersion} -> v${afterVersion}`
    );

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
        title: "Playbook Updated",
        body: `${teamName} playbook has been updated. Check out the new plays!`,
      },
      {
        type: "PLAYBOOK_PUBLISHED",
        teamId,
        version: afterVersion.toString(),
        timestamp: publishedAt.toMillis().toString(),
      }
    );

    return null;
  });
