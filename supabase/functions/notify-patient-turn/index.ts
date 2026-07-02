// supabase/functions/notify-patient-turn/index.ts
// Edge Function de Supabase: envía notificación push al paciente vía FCM HTTP v1 API
// cuando el dentista cambia el estado de su cita.
//
// Variables de entorno requeridas (configurar en Supabase → Settings → Edge Functions → Secrets):
//   SUPABASE_URL             → URL de tu proyecto Supabase (ya disponible por defecto)
//   SUPABASE_SERVICE_ROLE_KEY → Service role key de Supabase (ya disponible por defecto)
//   FCM_SERVER_KEY            → Server key de Firebase (Configuración del Proyecto → Cloud Messaging)

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

// ── Handler principal ───────────────────────────────────────────────────────
serve(async (req: Request) => {
  // Solo aceptar POST
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
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const message = STATUS_MESSAGES[newStatus];
    if (!message) {
      // Estado no notificable, terminar silenciosamente
      return new Response(JSON.stringify({ skipped: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // ── Inicializar cliente Supabase con service role ─────────────────────
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // ── Obtener patient_id de la cita ─────────────────────────────────────
    const { data: appointment, error: apptError } = await supabase
      .from("appointments")
      .select("patient_id, patients(profile_id)")
      .eq("id", appointmentId)
      .single();

    if (apptError || !appointment) {
      console.error("Error obteniendo cita:", apptError);
      return new Response(
        JSON.stringify({ error: "Cita no encontrada" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // patient_id es el id en tabla patients; necesitamos profile_id para buscar tokens
    const profileId = appointment.patients?.profile_id;
    if (!profileId) {
      return new Response(
        JSON.stringify({ error: "No se encontró el perfil del paciente" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── Obtener tokens FCM activos del paciente ───────────────────────────
    const { data: devices, error: devicesError } = await supabase
      .from("linked_devices")
      .select("push_token, device_type")
      .eq("user_id", profileId)
      .eq("is_active", true);

    if (devicesError || !devices || devices.length === 0) {
      console.log("No hay dispositivos vinculados para el paciente:", profileId);
      return new Response(
        JSON.stringify({ sent: 0, message: "Sin dispositivos registrados" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── Enviar push via FCM Legacy HTTP API ───────────────────────────────
    // (Más simple que v1: solo requiere el Server Key, no OAuth2)
    const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
    if (!fcmServerKey) {
      console.error("FCM_SERVER_KEY no configurado en los secrets de Supabase");
      return new Response(
        JSON.stringify({ error: "FCM no configurado" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    let successCount = 0;
    const errors: string[] = [];

    for (const device of devices) {
      const token = device.push_token as string;

      const fcmPayload = {
        to: token,
        notification: {
          title: message.title,
          body: message.body,
          sound: "default",
        },
        data: {
          appointmentId,
          newStatus,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        priority: "high",
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "dentalsync_high_importance",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const fcmResponse = await fetch(
        "https://fcm.googleapis.com/fcm/send",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `key=${fcmServerKey}`,
          },
          body: JSON.stringify(fcmPayload),
        }
      );

      const fcmResult = await fcmResponse.json();

      if (fcmResult.success === 1) {
        successCount++;
        console.log(`✓ Notificación enviada a ${device.device_type}`);
      } else {
        const errorMsg = fcmResult.results?.[0]?.error ?? "Error desconocido";
        errors.push(errorMsg);
        console.error(`✗ Error FCM (${device.device_type}): ${errorMsg}`);

        // Si el token ya no es válido, desactivarlo en Supabase
        if (
          errorMsg === "NotRegistered" ||
          errorMsg === "InvalidRegistration"
        ) {
          await supabase
            .from("linked_devices")
            .update({ is_active: false })
            .eq("push_token", token);
        }
      }
    }

    return new Response(
      JSON.stringify({
        sent: successCount,
        total: devices.length,
        errors: errors.length > 0 ? errors : undefined,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error inesperado en Edge Function:", error);
    return new Response(
      JSON.stringify({ error: "Error interno del servidor" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
