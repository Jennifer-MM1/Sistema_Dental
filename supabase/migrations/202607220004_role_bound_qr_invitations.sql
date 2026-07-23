-- Invitaciones seguras: cada codigo queda ligado a un rol y se canjea una vez.

ALTER TABLE public.invitation_codes
  ADD COLUMN IF NOT EXISTS target_role TEXT;

-- Los codigos antiguos no tenian rol verificable. Se invalidan antes de
-- asignarles un valor de compatibilidad para poder exigir NOT NULL.
UPDATE public.invitation_codes
SET is_used = true,
    target_role = 'client'
WHERE target_role IS NULL;

ALTER TABLE public.invitation_codes
  ALTER COLUMN target_role SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'invitation_codes_target_role_check'
      AND conrelid = 'public.invitation_codes'::regclass
  ) THEN
    ALTER TABLE public.invitation_codes
      ADD CONSTRAINT invitation_codes_target_role_check
      CHECK (target_role IN ('client', 'dentist', 'secretary'));
  END IF;
END;
$$;

-- Se eliminan las politicas permisivas anteriores. La creacion y el canje se
-- realizan exclusivamente mediante las funciones seguras de esta migracion.
DROP POLICY IF EXISTS "Lectura de códigos" ON public.invitation_codes;
DROP POLICY IF EXISTS "Inserción de códigos" ON public.invitation_codes;
DROP POLICY IF EXISTS "Actualización de códigos" ON public.invitation_codes;
DROP POLICY IF EXISTS role_bound_read_invitations ON public.invitation_codes;

CREATE POLICY role_bound_read_invitations ON public.invitation_codes
  FOR SELECT TO authenticated
  USING (
    created_by = auth.uid()
    OR public.is_active_clinic_staff(clinic_id)
  );

CREATE OR REPLACE FUNCTION public.create_role_invitation(
  p_clinic_id UUID,
  p_target_role TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  actor_role TEXT;
  generated_code TEXT;
  expiration TIMESTAMPTZ := now() + interval '24 hours';
BEGIN
  SELECT membership.role_in_clinic
  INTO actor_role
  FROM public.clinic_memberships AS membership
  WHERE membership.user_id = auth.uid()
    AND membership.clinic_id = p_clinic_id
    AND membership.is_active = true
  LIMIT 1;

  IF actor_role IS NULL THEN
    RAISE EXCEPTION 'Active clinic membership required' USING ERRCODE = '42501';
  END IF;

  IF p_target_role NOT IN ('client', 'dentist', 'secretary') THEN
    RAISE EXCEPTION 'Invalid invitation role' USING ERRCODE = '22023';
  END IF;

  IF actor_role NOT IN ('owner', 'dentist') AND
     NOT (actor_role = 'secretary' AND p_target_role = 'client') THEN
    RAISE EXCEPTION 'Not allowed to invite this role' USING ERRCODE = '42501';
  END IF;

  generated_code := CASE p_target_role
    WHEN 'client' THEN 'PAC-'
    WHEN 'dentist' THEN 'DEN-'
    ELSE 'SEC-'
  END || substr(upper(replace(gen_random_uuid()::text, '-', '')), 1, 8);

  INSERT INTO public.invitation_codes (
    clinic_id,
    code,
    created_by,
    target_role,
    is_used,
    expires_at
  ) VALUES (
    p_clinic_id,
    generated_code,
    auth.uid(),
    p_target_role,
    false,
    expiration
  );

  RETURN jsonb_build_object(
    'code', generated_code,
    'target_role', p_target_role,
    'expires_at', expiration
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_role_invitation(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  invitation public.invitation_codes%ROWTYPE;
  existing_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  SELECT code_row.*
  INTO invitation
  FROM public.invitation_codes AS code_row
  WHERE upper(code_row.code) = upper(btrim(p_code))
  FOR UPDATE;

  IF invitation.id IS NULL OR invitation.is_used = true OR
     invitation.expires_at IS NULL OR invitation.expires_at <= now() THEN
    RAISE EXCEPTION 'Invalid, expired or already used invitation'
      USING ERRCODE = '22023';
  END IF;

  SELECT membership.role_in_clinic
  INTO existing_role
  FROM public.clinic_memberships AS membership
  WHERE membership.clinic_id = invitation.clinic_id
    AND membership.user_id = auth.uid();

  IF existing_role = 'owner' THEN
    RAISE EXCEPTION 'Clinic owner role cannot be replaced'
      USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.clinic_memberships (
    clinic_id,
    user_id,
    role_in_clinic,
    is_active
  ) VALUES (
    invitation.clinic_id,
    auth.uid(),
    invitation.target_role,
    true
  )
  ON CONFLICT (clinic_id, user_id) DO UPDATE
  SET role_in_clinic = EXCLUDED.role_in_clinic,
      is_active = true;

  UPDATE public.profiles
  SET role = invitation.target_role
  WHERE id = auth.uid();

  IF invitation.target_role = 'dentist' AND NOT EXISTS (
    SELECT 1
    FROM public.doctors AS doctor
    WHERE doctor.user_id = auth.uid()
      AND doctor.clinic_id = invitation.clinic_id
  ) THEN
    INSERT INTO public.doctors (
      user_id,
      clinic_id,
      specialty,
      cabin_assigned,
      is_available
    ) VALUES (
      auth.uid(),
      invitation.clinic_id,
      'General',
      'Sin asignar',
      true
    );
  END IF;

  IF invitation.target_role = 'client' THEN
    UPDATE public.patients
    SET clinic_id = invitation.clinic_id
    WHERE profile_id = auth.uid()
      AND clinic_id IS NULL;
  END IF;

  UPDATE public.invitation_codes
  SET is_used = true,
      used_by = auth.uid()
  WHERE id = invitation.id;

  RETURN jsonb_build_object(
    'clinic_id', invitation.clinic_id,
    'role', invitation.target_role
  );
END;
$$;

REVOKE ALL ON FUNCTION public.create_role_invitation(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_role_invitation(UUID, TEXT)
  TO authenticated;
REVOKE ALL ON FUNCTION public.redeem_role_invitation(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_role_invitation(TEXT)
  TO authenticated;
