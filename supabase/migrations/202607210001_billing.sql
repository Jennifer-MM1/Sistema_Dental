-- Facturación auditable para DentalSync.
-- Aplicar con Supabase CLI o desde el SQL Editor antes de habilitar la vista.

CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE RESTRICT,
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE RESTRICT,
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE RESTRICT,
  invoice_number TEXT NOT NULL UNIQUE,
  subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
  discount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
  tax NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
  total NUMERIC(12,2) NOT NULL CHECK (total >= 0),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'partial', 'paid', 'void')),
  notes TEXT,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES public.profiles(id),
  voided_at TIMESTAMPTZ,
  voided_by UUID REFERENCES public.profiles(id),
  void_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (clinic_id, appointment_id),
  CHECK (total = ROUND(subtotal - discount + tax, 2)),
  CHECK (discount <= subtotal)
);

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE RESTRICT,
  invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE RESTRICT,
  receipt_number TEXT NOT NULL UNIQUE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  payment_method TEXT NOT NULL
    CHECK (payment_method IN ('cash', 'card', 'transfer', 'other')),
  reference TEXT,
  notes TEXT,
  paid_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  received_by UUID NOT NULL REFERENCES public.profiles(id),
  voided_at TIMESTAMPTZ,
  voided_by UUID REFERENCES public.profiles(id),
  void_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invoices_clinic_issued
  ON public.invoices(clinic_id, issued_at DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_patient ON public.invoices(patient_id);
CREATE INDEX IF NOT EXISTS idx_payments_invoice_paid
  ON public.payments(invoice_id, paid_at DESC);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Facturas visibles para miembros activos" ON public.invoices;
CREATE POLICY "Facturas visibles para miembros activos" ON public.invoices
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.clinic_memberships cm
      WHERE cm.clinic_id = invoices.clinic_id
        AND cm.user_id = auth.uid() AND cm.is_active = true
        AND cm.role_in_clinic IN ('owner', 'dentist', 'secretary')
    ) OR EXISTS (
      SELECT 1 FROM public.patients p
      WHERE p.id = invoices.patient_id AND p.profile_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Pagos visibles para miembros activos" ON public.payments;
CREATE POLICY "Pagos visibles para miembros activos" ON public.payments
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.clinic_memberships cm
      WHERE cm.clinic_id = payments.clinic_id
        AND cm.user_id = auth.uid() AND cm.is_active = true
        AND cm.role_in_clinic IN ('owner', 'dentist', 'secretary')
    ) OR EXISTS (
      SELECT 1 FROM public.invoices i
      JOIN public.patients p ON p.id = i.patient_id
      WHERE i.id = payments.invoice_id AND p.profile_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.create_invoice_for_appointment(
  p_appointment_id UUID,
  p_discount NUMERIC DEFAULT 0,
  p_tax NUMERIC DEFAULT 0,
  p_notes TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_appointment RECORD;
  v_invoice_id UUID := gen_random_uuid();
  v_subtotal NUMERIC(12,2);
  v_total NUMERIC(12,2);
BEGIN
  SELECT a.clinic_id, a.patient_id, a.status, s.price
    INTO v_appointment
  FROM public.appointments a
  JOIN public.services s ON s.id = a.service_id
  WHERE a.id = p_appointment_id
  FOR UPDATE OF a;

  IF NOT FOUND THEN RAISE EXCEPTION 'Cita no encontrada'; END IF;
  IF v_appointment.status <> 'completed' THEN
    RAISE EXCEPTION 'Solo se pueden facturar citas completadas';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.clinic_memberships cm
    WHERE cm.clinic_id = v_appointment.clinic_id
      AND cm.user_id = auth.uid()
      AND cm.is_active = true
      AND cm.role_in_clinic IN ('owner', 'dentist', 'secretary')
  ) THEN RAISE EXCEPTION 'Sin permiso para facturar esta clínica'; END IF;

  v_subtotal := ROUND(v_appointment.price, 2);
  IF COALESCE(p_discount, 0) < 0 OR COALESCE(p_discount, 0) > v_subtotal THEN
    RAISE EXCEPTION 'Descuento inválido';
  END IF;
  IF COALESCE(p_tax, 0) < 0 THEN RAISE EXCEPTION 'Impuesto inválido'; END IF;
  v_total := ROUND(v_subtotal - COALESCE(p_discount, 0) + COALESCE(p_tax, 0), 2);

  INSERT INTO public.invoices (
    id, clinic_id, patient_id, appointment_id, invoice_number,
    subtotal, discount, tax, total, notes, created_by
  ) VALUES (
    v_invoice_id, v_appointment.clinic_id, v_appointment.patient_id,
    p_appointment_id,
    'DS-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTR(REPLACE(v_invoice_id::TEXT, '-', ''), 1, 8)),
    v_subtotal, COALESCE(p_discount, 0), COALESCE(p_tax, 0), v_total,
    NULLIF(TRIM(p_notes), ''), auth.uid()
  );
  RETURN v_invoice_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.register_invoice_payment(
  p_invoice_id UUID,
  p_amount NUMERIC,
  p_payment_method TEXT,
  p_reference TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invoice RECORD;
  v_paid NUMERIC(12,2);
  v_payment_id UUID := gen_random_uuid();
  v_new_paid NUMERIC(12,2);
BEGIN
  SELECT * INTO v_invoice FROM public.invoices WHERE id = p_invoice_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Factura no encontrada'; END IF;
  IF v_invoice.status = 'void' THEN RAISE EXCEPTION 'La factura está anulada'; END IF;
  IF v_invoice.status = 'paid' THEN RAISE EXCEPTION 'La factura ya está pagada'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.clinic_memberships cm
    WHERE cm.clinic_id = v_invoice.clinic_id
      AND cm.user_id = auth.uid()
      AND cm.is_active = true
      AND cm.role_in_clinic IN ('owner', 'dentist', 'secretary')
  ) THEN RAISE EXCEPTION 'Sin permiso para registrar pagos'; END IF;
  IF p_amount <= 0 THEN RAISE EXCEPTION 'El pago debe ser mayor a cero'; END IF;
  IF p_payment_method NOT IN ('cash', 'card', 'transfer', 'other') THEN
    RAISE EXCEPTION 'Método de pago inválido';
  END IF;

  SELECT COALESCE(SUM(amount), 0) INTO v_paid
  FROM public.payments
  WHERE invoice_id = p_invoice_id AND voided_at IS NULL;
  IF p_amount > ROUND(v_invoice.total - v_paid, 2) THEN
    RAISE EXCEPTION 'El pago excede el saldo pendiente';
  END IF;

  INSERT INTO public.payments (
    id, clinic_id, invoice_id, receipt_number, amount, payment_method,
    reference, notes, received_by
  ) VALUES (
    v_payment_id, v_invoice.clinic_id, p_invoice_id,
    'REC-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTR(REPLACE(v_payment_id::TEXT, '-', ''), 1, 8)),
    ROUND(p_amount, 2), p_payment_method, NULLIF(TRIM(p_reference), ''),
    NULLIF(TRIM(p_notes), ''), auth.uid()
  );

  v_new_paid := ROUND(v_paid + p_amount, 2);
  UPDATE public.invoices
  SET status = CASE WHEN v_new_paid >= total THEN 'paid' ELSE 'partial' END,
      updated_at = NOW()
  WHERE id = p_invoice_id;
  RETURN v_payment_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.void_invoice(
  p_invoice_id UUID,
  p_reason TEXT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_invoice RECORD;
BEGIN
  SELECT * INTO v_invoice FROM public.invoices WHERE id = p_invoice_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Factura no encontrada'; END IF;
  IF LENGTH(TRIM(COALESCE(p_reason, ''))) < 5 THEN
    RAISE EXCEPTION 'Indica un motivo de anulación';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.clinic_memberships cm
    WHERE cm.clinic_id = v_invoice.clinic_id
      AND cm.user_id = auth.uid() AND cm.is_active = true
      AND cm.role_in_clinic IN ('owner', 'secretary')
  ) THEN RAISE EXCEPTION 'Sin permiso para anular facturas'; END IF;
  IF EXISTS (
    SELECT 1 FROM public.payments p
    WHERE p.invoice_id = p_invoice_id AND p.voided_at IS NULL
  ) THEN RAISE EXCEPTION 'No se puede anular una factura con pagos activos'; END IF;

  UPDATE public.invoices SET status = 'void', voided_at = NOW(),
    voided_by = auth.uid(), void_reason = TRIM(p_reason), updated_at = NOW()
  WHERE id = p_invoice_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.void_payment(
  p_payment_id UUID,
  p_reason TEXT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payment RECORD;
  v_invoice RECORD;
  v_paid NUMERIC(12,2);
BEGIN
  SELECT * INTO v_payment FROM public.payments WHERE id = p_payment_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pago no encontrado'; END IF;
  IF v_payment.voided_at IS NOT NULL THEN RAISE EXCEPTION 'El pago ya está anulado'; END IF;
  IF LENGTH(TRIM(COALESCE(p_reason, ''))) < 5 THEN
    RAISE EXCEPTION 'Indica un motivo de anulación';
  END IF;
  SELECT * INTO v_invoice FROM public.invoices WHERE id = v_payment.invoice_id FOR UPDATE;
  IF NOT EXISTS (
    SELECT 1 FROM public.clinic_memberships cm
    WHERE cm.clinic_id = v_payment.clinic_id
      AND cm.user_id = auth.uid() AND cm.is_active = true
      AND cm.role_in_clinic IN ('owner', 'secretary')
  ) THEN RAISE EXCEPTION 'Sin permiso para anular pagos'; END IF;

  UPDATE public.payments SET voided_at = NOW(), voided_by = auth.uid(),
    void_reason = TRIM(p_reason) WHERE id = p_payment_id;
  SELECT COALESCE(SUM(amount), 0) INTO v_paid FROM public.payments
    WHERE invoice_id = v_payment.invoice_id AND voided_at IS NULL;
  UPDATE public.invoices SET
    status = CASE
      WHEN v_paid <= 0 THEN 'pending'
      WHEN v_paid >= total THEN 'paid'
      ELSE 'partial'
    END,
    updated_at = NOW()
  WHERE id = v_payment.invoice_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_invoice_for_appointment(UUID, NUMERIC, NUMERIC, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.register_invoice_payment(UUID, NUMERIC, TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.void_invoice(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.void_payment(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_invoice_for_appointment(UUID, NUMERIC, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.register_invoice_payment(UUID, NUMERIC, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.void_invoice(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.void_payment(UUID, TEXT) TO authenticated;
