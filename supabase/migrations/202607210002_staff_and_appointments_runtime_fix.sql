-- Compatibilidad del esquema remoto con agenda y gestion de personal.

ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_patients_clinic_id
  ON public.patients(clinic_id);

UPDATE public.patients AS patient
SET clinic_id = (
  SELECT cm.clinic_id
  FROM public.clinic_memberships AS cm
  WHERE cm.user_id = patient.profile_id
    AND cm.role_in_clinic = 'client'
    AND cm.is_active = true
  ORDER BY cm.created_at
  LIMIT 1
)
WHERE patient.clinic_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.clinic_memberships AS cm
    WHERE cm.user_id = patient.profile_id
      AND cm.role_in_clinic = 'client'
      AND cm.is_active = true
  );

CREATE TABLE IF NOT EXISTS public.doctor_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL DEFAULT '08:00',
  end_time TIME NOT NULL DEFAULT '17:00',
  is_working_day BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (doctor_user_id, clinic_id, day_of_week),
  CHECK (end_time > start_time)
);

CREATE TABLE IF NOT EXISTS public.doctor_days_off (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (doctor_user_id, clinic_id, date)
);

CREATE OR REPLACE FUNCTION public.is_active_clinic_staff(
  target_clinic_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.clinic_memberships AS membership
    WHERE membership.clinic_id = target_clinic_id
      AND membership.user_id = auth.uid()
      AND membership.is_active = true
      AND membership.role_in_clinic IN ('owner', 'dentist', 'secretary')
  );
$$;

REVOKE ALL ON FUNCTION public.is_active_clinic_staff(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_active_clinic_staff(UUID) TO authenticated;

ALTER TABLE public.doctor_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_days_off ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS staff_runtime_read_schedules ON public.doctor_schedules;
CREATE POLICY staff_runtime_read_schedules ON public.doctor_schedules
  FOR SELECT TO authenticated
  USING (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_insert_schedules ON public.doctor_schedules;
CREATE POLICY staff_runtime_insert_schedules ON public.doctor_schedules
  FOR INSERT TO authenticated
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_update_schedules ON public.doctor_schedules;
CREATE POLICY staff_runtime_update_schedules ON public.doctor_schedules
  FOR UPDATE TO authenticated
  USING (public.is_active_clinic_staff(clinic_id))
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_read_days_off ON public.doctor_days_off;
CREATE POLICY staff_runtime_read_days_off ON public.doctor_days_off
  FOR SELECT TO authenticated
  USING (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_insert_days_off ON public.doctor_days_off;
CREATE POLICY staff_runtime_insert_days_off ON public.doctor_days_off
  FOR INSERT TO authenticated
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_delete_days_off ON public.doctor_days_off;
CREATE POLICY staff_runtime_delete_days_off ON public.doctor_days_off
  FOR DELETE TO authenticated
  USING (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_update_doctors ON public.doctors;
CREATE POLICY staff_runtime_update_doctors ON public.doctors
  FOR UPDATE TO authenticated
  USING (public.is_active_clinic_staff(clinic_id))
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_insert_doctors ON public.doctors;
CREATE POLICY staff_runtime_insert_doctors ON public.doctors
  FOR INSERT TO authenticated
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_insert_appointments ON public.appointments;
CREATE POLICY staff_runtime_insert_appointments ON public.appointments
  FOR INSERT TO authenticated
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_update_appointments ON public.appointments;
CREATE POLICY staff_runtime_update_appointments ON public.appointments
  FOR UPDATE TO authenticated
  USING (public.is_active_clinic_staff(clinic_id))
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_update_memberships ON public.clinic_memberships;
CREATE POLICY staff_runtime_update_memberships ON public.clinic_memberships
  FOR UPDATE TO authenticated
  USING (public.is_active_clinic_staff(clinic_id))
  WITH CHECK (public.is_active_clinic_staff(clinic_id));
