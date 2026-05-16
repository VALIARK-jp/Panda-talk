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
    const flowRaw =
      typeof body.flow === "string"
        ? body.flow.trim()
        : typeof body.auth_flow === "string"
        ? body.auth_flow.trim()
        : undefined;
    const flow = flowRaw === "login" ? "login" : "signup";

    const idToken = body.idToken || body.id_token;
    const accessToken = body.accessToken || body.access_token;

    let lineUserId = "";
    let emailCandidate = "";

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
        return json({
          error: verifyData.error_description || "LINE token verification failed",
        }, 400);
      }
      lineUserId = verifyData.sub;
      const rawEmail = verifyData.email as string | undefined;
      emailCandidate =
        rawEmail && String(rawEmail).trim() !== ""
          ? String(rawEmail).trim()
          : `${lineUserId}@line.local`;
    } else if (accessToken) {
      const profileRes = await fetch("https://api.line.me/v2/profile", {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (!profileRes.ok) {
        return json({ error: "Failed to get LINE user profile" }, 400);
      }
      const profile = await profileRes.json();
      lineUserId = profile.userId;
      emailCandidate = `${lineUserId}@line.local`;
    } else {
      return json({ error: "Missing id_token or access_token" }, 400);
    }

    emailCandidate = normalizeAuthEmail(emailCandidate);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: userIdByLine, error: rpcLineErr } = await admin.rpc(
      "get_user_by_line_id",
      { line_uid: lineUserId },
    );
    if (rpcLineErr) {
      return json({
        error: "Failed to search user",
        details: rpcLineErr.message,
      }, 500);
    }

    let resolvedByLine = userIdByLine as string | null | undefined;
    if (!resolvedByLine) {
      resolvedByLine = await findUserIdByLineIdListFallback(admin, lineUserId);
    }

    let finalUserId = resolvedByLine as string | null | undefined;
    let email: string;
    let isNewUser = false;

    if (finalUserId) {
      const loaded = await loadUserEmail(admin, finalUserId);
      if (loaded instanceof Response) return loaded;
      email = loaded.email;
      await admin.auth.admin.updateUserById(finalUserId, {
        app_metadata: { provider: "line", line_id: lineUserId },
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
        const conflict = await assertLineLinkAllowed(admin, finalUserId, lineUserId);
        if (conflict) return conflict;
        const loaded = await loadUserEmail(admin, finalUserId);
        if (loaded instanceof Response) return loaded;
        email = loaded.email;
        await admin.auth.admin.updateUserById(finalUserId, {
          app_metadata: { provider: "line", line_id: lineUserId },
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
            app_metadata: { provider: "line", line_id: lineUserId },
            user_metadata: { provider: "line" },
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
              resolvedId = await findUserIdByLineIdListFallback(
                admin,
                lineUserId,
              );
            }
            if (!resolvedId) {
              return json({
                error: "Failed to create user",
                details: createError.message,
              }, 500);
            }
            finalUserId = resolvedId;
            const c2 = await assertLineLinkAllowed(admin, finalUserId, lineUserId);
            if (c2) return c2;
            const loaded2 = await loadUserEmail(admin, finalUserId);
            if (loaded2 instanceof Response) return loaded2;
            email = loaded2.email;
            await admin.auth.admin.updateUserById(finalUserId, {
              app_metadata: { provider: "line", line_id: lineUserId },
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

/** RPC が null でも app_metadata に line_id があれば拾う（メールが実アドレスで @line.local とズレる場合） */
async function findUserIdByLineIdListFallback(
  admin: ReturnType<typeof createClient>,
  lineUserId: string,
): Promise<string | null> {
  const target = String(lineUserId).trim();
  if (!target) return null;
  const perPage = 1000;
  const maxPages = 100;
  for (let page = 1; page <= maxPages; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage });
    if (error) {
      console.error("listUsers line_id scan:", error.message);
      return null;
    }
    const users = data?.users ?? [];
    for (const u of users) {
      const lid = u.app_metadata?.line_id as string | undefined;
      if (lid != null && String(lid).trim() === target) return u.id;
    }
    if (users.length < perPage) break;
  }
  return null;
}

/** createUser 重複後に RPC が null のときの救済（DB/RPC 不整合） */
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

async function assertLineLinkAllowed(
  admin: ReturnType<typeof createClient>,
  userId: string,
  lineUserId: string,
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
  const existing = userResp.user.app_metadata?.line_id as string | undefined;
  if (existing && existing !== lineUserId) {
    return json({
      error: "identity_conflict",
      details:
        "このアカウントには別の LINE アカウントがすでに紐づいています。",
    }, 409);
  }
  return null;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
