# RailX Supabase Edge Functions

These functions run on the **same Supabase project as RailX Android**
(`etaaufimazvjdmpladom`). Deploying from this repo updates the same
functions the Android repo carries — they are intentionally identical
for `create-order` / `verify-payment`.

| Function | Purpose | Secrets it needs |
|---|---|---|
| `create-order` | Creates a Razorpay order for a signed-in user | `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` |
| `verify-payment` | Verifies a Razorpay payment signature (HMAC-SHA256) | `RAZORPAY_KEY_SECRET` |
| `railradar-proxy` | Proxies allowlisted RailRadar reads so the API key never ships in an app | `RAILRADAR_API_KEY` |

**Non-negotiable rules (same as Android):**
- The Razorpay secret and the RailRadar key live ONLY in Edge Function
  secrets — never in the iOS app, never in this repo.
- Orders are created and signatures verified only on the server.
- Every function requires a signed-in Supabase user (Bearer token).

## Deploy

```bash
# one-time
npm install -g supabase
supabase login
supabase link --project-ref etaaufimazvjdmpladom

# set secrets (values come from the Razorpay dashboard / RailRadar account)
supabase secrets set RAZORPAY_KEY_ID=rzp_test_... RAZORPAY_KEY_SECRET=... RAILRADAR_API_KEY=...

# deploy all three
supabase functions deploy create-order verify-payment railradar-proxy
```

Until these are deployed, the iOS app's payment screen and live train
search report that the server side isn't configured — nothing is faked
client-side.
