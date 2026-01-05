# Firestore Data Model

This document describes the complete Firestore schema for INSTALL.

## Collections Structure

```
/users/{userId}
/teams/{teamId}
  /members/{userId}
  /sets/{setId}
  /defense/{scenarioId}
  /practices/{practiceId}
  /notes/{noteId}
  /film/{filmId}
```

## Users Collection

**Path:** `/users/{userId}`

```typescript
{
  displayName: string;
  createdAt: Timestamp;
  lastSeenAt?: Timestamp;
}
```

**Fields:**
- `displayName`: User's display name (editable)
- `createdAt`: Account creation timestamp
- `lastSeenAt`: Optional last activity timestamp

## Teams Collection

**Path:** `/teams/{teamId}`

```typescript
{
  name: string;
  createdAt: Timestamp;
  createdBy: string; // userId
  joinCode: string; // 6-character code
  playbookVersion: number;
  playbookPublishedAt?: Timestamp;
}
```

**Fields:**
- `name`: Team name
- `createdBy`: Coach who created the team (userId)
- `joinCode`: 6-character alphanumeric code for joining
- `playbookVersion`: Increments on publish (starts at 0)
- `playbookPublishedAt`: Timestamp of last playbook publish

**Join Code Format:**
- Length: 6 characters
- Character set: `A-Z0-9` (uppercase, no ambiguous chars like O/0, I/1)
- Example: `J4K9M2`

## Team Members Subcollection

**Path:** `/teams/{teamId}/members/{userId}`

```typescript
{
  role: "coach" | "player";
  displayNameOverride?: string;
  jerseyNumber?: string;
  status: "active" | "removed";
  createdAt: Timestamp;
  fcmToken?: string;
}
```

**Fields:**
- `role`: User's role in this team
- `displayNameOverride`: Optional team-specific display name
- `jerseyNumber`: Optional jersey number (player)
- `status`: Membership status (removed = soft delete)
- `fcmToken`: Firebase Cloud Messaging token for push notifications

## Sets Subcollection (Offense)

**Path:** `/teams/{teamId}/sets/{setId}`

```typescript
{
  name: string;
  category: "horns" | "motion" | "flex" | "quick" | "blob" | "slob" | "transition" | "other";
  isTemplate: boolean;
  sourceTemplateId?: string;
  updatedAt: Timestamp;
  draftUpdatedAt?: Timestamp;
  publishedVersion?: number;
  steps: Step[];
}

interface Step {
  index: number;
  label: string;
  note?: string;
  enabled: boolean;
  emphasisPosition?: number; // 1-5
  playerActions: PlayerAction[]; // Always 5 items
}

interface PlayerAction {
  position: number; // 1-5
  actionType: string; // See ActionType enum
  fromSpotId: string;
  toSpotId?: string;
  targetPosition?: number; // 1-5 for screens
  hasBall: boolean;
}
```

**Fields:**
- `name`: Set name (e.g., "Horns (Basic)")
- `category`: Category for organization
- `isTemplate`: True for global templates, false for team-specific
- `sourceTemplateId`: If duplicated from template, reference to original
- `updatedAt`: Last update timestamp
- `draftUpdatedAt`: Draft-only update timestamp (optional)
- `publishedVersion`: Version number when last published (optional)
- `steps`: Array of steps (linear sequence)

**Step Fields:**
- `index`: Step order (0-based)
- `label`: Step name (e.g., "Ball Screen Right")
- `note`: Optional coach note for this step
- `enabled`: If false, step is skipped in playback
- `emphasisPosition`: Optional position to emphasize (1-5)
- `playerActions`: Exactly 5 actions (one per position)

**PlayerAction Fields:**
- `position`: Player position (1-5)
- `actionType`: Action from catalog (see ActionType enum)
- `fromSpotId`: Starting spot ID
- `toSpotId`: Ending spot ID (optional for stationary actions)
- `targetPosition`: For screens/handoffs, which position is targeted
- `hasBall`: True if player has ball in this step

## Defense Subcollection

**Path:** `/teams/{teamId}/defense/{scenarioId}`

```typescript
{
  name: string;
  category: "pickAndRoll" | "zone" | "manToMan" | "press" | "transition" | "other";
  isTemplate: boolean;
  sourceTemplateId?: string;
  updatedAt: Timestamp;
  draftUpdatedAt?: Timestamp;
  publishedVersion?: number;
  steps: Step[]; // Same structure as Sets
}
```

**Same structure as Sets**, but represents defensive coverage scenarios.

## Practices Subcollection

**Path:** `/teams/{teamId}/practices/{practiceId}`

```typescript
{
  title: string;
  startAt?: Timestamp;
  location?: string;
  focusText?: string;
  attachments: {
    setIds: string[];
    defenseIds: string[];
  };
  publishedAt?: Timestamp;
  updatedAt: Timestamp;
}
```

**Fields:**
- `title`: Practice title
- `startAt`: Optional date/time of practice
- `location`: Optional location
- `focusText`: Optional focus note for practice
- `attachments.setIds`: Array of set IDs to study
- `attachments.defenseIds`: Array of defense scenario IDs to study
- `publishedAt`: When practice was published (triggers push if updated)
- `updatedAt`: Last update timestamp

