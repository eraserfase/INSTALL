# INSTALL iOS App

Complete iOS application for basketball coaching and player study.

## Overview

This directory contains the SwiftUI-based iOS app for INSTALL. The app uses MVVM architecture with Firebase backend integration.

## Quick Start

### Prerequisites

- macOS with Xcode 15.0 or later
- iOS 16.0+ deployment target
- Apple Developer account (for device testing and App Store deployment)
- Firebase project configured (see `../../firebase/` directory)

### Option 1: Swift Package Manager (Recommended)

1. **Create Xcode Project**
   ```
   - Open Xcode
   - File → New → Project
   - Choose "iOS App"
   - Product Name: INSTALL
   - Bundle Identifier: com.yourcompany.INSTALL
   - Interface: SwiftUI
   - Language: Swift
   ```

2. **Add Source Files**
   - Copy all files from `INSTALL/` directory to your Xcode project
   - Ensure all .swift files are added to the target

3. **Add Firebase SDK via SPM**
   ```
   - File → Add Package Dependencies
   - URL: https://github.com/firebase/firebase-ios-sdk.git
   - Version: 10.20.0 or later
   - Add packages:
     • FirebaseAuth
     • FirebaseFirestore
     • FirebaseStorage
     • FirebaseMessaging
   ```

4. **Add GoogleService-Info.plist**
   - Download from Firebase Console → Project Settings → iOS App
   - Drag into Xcode project
   - Ensure "Copy items if needed" is checked
   - Add to INSTALL target

5. **Configure Capabilities**
   - Select project → Target → Signing & Capabilities
   - Add capability: Sign in with Apple
   - Add capability: Push Notifications
   - Add capability: Background Modes → Remote notifications

6. **Build and Run**
   ```
   ⌘B to build
   ⌘R to run
   ```

### Option 2: CocoaPods

1. **Install CocoaPods** (if not already installed)
   ```bash
   sudo gem install cocoapods
   ```

2. **Install Dependencies**
   ```bash
   cd mobile/ios
   pod install
   ```

3. **Open Workspace**
   ```bash
   open INSTALL.xcworkspace
   ```

4. Follow steps 4-6 from Option 1 above

## Project Structure

```
INSTALL/
├── App/
│   └── InstallApp.swift              # App entry point
├── Models/
│   └── Domain/                       # Core domain models
│       ├── Team.swift
│       ├── Membership.swift
│       ├── SetModel.swift
│       ├── DefenseScenario.swift
│       ├── Step.swift
│       ├── PlayerAction.swift
│       ├── Spots.swift
│       ├── Note.swift
│       ├── FilmRef.swift
│       └── PracticeSession.swift
├── Services/
│   ├── Auth/                         # Authentication
│   │   └── AuthService.swift
│   ├── Teams/                        # Team management
│   │   └── TeamService.swift
│   ├── Content/                      # Content services
│   │   ├── SetsService.swift
│   │   ├── DefenseService.swift
│   │   ├── NotesService.swift
│   │   ├── FilmService.swift
│   │   └── PracticesService.swift
│   ├── Infrastructure/               # Firebase integration
│   │   ├── FirestoreService.swift
│   │   ├── StorageService.swift
│   │   └── MessagingService.swift
│   └── Templates/
│       └── TemplatesLoader.swift
├── ViewModels/
│   ├── AuthViewModel.swift           # Auth state
│   ├── TeamViewModel.swift           # Team/membership
│   ├── PlaybackViewModel.swift       # Playback navigation
│   ├── LibraryViewModel.swift        # Sets/defense library
│   ├── EditSetViewModel.swift        # Editing state
│   └── NotesViewModel.swift          # Notes CRUD
├── Views/
│   ├── Auth/                         # Authentication
│   │   ├── SignInView.swift
│   │   └── RoleSelectView.swift
│   ├── Teams/                        # Team management
│   │   ├── TeamGateView.swift
│   │   ├── CreateTeamView.swift
│   │   └── JoinTeamView.swift
│   ├── Playback/                     # Court rendering
│   │   └── PlaybackView.swift
│   ├── Editing/                      # Coach editing
│   │   ├── EditSetView.swift
│   │   ├── EditStepView.swift
│   │   └── EditPlayerActionView.swift
│   ├── Practices/                    # Practice management
│   │   ├── PracticeDetailView.swift
│   │   └── EditPracticeView.swift
│   └── Shared/                       # Reusable components
│       ├── CourtCanvasView.swift
│       ├── NotesSheet.swift
│       ├── NoteComposerView.swift
│       ├── AudioRecorderView.swift
│       ├── FilmSheet.swift
│       ├── AddFilmLinkView.swift
│       └── TemplatePickerView.swift
├── Rendering/
│   ├── CourtGeometry.swift           # Coordinate transformation
│   └── POVCamera.swift               # Focus emphasis
├── Resources/
│   └── templates/
│       ├── offense_templates.json
│       └── defense_templates.json
├── Tests/
│   ├── SpotMappingTests.swift
│   ├── NotesTargetingTests.swift
│   ├── TemplateDecodeTests.swift
│   ├── PublishVersioningTests.swift
│   └── RoleGatingTests.swift
├── Info.plist                        # App configuration
└── XCODE_SETUP.md                    # Detailed setup guide
```

