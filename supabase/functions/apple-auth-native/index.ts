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
    const flowRaw =
      typeof body.flow === "string"
        ? body.flow.trim()
        : typeof body.auth_flow === "string"
        ? body.auth_flow.trim()
        : undefined;
    /** 未指定は従来どおり signup（古いクライアント互換） */
    const flow = flowRaw === "login" ? "login" : "signup";

    const identityToken = body.identityToken || body.identity_token;
    if (!identityToken) return json({ error: "Missing identity_token" }, 400);

    const payload = decodeJwtPayload(identityToken);
    const appleUserId = payload.sub as string;
    const fromJwt =
      typeof payload.email === "string" ? payload.email.trim() : "";
    const fromBody =
      typeof body.email === "string" ? body.email.trim() : "";

    const displayName =
      body.familyName && body.givenName
        ? `${body.familyName} ${body.givenName}`
        : body.familyName || body.givenName || null;

    const emailCandidate = normalizeAuthEmail(
      (fromJwt !== "" ? fromJwt : null) ??
        (fromBody !== "" ? fromBody : null) ??
        `${appleUserId}@apple.local`,
    );

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: userIdByApple, error: rpcAppleErr } = await admin.rpc(
      "get_user_by_apple_id",
      { apple_sub: appleUserId },
    );
    if (rpcAppleErr) {
      return json({
        error: "Failed to search user",
        details: rpcAppleErr.message,
      }, 500);
    }

    let resolvedByApple = userIdByApple as string | null | undefined;
    if (!resolvedByApple) {
      resolvedByApple = await findUserIdByAppleIdListFallback(
        admin,
        appleUserId,
      );
    }

    let finalUserId = resolvedByApple as string | null | undefined;
    let email: string;
    let isNewUser = false;

    const userMetaPatch = {
      displayName,
      givenName: body.givenName ?? null,
      familyName: body.familyName ?? null,
    };

    if (finalUserId) {
      const loaded = await loadUserEmail(admin, finalUserId);
      if (loaded instanceof Response) return loaded;
      email = loaded.email;
      await admin.auth.admin.updateUserById(finalUserId, {
        app_metadata: { provider: "apple", apple_id: appleUserId },
        user_metadata: userMetaPatch,
      });
    } else {
      const { data: userIdByEmail, error: rpcEmailErr } = await admin.rpc(
        "get_user_by_email",
        { user_email: emailCandidate },
      );
      if (rpcEmailErr) {
        return json({
          error: "Failed to search user",
          details: rpcEmailErr.message,
        }, 500);
      }

      if (userIdByEmail) {
        finalUserId = userIdByEmail as string;
        const conflict = await assertAppleLinkAllowed(admin, finalUserId, appleUserId);
        if (conflict) return conflict;
        const loaded = await loadUserEmail(admin, finalUserId);
        if (loaded instanceof Response) return loaded;
        email = loaded.email;
        await admin.auth.admin.updateUserById(finalUserId, {
          app_metadata: { provider: "apple", apple_id: appleUserId },
          user_metadata: userMetaPatch,
        });
        isNewUser = false;
      } else if (flow === "login") {
        return json({
          error: "account_not_found",
          details:
            "このアカウントではまだ登録されていません。「新規登録」から同じ方法でアカウントを作成してください。",
        }, 404);
      } else {
        const { data: newUser, error: createError } = await admin.auth.admin
          .createUser({
            email: emailCandidate,
            email_confirm: true,
            app_metadata: { provider: "apple", apple_id: appleUserId },
            user_metadata: userMetaPatch,
          });
        if (createError) {
          const msg = (createError.message ?? "").toLowerCase();
          const dup =
            msg.includes("already") ||
            msg.includes("registered") ||
            msg.includes("exists") ||
            msg.includes("duplicate") ||
            msg.includes("unique");
          if (dup) {
            let resolvedId: string | null = null;
            const { data: retryId, error: reErr } = await admin.rpc(
              "get_user_by_email",
              { user_email: emailCandidate },
            );
            if (!reErr && retryId) {
              resolvedId = retryId as string;
            } else {
              resolvedId = await findUserIdByEmailListFallback(
                admin,
                emailCandidate,
              );
            }
            if (!resolvedId) {
              resolvedId = await findUserIdByAppleIdListFallback(
                admin,
                appleUserId,
              );
            }
            if (!resolvedId) {
              return json({
                error: "Failed to create user",
                details: createError.message,
              }, 500);
            }
            finalUserId = resolvedId;
            const c2 = await assertAppleLinkAllowed(admin, finalUserId, appleUserId);
            if (c2) return c2;
            const loaded2 = await loadUserEmail(admin, finalUserId);
            if (loaded2 instanceof Response) return loaded2;
            email = loaded2.email;
            await admin.auth.admin.updateUserById(finalUserId, {
              app_metadata: { provider: "apple", apple_id: appleUserId },
              user_metadata: userMetaPatch,
            });
            isNewUser = false;
          } else {
            return json({
              error: "Failed to create user",
              details: createError.message,
            }, 500);
          }
        } else {
          finalUserId = newUser.user?.id;
          if (!finalUserId) {
            return json({
              error: "Failed to create user",
              details: "missing user id",
            }, 500);
          }
          email = emailCandidate;
          isNewUser = true;
        }
      }
    }

    const { data: linkData, error: linkError } = await admin.auth.admin
      .generateLink({
        email,
        type: "magiclink",
      });
    if (linkError) {
      return json({
        error: "Failed to generate magic link",
        details: linkError.message,
      }, 500);
    }

    const hashedToken =
      (linkData as { properties?: { hashed_token?: string }; hashed_token?: string } | null)
        ?.properties?.hashed_token ??
      (linkData as { hashed_token?: string } | null)?.hashed_token;
    if (!hashedToken) {
      return json({
        error: "Failed to generate magic link",
        details: "hashed_token missing",
      }, 500);
    }

    return json({
      hashed_token: hashedToken,
      email,
      user_id: finalUserId,
      is_new_user: isNewUser,
      otp_type: "magiclink",
    });
  } catch (error) {
    return json({
      error: error instanceof Error ? error.message : String(error),
    }, 500);
  }
});

function normalizeAuthEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

async function findUserIdByAppleIdListFallback(
  admin: ReturnType<typeof createClient>,
  appleSub: string,
): Promise<string | null> {
  const target = String(appleSub).trim();
  if (!target) return null;
  const perPage = 1000;
  const maxPages = 100;
  for (let page = 1; page <= maxPages; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage });
    if (error) {
      console.error("listUsers apple_id scan:", error.message);
      return null;
    }
    const users = data?.users ?? [];
    for (const u of users) {
      const aid = u.app_metadata?.apple_id as string | undefined;
      if (aid != null && String(aid).trim() === target) return u.id;
    }
    if (users.length < perPage) break;
  }
  return null;
}

/** RPC がヒットしないが createUser が重複のとき（マイグレーション未適用等）の救済 */
async function findUserIdByEmailListFallback(
  admin: ReturnType<typeof createClient>,
  normalizedTarget: string,
): Promise<string | null> {
  const target = normalizeAuthEmail(normalizedTarget);
  const perPage = 1000;
  const maxPages = 100;
  for (let page = 1; page <= maxPages; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage });
    if (error) {
      console.error("listUsers email scan:", error.message);
      return null;
    }
    const users = data?.users ?? [];
    for (const u of users) {
      const em = u.email;
      if (em && normalizeAuthEmail(em) === target) return u.id;
    }
    if (users.length < perPage) break;
  }
  return null;
}

async function loadUserEmail(
  admin: ReturnType<typeof createClient>,
  userId: string,
): Promise<{ email: string } | Response> {
  const { data: userResp, error: getErr } = await admin.auth.admin.getUserById(
    userId,
  );
  if (getErr || !userResp.user?.email) {
    return json({
      error: "Failed to load user",
      details: getErr?.message ?? "no email on user",
    }, 500);
  }
  return { email: normalizeAuthEmail(userResp.user.email) };
}

/** 別の Apple ID が既に付いていればなりすまし連結を拒否 */
async function assertAppleLinkAllowed(
  admin: ReturnType<typeof createClient>,
  userId: string,
  appleUserId: string,
): Promise<Response | null> {
  const { data: userResp, error: getErr } = await admin.auth.admin.getUserById(
    userId,
  );
  if (getErr || !userResp.user) {
    return json({
      error: "Failed to load user",
      details: getErr?.message ?? "user missing",
    }, 500);
  }
  const existing = userResp.user.app_metadata?.apple_id as string | undefined;
  if (existing && existing !== appleUserId) {
    return json({
      error: "identity_conflict",
      details:
        "このメールアドレスは別の Apple アカウントにすでに紐づいています。",
    }, 409);
  }
  return null;
}

function decodeJwtPayload(token: string): Record<string, unknown> {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWT token format");
  let b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4;
  if (pad === 2) b64 += "==";
  else if (pad === 3) b64 += "=";
  else if (pad !== 0) throw new Error("Invalid JWT token format");
  return JSON.parse(atob(b64));
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
