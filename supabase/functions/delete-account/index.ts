// RailX — permanently delete the signed-in user's account and data.
//
// App Store Review Guideline 5.1.1(v): apps that support account
// creation must let users delete their account in the app. This
// function deletes the user's rows (bookings, saved passengers,
// favourite routes, profile) and then the auth user itself, using the
// service role key that Supabase injects into Edge Functions — it is
// never shipped in any app.

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

  const user = await requireUser(req);
  if (!user) {
    return json({ error: "Not authenticated" }, 401);
  }

  const base = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!base || !serviceKey) {
    return json({ error: "Account deletion is not configured on the server" }, 500);
  }
  const serviceHeaders = {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    Prefer: "return=minimal",
  };

  // Delete the user's data first (service role bypasses RLS).
  const tables: Array<[string, string]> = [
    ["bookings", "user_id"],
    ["passengers", "user_id"],
    ["favourite_routes", "user_id"],
    ["profiles", "id"],
  ];
  for (const [table, column] of tables) {
    const resp = await fetch(
      `${base}/rest/v1/${table}?${column}=eq.${user.id}`,
      { method: "DELETE", headers: serviceHeaders },
    );
    if (!resp.ok) {
      return json({ error: `Failed to delete ${table}` }, 502);
    }
  }

  // Then the auth user itself.
  const adminResp = await fetch(`${base}/auth/v1/admin/users/${user.id}`, {
    method: "DELETE",
    headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
  });
  if (!adminResp.ok) {
    return json({ error: "Failed to delete the auth user" }, 502);
  }

  return json({ deleted: true });
});
