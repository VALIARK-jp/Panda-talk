import { serve } from "https://deno.land/std@0.201.0/http/server.ts";
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm";

const LINE_CHANNEL_ID = Deno.env.get("LINE_CHANNEL_ID") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
  try {
    if (!LINE_CHANNEL_ID || !SUPABASE_URL || !SERVICE_ROLE) {
      return json({ error: "Server not configured" }, 500);
    }

    const body = await req.json().catch(() => ({}));
    const idToken = body.idToken || body.id_token;
    const accessToken = body.accessToken || body.access_token;

    let lineUserId = "";
    let email = "";

    if (idToken) {
      const params = new URLSearchParams();
      params.append("id_token", idToken);
      params.append("client_id", LINE_CHANNEL_ID);

      const verifyRes = await fetch("https://api.line.me/oauth2/v2.1/verify", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: params,
      });
      const verifyData = await verifyRes.json();
      if (!verifyRes.ok) {
        return json({ error: verifyData.error_description || "LINE token verification failed" }, 400);
      }
      lineUserId = verifyData.sub;
      email = verifyData.email;
    } else if (accessToken) {
      const profileRes = await fetch("https://api.line.me/v2/profile", {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (!profileRes.ok) return json({ error: "Failed to get LINE user profile" }, 400);
      const profile = await profileRes.json();
      lineUserId = profile.userId;
      email = `${lineUserId}@line.local`;
    } else {
      return json({ error: "Missing id_token or access_token" }, 400);
    }

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: userId, error: rpcError } = await admin.rpc("get_user_by_email", {
      user_email: email,
    });
    if (rpcError) return json({ error: "Failed to search user", details: rpcError.message }, 500);

    let finalUserId = userId;
    let isNewUser = false;
    if (!finalUserId) {
      const { data: newUser, error: createError } = await admin.auth.admin.createUser({
        email,
        email_confirm: true,
        app_metadata: { provider: "line", line_id: lineUserId },
        user_metadata: { provider: "line" },
      });
      if (createError) return json({ error: "Failed to create user", details: createError.message }, 500);
      finalUserId = newUser.user?.id;
      isNewUser = true;
    } else {
      await admin.auth.admin.updateUserById(finalUserId, {
        app_metadata: { provider: "line", line_id: lineUserId },
      });
    }

    const { data: linkData, error: linkError } = await admin.auth.admin.generateLink({
      email,
      type: "magiclink",
    });
    if (linkError) return json({ error: "Failed to generate magic link", details: linkError.message }, 500);

    const hashedToken = linkData?.properties?.hashed_token;
    if (!hashedToken) return json({ error: "Failed to generate magic link", details: "hashed_token missing" }, 500);

    return json({
      hashed_token: hashedToken,
      email,
      user_id: finalUserId,
      is_new_user: isNewUser,
      otp_type: "magiclink",
    });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : String(error) }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
