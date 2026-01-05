# INSTALL - Basketball Coaching & Study

**App Store Subtitle:** Basketball Coaching & Study

INSTALL is a coach-led learning system for youth/HS/AAU basketball. Coaches install sets and defensive schemes with notes, film references, and practice curriculum. Players study their role (with POV emphasis) on phones between practices.

## Project Structure

```
INSTALL/
├── README.md                          # This file
├── docs/                              # Comprehensive documentation
│   ├── 01_PRD.md                     # Product requirements
│   ├── 02_FUNCTIONAL_SPEC.md         # Feature specifications
│   ├── 03_DATA_MODEL_FIRESTORE.md   # Firestore schema
│   ├── 04_ACTIONS_AND_SPOTS.md      # Parametric play system
│   └── ...
├── firebase/                          # Backend (Firebase)
│   ├── firestore.rules               # Security rules for Firestore
│   ├── storage.rules                 # Security rules for Storage
│   ├── firestore.indexes.json        # Firestore composite indexes
│   └── functions/                     # Cloud Functions (Node.js/TypeScript)
│       ├── src/
│       │   ├── index.ts              # Function exports
│       │   ├── notifyPlaybookPublish.ts
│       │   ├── notifyPracticePublish.ts
│       │   └── shared.ts
│       └── package.json
└── mobile/
    ├── ios/                           # iOS app (SwiftUI)
    │   └── INSTALL/
    │       ├── App/                   # App entry point
    │       ├── Models/                # Data models
    │       │   ├── Domain/           # Core domain models
    │       │   └── DTO/              # Firestore DTOs
    │       ├── Services/              # Business logic
    │       │   ├── Auth/
    │       │   ├── Firebase/
    │       │   ├── Teams/
    │       │   ├── Content/
    │       │   └── Permissions/
    │       ├── ViewModels/            # MVVM view models
    │       ├── Views/                 # SwiftUI views
    │       │   ├── Auth/
    │       │   ├── Team/
    │       │   ├── Library/
    │       │   ├── Playback/
    │       │   ├── Editing/
    │       │   ├── Practices/
    │       │   └── Shared/
    │       ├── Rendering/             # Court rendering engine
    │       ├── Resources/             # Assets & templates
    │       │   └── templates/
    │       │       ├── offense_templates.json  # 12 offense templates
    │       │       └── defense_templates.json  # 5 defense scenarios
    │       └── Tests/
    └── android/                       # Android app (v1.1)
        └── README.md
```

## Core Features (V1)

### 1. Authentication
- **Sign In Methods:** Apple, Google, Email magic link
- **First-time flow:** Display name + role selection (Coach/Player)
- **Firebase Auth** with persistent sessions

### 2. Teams
- **Coach:** Create team, generate join code/invite link
- **Player:** Join team via code
- **Role-based permissions** enforced by Firestore security rules

### 3. Sets (Offense) & Defense Scenarios
- **Parametric editing system:** Named spots + action catalog (NO freeform drawing)
- **Preloaded templates:** 12 offense sets, 5 defense scenarios (ships with app)
- **Coach can:**
  - Duplicate templates to team playbook
  - Edit spot positions, action types, step labels/notes
  - Enable/disable steps
  - Reorder steps
- **Player can:**
  - View playback only
  - Focus on their position (POV emphasis)

### 4. Playback + POV
- **Half-court rendering:** SwiftUI Canvas with court geometry
- **Step navigation:** Big Prev/Next buttons
- **POV focus selector:** Emphasize positions 1-5
- **Camera bias:** Subtle, bounded framing toward focus player
- **Phone-first UI:** Optimized for iPhone portrait

### 5. Notes (Text + Audio)
- **Attach to:** Set, Step (optional), Defense Scenario, Practice, Film
- **Targeting:**
  - ALL (team-wide)
  - POSITION (1-5)
  - PLAYER (specific roster member)
- **Audio:** Record/play via Firebase Storage
- **No replies or threads**

### 6. Film References
- **External links only** (YouTube, Vimeo, Hudl, etc.)
- **Optional timecodes:** start/end seconds
- **Attach to:** Set, Defense Scenario, Practice
- **Coach can add notes** (text/audio) to film references

### 7. Practice Sessions (Curriculum)
- **Coach creates:** Title, date/time (optional), focus note
- **Attach:** Sets, defense scenarios, film references
- **Publish triggers push notification** to players

### 8. Publishing + Push Notifications
- **Coach edits drafts freely** (no spam)
- **Explicit Publish action:**
  - Increments playbook version
  - Sets `publishedAt` timestamp
  - Triggers FCM push to all active players
