-- Permite al personal activo registrar servicios para su propia clinica.
-- Requiere la funcion is_active_clinic_staff creada por la migracion anterior.

DROP POLICY IF EXISTS staff_runtime_read_services ON public.services;
CREATE POLICY staff_runtime_read_services ON public.services
  FOR SELECT TO authenticated
  USING (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_insert_services ON public.services;
CREATE POLICY staff_runtime_insert_services ON public.services
  FOR INSERT TO authenticated
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_update_services ON public.services;
CREATE POLICY staff_runtime_update_services ON public.services
  FOR UPDATE TO authenticated
  USING (public.is_active_clinic_staff(clinic_id))
  WITH CHECK (public.is_active_clinic_staff(clinic_id));

DROP POLICY IF EXISTS staff_runtime_delete_services ON public.services;
CREATE POLICY staff_runtime_delete_services ON public.services
  FOR DELETE TO authenticated
  USING (public.is_active_clinic_staff(clinic_id));

-- El alta usa una funcion controlada para no depender de la combinacion de
-- politicas RLS que pueda existir en instalaciones anteriores.
CREATE OR REPLACE FUNCTION public.create_clinic_service(
  p_clinic_id UUID,
  p_service_name TEXT,
  p_price NUMERIC,
  p_duration_mins INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  created_service public.services%ROWTYPE;
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

  IF NULLIF(btrim(p_service_name), '') IS NULL THEN
    RAISE EXCEPTION 'Service name is required' USING ERRCODE = '22023';
  END IF;
  IF p_price IS NULL OR p_price < 0 THEN
    RAISE EXCEPTION 'Price must be zero or greater' USING ERRCODE = '22023';
  END IF;
  IF p_duration_mins IS NULL OR p_duration_mins NOT BETWEEN 1 AND 480 THEN
    RAISE EXCEPTION 'Duration must be between 1 and 480 minutes'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.services (
    clinic_id,
    service_name,
    price,
    duration_mins
  ) VALUES (
    p_clinic_id,
    btrim(p_service_name),
    p_price,
    p_duration_mins
  )
  RETURNING * INTO created_service;

  RETURN jsonb_build_object(
    'id', created_service.id,
    'service_name', created_service.service_name,
    'price', created_service.price,
    'duration_mins', created_service.duration_mins
  );
END;
$$;

REVOKE ALL ON FUNCTION public.create_clinic_service(UUID, TEXT, NUMERIC, INTEGER)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_clinic_service(UUID, TEXT, NUMERIC, INTEGER)
  TO authenticated;
