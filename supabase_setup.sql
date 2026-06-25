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
CREATE POLICY "Clinicas visibles para autenticados" ON public.clinics
  FOR SELECT TO authenticated USING (true);

-- 2. PROFILES — Perfiles de usuario con roles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'patient'
    CHECK (role IN ('super_admin', 'admin_dentist', 'admin_secretary', 'patient')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura de perfiles" ON public.profiles
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Actualización propia" ON public.profiles
  FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "Inserción de perfiles" ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (true);

-- 3. CLINIC_MEMBERSHIPS — Vinculación usuario ↔ clínica
CREATE TABLE IF NOT EXISTS public.clinic_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role_in_clinic TEXT NOT NULL CHECK (role_in_clinic IN ('owner', 'dentist', 'secretary', 'patient')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(clinic_id, user_id)
);
ALTER TABLE public.clinic_memberships ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Miembros ven su clínica" ON public.clinic_memberships
  FOR SELECT TO authenticated USING (true);
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
CREATE POLICY "Lectura de doctores" ON public.doctors
  FOR SELECT TO authenticated USING (true);

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
CREATE POLICY "Servicios visibles" ON public.services
  FOR SELECT TO authenticated USING (true);

-- 6. APPOINTMENTS — Citas
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES public.clinics(id) ON DELETE CASCADE NOT NULL,
  patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
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
CREATE POLICY "Lectura de citas" ON public.appointments
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Inserción de citas" ON public.appointments
  FOR INSERT TO authenticated WITH CHECK (true);
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
CREATE POLICY "Lectura de códigos" ON public.invitation_codes
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Inserción de códigos" ON public.invitation_codes
  FOR INSERT TO authenticated WITH CHECK (true);
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
CREATE POLICY "Dispositivos propios" ON public.linked_devices
  FOR SELECT TO authenticated USING (user_id = auth.uid());
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
    COALESCE(new.raw_user_meta_data->>'role', 'patient')
  );
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
-- PASO 4: CREAR USUARIOS DE PRUEBA
-- ============================================================
-- Contraseña para TODOS los usuarios de prueba: Dental2026!
-- ============================================================

-- Usuario 1: Super Administrador
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change, email_change_token_new, email_change_token_current,
  phone_change_token, reauthentication_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), 'authenticated', 'authenticated',
  'superadmin@dentalsync.com',
  crypt('Dental2026!', gen_salt('bf')),
  NOW(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"name": "Admin General", "role": "super_admin"}'::jsonb,
  NOW(), NOW(), '', '', '', '', '', '', ''
);

-- Usuario 2: Admin Dentista
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change, email_change_token_new, email_change_token_current,
  phone_change_token, reauthentication_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), 'authenticated', 'authenticated',
  'dentista@dentalsync.com',
  crypt('Dental2026!', gen_salt('bf')),
  NOW(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"name": "Dra. Elena Martínez", "role": "admin_dentist"}'::jsonb,
  NOW(), NOW(), '', '', '', '', '', '', ''
);

-- Usuario 3: Admin Secretaria
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change, email_change_token_new, email_change_token_current,
  phone_change_token, reauthentication_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), 'authenticated', 'authenticated',
  'secretaria@dentalsync.com',
  crypt('Dental2026!', gen_salt('bf')),
  NOW(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"name": "Ana López", "role": "admin_secretary"}'::jsonb,
  NOW(), NOW(), '', '', '', '', '', '', ''
);

-- Usuario 4: Paciente
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change, email_change_token_new, email_change_token_current,
  phone_change_token, reauthentication_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), 'authenticated', 'authenticated',
  'paciente@dentalsync.com',
  crypt('Dental2026!', gen_salt('bf')),
  NOW(),
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"name": "Carlos Mendoza", "role": "patient"}'::jsonb,
  NOW(), NOW(), '', '', '', '', '', '', ''
);

-- ============================================================
-- PASO 5: CREAR CLÍNICA DE PRUEBA Y VINCULAR USUARIOS
-- ============================================================

-- Crear clínica
INSERT INTO public.clinics (id, business_name, sanitary_license, professional_id, gps_latitude, gps_longitude, geofence_radius)
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'DentalSync Connect - Clínica Central',
  'LIC-SANIT-2026-001',
  'CED-PROF-12345',
  21.2167,  -- Jalpan de Serra, Qro. (latitud)
  -99.4722, -- Jalpan de Serra, Qro. (longitud)
  150       -- Radio geocerca en metros
);

-- Vincular usuarios a la clínica
-- (El trigger ya creó los perfiles, ahora vinculamos con la clínica)
INSERT INTO public.clinic_memberships (clinic_id, user_id, role_in_clinic)
SELECT 'a0000000-0000-0000-0000-000000000001', id, 'owner'
FROM public.profiles WHERE email = 'superadmin@dentalsync.com';

INSERT INTO public.clinic_memberships (clinic_id, user_id, role_in_clinic)
SELECT 'a0000000-0000-0000-0000-000000000001', id, 'dentist'
FROM public.profiles WHERE email = 'dentista@dentalsync.com';

INSERT INTO public.clinic_memberships (clinic_id, user_id, role_in_clinic)
SELECT 'a0000000-0000-0000-0000-000000000001', id, 'secretary'
FROM public.profiles WHERE email = 'secretaria@dentalsync.com';

INSERT INTO public.clinic_memberships (clinic_id, user_id, role_in_clinic)
SELECT 'a0000000-0000-0000-0000-000000000001', id, 'patient'
FROM public.profiles WHERE email = 'paciente@dentalsync.com';

-- Crear registro de doctor para la dentista
INSERT INTO public.doctors (user_id, clinic_id, specialty, cabin_assigned)
SELECT id, 'a0000000-0000-0000-0000-000000000001', 'Ortodoncia', 'Consultorio 1'
FROM public.profiles WHERE email = 'dentista@dentalsync.com';

-- Crear servicios de ejemplo para la clínica
INSERT INTO public.services (clinic_id, service_name, price, duration_mins) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Limpieza Dental', 80.00, 30),
  ('a0000000-0000-0000-0000-000000000001', 'Chequeo General', 60.00, 20),
  ('a0000000-0000-0000-0000-000000000001', 'Blanqueamiento', 250.00, 60),
  ('a0000000-0000-0000-0000-000000000001', 'Ortodoncia', 120.00, 45),
  ('a0000000-0000-0000-0000-000000000001', 'Extracción', 150.00, 40);
