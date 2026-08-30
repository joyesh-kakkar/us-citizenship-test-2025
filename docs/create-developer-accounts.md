# Creating Developer Accounts
## Google Play + Apple App Store

---

## Google Play Developer Account

**Cost:** $25 one-time fee (never expires)
**Time:** 15 minutes to set up, up to 48 hours for verification

### Step 1 — Sign in with a Google account
1. Go to [play.google.com/console/signup](https://play.google.com/console/signup)
2. Sign in with a Google account — use one you plan to keep long-term
   - You can use your existing Gmail or create a new one dedicated to Maplewood Apps
   - The account email becomes your developer contact and is visible to users

### Step 2 — Choose account type
- Select **Individual** (not Organization)
- Individual accounts are simpler — no D-U-N-S number, no business verification

### Step 3 — Fill in developer profile
- **Developer name:** `Maplewood Apps`
  *(This is what users see on the Play Store next to your app — choose carefully)*
- **Email address:** your contact email (shown publicly on your store listings)
- **Website:** optional — can leave blank or add later
- **Phone number:** required for verification, not shown publicly

### Step 4 — Pay the registration fee
- $25 USD, one-time, non-refundable
- Google accepts most major credit/debit cards
- Pay via the Google Payments page that appears

### Step 5 — Verify your identity
Google now requires identity verification for all new accounts:
1. After payment, you'll be prompted to verify identity
2. Have a **government-issued photo ID** ready (passport or driver's license)
3. Complete the verification flow in Play Console
4. Approval usually comes within **a few hours to 2 days**
5. You'll get an email when your account is fully activated

### Step 6 — Complete account setup
Once approved:
1. Go to [play.google.com/console](https://play.google.com/console)
2. Accept the **Developer Distribution Agreement**
3. Your account is ready — you can create your first app

### Notes
- The $25 fee covers unlimited app submissions forever
- You can publish free and paid apps on the same account
- Developer name can be changed later but it affects trust — choose once

---

## Apple Developer Account (App Store)

**Cost:** $99/year (recurring, billed annually)
**Time:** 15–30 minutes to set up, up to 48 hours for verification

### Step 1 — Make sure you have an Apple ID
- Use an Apple ID you own long-term (not a temporary one)
- If you don't have one: [appleid.apple.com](https://appleid.apple.com) → Create Apple ID
- Enable two-factor authentication on the Apple ID — Apple requires it for developer accounts

### Step 2 — Enroll in the Apple Developer Program
1. Go to [developer.apple.com/enroll](https://developer.apple.com/enroll)
2. Sign in with your Apple ID
3. Choose **Individual / Sole Proprietor**
   - Does not require a business entity
   - Your legal name appears as the developer name on the App Store
   - You can display as "Maplewood Apps" in the store listing even with an individual account

### Step 3 — Review and accept terms
- Read and accept the Apple Developer Program License Agreement
- Click **Continue**

### Step 4 — Pay the annual fee
- $99 USD/year, billed annually
- Apple accepts most major credit/debit cards
- Renewal reminders come by email — if your membership lapses, your apps are removed from the store until you renew

### Step 5 — Identity verification
Apple verifies your identity automatically using your:
- Apple ID information
- Payment method billing address
- For most individual enrollments this is instant or within a few hours

If additional verification is required:
- Apple will email you with next steps
- May ask for a government ID or a call with Apple support
- Full approval can take up to **48 hours** in edge cases

### Step 6 — Access App Store Connect
Once approved:
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Sign in with the same Apple ID
3. Accept the **Paid Applications Agreement** even for free apps (required)
4. Your account is ready

### Step 7 — Add your Apple ID to Xcode
1. Open Xcode
2. Menu → **Xcode → Settings → Accounts**
3. Click **+** → **Apple ID** → sign in
4. Your developer team will appear — this is what you select when configuring signing

### Notes
- The $99/year fee covers unlimited app submissions on iOS, macOS, watchOS, and tvOS
- If your membership expires, apps stay on the store but you cannot submit updates until you renew
- Individual account: your legal name is the "seller" name on the App Store. You can set a separate display name for your developer profile.
- You need an iPhone or Mac with your Apple ID signed in to complete 2FA during enrollment

---

## Side-by-Side Comparison

| | Google Play | Apple App Store |
|---|---|---|
| Cost | $25 one-time | $99/year |
| Account type | Individual | Individual / Sole Proprietor |
| Developer name shown | `Maplewood Apps` | Your legal name (seller) + display name |
| Verification | Government ID | Apple ID + payment method |
| Approval time | A few hours – 2 days | Usually same day, up to 48 hrs |
| Review portal | play.google.com/console | appstoreconnect.apple.com |
| App review time (first submission) | 3–7 days | 24–48 hours |

---

## What to Do After Both Accounts Are Approved

1. **Google Play:** Create the app record in Play Console → upload your `.aab` file
   → follow `docs/playstore-submission.md`

2. **Apple:** Add your Apple ID to Xcode → configure signing → build the IPA
   → follow `docs/appstore-submission.md`

---

## Important — Keep These Safe

| Item | Where it is | Why it matters |
|---|---|---|
| Google account password | Your password manager | Losing access = losing the Play Console |
| `~/maplewood-upload.jks` | Your Mac home folder | Required to update Android app forever |
| Keystore password | Your password manager | Required every time you build a release |
| Apple ID password + 2FA device | Your Apple ID settings | Required to submit iOS updates |

**Back up `~/maplewood-upload.jks` to an external drive or cloud storage now.**
Losing this file means you can never push an update to your Android app.
