// supabase/functions/notify-patient-turn/index.ts
// Edge Function: envía notificación push al paciente vía FCM v1 API
// usando Service Account (JWT OAuth2) — más seguro que el Server Key.
//
// Secret requerido en Supabase (Settings → Edge Functions → Secrets):
//   FIREBASE_SERVICE_ACCOUNT  → contenido JSON de la cuenta de servicio Firebase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Mensajes por estado ─────────────────────────────────────────────────────
const STATUS_MESSAGES: Record<string, { title: string; body: string }> = {
  in_lobby: {
    title: "🦷 DentalSync – ¡Prepárate!",
    body: "El dentista te llamará en breve. Por favor dirígete a la sala de espera.",
  },
  in_treatment: {
    title: "🦷 DentalSync – ¡Es tu turno!",
    body: "El dentista está listo para atenderte. Por favor pasa al consultorio.",
  },
  completed: {
    title: "✅ DentalSync – Consulta completada",
    body: "Tu consulta ha finalizado. Esperamos verte pronto. ¡Que te mejores!",
  },
};

// ── JWT + OAuth2 para FCM v1 API ────────────────────────────────────────────

/** Codifica un objeto en Base64URL (sin padding) */
function base64url(data: string): string {
  return btoa(unescape(encodeURIComponent(data)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

/** Obtiene un access token de Google usando el Service Account */
async function getGoogleAccessToken(serviceAccount: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  const signingInput = `${header}.${payload}`;

  // Importar la clave privada RSA del service account
  const pemKey = serviceAccount.private_key.replace(/\\n/g, "\n");
  const pemBody = pemKey
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  // Firmar el JWT
  const encoder = new TextEncoder();
  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(signingInput),
  );

  const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const jwt = `${signingInput}.${signature}`;

  // Intercambiar JWT por access token
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) {
    throw new Error(`OAuth2 token error: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

/** Envía un push a un token FCM usando la API v1 */
async function sendFcmV1(
  projectId: string,
  accessToken: string,
  deviceToken: string,
  notification: { title: string; body: string },
  data: Record<string, string>,
): Promise<{ success: boolean; error?: string }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "dentalsync_high_importance",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: { sound: "default", badge: 1 },
            },
          },
          data,
        },
      }),
    },
  );

  const result = await res.json();
  if (res.ok) {
    return { success: true };
  }

  const errorCode = result?.error?.details?.[0]?.errorCode ?? result?.error?.message ?? "UNKNOWN";
  return { success: false, error: errorCode };
}

// ── Handler principal ───────────────────────────────────────────────────────
serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { appointmentId, newStatus } = await req.json();

    if (!appointmentId || !newStatus) {
      return new Response(
        JSON.stringify({ error: "appointmentId y newStatus son requeridos" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const message = STATUS_MESSAGES[newStatus];
    if (!message) {
      return new Response(JSON.stringify({ skipped: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // ── Service Account ──────────────────────────────────────────────────
    const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!saRaw) {
      console.error("FIREBASE_SERVICE_ACCOUNT no configurado");
      return new Response(JSON.stringify({ error: "Firebase no configurado" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
    const serviceAccount = JSON.parse(saRaw);
    const projectId: string = serviceAccount.project_id;

    // ── Supabase ─────────────────────────────────────────────────────────
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Obtener profile_id del paciente a partir del appointmentId
    const { data: appointment, error: apptError } = await supabase
      .from("appointments")
      .select("patient_id, patients(profile_id)")
      .eq("id", appointmentId)
      .single();

    if (apptError || !appointment) {
      console.error("Cita no encontrada:", apptError);
      return new Response(JSON.stringify({ error: "Cita no encontrada" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    const profileId = (appointment.patients as { profile_id: string } | null)?.profile_id;
    if (!profileId) {
      return new Response(
        JSON.stringify({ error: "No se encontró el perfil del paciente" }),
        { status: 404, headers: { "Content-Type": "application/json" } },
      );
    }

    // Obtener tokens FCM activos
    const { data: devices } = await supabase
      .from("linked_devices")
      .select("id, push_token, device_type")
      .eq("user_id", profileId)
      .eq("is_active", true);

    if (!devices || devices.length === 0) {
      console.log("Sin dispositivos vinculados para:", profileId);
      return new Response(
        JSON.stringify({ sent: 0, message: "Sin dispositivos registrados" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // Obtener access token OAuth2 (una sola vez para todos los envíos)
    const accessToken = await getGoogleAccessToken(serviceAccount);

    let successCount = 0;
    const errors: string[] = [];

    for (const device of devices) {
      const result = await sendFcmV1(
        projectId,
        accessToken,
        device.push_token as string,
        message,
        { appointmentId, newStatus },
      );

      if (result.success) {
        successCount++;
        console.log(`✓ Notificación enviada (${device.device_type})`);
      } else {
        errors.push(result.error ?? "UNKNOWN");
        console.error(`✗ Error FCM (${device.device_type}): ${result.error}`);

        // Desactivar tokens inválidos automáticamente
        if (
          result.error === "UNREGISTERED" ||
          result.error === "INVALID_ARGUMENT"
        ) {
          await supabase
            .from("linked_devices")
            .update({ is_active: false })
            .eq("id", device.id);
        }
      }
    }

    return new Response(
      JSON.stringify({
        sent: successCount,
        total: devices.length,
        errors: errors.length > 0 ? errors : undefined,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Error inesperado:", error);
    return new Response(JSON.stringify({ error: "Error interno del servidor" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