## Notes Subcollection

**Path:** `/teams/{teamId}/notes/{noteId}`

```typescript
{
  attachmentType: "set" | "step" | "defense" | "practice" | "film";
  attachmentId: string;
  stepIndex?: number; // Optional: for step-level notes
  targetType: "ALL" | "POSITION" | "PLAYER";
  targetId?: string; // null for ALL, "1"-"5" for POSITION, userId for PLAYER
  text?: string;
  audio?: {
    storagePath: string;
    durationMs: number;
  };
  createdBy: string; // userId
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**Fields:**
- `attachmentType`: What the note is attached to
- `attachmentId`: ID of the attachment (setId, defenseId, practiceId, filmId)
- `stepIndex`: Optional step index (for step-level notes)
- `targetType`: Who the note is for
- `targetId`:
  - `null` for ALL
  - `"1"` - `"5"` for POSITION
  - `userId` for PLAYER
- `text`: Optional text content
- `audio.storagePath`: Storage path for audio file (e.g., `teams/{teamId}/notes/{noteId}/audio.m4a`)
- `audio.durationMs`: Audio duration in milliseconds
- `createdBy`: Coach who created the note
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

**Note Composition Logic:**
When a player views a set, they see:
1. All notes where `targetType == "ALL"`
2. All notes where `targetType == "POSITION"` AND `targetId == "{player's position}"`
3. All notes where `targetType == "PLAYER"` AND `targetId == "{player's userId}"`

## Film Subcollection

**Path:** `/teams/{teamId}/film/{filmId}`

```typescript
{
  attachmentType: "set" | "defense" | "practice";
  attachmentId: string;
  targetType: "ALL" | "POSITION" | "PLAYER";
  targetId?: string;
  url: string;
  startSeconds?: number;
  endSeconds?: number;
  noteText?: string;
  noteAudioStoragePath?: string;
  createdBy: string; // userId
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**Fields:**
- `attachmentType`: What the film is attached to
- `attachmentId`: ID of the attachment
- `targetType` / `targetId`: Same targeting as Notes
- `url`: External film URL (YouTube, Vimeo, Hudl, etc.)
- `startSeconds`: Optional start timecode
- `endSeconds`: Optional end timecode
- `noteText`: Optional text note about the film
- `noteAudioStoragePath`: Optional audio note path
- `createdBy`: Coach who added the film
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

## Action Type Enum

```typescript
enum ActionType {
  spot_up = "spot_up",
  cut = "cut",
  replace = "replace",
  lift = "lift",
  drift = "drift",
  screen = "screen",
  down_screen = "down_screen",
  flare_screen = "flare_screen",
  ball_screen = "ball_screen",
  handoff = "handoff",
  roll = "roll",
  pop = "pop",
  slip = "slip",
  post_up = "post_up",
  duck_in = "duck_in",
  flash = "flash",
  seal = "seal",
  decoy = "decoy"
}
```

## Spot IDs (Half-Court Coordinates)

All spots use normalized coordinates [0..1] where:
- `x`: 0 = left sideline, 1 = right sideline
- `y`: 0 = baseline, 1 = half court

**Spot IDs:**
- `top` (0.5, 0.85)
- `slot_l` (0.25, 0.75), `slot_r` (0.75, 0.75)
- `wing_l` (0.15, 0.60), `wing_r` (0.85, 0.60)
- `corner_l` (0.05, 0.15), `corner_r` (0.95, 0.15)
- `shortcorner_l` (0.10, 0.35), `shortcorner_r` (0.90, 0.35)
- `elbow_l` (0.28, 0.55), `elbow_r` (0.72, 0.55)
- `lowpost_l` (0.25, 0.25), `lowpost_r` (0.75, 0.25)
- `dunker_l` (0.20, 0.12), `dunker_r` (0.80, 0.12)

## Indexes Required

See `firebase/firestore.indexes.json` for composite indexes:
- `sets`: `category` + `updatedAt`
- `defense`: `category` + `updatedAt`
- `practices`: `startAt` + `updatedAt`
- `notes`: `attachmentType` + `attachmentId` + `createdAt`
- `film`: `attachmentType` + `attachmentId` + `createdAt`
- `members`: `role` + `status`

## Security Rules

All rules are defined in `firebase/firestore.rules`. Key principles:
- **Users** can only read/write their own document
- **Teams** are readable by active members, writable by coaches only
- **Subcollections** (sets, defense, etc.) are readable by members, writable by coaches
- **Members** can self-join as player, but only coaches can change roles/status

## Storage Paths

Audio files are stored in Firebase Storage:
- **Note audio:** `teams/{teamId}/notes/{noteId}/audio.m4a`
- **Film note audio:** `teams/{teamId}/film/{filmId}/audio.m4a`

Storage rules enforce:
- Upload: Coaches only
- Read: Active team members only
- Max size: 10MB
- Content-Type: `audio/*`
