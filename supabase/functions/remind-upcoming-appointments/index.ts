// supabase/functions/remind-upcoming-appointments/index.ts
// Edge Function: envía recordatorios push a pacientes con citas próximas (24h).
// Se ejecuta periódicamente via pg_cron (cada hora).
//
// Secrets requeridos en Supabase (Settings → Edge Functions → Secrets):
//   FIREBASE_SERVICE_ACCOUNT  → contenido JSON de la cuenta de servicio Firebase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
serve(async (_req: Request) => {
  try {
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

    // ── Buscar citas próximas (en las siguientes 24–25 horas) ────────────
    // La ventana de 25 horas evita perder citas entre ejecuciones del cron
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in25Hours = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    const { data: appointments, error: apptError } = await supabase
      .from("appointments")
      .select(`
        id,
        date_time,
        patient_id,
        patients(profile_id, first_name),
        doctor:doctors(user:profiles(name)),
        service:services(service_name)
      `)
      .eq("status", "upcoming")
      .eq("reminder_sent", false)
      .gte("date_time", in24Hours.toISOString())
      .lte("date_time", in25Hours.toISOString());

    if (apptError) {
      console.error("Error buscando citas:", apptError);
      return new Response(
        JSON.stringify({ error: "Error buscando citas próximas" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!appointments || appointments.length === 0) {
      console.log("No hay citas que requieran recordatorio en este ciclo.");
      return new Response(
        JSON.stringify({ sent: 0, message: "No hay citas para recordar" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    console.log(`Encontradas ${appointments.length} citas para recordar.`);

    // Obtener access token OAuth2 (una sola vez para todos los envíos)
    const accessToken = await getGoogleAccessToken(serviceAccount);

    let totalSent = 0;
    let totalErrors = 0;

    for (const appointment of appointments) {
      const profileId = (appointment.patients as { profile_id: string } | null)?.profile_id;
      if (!profileId) {
        console.warn(`Cita ${appointment.id}: sin profile_id asociado.`);
        continue;
      }

      // Obtener tokens FCM activos del paciente
      const { data: devices } = await supabase
        .from("linked_devices")
        .select("id, push_token, device_type")
        .eq("user_id", profileId)
        .eq("is_active", true);

      if (!devices || devices.length === 0) {
        console.log(`Cita ${appointment.id}: paciente sin dispositivos vinculados.`);
        // Aún así marcar como enviado para no reintentar
        await supabase
          .from("appointments")
          .update({ reminder_sent: true })
          .eq("id", appointment.id);
        continue;
      }

      // Formatear hora de la cita
      const appointmentDate = new Date(appointment.date_time as string);
      const timeStr = appointmentDate.toLocaleTimeString("es-MX", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: true,
      });
      const dateStr = appointmentDate.toLocaleDateString("es-MX", {
        weekday: "long",
        day: "numeric",
        month: "long",
      });

      const patientFirstName = (appointment.patients as { first_name: string } | null)?.first_name ?? "Paciente";
      const doctorName = (appointment.doctor as { user: { name: string } } | null)?.user?.name ?? "tu dentista";
      const serviceName = (appointment.service as { service_name: string } | null)?.service_name ?? "consulta";

      const notification = {
        title: "🦷 DentalSync – Recordatorio de cita",
        body: `Hola ${patientFirstName}, mañana ${dateStr} a las ${timeStr} tienes cita de ${serviceName} con ${doctorName}. ¡No faltes!`,
      };

      let sentForThisAppt = false;
      for (const device of devices) {
        const result = await sendFcmV1(
          projectId,
          accessToken,
          device.push_token as string,
          notification,
          {
            appointmentId: appointment.id as string,
            type: "reminder",
          },
        );

        if (result.success) {
          sentForThisAppt = true;
          totalSent++;
          console.log(`✓ Recordatorio enviado (${device.device_type}) para cita ${appointment.id}`);
        } else {
          totalErrors++;
          console.error(`✗ Error FCM (${device.device_type}): ${result.error}`);
          // Desactivar tokens inválidos
          if (result.error === "UNREGISTERED" || result.error === "INVALID_ARGUMENT") {
            await supabase
              .from("linked_devices")
              .update({ is_active: false })
              .eq("id", device.id);
          }
        }
      }

      // Marcar cita como recordada (independientemente de si se envió o no)
      await supabase
        .from("appointments")
        .update({ reminder_sent: true })
        .eq("id", appointment.id);

      if (sentForThisAppt) {
        console.log(`✓ Cita ${appointment.id} marcada como recordada.`);
      }
    }

    return new Response(
      JSON.stringify({
        sent: totalSent,
        errors: totalErrors,
        appointmentsProcessed: appointments.length,
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
