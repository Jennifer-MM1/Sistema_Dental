-- ============================================================
-- SCRIPT COMPLETO: DENTALSYNC CONNECT
-- Ejecutar en Supabase → SQL Editor → New query → Run
-- ============================================================
-- Este script:
--   1. Crea todas las tablas del sistema
--   2. Crea 4 usuarios de prueba (uno por cada rol)
--   3. Crea una clínica de prueba
--   4. Vincula a los usuarios con la clínica
-- ============================================================

-- ============================================================
-- PASO 1: CREAR TABLAS
-- ============================================================

-- 1. CLINICS — Establecimientos médicos
CREATE TABLE IF NOT EXISTS public.clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name TEXT NOT NULL,
  sanitary_license TEXT,
  professional_id TEXT,
  trust_seal_token TEXT,
  gps_latitude DOUBLE PRECISION,
  gps_longitude DOUBLE PRECISION,
  geofence_radius INT DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Clinicas visibles para autenticados" ON public.clinics;
CREATE POLICY "Clinicas visibles para autenticados" ON public.clinics
  FOR SELECT TO authenticated USING (true);

-- 2. PROFILES — Perfiles de usuario con roles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'client'
    CHECK (role IN ('dentist', 'secretary', 'client')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura de perfiles" ON public.profiles;
CREATE POLICY "Lectura de perfiles" ON public.profiles
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Actualización propia" ON public.profiles;
CREATE POLICY "Actualización propia" ON public.profiles
  FOR UPDATE TO authenticated USING (auth.uid() = id);
DROP POLICY IF EXISTS "Inserción de perfiles" ON public.profiles;
CREATE POLICY "Inserción de perfiles" ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (true);

-- 2.5 PATIENTS — Fichas médicas (Multi-paciente por cuenta)
CREATE TABLE IF NOT EXISTS public.patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  date_of_birth DATE,
  relationship TEXT DEFAULT 'self' CHECK (relationship IN ('self', 'child', 'spouse', 'parent', 'other')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_patients_clinic_id ON public.patients(clinic_id);
CREATE INDEX IF NOT EXISTS idx_patients_profile_clinic ON public.patients(profile_id, clinic_id);
UPDATE public.patients p
SET clinic_id = (
  SELECT cm.clinic_id
  FROM public.clinic_memberships cm
  WHERE cm.user_id = p.profile_id
    AND cm.role_in_clinic = 'client'
    AND cm.is_active = true
  ORDER BY cm.created_at ASC
  LIMIT 1
)
WHERE p.clinic_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.clinic_memberships cm
    WHERE cm.user_id = p.profile_id
      AND cm.role_in_clinic = 'client'
      AND cm.is_active = true
  );
DROP POLICY IF EXISTS "Pacientes visibles para la clínica y el perfil dueño" ON public.patients;
CREATE POLICY "Pacientes visibles para la clínica y el perfil dueño" ON public.patients
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Inserción de pacientes" ON public.patients;
CREATE POLICY "Inserción de pacientes" ON public.patients
  FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Actualización de pacientes" ON public.patients;
CREATE POLICY "Actualización de pacientes" ON public.patients
  FOR UPDATE TO authenticated USING (true);

-- 3. CLINIC_MEMBERSHIPS — Vinculación usuario ↔ clínica
CREATE TABLE IF NOT EXISTS public.clinic_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role_in_clinic TEXT NOT NULL CHECK (role_in_clinic IN ('owner', 'dentist', 'secretary', 'client')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(clinic_id, user_id)
);
ALTER TABLE public.clinic_memberships ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Miembros ven su clínica" ON public.clinic_memberships;
CREATE POLICY "Miembros ven su clínica" ON public.clinic_memberships
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Inserción de membresías" ON public.clinic_memberships;
CREATE POLICY "Inserción de membresías" ON public.clinic_memberships
  FOR INSERT TO authenticated WITH CHECK (true);

-- 4. DOCTORS — Detalles del personal médico
CREATE TABLE IF NOT EXISTS public.doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  specialty TEXT NOT NULL,
  cabin_assigned TEXT NOT NULL,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura de doctores" ON public.doctors;
CREATE POLICY "Lectura de doctores" ON public.doctors
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Inserción de doctores" ON public.doctors;
CREATE POLICY "Inserción de doctores" ON public.doctors
  FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Actualización de doctores" ON public.doctors;
CREATE POLICY "Actualización de doctores" ON public.doctors
  FOR UPDATE TO authenticated USING (true);

-- 5. SERVICES — Catálogo de servicios
CREATE TABLE IF NOT EXISTS public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  service_name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  duration_mins INT NOT NULL DEFAULT 30,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Servicios visibles" ON public.services;
CREATE POLICY "Servicios visibles" ON public.services
  FOR SELECT TO authenticated USING (true);

-- 6. APPOINTMENTS — Citas
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE NOT NULL,
  doctor_id UUID REFERENCES public.doctors(id) ON DELETE CASCADE NOT NULL,
  service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
  date_time TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'upcoming'
    CHECK (status IN ('upcoming', 'in_lobby', 'in_treatment', 'completed', 'cancelled')),
  queue_code TEXT,
  medical_notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura de citas" ON public.appointments;
CREATE POLICY "Lectura de citas" ON public.appointments
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Inserción de citas" ON public.appointments;
CREATE POLICY "Inserción de citas" ON public.appointments
  FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Actualización de citas" ON public.appointments;
CREATE POLICY "Actualización de citas" ON public.appointments
  FOR UPDATE TO authenticated USING (true);

-- 7. INVITATION_CODES — Códigos de invitación para pacientes
CREATE TABLE IF NOT EXISTS public.invitation_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  code TEXT NOT NULL UNIQUE,
  created_by UUID REFERENCES public.profiles(id) NOT NULL,
  used_by UUID REFERENCES public.profiles(id),
  is_used BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.invitation_codes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura de códigos" ON public.invitation_codes;
CREATE POLICY "Lectura de códigos" ON public.invitation_codes
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Inserción de códigos" ON public.invitation_codes;
CREATE POLICY "Inserción de códigos" ON public.invitation_codes
  FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Actualización de códigos" ON public.invitation_codes;
CREATE POLICY "Actualización de códigos" ON public.invitation_codes
  FOR UPDATE TO authenticated USING (true);

-- 8. LINKED_DEVICES — Tokens push para smartwatch
CREATE TABLE IF NOT EXISTS public.linked_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  device_type TEXT NOT NULL CHECK (device_type IN ('watch_os', 'wear_os', 'ios', 'android', 'web')),
  push_token TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.linked_devices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Dispositivos propios" ON public.linked_devices;
CREATE POLICY "Dispositivos propios" ON public.linked_devices
  FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Registrar dispositivos" ON public.linked_devices;
CREATE POLICY "Registrar dispositivos" ON public.linked_devices
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- ============================================================
-- PASO 2: TRIGGER PARA AUTO-CREAR PERFIL AL REGISTRARSE
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, phone, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'Nuevo Usuario'),
    new.email,
    new.phone,
    COALESCE(new.raw_user_meta_data->>'role', 'client')
  );
  
  -- Si es cliente, crear automáticamente su ficha principal (self)
  IF COALESCE(new.raw_user_meta_data->>'role', 'client') = 'client' THEN
    INSERT INTO public.patients (profile_id, first_name, last_name, relationship)
    VALUES (
      new.id,
      split_part(COALESCE(new.raw_user_meta_data->>'name', 'Nuevo Usuario'), ' ', 1),
      COALESCE(NULLIF(split_part(COALESCE(new.raw_user_meta_data->>'name', 'Nuevo Usuario'), ' ', 2), ''), 'Apellido'),
      'self'
    );
  END IF;

  -- Si es dentista, crear automáticamente su clínica y asignarlo como owner
  IF COALESCE(new.raw_user_meta_data->>'role', 'client') = 'dentist' THEN
    INSERT INTO public.clinics (id, business_name)
    VALUES (new.id, 'Clínica de ' || COALESCE(new.raw_user_meta_data->>'name', 'Nuevo Dentista'));
    
    INSERT INTO public.clinic_memberships (clinic_id, user_id, role_in_clinic)
    VALUES (new.id, new.id, 'owner');
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- PASO 3: HABILITAR REALTIME
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr 
    JOIN pg_publication p ON p.oid = pr.prpubid 
    JOIN pg_class c ON c.oid = pr.prrelid 
    WHERE p.pubname = 'supabase_realtime' AND c.relname = 'appointments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
  END IF;
