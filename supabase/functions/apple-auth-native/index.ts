import { serve } from "https://deno.land/std@0.201.0/http/server.ts";
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
  try {
    if (!SUPABASE_URL || !SERVICE_ROLE) {
      return json({ error: "Server not configured" }, 500);
    }

    const body = await req.json().catch(() => ({}));
    const identityToken = body.identityToken || body.identity_token;
    if (!identityToken) return json({ error: "Missing identity_token" }, 400);

    const payload = decodeJwtPayload(identityToken);
    const appleUserId = payload.sub as string;
    const email = (payload.email as string | undefined) || body.email || `${appleUserId}@apple.local`;
    const displayName = body.familyName && body.givenName
      ? `${body.familyName} ${body.givenName}`
      : body.familyName || body.givenName || null;

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
        app_metadata: { provider: "apple", apple_id: appleUserId },
        user_metadata: {
          displayName,
          givenName: body.givenName ?? null,
          familyName: body.familyName ?? null,
        },
      });
      if (createError) return json({ error: "Failed to create user", details: createError.message }, 500);
      finalUserId = newUser.user?.id;
      isNewUser = true;
    } else {
      await admin.auth.admin.updateUserById(finalUserId, {
        app_metadata: { provider: "apple", apple_id: appleUserId },
        user_metadata: {
          displayName,
          givenName: body.givenName ?? null,
          familyName: body.familyName ?? null,
        },
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

function decodeJwtPayload(token: string): Record<string, unknown> {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWT token format");
  return JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
