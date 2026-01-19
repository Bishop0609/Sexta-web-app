-- ============================================
-- FIX: Modificar tabla users para quitar dependencia de auth.users
-- ============================================
-- EJECUTA ESTE SCRIPT PRIMERO si ya ejecutaste supabase_schema.sql

-- 1. Deshabilitar RLS temporalmente
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE permissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_events DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_registrations DISABLE ROW LEVEL SECURITY;

-- 2. Eliminar constraint de foreign key a auth.users
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- 3. Modificar la columna ID para que sea generada automáticamente
ALTER TABLE users ALTER COLUMN id SET DEFAULT uuid_generate_v4();

-- ============================================
-- DATOS DE PRUEBA
-- ============================================

-- Limpiar datos existentes (si los hay)
TRUNCATE TABLE shift_attendance CASCADE;
TRUNCATE TABLE shift_registrations CASCADE;
TRUNCATE TABLE shift_configurations CASCADE;
TRUNCATE TABLE attendance_records CASCADE;
TRUNCATE TABLE attendance_events CASCADE;
TRUNCATE TABLE permissions CASCADE;
TRUNCATE TABLE users CASCADE;

-- ============================================
-- 1. USUARIOS DE PRUEBA
-- ============================================

-- Admin
INSERT INTO users (rut, victor_number, full_name, gender, marital_status, rank, role, email)
VALUES 
  ('12345678-9', 'V001', 'Juan Pérez González', 'M', 'married', 'Capitán', 'admin', 'admin@sexta.cl');

-- Oficiales
INSERT INTO users (rut, victor_number, full_name, gender, marital_status, rank, role, email)
VALUES 
  ('23456789-0', 'V002', 'María Rodriguez Silva', 'F', 'single', 'Teniente', 'officer', 'maria@sexta.cl'),
  ('34567890-1', 'V003', 'Carlos López Vega', 'M', 'married', 'Subteniente', 'officer', 'carlos@sexta.cl');

-- Bomberos
INSERT INTO users (rut, victor_number, full_name, gender, marital_status, rank, role, email)
VALUES 
  ('45678901-2', 'V004', 'Ana Martínez Cruz', 'F', 'single', 'Bombero 1ra', 'firefighter', 'ana@sexta.cl'),
  ('56789012-3', 'V005', 'Pedro Fernández Rojas', 'M', 'single', 'Bombero 2da', 'firefighter', 'pedro@sexta.cl'),
  ('67890123-4', 'V006', 'Laura Sánchez Muñoz', 'F', 'married', 'Bombero 1ra', 'firefighter', 'laura@sexta.cl'),
  ('78901234-5', 'V007', 'Diego Torres Vargas', 'M', 'single', 'Bombero 3ra', 'firefighter', 'diego@sexta.cl'),
  ('89012345-6', 'V008', 'Sofía Ramírez Díaz', 'F', 'single', 'Bombero 2da', 'firefighter', 'sofia@sexta.cl'),
  ('90123456-7', 'V009', 'Miguel Ángel Herrera', 'M', 'married', 'Bombero 1ra', 'firefighter', 'miguel@sexta.cl'),
  ('01234567-8', 'V010', 'Valentina Castro Ponce', 'F', 'single', 'Bombero 3ra', 'firefighter', 'valentina@sexta.cl'),
  ('11111111-1', 'V011', 'Andrés Silva Morales', 'M', 'single', 'Bombero 2da', 'firefighter', 'andres@sexta.cl'),
  ('22222222-2', 'V012', 'Camila Flores Núñez', 'F', 'married', 'Bombero 1ra', 'firefighter', 'camila@sexta.cl');

-- ============================================
-- 2. CONFIGURACIÓN DE GUARDIA
-- ============================================

INSERT INTO shift_configurations (period_name, start_date, end_date, registration_start, registration_end)
VALUES 
  ('Enero 2026', '2026-01-06', '2026-01-31', '2026-01-01', '2026-01-05'),
  ('Febrero 2026', '2026-02-01', '2026-02-28', '2026-01-25', '2026-01-31');

-- ============================================
-- 3. PERMISOS DE PRUEBA
-- ============================================

-- Permiso pendiente (Ana Martínez)
INSERT INTO permissions (user_id, start_date, end_date, reason, status)
SELECT 
  id,
  '2026-01-10',
  '2026-01-12',
  'Viaje familiar',
  'pending'
FROM users 
WHERE rut = '45678901-2';

-- Permiso aprobado (Pedro Fernández - para probar auto-crosscheck)
INSERT INTO permissions (user_id, start_date, end_date, reason, status, reviewed_by, reviewed_at)
SELECT 
  u.id,
  '2026-01-08',
  '2026-01-09',
  'Trámites personales',
  'approved',
  (SELECT id FROM users WHERE role = 'admin' LIMIT 1),
  NOW()
FROM users u
WHERE u.rut = '56789012-3';

-- Permiso rechazado (Diego Torres)
INSERT INTO permissions (user_id, start_date, end_date, reason, status, reviewed_by, reviewed_at)
SELECT 
  u.id,
  '2026-01-15',
  '2026-01-16',
  'Vacaciones',
  'rejected',
  (SELECT id FROM users WHERE role = 'officer' LIMIT 1),
  NOW() - INTERVAL '2 days'
FROM users u
WHERE u.rut = '78901234-5';

-- ============================================
-- 4. EVENTOS Y REGISTROS DE ASISTENCIA
-- ============================================

-- Evento 1: Incendio (Efectiva) - hace 3 días
DO $$
DECLARE
  event_id UUID;
  act_type_id UUID;
  user_ids UUID[];
  i INT;
