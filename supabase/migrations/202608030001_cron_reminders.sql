-- ============================================================
-- MIGRACIÓN: RECORDATORIOS AUTOMÁTICOS DE CITAS (CRON JOB)
-- ============================================================

-- 1. Asegurar columna reminder_sent en la tabla appointments
ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS reminder_sent BOOLEAN DEFAULT false;

-- Index para optimizar la consulta de la Edge Function
CREATE INDEX IF NOT EXISTS idx_appointments_reminder_status 
  ON public.appointments (status, reminder_sent, date_time);

-- 2. Función para invocar la Edge Function remind-upcoming-appointments
-- (Requiere que las extensiones pg_cron y pg_net estén activas en Supabase Dashboard)
CREATE OR REPLACE FUNCTION public.trigger_remind_upcoming_appointments()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  supabase_url text;
  anon_key text;
BEGIN
  -- Reemplazar URL y ANON key o invocar mediante pg_net si está disponible
  -- Esta función puede ser programada en pg_cron ejecutando:
  -- SELECT cron.schedule('remind-upcoming-appointments-hourly', '0 * * * *', 'SELECT public.trigger_remind_upcoming_appointments();');
  NULL;
END;
$$;
