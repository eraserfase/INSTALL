# INSTALL Cloud Functions

This directory contains Firebase Cloud Functions for the INSTALL basketball coaching app.

## Functions

### `notifyPlaybookPublish`
- **Trigger**: Firestore document update on `teams/{teamId}`
- **Purpose**: Sends push notifications to all active players when the playbook version increments
- **Logic**:
  1. Checks if `playbookVersion` has incremented
  2. Verifies `playbookPublishedAt` timestamp exists
  3. Retrieves all active player FCM tokens from `teams/{teamId}/members`
  4. Sends multicast push notification via FCM

### `notifyPracticePublish`
- **Trigger**: Firestore document write on `teams/{teamId}/practices/{practiceId}`
- **Purpose**: Sends push notifications when a practice is published or updated
- **Logic**:
  1. Checks if `publishedAt` field is set or has changed
  2. Retrieves all active player FCM tokens
  3. Sends multicast push notification with practice details
  4. Differentiates between "New Practice" and "Practice Updated"

## Setup

1. Install dependencies:
   ```bash
   cd firebase/functions
   npm install
   ```

2. Build TypeScript:
   ```bash
   npm run build
   ```

3. Deploy to Firebase:
   ```bash
   npm run deploy
   ```

4. Run locally with emulator:
   ```bash
   npm run serve
   ```

## FCM Token Management

Player devices must store their FCM tokens in Firestore:
- Path: `teams/{teamId}/members/{userId}`
- Field: `fcmToken` (string, optional)

iOS app should:
1. Request notification permissions
2. Obtain FCM token via Firebase Messaging SDK
3. Update user's member document with token on login/token refresh

## Notification Payload

### Playbook Published
```json
{
  "notification": {
    "title": "Playbook Updated",
    "body": "{Team Name} playbook has been updated. Check out the new plays!"
  },
  "data": {
    "type": "PLAYBOOK_PUBLISHED",
    "teamId": "...",
    "version": "2",
    "timestamp": "1234567890000"
  }
}
```

### Practice Published/Updated
```json
{
  "notification": {
    "title": "New Practice" | "Practice Updated",
    "body": "{Team Name}: {Practice Title}"
  },
  "data": {
    "type": "PRACTICE_PUBLISHED" | "PRACTICE_UPDATED",
    "teamId": "...",
    "practiceId": "...",
    "timestamp": "1234567890000"
  }
}
```

## Testing

Test with Firebase emulator suite:
```bash
firebase emulators:start
```

Then use Firestore emulator UI to manually trigger document changes and verify function execution.

## Security

- Functions only send notifications to users with `role=player` and `status=active`
- Invalid/expired FCM tokens are logged but do not halt execution
- All Firestore reads respect security rules (functions run with admin privileges but should respect logical access patterns)

## Costs

- Each function invocation costs based on:
  - Compute time (typically <1 second per notification batch)
  - Firestore reads (1 read per team doc + N reads for member tokens)
  - FCM sends (free for iOS/Android)

For a team of 15 players with weekly playbook updates, expected monthly cost: <$0.10
