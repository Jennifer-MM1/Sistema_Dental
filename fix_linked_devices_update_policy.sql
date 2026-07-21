DROP POLICY IF EXISTS "Actualizar dispositivos propios" ON public.linked_devices;

CREATE POLICY "Actualizar dispositivos propios" ON public.linked_devices
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