## Architecture

### MVVM Pattern

- **Models**: Domain entities with Codable conformance for Firestore
- **Views**: SwiftUI views with no business logic
- **ViewModels**: ObservableObject classes managing state and business logic
- **Services**: Abstract Firebase operations, injected into ViewModels

### Key Services

| Service | Purpose |
|---------|---------|
| **AuthService** | Sign in with Apple, Google, Email magic link |
| **TeamService** | Team CRUD, membership, publish with version increment |
| **SetsService** | Offensive sets CRUD + real-time listeners |
| **DefenseService** | Defensive scenarios CRUD |
| **NotesService** | Text + audio notes with targeting (ALL/POSITION/PLAYER) |
| **FilmService** | External film links with timecodes |
| **PracticesService** | Practice curriculum with attached content |
| **StorageService** | Audio upload/download (Firebase Storage) |
| **MessagingService** | FCM token registration |

### Environment Object Pattern

The app uses `AppEnvironment` to inject services:

```swift
class AppEnvironment: ObservableObject {
    let authService: AuthService
    let teamService: TeamService
    let setsService: SetsService
    // ... other services
}

@main
struct InstallApp: App {
    @StateObject private var environment = AppEnvironment()
    @StateObject private var authViewModel: AuthViewModel

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
                .environmentObject(authViewModel)
        }
    }
}
```

## Key Features

### Parametric Play System

14 named court spots with normalized coordinates [0..1]:
- `top`, `left_wing`, `right_wing`, `left_corner`, `right_corner`
- `left_elbow`, `right_elbow`, `left_block`, `right_block`
- `left_slot`, `right_slot`, `high_post`, `dunker_left`, `dunker_right`

17 action types:
- `spot_up`, `cut`, `screen`, `ball_screen`, `roll`, `pop`, `slip`
- `dho`, `post_up`, `iso`, `drive`, `shoot`, `pass`, `rebound`
- `deny`, `help`, `rotate`

### POV Camera System

Focus emphasis for player study:
```swift
// CourtCanvasView applies these to each player token
let opacity = POVCamera.opacity(for: position, focusPosition: focusPosition)
let scale = POVCamera.scale(for: position, focusPosition: focusPosition)

// Position matching focus: opacity 1.0, scale 1.15
// Other positions: opacity 0.4, scale 0.95
```

### Audio Recording

AVAudioRecorder integration with real-time waveform:
```swift
AudioRecorderView { url in
    // Handle recorded audio URL
}

// Configuration: M4A format, 44.1kHz, AAC codec
// Max file size enforced by Storage rules: 10MB
```

### Real-time Sync

