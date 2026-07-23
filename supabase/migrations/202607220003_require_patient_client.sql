-- Restaura la regla: todo paciente debe pertenecer a un cliente del sistema.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.patients WHERE profile_id IS NULL
  ) THEN
    RAISE EXCEPTION
      'Hay pacientes sin cliente. Vincule esos registros antes de aplicar esta migracion.';
  END IF;
END;
$$;

ALTER TABLE public.patients
  ALTER COLUMN profile_id SET NOT NULL;

CREATE OR REPLACE FUNCTION public.create_clinic_patient(
  p_clinic_id UUID,
  p_profile_id UUID,
  p_first_name TEXT,
  p_last_name TEXT,
  p_date_of_birth DATE,
  p_relationship TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  created_patient public.patients%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.clinic_memberships AS membership
    WHERE membership.user_id = auth.uid()
      AND membership.clinic_id = p_clinic_id
      AND membership.is_active = true
      AND membership.role_in_clinic IN ('owner', 'dentist', 'secretary')
  ) THEN
    RAISE EXCEPTION 'Active clinic staff membership required'
      USING ERRCODE = '42501';
  END IF;

  IF p_profile_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.clinic_memberships AS client_membership
    WHERE client_membership.user_id = p_profile_id
      AND client_membership.clinic_id = p_clinic_id
      AND client_membership.is_active = true
      AND client_membership.role_in_clinic = 'client'
  ) THEN
    RAISE EXCEPTION 'An active client from this clinic is required'
      USING ERRCODE = '22023';
  END IF;

  IF NULLIF(btrim(p_first_name), '') IS NULL OR
     NULLIF(btrim(p_last_name), '') IS NULL THEN
    RAISE EXCEPTION 'Patient first and last name are required'
      USING ERRCODE = '22023';
  END IF;

  IF p_relationship NOT IN ('self', 'child', 'spouse', 'parent', 'other') THEN
    RAISE EXCEPTION 'Invalid patient relationship' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.patients (
    clinic_id,
    profile_id,
    first_name,
    last_name,
    date_of_birth,
    relationship
  ) VALUES (
    p_clinic_id,
    p_profile_id,
    btrim(p_first_name),
    btrim(p_last_name),
    p_date_of_birth,
    p_relationship
  )
  RETURNING * INTO created_patient;

  RETURN jsonb_build_object(
    'id', created_patient.id,
    'clinic_id', created_patient.clinic_id,
    'profile_id', created_patient.profile_id,
    'first_name', created_patient.first_name,
    'last_name', created_patient.last_name,
    'date_of_birth', created_patient.date_of_birth,
    'relationship', created_patient.relationship,
    'created_at', created_patient.created_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.create_clinic_patient(
  UUID, UUID, TEXT, TEXT, DATE, TEXT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_clinic_patient(
  UUID, UUID, TEXT, TEXT, DATE, TEXT
) TO authenticated;
