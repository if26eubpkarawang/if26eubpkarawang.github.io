import { createClient } from "npm:@supabase/supabase-js@2";

const allowedOrigin = "https://yudhasinaga-26.github.io";
const loginEmailSuffix = "@if26e.invalid";
const corsHeaders = {
  "Access-Control-Allow-Origin": allowedOrigin,
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
  "Cache-Control": "no-store",
  "Vary": "Origin",
};

function jsonResponse(status: number, message: string, userId?: string): Response {
  const body: { error?: string; userId?: string } = {};
  if (status >= 400) body.error = message;
  else body.userId = userId;
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function getDefaultKey(keysName: string, legacyName: string): string {
  const serializedKeys = Deno.env.get(keysName);
  if (serializedKeys) {
    const keys = JSON.parse(serializedKeys) as Record<string, unknown>;
    if (typeof keys.default === "string" && keys.default) return keys.default;
  }
  const legacyKey = Deno.env.get(legacyName);
  if (legacyKey) return legacyKey;
  throw new Error("Supabase API key is not configured.");
}

Deno.serve(async (request: Request): Promise<Response> => {
  const origin = request.headers.get("origin");
  if (origin !== allowedOrigin) {
    return new Response(JSON.stringify({ error: "Origin tidak diizinkan." }), {
      status: 403,
      headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
    });
  }

  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse(405, "Metode permintaan tidak diizinkan.");
  }

  const authorization = request.headers.get("authorization") || "";
  const accessToken = authorization.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) return jsonResponse(401, "Sesi login tidak valid. Silakan login kembali.");

  let payload: Record<string, unknown>;
  try {
    const parsed: unknown = await request.json();
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return jsonResponse(400, "Data perubahan tidak valid.");
    }
    payload = parsed as Record<string, unknown>;
  } catch {
    return jsonResponse(400, "Data perubahan tidak valid.");
  }

  const currentPassword = payload.currentPassword;
  const requestedUserId = payload.userId;
  const newPassword = payload.newPassword;
  if (
    typeof currentPassword !== "string" || currentPassword.length === 0 || currentPassword.length > 256 ||
    typeof requestedUserId !== "string" || typeof newPassword !== "string"
  ) {
    return jsonResponse(400, "Lengkapi User ID dan password dengan format yang benar.");
  }

  const userId = requestedUserId.trim().toLowerCase();
  if (!/^[a-z0-9._-]{3,64}$/.test(userId)) {
    return jsonResponse(400, "User ID harus 3–64 karakter: huruf, angka, titik, garis bawah, atau tanda hubung.");
  }
  if (newPassword.length < 12 || newPassword.length > 128) {
    return jsonResponse(400, "Password baru harus terdiri dari 12–128 karakter.");
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!supabaseUrl) throw new Error("Supabase URL is not configured.");

    const publishableKey = getDefaultKey("SUPABASE_PUBLISHABLE_KEYS", "SUPABASE_ANON_KEY");
    const secretKey = getDefaultKey("SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY");
    const userClient = createClient(supabaseUrl, publishableKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const membershipClient = createClient(supabaseUrl, publishableKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: "Bearer " + accessToken } },
    });
    const adminClient = createClient(supabaseUrl, secretKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: userResult, error: userError } = await userClient.auth.getUser(accessToken);
    if (userError || !userResult.user) {
      return jsonResponse(401, "Sesi login tidak valid. Silakan login kembali.");
    }
    const user = userResult.user;
    if (!user.email || !user.email.toLowerCase().endsWith(loginEmailSuffix)) {
      return jsonResponse(403, "Akun ini tidak memakai format login portal IF26E.");
    }

    const { data: membership, error: membershipError } = await membershipClient
      .from("if26e_admins")
      .select("user_id")
      .eq("user_id", user.id)
      .maybeSingle();
    if (membershipError) {
      console.error("Tidak dapat memeriksa hak admin.", membershipError.code || membershipError.name);
      return jsonResponse(500, "Hak admin tidak dapat diperiksa. Coba lagi nanti.");
    }
    if (!membership) return jsonResponse(403, "Akun ini tidak memiliki hak admin.");

    const { error: passwordError } = await userClient.auth.signInWithPassword({
      email: user.email,
      password: currentPassword,
    });
    if (passwordError) return jsonResponse(401, "Password saat ini tidak cocok.");

    const { error: updateError } = await adminClient.auth.admin.updateUserById(user.id, {
      email: userId + loginEmailSuffix,
      email_confirm: true,
      password: newPassword,
    });
    if (updateError) {
      const code = String(updateError.code || "");
      if (code === "email_exists" || code === "user_already_exists") {
        return jsonResponse(409, "User ID tersebut sudah digunakan.");
      }
      console.error("Pembaruan kredensial admin gagal.", code || updateError.name);
      return jsonResponse(400, "Kredensial tidak dapat diperbarui. Periksa password dan coba lagi.");
    }

    return jsonResponse(200, "", userId);
  } catch (error) {
    console.error(
      "Fungsi perubahan kredensial gagal.",
      error instanceof Error ? error.name : "Unknown error",
    );
    return jsonResponse(500, "Layanan perubahan kredensial belum siap. Hubungi administrator.");
  }
});