Firestore listeners for instant updates:
```swift
// Example: SetsService.observeSets(teamId:)
db.collection("teams").document(teamId)
    .collection("sets")
    .addSnapshotListener { snapshot, error in
        // Updates published @Published var sets
    }
```

## Testing

### Run Unit Tests

```bash
# In Xcode
⌘U

# Or via xcodebuild
xcodebuild test -scheme INSTALL -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Suites

1. **SpotMappingTests**: Validate coordinate transformation determinism
2. **NotesTargetingTests**: Verify ALL/POSITION/PLAYER filtering
3. **TemplateDecodeTests**: Ensure all templates decode correctly
4. **PublishVersioningTests**: Test version increment logic
5. **RoleGatingTests**: Verify permission checks

### Manual Testing Checklist

- [ ] Sign in with Apple (requires physical device)
- [ ] Sign in with Google
- [ ] Sign in with Email magic link
- [ ] Create team as coach → receive join code
- [ ] Join team as player (use second simulator)
- [ ] Browse templates
- [ ] Duplicate template to team playbook
- [ ] Edit set (change spots, action types)
- [ ] Save changes → verify Firestore updated
- [ ] Publish playbook → verify version increments
- [ ] Player receives push notification (device only)
- [ ] Record audio note (device only for microphone)
- [ ] Play audio note
- [ ] Add film reference with timecode
- [ ] Create practice with attached sets
- [ ] Publish practice → verify push notification

## Deployment

See `XCODE_SETUP.md` for detailed Xcode project setup.

See `../../DEPLOYMENT_GUIDE.md` for production deployment (TestFlight, App Store).

### Quick Archive for TestFlight

1. **Update build number**
   - Select project → Target → General
   - Increment Build number

2. **Archive**
   ```
   Product → Archive
   Wait for build to complete
   ```

3. **Upload to App Store Connect**
   ```
   Organizer → Distribute App → App Store Connect
   Upload build
   Wait for processing (10-30 minutes)
   ```

4. **Add to TestFlight**
   ```
   App Store Connect → TestFlight
   Select build → Add to group
   Invite testers
   ```

## Troubleshooting

### Build Errors

**"No such module 'Firebase'"**
- Ensure Firebase packages are added via SPM or CocoaPods
- Clean build folder: ⌘⇧K
- Rebuild: ⌘B

**GoogleService-Info.plist not found**
- Verify file is in project navigator
- Check Build Phases → Copy Bundle Resources includes it

### Runtime Errors

**Sign in with Apple fails**
- Verify capability is enabled
- Check Bundle ID matches Apple Developer Console
- Test on physical device (simulator has limitations)

**Firestore permission denied**
- Verify user is authenticated
- Check membership document exists: `teams/{teamId}/members/{userId}`
- Verify membership status is "active"
- Check role is "coach" for write operations

**Push notifications not delivering**
- Verify APNs certificate/key uploaded to Firebase
- Check FCM token stored in Firestore membership
- Test with Firebase Console → Cloud Messaging
- Ensure device has notifications enabled

### Performance

**Slow Firestore queries**
- Verify composite indexes are deployed (see `firebase/firestore.indexes.json`)
- Use `.limit()` for large collections
- Implement pagination for long lists

**Large app size**
- Enable bitcode (Build Settings → Build Options)
- Use App Thinning (automatic in App Store)
- Optimize images in Assets.xcassets

## Resources

### Documentation

- [XCODE_SETUP.md](XCODE_SETUP.md) - Step-by-step Xcode project creation
- [../../DEPLOYMENT_GUIDE.md](../../DEPLOYMENT_GUIDE.md) - Production deployment
- [../../docs/03_DATA_MODEL_FIRESTORE.md](../../docs/03_DATA_MODEL_FIRESTORE.md) - Firestore schema
- [../../docs/04_ACTIONS_AND_SPOTS.md](../../docs/04_ACTIONS_AND_SPOTS.md) - Parametric system

### External Links

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## License

Proprietary - All rights reserved

## Support

For issues, see GitHub Issues or contact support@yourcompany.com