BEGIN
  SELECT id INTO act_type_id FROM act_types WHERE name = 'Incendio' LIMIT 1;
  SELECT ARRAY_AGG(id) INTO user_ids FROM users;
  
  INSERT INTO attendance_events (act_type_id, event_date, created_by)
  VALUES (
    act_type_id,
    CURRENT_DATE - INTERVAL '3 days',
    (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
  )
  RETURNING id INTO event_id;
  
  -- Insertar registros (70% presente)
  FOR i IN 1..array_length(user_ids, 1) LOOP
    INSERT INTO attendance_records (event_id, user_id, status, is_locked)
    VALUES (
      event_id,
      user_ids[i],
      CASE WHEN random() < 0.7 THEN 'present' ELSE 'absent' END,
      false
    );
  END LOOP;
END $$;

-- Evento 2: Academia (Efectiva) - hace 1 semana
DO $$
DECLARE
  event_id UUID;
  act_type_id UUID;
  user_ids UUID[];
  i INT;
BEGIN
  SELECT id INTO act_type_id FROM act_types WHERE name = 'Academia' LIMIT 1;
  SELECT ARRAY_AGG(id) INTO user_ids FROM users;
  
  INSERT INTO attendance_events (act_type_id, event_date, created_by)
  VALUES (
    act_type_id,
    CURRENT_DATE - INTERVAL '7 days',
    (SELECT id FROM users WHERE role = 'officer' LIMIT 1)
  )
  RETURNING id INTO event_id;
  
  FOR i IN 1..array_length(user_ids, 1) LOOP
    INSERT INTO attendance_records (event_id, user_id, status, is_locked)
    VALUES (
      event_id,
      user_ids[i],
      CASE WHEN random() < 0.8 THEN 'present' ELSE 'absent' END,
      false
    );
  END LOOP;
END $$;

-- Evento 3: Capacitación (Abono) - hace 5 días
DO $$
DECLARE
  event_id UUID;
  act_type_id UUID;
  user_ids UUID[];
  i INT;
BEGIN
  SELECT id INTO act_type_id FROM act_types WHERE name = 'Capacitación' LIMIT 1;
  SELECT ARRAY_AGG(id) INTO user_ids FROM users;
  
  INSERT INTO attendance_events (act_type_id, event_date, created_by)
  VALUES (
    act_type_id,
    CURRENT_DATE - INTERVAL '5 days',
    (SELECT id FROM users WHERE role = 'officer' LIMIT 1)
  )
  RETURNING id INTO event_id;
  
  FOR i IN 1..array_length(user_ids, 1) LOOP
    INSERT INTO attendance_records (event_id, user_id, status, is_locked)
    VALUES (
      event_id,
      user_ids[i],
      CASE WHEN random() < 0.5 THEN 'present' ELSE 'absent' END,
      false
    );
  END LOOP;
END $$;

-- ============================================
-- 5. INSCRIPCIONES DE GUARDIA (cupo 6M/4F)
-- ============================================

DO $$
DECLARE
  config_id UUID;
  male_users UUID[];
  female_users UUID[];
  i INTEGER;
BEGIN
  SELECT id INTO config_id FROM shift_configurations WHERE period_name = 'Enero 2026';
  
  SELECT ARRAY_AGG(id) INTO male_users 
  FROM users 
  WHERE gender = 'M' AND role = 'firefighter' 
  LIMIT 4;
  
  SELECT ARRAY_AGG(id) INTO female_users 
  FROM users 
  WHERE gender = 'F' AND role = 'firefighter' 
  LIMIT 2;
  
  -- Inscribir 4 hombres para hoy
  FOR i IN 1..4 LOOP
    IF male_users[i] IS NOT NULL THEN
      INSERT INTO shift_registrations (config_id, user_id, shift_date)
      VALUES (config_id, male_users[i], CURRENT_DATE);
    END IF;
  END LOOP;
  
  -- Inscribir 2 mujeres para hoy
  FOR i IN 1..2 LOOP
    IF female_users[i] IS NOT NULL THEN
      INSERT INTO shift_registrations (config_id, user_id, shift_date)
      VALUES (config_id, female_users[i], CURRENT_DATE);
    END IF;
  END LOOP;
END $$;

-- ============================================
-- VERIFICACIÓN
-- ============================================

SELECT '✅ Usuarios creados' as resultado, COUNT(*) as total FROM users;
SELECT '✅ Permisos creados' as resultado, COUNT(*) as total FROM permissions;
SELECT '✅ Eventos creados' as resultado, COUNT(*) as total FROM attendance_events;
SELECT '✅ Registros de asistencia' as resultado, COUNT(*) as total FROM attendance_records;
SELECT '✅ Configuraciones de guardia' as resultado, COUNT(*) as total FROM shift_configurations;
SELECT '✅ Inscripciones de guardia' as resultado, COUNT(*) as total FROM shift_registrations;

-- Mostrar distribución de permisos
SELECT 
  CASE status
    WHEN 'pending' THEN '⏳ Pendiente'
    WHEN 'approved' THEN '✅ Aprobado'
    WHEN 'rejected' THEN '❌ Rechazado'
  END as estado,
  COUNT(*) as cantidad 
FROM permissions 
GROUP BY status;

-- Mostrar cupo actual de guardia para hoy
SELECT 
  '📊 Cupo de guardia HOY:' as info,
  SUM(CASE WHEN u.gender = 'M' THEN 1 ELSE 0 END) as hombres,
  SUM(CASE WHEN u.gender = 'F' THEN 1 ELSE 0 END) as mujeres
FROM shift_registrations sr
JOIN users u ON sr.user_id = u.id
WHERE sr.shift_date = CURRENT_DATE;

SELECT '🎉 ¡Datos de prueba cargados exitosamente!' as resultado;