- **Practice updates** similarly trigger push

## Tech Stack

### Backend
- **Firebase:**
  - **Authentication:** Apple, Google, Email Link
  - **Firestore:** All structured data (teams, sets, defense, practices, notes, film)
  - **Storage:** Audio notes (M4A format)
  - **Cloud Functions:** Push notification triggers (TypeScript)
  - **Cloud Messaging (FCM):** iOS/Android push notifications

### iOS (v1)
- **SwiftUI** (iOS 16+)
- **Architecture:** MVVM
- **Rendering:** SwiftUI Canvas + CoreGraphics
- **Firebase SDK:** Auth, Firestore, Storage, Messaging

### Android (v1.1)
- **Kotlin + Jetpack Compose**
- **Player-first:** Playback, notes, film, practices
- **Coach-lite:** Optional later

## Setup Instructions

### Prerequisites
- **iOS Development:**
  - Xcode 15+
  - Swift 5.9+
  - CocoaPods or Swift Package Manager
- **Firebase:**
  - Firebase project created
  - iOS app registered
  - `GoogleService-Info.plist` downloaded
- **Node.js:** 18+ (for Cloud Functions)

### Firebase Setup

1. **Create Firebase Project:**
   ```bash
   # Visit https://console.firebase.google.com
   # Create new project: "INSTALL"
   # Enable Authentication, Firestore, Storage, Cloud Messaging
   ```

2. **Configure Authentication:**
   - Enable **Sign in with Apple**
   - Enable **Google** (configure OAuth)
   - Enable **Email Link** (passwordless)

3. **Deploy Firestore Rules & Indexes:**
   ```bash
   cd firebase
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

4. **Deploy Storage Rules:**
   ```bash
   firebase deploy --only storage
   ```

5. **Deploy Cloud Functions:**
   ```bash
   cd firebase/functions
   npm install
   npm run build
   firebase deploy --only functions
   ```

### iOS Setup

1. **Install Dependencies:**
   ```bash
   cd mobile/ios
   pod install  # or use SPM
   ```

2. **Add `GoogleService-Info.plist`:**
   - Download from Firebase Console
   - Add to `INSTALL/` folder in Xcode

3. **Configure Signing:**
   - Open `INSTALL.xcworkspace`
   - Select target → Signing & Capabilities
   - Enable **Sign in with Apple** capability
   - Enable **Push Notifications** capability
   - Enable **Background Modes** → Remote notifications

4. **Build & Run:**
   ```bash
   # Open in Xcode
   open INSTALL.xcworkspace

   # Or build from CLI
   xcodebuild -workspace INSTALL.xcworkspace -scheme INSTALL -configuration Debug
   ```

## Data Model Overview

### Firestore Collections

```
users/{userId}
  - displayName: string
  - createdAt: timestamp
  - lastSeenAt: timestamp (optional)

teams/{teamId}
  - name: string
  - createdBy: userId
  - joinCode: string (6-char, rotatable)
  - playbookVersion: int
  - playbookPublishedAt: timestamp (optional)

  /members/{userId}
    - role: "coach" | "player"
    - displayNameOverride: string (optional)
    - jerseyNumber: string (optional)
    - status: "active" | "removed"
    - fcmToken: string (optional, for push)

  /sets/{setId}
    - name: string
    - category: "horns" | "motion" | "flex" | ...
    - isTemplate: boolean
    - sourceTemplateId: string (optional)
    - updatedAt: timestamp
    - steps: [Step] (array)

  /defense/{scenarioId}
    - (same structure as sets)

  /practices/{practiceId}
    - title: string
    - startAt: timestamp (optional)
    - location: string (optional)
    - focusText: string (optional)
    - attachments: {setIds: [], defenseIds: []}
    - publishedAt: timestamp (optional)
    - updatedAt: timestamp

  /notes/{noteId}
    - attachmentType: "set" | "step" | "defense" | "practice" | "film"
    - attachmentId: string
    - stepIndex: int (optional)
    - targetType: "ALL" | "POSITION" | "PLAYER"
    - targetId: null | "1"-"5" | userId
    - text: string (optional)
    - audio: {storagePath, durationMs} (optional)
    - createdBy: userId
    - createdAt: timestamp

  /film/{filmId}
    - attachmentType: "set" | "defense" | "practice"
    - attachmentId: string
    - targetType: "ALL" | "POSITION" | "PLAYER"
    - targetId: null | "1"-"5" | userId
    - url: string
    - startSeconds: double (optional)
    - endSeconds: double (optional)
    - noteText: string (optional)
    - noteAudioStoragePath: string (optional)
    - createdBy: userId
