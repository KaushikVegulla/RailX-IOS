// RailX — RailRadar proxy for signed-in Supabase users.
//
// Why this exists: RailRadar data needs an API key, and that key must
// never ship inside a mobile app (Android reads it from a build-time
// secret; iOS has no safe place for it). This function holds the key
// in Edge Function secrets (RAILRADAR_API_KEY) and forwards a small
// allowlist of read-only RailRadar paths for authenticated users.
//
// Request:  POST { "path": "trains/between/NDLS/MMCT?date=2026-11-26" }
// Response: the upstream RailRadar JSON, unchanged.

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

// Read-only RailRadar paths the apps are allowed to use.
const ALLOWED_PATHS: RegExp[] = [
  /^trains\/between\/[A-Za-z0-9]+\/[A-Za-z0-9]+(\?date=\d{4}-\d{2}-\d{2})?$/,
  /^trains\/\d{5}\/seats\?journeyDate=\d{4}-\d{2}-\d{2}&source=[A-Za-z0-9]+&destination=[A-Za-z0-9]+&classCode=[A-Za-z0-9]+&quotaCode=[A-Za-z0-9]+$/,
  /^trains\/\d{5}\/fare\?journeyDate=\d{4}-\d{2}-\d{2}&source=[A-Za-z0-9]+&destination=[A-Za-z0-9]+&classCode=[A-Za-z0-9]+&quotaCode=[A-Za-z0-9]+$/,
  /^trains\/\d{5}\/live(\?haltsOnly=true)?$/,
  /^pnr\/\d{10}$/,
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const user = await requireUser(req);
  if (!user) {
    return json({ error: "Not authenticated" }, 401);
  }

  const apiKey = Deno.env.get("RAILRADAR_API_KEY") ?? "";
  if (!apiKey) {
    return json({ error: "RailRadar is not configured on the server" }, 500);
  }

  let path = "";
  try {
    const body = await req.json();
    path = String(body.path ?? "");
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  if (!ALLOWED_PATHS.some((pattern) => pattern.test(path))) {
    return json({ error: "Path not allowed" }, 400);
  }

  const upstream = await fetch(`https://api.railradar.in/v1/${path}`, {
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  const text = await upstream.text();
  return new Response(text, {
    status: upstream.status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
