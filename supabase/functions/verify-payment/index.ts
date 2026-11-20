// RailX — verify a Razorpay payment signature for a signed-in Supabase user.
//
// Verification is HMAC-SHA256 over "<order_id>|<payment_id>" with the
// Razorpay secret, which lives only in Edge Function secrets
// (RAZORPAY_KEY_SECRET), never in the Android app.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(message),
  );
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function signaturesMatch(expected: string, actual: string): boolean {
  if (expected.length !== actual.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) {
    diff |= expected.charCodeAt(i) ^ actual.toLowerCase().charCodeAt(i);
  }
  return diff === 0;
}

async function requireUser(req: Request): Promise<{ id: string } | null> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return null;
  const base = Deno.env.get("SUPABASE_URL") ?? "";
  const apikey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
  try {
    const resp = await fetch(`${base}/auth/v1/user`, {
      headers: { Authorization: auth, apikey },
    });
    if (!resp.ok) return null;
    const user = await resp.json();
    return user?.id ? { id: String(user.id) } : null;
  } catch {
    return null;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // Require a signed-in Supabase user.
  const user = await requireUser(req);
  if (!user) {
    return json({ error: "Not authenticated" }, 401);
  }

  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
  if (!keySecret) {
    return json({ error: "Payments are not configured on the server" }, 500);
  }

  let paymentId = "";
  let orderId = "";
  let signature = "";
  try {
    const body = await req.json();
    paymentId = String(body.paymentId ?? "");
    orderId = String(body.orderId ?? "");
    signature = String(body.signature ?? "");
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  if (!paymentId || !orderId || !signature) {
    return json({ error: "paymentId, orderId and signature are required" }, 400);
  }

  const expected = await hmacSha256Hex(keySecret, `${orderId}|${paymentId}`);
  const verified = signaturesMatch(expected, signature);
  if (!verified) {
    return json({ verified: false, error: "Invalid payment signature" }, 400);
  }
  return json({ verified: true });
});
