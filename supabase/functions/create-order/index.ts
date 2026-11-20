// RailX — create a Razorpay order for a signed-in Supabase user.
//
// The Razorpay secret lives only in Edge Function secrets
// (RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET), never in the Android app.
// Deploy and set secrets as described in supabase/README.md.

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

  const keyId = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
  if (!keyId || !keySecret) {
    return json({ error: "Payments are not configured on the server" }, 500);
  }

  let amountRupees = 0;
  let receipt = "railx";
  try {
    const body = await req.json();
    amountRupees = Number(body.amountRupees ?? 0);
    if (typeof body.receipt === "string" && body.receipt.length > 0) {
      receipt = body.receipt.replace(/[^A-Za-z0-9_]/g, "").slice(0, 40) || "railx";
    }
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  if (!Number.isFinite(amountRupees) || amountRupees < 1) {
    return json({ error: "amountRupees must be at least 1" }, 400);
  }
  const amountPaise = Math.round(amountRupees) * 100;

  const response = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      "Authorization": "Basic " + btoa(`${keyId}:${keySecret}`),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: amountPaise,
      currency: "INR",
      receipt,
      payment_capture: 1,
      notes: { user_id: user.id },
    }),
  });
  const order = await response.json().catch(() => ({}));
  if (!response.ok || !order.id) {
    const description = order?.error?.description ?? "Create order failed";
    return json({ error: description }, 502);
  }

  return json({
    orderId: order.id,
    keyId,
    amountPaise: order.amount ?? amountPaise,
    currency: order.currency ?? "INR",
  });
});
