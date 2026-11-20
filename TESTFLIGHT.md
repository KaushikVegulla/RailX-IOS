# Phase 4 — TestFlight: what Kaushik must do (everything else is built)

The app, CI and backend are ready. TestFlight needs an **Apple
Developer Program** membership, and that account must belong to the
person who will own the app — the account holder is the legal seller,
owns the bundle ID registration, and controls the app record. Enroll
with **your own Apple ID**, not someone else's.

## 1. Enroll (only you can do this)

1. Go to https://developer.apple.com/programs/enroll/ signed in with
   **your** Apple ID (create one first at appleid.apple.com if needed).
2. Enroll as an **Individual**. Cost: **$99/year** (charged by Apple).
3. Wait for Apple's confirmation email (usually minutes to ~48h).

## 2. Create the app record

1. https://appstoreconnect.apple.com → My Apps → **+** → New App.
2. Platform iOS, name **RailX**, primary language English (India),
   bundle ID **com.kaushikvegulla.railx** (register it under
   Certificates, Identifiers & Profiles → Identifiers if it isn't
   listed), SKU `railx-ios`.

## 3. Create an App Store Connect API key

1. App Store Connect → Users and Access → Integrations →
   App Store Connect API → **Generate API Key** (role: Admin or
   App Manager).
2. Download the `.p8` file — **you can only download it once**.
3. Note the **Key ID** and the **Issuer ID** shown on that page.

## 4. Add four secrets to this repo

Repo → Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | Your 10-character Team ID (developer.apple.com → Membership) |
| `ASC_KEY_ID` | The API Key ID from step 3 |
| `ASC_ISSUER_ID` | The Issuer ID from step 3 |
| `ASC_API_KEY_P8_BASE64` | The `.p8` file base64-encoded (`base64 -i AuthKey_XXXX.p8` on a Mac/Linux terminal) |

## 5. Ship it

Actions tab → **TestFlight (manual)** → Run workflow. CI archives with
automatic signing and uploads. The build appears in App Store Connect →
TestFlight after Apple processing (~15–60 min). Add your Apple ID email
as an internal tester to install it via the TestFlight app.

## App Review readiness (already handled in code)

- **Account deletion** in-app (Profile → Danger zone) — Guideline 5.1.1(v)
- **Privacy manifest** (`App/PrivacyInfo.xcprivacy`) declaring email,
  name, user ID and payment info, no tracking
- **Encryption compliance** pre-answered (`ITSAppUsesNonExemptEncryption=false`)
- **Sign in with Apple** is *not* required: RailX offers only its own
  email/user-ID login, no third-party social login
- **Payments**: rail tickets are real-world services, so Razorpay is
  allowed — Apple's 30% IAP rule does not apply

## Still to fill in App Store Connect at submission time (Phase 5)

Privacy labels matching the manifest, screenshots, description,
support URL, and a demo account for the reviewer (a RailX test login).