END $$;

-- ============================================================
-- PASO 4: GESTIÓN DE PERSONAL Y CONSULTORIOS
-- ============================================================

-- 9. DOCTOR_SCHEDULES — Horario semanal de cada doctor
-- day_of_week: 0=Domingo, 1=Lunes, ..., 6=Sábado
CREATE TABLE IF NOT EXISTS public.doctor_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL DEFAULT '08:00',
  end_time TIME NOT NULL DEFAULT '17:00',
  is_working_day BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(doctor_user_id, clinic_id, day_of_week)
);
ALTER TABLE public.doctor_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Horarios visibles para la clínica" ON public.doctor_schedules;
CREATE POLICY "Horarios visibles para la clínica" ON public.doctor_schedules
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Inserción de horarios" ON public.doctor_schedules;
CREATE POLICY "Inserción de horarios" ON public.doctor_schedules
  FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Actualización de horarios" ON public.doctor_schedules;
CREATE POLICY "Actualización de horarios" ON public.doctor_schedules
  FOR UPDATE TO authenticated USING (true);

-- 10. DOCTOR_DAYS_OFF — Días libres / ausencias puntuales
CREATE TABLE IF NOT EXISTS public.doctor_days_off (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.doctor_days_off ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Días libres visibles para la clínica" ON public.doctor_days_off;
CREATE POLICY "Días libres visibles para la clínica" ON public.doctor_days_off
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Inserción de días libres" ON public.doctor_days_off;
CREATE POLICY "Inserción de días libres" ON public.doctor_days_off
  FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Eliminación de días libres" ON public.doctor_days_off;
CREATE POLICY "Eliminación de días libres" ON public.doctor_days_off
  FOR DELETE TO authenticated USING (true);

-- ============================================================
-- FUNCIÓN: Auto-actualizar updated_at en doctor_schedules
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_doctor_schedules_updated_at ON public.doctor_schedules;
CREATE TRIGGER update_doctor_schedules_updated_at
  BEFORE UPDATE ON public.doctor_schedules
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
