// supabase/functions/send-fcm/index.ts
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";

type ServiceAccount = {
  private_key: string;
  client_email: string;
  token_uri: string;
};

const SA_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT");
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID");

if (!SA_JSON || !FCM_PROJECT_ID) {
  console.error("Missing FCM_SERVICE_ACCOUNT or FCM_PROJECT_ID environment variables");
}

const serviceAccount: ServiceAccount = SA_JSON ? JSON.parse(SA_JSON) : ({} as any);
let cachedToken: { access_token: string; exp: number } | null = null;

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.access_token;

  const iat = now;
  const exp = now + 3600;
  const scope = "https://www.googleapis.com/auth/firebase.messaging";
  const alg = "RS256";
  const key = await importPKCS8(serviceAccount.private_key, alg);

  const jwt = await new SignJWT({ scope })
    .setProtectedHeader({ alg, typ: "JWT" })
    .setIssuedAt(iat)
    .setExpirationTime(exp)
    .setAudience(serviceAccount.token_uri)
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .sign(key);

  const resp = await fetch(serviceAccount.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!resp.ok) {
    throw new Error(`Token exchange failed: ${resp.status} ${await resp.text()}`);
  }

  const json = await resp.json();
  cachedToken = { access_token: json.access_token, exp: now + (json.expires_in ?? 3600) };
  return cachedToken.access_token;
}

type InvokeBody = {
  token: string;
  title?: string;
  body?: string;
  data?: Record<string, string>;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Only POST allowed", { status: 405 });
  }

  try {
    const { token, title, body, data }: InvokeBody = await req.json();
    if (!token) return new Response("Missing token", { status: 400 });

    const accessToken = await getAccessToken();
    const url = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;

    const payload = {
      message: {
        token,
        notification: title || body ? { title: title ?? "", body: body ?? "" } : undefined,
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "default",
            sound: "default",
          },
        },
        data: data ?? {},
      },
    };

    const fcm = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const fcmText = await fcm.text();
    if (!fcm.ok) return new Response(`FCM error ${fcm.status}: ${fcmText}`, { status: 500 });

    return new Response(fcmText, { status: 200 });
  } catch (err) {
    return new Response(String(err?.message ?? err), { status: 500 });
  }
});
