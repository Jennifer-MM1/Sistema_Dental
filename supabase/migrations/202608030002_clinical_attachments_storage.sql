-- ============================================================
-- MIGRACIÓN: ESTUDIOS CLÍNICOS Y RADIOGRAFÍAS (SUPABASE STORAGE)
-- ============================================================

-- 1. Tabla de metadatos de archivos adjuntos
CREATE TABLE IF NOT EXISTS public.clinical_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL DEFAULT 'image', -- 'image' (radiografía/foto) o 'pdf' (estudio/analítica)
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para búsqueda rápida
CREATE INDEX IF NOT EXISTS idx_clinical_attachments_patient ON public.clinical_attachments(patient_id);
CREATE INDEX IF NOT EXISTS idx_clinical_attachments_appointment ON public.clinical_attachments(appointment_id);

-- Habilitar RLS
ALTER TABLE public.clinical_attachments ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS
DROP POLICY IF EXISTS "Lectura de adjuntos para usuarios autenticados" ON public.clinical_attachments;
CREATE POLICY "Lectura de adjuntos para usuarios autenticados" ON public.clinical_attachments
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Inserción de adjuntos para usuarios autenticados" ON public.clinical_attachments;
CREATE POLICY "Inserción de adjuntos para usuarios autenticados" ON public.clinical_attachments
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Eliminación de adjuntos propios o dentistas" ON public.clinical_attachments;
CREATE POLICY "Eliminación de adjuntos propios o dentistas" ON public.clinical_attachments
  FOR DELETE TO authenticated USING (true);

-- 2. Crear bucket en storage.buckets si no existe
INSERT INTO storage.buckets (id, name, public)
VALUES ('clinical-files', 'clinical-files', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas para storage.objects
DROP POLICY IF EXISTS "Acceso a objetos clinical-files" ON storage.objects;
CREATE POLICY "Acceso a objetos clinical-files" ON storage.objects
  FOR ALL TO authenticated USING (bucket_id = 'clinical-files')
  WITH CHECK (bucket_id = 'clinical-files');
