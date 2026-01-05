# INSTALL - Deployment Guide

Complete guide to deploying INSTALL to production.

## Prerequisites

- Firebase account (Blaze plan for Cloud Functions)
- Apple Developer Program membership ($99/year)
- Xcode 15+ with iOS 16+ SDK
- Node.js 18+
- CocoaPods or Swift Package Manager

---

## Phase 1: Firebase Setup

### 1.1 Create Firebase Project

1. Visit https://console.firebase.google.com
2. Click "Add project"
3. Project name: **INSTALL**
4. Enable Google Analytics (optional but recommended)
5. Choose your Analytics account or create new
6. Click "Create project"

### 1.2 Register iOS App

1. In Firebase Console → Project Settings
2. Click iOS icon to add iOS app
3. Enter details:
   - **Bundle ID**: `com.yourcompany.INSTALL`
   - **App nickname**: INSTALL iOS
   - **App Store ID**: (leave blank for now)
4. Download `GoogleService-Info.plist`
5. Save securely (you'll add this to Xcode later)

### 1.3 Enable Authentication

1. Firebase Console → Build → Authentication
2. Click "Get started"
3. Enable providers:
   - **Email/Password**: Enable (for email link auth)
   - **Google**: Enable, configure OAuth consent
   - **Apple**: Enable, configure Apple Developer settings

#### Apple Sign In Configuration

1. In Apple Developer Console:
   - Identifiers → App IDs → Your App ID
   - Enable "Sign in with Apple"
   - Configure Services ID if needed
2. Back in Firebase:
   - Enter your Apple Team ID
   - Upload private key (.p8 file)

### 1.4 Set Up Firestore

1. Firebase Console → Build → Firestore Database
2. Click "Create database"
3. Choose **Start in production mode** (we'll deploy rules next)
4. Select region (choose closest to your users)
5. Click "Enable"

### 1.5 Set Up Storage

1. Firebase Console → Build → Storage
2. Click "Get started"
3. Choose **Start in production mode**
4. Use same region as Firestore
5. Click "Done"

### 1.6 Deploy Firestore Rules & Indexes

```bash
cd /path/to/INSTALL/firebase

# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init

# Select:
# - Firestore (rules and indexes)
# - Storage
# - Functions

# Use existing project: INSTALL

# Deploy rules and indexes
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

**Verify deployment:**
- Firestore Console → Rules → Should see role-based permissions
- Storage Console → Rules → Should see team-based permissions

### 1.7 Deploy Cloud Functions

```bash
cd /path/to/INSTALL/firebase/functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy functions
firebase deploy --only functions

# Expected output:
# ✓ functions[notifyPlaybookPublish]
# ✓ functions[notifyPracticePublish]
```

**Verify deployment:**
```bash
firebase functions:log --only notifyPlaybookPublish
```

### 1.8 Configure Cloud Messaging (FCM)

1. Firebase Console → Project Settings → Cloud Messaging
2. iOS app configuration:
   - Upload APNs Authentication Key (.p8 file)
   - Or upload APNs Certificate (if using cert-based auth)
3. Note your **Server Key** (for testing)

---

## Phase 2: iOS App Setup

### 2.1 Create Xcode Project

Follow the detailed guide in `mobile/ios/XCODE_SETUP.md`:

```bash
# 1. Open Xcode
# 2. File → New → Project → iOS App
# 3. Product Name: INSTALL
# 4. Bundle Identifier: com.yourcompany.INSTALL
# 5. Interface: SwiftUI
# 6. Language: Swift
```

### 2.2 Add Firebase SDK

**Option A: Swift Package Manager (Recommended)**

1. File → Add Package Dependencies
2. URL: `https://github.com/firebase/firebase-ios-sdk.git`
3. Version: 10.20.0 or later
4. Add packages:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseMessaging

**Option B: CocoaPods**

```bash
cd mobile/ios
pod install
open INSTALL.xcworkspace
```

### 2.3 Add GoogleService-Info.plist

1. Drag `GoogleService-Info.plist` into Xcode project navigator
2. ✅ Check "Copy items if needed"
3. ✅ Add to target: INSTALL
4. Verify it's included in Build Phases → Copy Bundle Resources

### 2.4 Configure Capabilities

**Signing & Capabilities:**

1. Select target: INSTALL
2. Signing & Capabilities tab
3. Add capabilities:
   - **Sign in with Apple**
   - **Push Notifications**
   - **Background Modes** → Remote notifications

**Entitlements (auto-generated):**

```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
<key>aps-environment</key>
<string>development</string>  <!-- Change to "production" for App Store -->
```

### 2.5 Update Info.plist

Ensure `Info.plist` includes:

```xml
<!-- Microphone for audio notes -->
<key>NSMicrophoneUsageDescription</key>
<string>INSTALL needs microphone access to record audio notes.</string>

<!-- Background modes -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 2.6 Build & Test

```bash
# Clean build folder
⌘⇧K

# Build
⌘B

# Run on simulator
⌘R
```

**Test checklist:**
- [ ] App launches without crashes
- [ ] Sign in with Apple works
- [ ] Create team (coach)
- [ ] Join team via code (player, use second simulator)
- [ ] Browse templates
- [ ] Duplicate template to team playbook
- [ ] Edit set (change spots/actions)
- [ ] Save changes (verify Firestore updated)

---

## Phase 3: Push Notifications Setup

### 3.1 APNs Configuration

**Option A: Authentication Key (.p8) - Recommended**

1. Apple Developer Console → Certificates, IDs & Profiles
2. Keys → Create new key
3. Name: "INSTALL Push Notifications"
4. Enable: Apple Push Notifications service (APNs)
5. Download .p8 file (save securely, can't re-download)
6. Note Key ID and Team ID
7. Upload to Firebase Console → Cloud Messaging

**Option B: APNs Certificate**

1. In Xcode: Request Certificate Signing Request (CSR)
2. Keychain Access → Certificate Assistant → Request from CA
3. Save CSR to disk
4. Apple Developer Console → Certificates
5. Create new: Apple Push Notification service SSL
6. Upload CSR, download certificate
7. Open certificate in Keychain
8. Export as .p12
9. Upload to Firebase Console

### 3.2 Register Device for Testing

```bash
# In Xcode, run on real device
# AppDelegate will request push permissions
# FCM token will be stored in Firestore membership document
```

**Verify FCM token storage:**

```javascript
// Firestore Console
teams/{teamId}/members/{userId}
// Should contain field: fcmToken
```

### 3.3 Test Push Notifications

**Test publish notification:**

1. Coach: Edit a set, tap "Publish"
2. Cloud Function `notifyPlaybookPublish` triggers
3. Player device should receive push:
   - "Playbook Updated"
   - "{Team Name} playbook has been updated..."

**Manual test via Firebase Console:**

1. Firebase Console → Engage → Cloud Messaging
2. Send test message
3. Enter FCM token from Firestore
4. Verify delivery

---

## Phase 4: App Store Preparation

### 4.1 App Store Connect Setup

1. Visit https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Details:
   - **Platforms**: iOS
   - **Name**: INSTALL
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.yourcompany.INSTALL
   - **SKU**: INSTALL-iOS-2026
4. Click "Create"

### 4.2 App Information

**Category:**
- Primary: Sports
- Secondary: Education

**Content Rights:**
- [ ] Does not contain third-party content

**Age Rating:**
- 4+ (No objectionable content)

### 4.3 Prepare Assets

**App Icon:**
- Size: 1024x1024px
- No transparency
- No rounded corners (iOS adds automatically)

**Screenshots (Required):**
- iPhone 6.7" (iPhone 15 Pro Max): 1290x2796px (3-10 images)
- iPhone 6.5" (iPhone 11 Pro Max): 1242x2688px
- iPhone 5.5" (iPhone 8 Plus): 1242x2208px

**Recommended screenshots:**
1. Sign in screen
2. Team join (player view)
3. Playback with court rendering
4. Coach editing (spot/action dropdowns)
5. Notes with audio waveform

**App Preview Video (Optional):**
- 15-30 seconds
- Show: Join team → Browse sets → Playback with POV focus

### 4.4 App Store Listing

**Subtitle (30 chars):**
```
Basketball Coaching & Study
```

**Description:**
```
INSTALL helps coaches teach sets, coverages, and habits—and helps players study their role between practices.

FEATURES:
• Step-by-step offensive sets and defensive scenarios
• Role-focused POV study mode for players
• Coach notes (text and audio), including position-specific reminders
• Film references with timecodes (no uploads required)
• Practice curriculum that links sets to study with drills to run
• Push notifications when playbook is updated

FOR COACHES:
• Create teams and invite players via join code
• Duplicate from 12+ preloaded templates (Horns, UCLA, Flex, Motion, etc.)
• Edit plays using parametric system (spots + actions)
• Attach text and audio notes to sets, steps, or players
• Publish playbook updates to notify all players

FOR PLAYERS:
• Join team with 6-character code
• Study sets and defense scenarios on your phone
• Focus on your position with POV emphasis
• Listen to coach notes (team, position, or personal)
• Watch film references linked to plays

PHONE-FIRST DESIGN:
Every diagram is legible on iPhone screens. No tiny, hand-drawn plays. No social clutter. Just clean, coach-led learning.

PRIVACY:
• No chat, comments, or social features
• Role-based permissions (players are read-only)
• External film links only (no video hosting)

REQUIREMENTS:
• iOS 16.0 or later
• Internet connection for real-time sync
```

**Keywords (100 chars):**
```
basketball,coaching,playbook,plays,defense,youth,hs,aau,study,film,notes,practice,sets
```

**Support URL:**
```
https://yourwebsite.com/install/support
```

**Privacy Policy URL:**
```
https://yourwebsite.com/install/privacy
```

### 4.5 Build for Release

**Update build configuration:**

```swift
// In InstallApp.swift, remove debug logging:
FirebaseConfiguration.shared.setLoggerLevel(.min)  // Keep this
```

**Update entitlements:**

```xml
<!-- Change from development to production -->
<key>aps-environment</key>
<string>production</string>
```

**Archive build:**

1. Xcode → Product → Scheme → Edit Scheme
2. Run → Build Configuration → **Release**
3. Product → Archive
4. Organizer opens with archive
5. Distribute App → App Store Connect
6. Upload build

**Wait for processing** (10-30 minutes)

### 4.6 TestFlight Beta Testing

1. App Store Connect → TestFlight
2. Select uploaded build
3. Add Internal Testers:
   - Your dev team (up to 100 testers)
   - Automatic distribution
4. Add External Testers:
   - Requires App Review
   - Submit "What to Test" notes
   - Invite via email

**Beta test checklist:**
- [ ] All auth methods work (Apple, Google, Email)
- [ ] Push notifications deliver
- [ ] Audio recording works
- [ ] Film links open correctly
- [ ] Publish triggers notification
- [ ] Security rules prevent unauthorized writes

### 4.7 Submit for Review

**Before submission:**
- [ ] Test on iPhone (not just simulator)
- [ ] All screenshots uploaded
- [ ] App privacy filled out
- [ ] Export compliance: No encryption (or proper docs)
- [ ] Content Rights acknowledged

**Version 1.0 Release Notes:**
```
INSTALL makes it easy for basketball coaches to teach sets and coverages, and for players to study their role on their phones between practices.

v1.0 Features:
• 12+ preloaded offense templates (Horns, UCLA, Flex, Motion, etc.)
• 5 defense scenarios (PnR coverages, zone rotations)
• Parametric play editing (spots + actions)
• POV study mode (focus on your position)
• Text and audio notes (team, position, or player-specific)
• Film reference links with timecodes
• Practice curriculum management
• Push notifications for playbook updates

Built phone-first. No freeform drawing. Clean, coach-led learning.
```

**Submit for review:**

1. App Store Connect → App Store → 1.0 Prepare for Submission
2. Fill all required fields
3. Click "Submit for Review"
4. Review time: 1-3 days (typically 24 hours)

---

## Phase 5: Post-Launch

### 5.1 Monitor Cloud Functions

```bash
# View function logs
firebase functions:log

# Filter by function
firebase functions:log --only notifyPlaybookPublish

# Tail logs in real-time
firebase functions:log --tail
```

**Watch for:**
- Failed FCM sends (invalid tokens)
- Firestore permission errors
- Function timeouts

### 5.2 Monitor Firestore Usage

**Firebase Console → Usage:**
- Document reads/writes
- Storage usage
- Cloud Functions invocations

**Set budget alerts:**
1. Firebase Console → Usage and billing
2. Set monthly budget
3. Add alerts at 50%, 75%, 90%

### 5.3 User Feedback

**App Store reviews:**
- Respond to all reviews within 48 hours
- Address bugs reported in reviews

**Crash reports:**
- Xcode → Organizer → Crashes
- Firebase → Crashlytics (if enabled)

### 5.4 Update Cycle

**Recommended update cadence:**
- **Minor updates (bug fixes)**: Every 2 weeks
- **Feature updates**: Monthly
- **Major versions**: Quarterly

**v1.1 Roadmap (see docs/13_KNOWN_LIMITATIONS_AND_ROADMAP.md):**
- Deep links for team invites
- Step-level notes (if not in v1)
- Import/export sets (JSON)
- Android player app
- More templates

---

## Troubleshooting

### Firebase Functions Not Triggering

**Check:**
```bash
firebase functions:log --only notifyPlaybookPublish

# If no logs appear:
# 1. Verify function deployed: firebase functions:list
# 2. Check Firestore rules allow writes
# 3. Verify playbookVersion increments in Firestore Console
```

### Push Notifications Not Delivering

**Debug steps:**
1. Verify FCM token stored in Firestore membership
2. Check APNs certificate/key uploaded to Firebase
3. Verify `aps-environment` in entitlements
4. Test with Firebase Console → Cloud Messaging → Send test message
5. Check device Notification Settings → INSTALL → Allow Notifications

### Sign in with Apple Failing

**Check:**
1. Bundle ID matches Apple Developer Console
2. "Sign in with Apple" capability enabled in Xcode
3. App ID has "Sign in with Apple" enabled in Developer Console
4. Firebase has Apple provider enabled

### Firestore Permission Denied

**Debug:**
1. Check Firestore Console → Rules
2. Verify membership document exists: `teams/{teamId}/members/{userId}`
3. Verify membership status is "active"
4. Check role is "coach" for write operations

---

## Cost Estimates

### Firebase (Blaze Plan)

**Firestore:**
- Reads: 50,000 free/day → $0.06 per 100K after
- Writes: 20,000 free/day → $0.18 per 100K after
- Storage: 1 GB free → $0.18/GB after

**Storage (audio notes):**
- 5 GB free → $0.026/GB after
- Downloads: 1 GB free/day → $0.12/GB after

**Cloud Functions:**
- Invocations: 2M free/month → $0.40 per 1M after
- Compute time: 400K GB-sec free → $0.0000025 per GB-sec after

**Cloud Messaging:**
- Completely free

**Estimated cost for 50 teams (750 players):**
- Firestore: ~$2/month
- Storage: ~$1/month
- Functions: <$1/month
- **Total: ~$4/month**

### Apple

- Developer Program: $99/year
- No in-app purchases → No App Store commission

---

## Support & Maintenance

**Documentation:**
- README.md
- XCODE_SETUP.md
- This deployment guide

**Community:**
- GitHub Issues: Report bugs
- App Store reviews: User feedback

**Contact:**
- Support email: support@yourcompany.com
- Website: https://yourwebsite.com/install

---

## Compliance

**GDPR/Privacy:**
- No personal data collected beyond email/name
- No third-party tracking
- Privacy policy required

**COPPA (if targeting youth <13):**
- Parental consent required
- No behavioral advertising
- Data retention policies

**App Store Guidelines:**
- No objectionable content
- No private APIs
- No misleading functionality

---

**You're ready to launch! 🚀**

Good luck with INSTALL!
