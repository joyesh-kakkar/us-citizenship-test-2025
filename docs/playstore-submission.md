# Play Store Submission Guide
## Civics Test 2025 — com.maplewood.civicstest2025

---

## Prerequisites Checklist

- [ ] Google Play developer account created ($25 one-time fee)
- [ ] Identity verification approved (can take 1–2 days)
- [ ] App icon PNG (1024×1024, no alpha channel)
- [ ] Feature graphic (1024×500 PNG)
- [ ] Screenshots — minimum 2 phone screenshots
- [ ] Privacy policy hosted at a public URL
- [ ] Signed `.aab` file built

---

## Step 1 — Create Your Developer Account

1. Go to [play.google.com/console/signup](https://play.google.com/console/signup)
2. Pay the **$25 one-time registration fee**
3. Complete identity verification (individual account — just your name + government ID)
4. Wait for approval email (usually same day, sometimes 1–2 days)

---

## Step 2 — Build the Signed Release Bundle

Run from the project root:

```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) ANDROID_HOME=$HOME/Library/Android/sdk flutter build appbundle --release
```

Output file: `build/app/outputs/bundle/release/app-release.aab`

> **Important:** The keystore file is at `~/maplewood-upload.jks`.
> Back it up somewhere safe. Losing it = can never update the app.

---

## Step 3 — Create the App in Play Console

1. Open [play.google.com/console](https://play.google.com/console)
2. Click **"Create app"**
3. Fill in:
   - App name: `Civics Test 2025`
   - Default language: `English (United States)`
   - App or game: `App`
   - Free or paid: `Free`
4. Accept the declarations → **Create app**

---

## Step 4 — Store Listing

Go to **Grow → Store presence → Main store listing**

### App details
- **App name:** Civics Test 2025
- **Short description** (80 chars max):
  > Study all 128 USCIS civics questions. Free, offline, no account needed.

- **Full description** (paste this):

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

### Graphics
- **App icon:** 512×512 PNG (resize your 1024×1024 icon)
- **Feature graphic:** 1024×500 PNG (a simple banner — app name on navy background works)
- **Phone screenshots:** minimum 2, taken from your Samsung Galaxy S22 Ultra
  - Home screen
  - Quiz screen
  - Practice test screen
  - Study detail screen (shows official answers)

---

## Step 5 — Content Rating

Go to **Policy → App content → Content rating**

1. Click **Start questionnaire**
2. Category: **Education**
3. Answer all questions (all "No" for this app)
4. Submit → rating will be **Everyone (E)**

---

## Step 6 — Data Safety

Go to **Policy → App content → Data safety**

1. Does your app collect or share user data? **No**
2. Is data encrypted in transit? **Yes** (the one optional network call uses HTTPS)
3. Does the user have the ability to request data deletion? **No data is collected**
4. Submit

---

## Step 7 — App Content Declarations

Go to **Policy → App content** and complete:
- **Privacy policy:** paste your hosted privacy policy URL
- **Ads:** `This app does not contain ads`
- **Target audience:** Age 18 and over
- **News apps:** No

---

## Step 8 — Upload the AAB

Go to **Release → Production → Create new release**

> **Tip:** Start with **Internal testing** first (same steps, instant publish,
> no review). Install on your phone via the Play Store to smoke-test before
> going to Production.

1. Click **Create new release**
2. Under **App bundles**, click **Upload** → select `app-release.aab`
3. Release name: `1.0.0`
4. Release notes:
   ```
   Initial release — all 128 USCIS 2025 civics questions, 20 practice tests,
   quiz mode, flashcards, and progress tracking. Fully offline, no account needed.
   ```
5. Click **Save** → **Review release** → **Start rollout to Production**

---

## Step 9 — Submit for Review

1. Fix any warnings Play Console flags (usually policy declarations)
2. Click **Send for review**
3. First review: **3–7 days** for new accounts
4. You'll get an email when approved or if changes are needed

---

## After Approval

- Monitor ratings and reviews in Play Console → **Grow → Ratings and reviews**
- To update the app: bump `version` in `pubspec.yaml` (e.g. `1.0.1+2`), rebuild the `.aab`, upload to a new release
- **Never lose** `~/maplewood-upload.jks` — it is required for every future update

---

## Quick Reference

| Item | Value |
|---|---|
| Package name | `com.maplewood.civicstest2025` |
| Keystore | `~/maplewood-upload.jks` |
| Key alias | `upload` |
| Build command | `JAVA_HOME=$(/usr/libexec/java_home -v 17) ANDROID_HOME=$HOME/Library/Android/sdk flutter build appbundle --release` |
| AAB output | `build/app/outputs/bundle/release/app-release.aab` |
| Min Android | Flutter default (~Android 5.0) |