```

### Spots & Actions (Parametric System)

**Spots** (normalized coordinates [0..1] on half-court):
- `top`, `slot_l`, `slot_r`
- `wing_l`, `wing_r`
- `corner_l`, `corner_r`
- `shortcorner_l`, `shortcorner_r`
- `elbow_l`, `elbow_r`
- `lowpost_l`, `lowpost_r`
- `dunker_l`, `dunker_r`

**Action Types:**
- `spot_up`, `cut`, `replace`, `lift`, `drift`
- `screen`, `down_screen`, `flare_screen`, `ball_screen`
- `handoff`, `roll`, `pop`, `slip`
- `post_up`, `duck_in`, `flash`, `seal`, `decoy`

**Step Model:**
```swift
struct Step {
    let index: Int
    var label: String
    var note: String?
    var enabled: Bool
    var emphasisPosition: Int? // 1-5
    var playerActions: [PlayerAction] // Always 5
}

struct PlayerAction {
    let position: Int // 1-5
    var actionType: ActionType
    var fromSpotId: String
    var toSpotId: String? // Optional for stationary
    var targetPosition: Int? // Optional for screens
    var hasBall: Bool
}
```

## Security

### Firestore Security Rules
- **Users** can only read/write their own document
- **Teams:**
  - Read: Any active team member
  - Write: Coaches only
- **Sets/Defense/Practices/Notes/Film:**
  - Read: Any active team member
  - Create/Update/Delete: Coaches only

### Storage Security Rules
- **Audio notes:**
  - Upload: Coaches only
  - Read: Any active team member
  - Max size: 10MB
  - Content-Type: `audio/*`

## Testing

### Unit Tests (iOS)
Located in `mobile/ios/INSTALL/Tests/`:
- **TemplateDecodeTests:** Verify JSON templates decode correctly
- **SpotMappingTests:** Ensure spot coordinates are deterministic
- **NotesTargetingTests:** Validate note composition logic (ALL + POSITION + PLAYER)
- **PublishVersioningTests:** Confirm version increments only on explicit publish
- **RoleGatingTests:** Verify permission logic

Run tests:
```bash
xcodebuild test -workspace INSTALL.xcworkspace -scheme INSTALL -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Integration Tests (Manual)
- **Publish triggers push:** Coach publishes → Player receives notification
- **Security rules enforce permissions:** Player cannot write via Firestore
- **Audio upload/playback:** Record note → Upload → Download → Play
- **Film links open correctly:** Tap film → Open in web view/browser → Return to app

## Known Limitations (V1)

1. **No freeform drawing:** Coach must start from templates and edit parametrically
2. **No step-level notes YET:** Notes attach to Set/Defense/Practice (Step-level if easy)
3. **No deep links for invites:** Join via 6-character code only (deep links in v1.1)
4. **Single team per user:** Multi-team support deferred
5. **No branching logic:** All steps are linear
6. **No film hosting:** External links only
7. **No social features:** No chat, comments, reactions, read receipts
8. **No analytics dashboard:** Basic usage only

## V1.1 Roadmap (Allowed Extensions)

- **Deep links** for team invites
- **Step-level notes** (if not in v1)
- **Import/export sets** as JSON
- **More templates** (community-submitted)
- **Basic quiz mode:** "What's your next action?" (no social scoring)
- **Android player app** (Kotlin + Compose)
- **Coach-lite on Android** (optional)

## Explicitly NOT Planned

- Video hosting/editing
- Messaging/chat
- Parent portal
- Payments/subscriptions
- Attendance tracking
- Freeform play designer
- Advanced analytics
- Social feeds

## App Store Copy

**Subtitle:** Basketball Coaching & Study

**Description:**
INSTALL helps coaches teach sets, coverages, and habits—and helps players study their role between practices.

**Features:**
- Step-by-step sets and defensive scenarios
- Role-focused POV study for players
- Coach notes (text and audio), including position and player-specific reminders
- Film links with instruction (no uploads required)
- Practice sessions that link what to learn with what to run

## Contributing

This is a coach-led, structured system. Contributions should respect the core constraints:
- Phone-first UI
- Parametric editing (no freeform drawing in v1)
- Linear steps (no branching)
- Coach-authoritative (no player edits)
- Firebase backend (cross-platform required)

## License

Proprietary. All rights reserved.

## Contact

For questions or feedback, see `/help` in the app or file an issue at [repository URL].

---

**Built with:**
- SwiftUI (iOS)
- Firebase (Backend)
- TypeScript (Cloud Functions)
- Love for the game 🏀
