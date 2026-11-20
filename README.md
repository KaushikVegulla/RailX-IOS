# RailX-IOS

Native Swift / SwiftUI client for **RailX**, Kaushik's railway reservation app.
The Android app (Kotlin / Jetpack Compose) lives in
[Railway-Reservation-System-](https://github.com/KaushikVegulla/Railway-Reservation-System-);
this repo is the iOS counterpart planned in the RailX iOS roadmap (20 Nov 2026).

**Status: Phase 4 prepared.** Pipeline, app target, Supabase auth, core
screens, payments and live search are proven (macOS CI green). Payments
and live search run through Supabase Edge Functions so no secret ever
ships in the app: `create-order` + `verify-payment` for Razorpay (with
a checkout bridge and a test-payment screen under Profile),
`railradar-proxy` for live train search, and `delete-account` for
in-app account deletion — all deployed live on 20 Nov 2026. The
TestFlight pipeline, app icon and privacy manifest are built; shipping
the first TestFlight build needs the Apple Developer enrollment and
four repo secrets — see `TESTFLIGHT.md`.

## How it builds with no Mac

GitHub Actions **macOS runners** do the building. Every push to `main`:

1. GitHub starts a fresh macOS VM (`macos-latest`, Apple Silicon) with Xcode
   and the iOS Simulator pre-installed.
2. `.github/workflows/ios.yml` builds `RailXCore` for the iOS Simulator
   (unsigned — no Apple Developer account needed for simulator builds).
3. It boots an available iPhone simulator and runs the unit tests,
   uploading the test results as a workflow artifact.

Standard runners are free and unlimited for public repositories, so this
costs nothing while the repo stays public. Signing, TestFlight and the
App Store come later and *do* need the paid Apple Developer Program.

## Layout

| Path | What |
|---|---|
| `Package.swift` | SwiftPM package, iOS 17 minimum |
| `Sources/RailXCore/` | Shared logic + SwiftUI home shell |
| `Sources/RailXCore/RefundCalculator.swift` | IRCTC cancellation slabs ported from Android's Cancellation Advisor |
| `Sources/RailXCore/WaitlistEstimator.swift` | Heuristic waitlist estimator (labelled a RailX estimate, not official data) |
| `Sources/RailXCore/RailXHomeView.swift` | SwiftUI home screen shell |
| `Tests/RailXCoreTests/` | XCTest unit tests (incl. the Rs 4520 1A case verified on Android) |
| `App/RailXApp.swift` | `@main` app entry, used by the Xcode project |
| `project.yml` | XcodeGen spec to generate `RailX.xcodeproj` in Phase 1 |

## Backend

Same Supabase project as Android (same tables, same RLS policies, same
users) — no backend rewrite. Razorpay payments, when they land, must
create orders and verify signatures in a Supabase Edge Function, never
on the client — same rule as Android.

## Roadmap

- **Phase 0** — Audit Android feature list, Supabase schema + RLS *(this scaffold is the first step)*
- **Phase 1** — Generate the Xcode project (XcodeGen), Supabase Swift SDK, auth parity
- **Phase 2** — Core screens: search → results → booking → history → profile
- **Phase 3** — Razorpay via Edge Functions + SwiftUI bridge
- **Phase 4** — TestFlight + polish
- **Phase 5** — App Store
