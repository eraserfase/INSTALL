# Xcode Project Setup Guide

This guide walks you through creating the Xcode project for INSTALL.

## Prerequisites

- macOS 13+ (Ventura or later)
- Xcode 15+
- iOS 16+ SDK
- Firebase project created and configured
- CocoaPods or Swift Package Manager

## Step 1: Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose **iOS** → **App**
4. Project settings:
   - **Product Name:** INSTALL
   - **Team:** Your Apple Developer Team
   - **Organization Identifier:** com.yourcompany
   - **Bundle Identifier:** com.yourcompany.INSTALL
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (we'll add Core Data if needed later)
   - **Include Tests:** Yes

5. Save to: `INSTALL/mobile/ios/`

## Step 2: Add Firebase Dependencies

### Option A: Swift Package Manager (Recommended)

1. In Xcode, File → Add Package Dependencies
2. Enter Firebase SDK URL:
   ```
   https://github.com/firebase/firebase-ios-sdk.git
   ```
3. Select version: 10.20.0 or later
4. Add these packages to target:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseMessaging

### Option B: CocoaPods

1. Create `Podfile` in `mobile/ios/`:
   ```ruby
   platform :ios, '16.0'
   use_frameworks!

   target 'INSTALL' do
     pod 'Firebase/Auth'
     pod 'Firebase/Firestore'
     pod 'Firebase/Storage'
     pod 'Firebase/Messaging'
   end
   ```

2. Run:
   ```bash
   cd mobile/ios
   pod install
   ```

3. Open `INSTALL.xcworkspace` (not `.xcodeproj`)

## Step 3: Add GoogleService-Info.plist

1. Download `GoogleService-Info.plist` from Firebase Console:
   - Go to Project Settings → Your iOS App
   - Download configuration file

2. Drag `GoogleService-Info.plist` into Xcode project root
   - ✅ Check "Copy items if needed"
   - ✅ Add to target: INSTALL

## Step 4: Configure Capabilities

1. Select project in Navigator → Target: INSTALL → Signing & Capabilities

2. Add **Sign in with Apple**:
   - Click "+ Capability"
   - Search "Sign in with Apple"
   - Add

3. Add **Push Notifications**:
   - Click "+ Capability"
   - Search "Push Notifications"
   - Add

4. Add **Background Modes**:
   - Click "+ Capability"
   - Search "Background Modes"
   - Add
   - ✅ Check "Remote notifications"

## Step 5: Update Info.plist

Replace the generated `Info.plist` with the one provided in this repo at `mobile/ios/Info.plist`.

Key additions:
- Microphone usage description (for audio notes)
- Background modes (remote notifications)
- URL schemes (for Sign in with Apple)

## Step 6: Add Source Files

The source files are already organized in this repo. Add them to Xcode:

1. Right-click on INSTALL folder in Navigator → "Add Files to INSTALL"

2. Select these folders (ensure "Create groups" is selected):
   - `App/`
   - `Models/`
   - `Services/`
   - `ViewModels/`
   - `Views/`
   - `Rendering/`
   - `Resources/`

3. For `Resources/templates/`, ensure:
   - ✅ "Copy items if needed"
   - ✅ Add to target: INSTALL

## Step 7: Configure Build Settings

1. Build Settings → Search "Swift Language Version"
   - Set to **Swift 5**

2. Build Settings → Search "iOS Deployment Target"
   - Set to **iOS 16.0**

3. Build Settings → Search "ENABLE_PREVIEWS"
   - Set to **Yes** (for SwiftUI Previews)

## Step 8: Add Entitlements

Xcode should auto-generate `INSTALL.entitlements` when you add capabilities. Verify it includes:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

## Step 9: Build & Run

1. Select target device: iPhone 15 (or any iOS 16+ simulator)
2. Product → Build (⌘B)
3. Fix any build errors (check import statements, file paths)
4. Product → Run (⌘R)

## Step 10: Configure for Real Device (Optional)

For testing on physical iPhone:

1. Connect iPhone via USB
2. Select your iPhone as build destination
3. Signing & Capabilities → Team: Select your Apple Developer account
4. Build and run

For Sign in with Apple to work on device:
- You need a valid Apple Developer Program membership
- App ID must have Sign in with Apple enabled in Developer Portal

## Common Build Issues

### Issue: "No such module FirebaseAuth"

**Solution:**
- Verify Firebase packages are added in Package Dependencies
- Clean build folder: Product → Clean Build Folder (⌘⇧K)
- Restart Xcode

### Issue: "Cannot find GoogleService-Info.plist"

**Solution:**
- Ensure file is added to project target
- Check Target Membership in File Inspector

### Issue: "Signing for INSTALL requires a development team"

**Solution:**
- Select your team in Signing & Capabilities
- Or use "Sign to Run Locally" for simulator-only testing

### Issue: Missing Resources (templates JSONs)

**Solution:**
- Verify `Resources/templates/` is added to target
- Check Build Phases → Copy Bundle Resources

## Next Steps

After successful build:

1. **Run unit tests:**
   ```
   Product → Test (⌘U)
   ```

2. **Connect to Firebase:**
   - Create Firebase project
   - Deploy Firestore rules: `firebase deploy --only firestore:rules`
   - Deploy Cloud Functions: `cd firebase/functions && npm run deploy`

3. **Test authentication:**
   - Sign in with Apple (requires real device or configured simulator)
   - Email link sign-in

4. **Test team creation:**
   - Create team as coach
   - Join team as player (use second simulator)

## Development Tips

- Use SwiftUI Previews for rapid UI iteration
- Enable Firebase debug logging in AppDelegate:
  ```swift
  FirebaseConfiguration.shared.setLoggerLevel(.debug)
  ```
- Use Firebase Emulator Suite for local testing:
  ```bash
  firebase emulators:start
  ```

## Production Checklist

Before App Store submission:

- [ ] Change `aps-environment` to `production` in entitlements
- [ ] Update Firebase with production APNs certificate
- [ ] Remove debug logging
- [ ] Test all auth flows on real devices
- [ ] Verify push notifications work in production
- [ ] Submit for TestFlight beta testing

## Support

For issues with Xcode setup:
- Check official Firebase iOS setup: https://firebase.google.com/docs/ios/setup
- Check Xcode documentation
- File issue in this repo
