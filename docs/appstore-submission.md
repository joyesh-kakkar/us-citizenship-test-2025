# App Store Submission Guide
## Civics Test 2025 — com.maplewood.civicstest2025

---

## Prerequisites Checklist

- [ ] Xcode installed from Mac App Store (~8 GB)
- [ ] Xcode first-launch setup run (`sudo xcodebuild -runFirstLaunch`)
- [ ] CocoaPods installed (`sudo gem install cocoapods`)
- [ ] Apple Developer account created ($99/year)
- [ ] Identity verification approved (1–2 days)
- [ ] Signing configured in Xcode (Automatically manage signing → your team)
- [ ] App icon PNG (1024×1024, **no alpha channel** — iOS rejects transparent icons)
- [ ] Screenshots — iPhone 6.9" and 6.5" sizes required
- [ ] Privacy policy hosted at a public URL

---

## Step 1 — Create Your Apple Developer Account

1. Go to [developer.apple.com/enroll](https://developer.apple.com/enroll)
2. Choose **Individual** enrollment
3. Pay the **$99/year** fee
4. Complete identity verification — Apple verifies via credit card + government ID
5. Wait for approval email (usually within 24–48 hours)

---

## Step 2 — Xcode Setup (run once after Xcode installs)

```bash
# Point developer tools at Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Run first-launch setup (installs iOS simulators etc.)
sudo xcodebuild -runFirstLaunch

# Install CocoaPods (Flutter's iOS dependency manager)
sudo gem install cocoapods
```

Then verify Flutter sees everything:
```bash
flutter doctor
```

Xcode and CocoaPods should both show ✓.

---

## Step 3 — Configure Signing in Xcode

This step **must be done in Xcode's UI** — it generates your provisioning profile.

```bash
# Open the iOS workspace (not the .xcodeproj)
open /Users/joyeshkakkar/repos/civics-test-app/ios/Runner.xcworkspace
```

In Xcode:
1. Click **Runner** in the left sidebar (top of the file tree)
2. Select the **Runner** target (not RunnerTests)
3. Click the **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Under **Team**, select your Apple Developer account from the dropdown
6. Xcode will generate and download a provisioning profile automatically
7. Repeat for the **RunnerTests** target if prompted

> If you see "Failed to create provisioning profile" — make sure your Apple
> Developer enrollment is fully approved before this step.

---

## Step 4 — Install iOS Dependencies

```bash
cd /Users/joyeshkakkar/repos/civics-test-app
flutter pub get
cd ios && pod install && cd ..
```

---

## Step 5 — Build the Release IPA

```bash
flutter build ipa --release
```

Output: `build/ios/ipa/civics_test_app.ipa`

> If the build asks about a development team, make sure Step 3 is done first.

---

## Step 6 — Create the App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Fill in:
   - Platform: **iOS**
   - Name: `Civics Test 2025`
   - Primary language: `English (U.S.)`
   - Bundle ID: select `com.maplewood.civicstest2025` from the dropdown
     *(it appears after signing is configured in Xcode)*
   - SKU: `civicstest2025` (internal reference, not shown to users)
4. Click **Create**

---

## Step 7 — Store Listing

Go to **App Store → 1.0 Prepare for Submission**

### App information
- **Subtitle** (30 chars): `USCIS 2025 Civics Study Guide`
- **Category:** Education
- **Secondary category:** Reference

### Description
```
Preparing for the U.S. citizenship civics test? This app has everything you
need — all 128 official questions and answers from the USCIS 2025 civics
test, organized and ready to study.

STUDY YOUR WAY
• Browse all questions by topic and read every official answer
• Practice with multiple-choice quizzes and get instant feedback
• Take 20 full practice tests (20 questions, need 12 to pass)
• Special 65/20 track: 10 questions for applicants 65 or older
• Flashcards to flip through at your own pace
• Fix Your Misses: quiz only the questions you got wrong
• Bookmark favorites to review anytime

BUILT FOR HOW PEOPLE REALLY STUDY
• Works completely offline — no internet needed after download
• No account, no sign-up, no data collected
• Large text, high contrast, big tap targets — easy to read on any phone
• Tracks your progress and streak so you can see yourself improve

HONEST ABOUT WHAT IT IS
Questions and answers come word-for-word from the official USCIS 2025
civics test. The wrong options in the quiz were written for practice — they
are not official USCIS content. This app is not affiliated with USCIS or
the U.S. government.
```

### Keywords (100 chars total, comma-separated)
```
civics test,citizenship test,uscis,naturalization,immigration,civics study,us citizenship
```

### Support URL
Your privacy policy URL (or a contact page)

### Privacy Policy URL
Your hosted privacy policy URL (required)

---

## Step 8 — Screenshots

Apple requires specific sizes. Easiest method: use the iOS Simulator.

**Required sizes:**
- **6.9" iPhone** (iPhone 16 Pro Max): 1320×2868 px
- **6.5" iPhone** (iPhone 14 Plus): 1290×2796 px

**How to take them:**
1. In Xcode → open Simulator → choose iPhone 16 Pro Max
2. Run: `flutter run` (debug build is fine for screenshots)
3. Navigate to each screen and press `Cmd+S` to save a screenshot
4. Repeat for iPhone 14 Plus simulator

**Screens to screenshot:**
- Home screen (readiness meter visible)
- Quiz in progress (question + 4 options)
- Practice test list
- Study detail (showing official answers)
- Flashcard (front and back)

---

## Step 9 — App Review Information

- **Sign-in required:** No
- **Notes for reviewer:**
  ```
  This app requires no sign-in. All content is available immediately on launch.
  The app studies questions from the official USCIS 2025 civics test.
  It is not affiliated with USCIS or any government agency — this is stated
  clearly in the app's About section (Settings → About this app).
  ```

---

## Step 10 — Age Rating

Go to **App Information → Age Rating**

1. Click **Edit**
2. Answer all questionnaire items — all "None" or "No" for this app
3. Rating will be **4+**

---

## Step 11 — Pricing and Availability

- Price: **Free**
- Availability: All territories (or limit to US only if preferred)

---

## Step 12 — Upload and Submit

**Option A — Transporter app (easiest):**
1. Download **Transporter** from the Mac App Store (free, by Apple)
2. Sign in with your Apple ID
3. Drag `build/ios/ipa/civics_test_app.ipa` into Transporter
4. Click **Deliver**

**Option B — Xcode Organizer:**
1. In Xcode: **Product → Archive**
2. In the Organizer window: **Distribute App → App Store Connect → Upload**

After upload (takes a few minutes to process):
1. In App Store Connect, go to your app → select the build under **Build**
2. Click **Submit for Review**

---

## Step 13 — TestFlight First (strongly recommended)

Before submitting to the App Store, test on a real iPhone via TestFlight:

1. Upload the IPA (same as Step 12)
2. In App Store Connect → **TestFlight** tab
3. Add yourself as an internal tester
4. Install the TestFlight app on your iPhone → install the build
5. Tap through every screen on a real device before App Store submission

First TestFlight review: ~24 hours. Subsequent builds: often under 1 hour.

---

## Review Timeline

- **First submission:** typically **24–48 hours**
- Rejections reset the clock — read Apple's feedback carefully
- Common rejection reasons for this category:
  - Icon or name implies official government affiliation → already handled
  - Missing privacy policy URL → add before submitting
  - Metadata accuracy issues → make sure description matches what's in the app

---

## Quick Reference

| Item | Value |
|---|---|
| Bundle ID | `com.maplewood.civicstest2025` |
| Display name | `Civics Test 2025` |
| Build command | `flutter build ipa --release` |
| IPA output | `build/ios/ipa/civics_test_app.ipa` |
| Workspace | `ios/Runner.xcworkspace` |
| Min iOS | Flutter default (iOS 12+) |
| App Store Connect | [appstoreconnect.apple.com](https://appstoreconnect.apple.com) |
| Developer portal | [developer.apple.com](https://developer.apple.com) |
