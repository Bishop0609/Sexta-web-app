-- ============================================
-- RESET COMPLETO CON FOREIGN KEYS
-- ============================================
-- Este SQL elimina TODO en orden correcto

-- PASO 1: Hacer 12345678-9 administrador primero
UPDATE users 
SET role = 'admin'
WHERE rut = '12345678-9';

-- PASO 2: Eliminar datos relacionados a otros usuarios (NO al admin)

-- 2.1 Permisos (permissions)
DELETE FROM permissions 
WHERE user_id != (SELECT id FROM users WHERE rut = '12345678-9')
   OR reviewed_by != (SELECT id FROM users WHERE rut = '12345678-9');

-- 2.2 Asistencias (attendance_events)
DELETE FROM attendance_events
WHERE user_id != (SELECT id FROM users WHERE rut = '12345678-9');

-- 2.3 Registros de guardias (shift_registrations)
DELETE FROM shift_registrations
WHERE user_id != (SELECT id FROM users WHERE rut = '12345678-9');

-- 2.4 Asistencias de guardias (shift_attendances)
DELETE FROM shift_attendances
WHERE user_id != (SELECT id FROM users WHERE rut = '12345678-9');

-- PASO 3: Ahora SÍ podemos eliminar otros usuarios
DELETE FROM users 
WHERE rut != '12345678-9';

-- PASO 4: Verificar resultado
SELECT 
  'users' as tabla,
  COUNT(*) as registros
FROM users
UNION ALL
SELECT 
  'auth_credentials' as tabla,
  COUNT(*) as registros
FROM auth_credentials
UNION ALL
SELECT 
  'permissions' as tabla,
  COUNT(*) as registros
FROM permissions
UNION ALL
SELECT 
  'attendance_events' as tabla,
  COUNT(*) as registros
FROM attendance_events
UNION ALL
SELECT 
  'shift_registrations' as tabla,
  COUNT(*) as registros
FROM shift_registrations;

-- PASO 5: Ver el único usuario que quedó
SELECT 
  u.rut,
  u.full_name,
  u.role,
  ac.password_hash IS NOT NULL as tiene_credenciales
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id;

-- ============================================
-- ✅ AHORA SÍ ESTÁ LIMPIO
-- ============================================
-- Solo quedará el admin 12345678-9
-- Sin datos antiguos que causen problemas
-- Sistema listo para crear usuarios nuevos
-- ============================================
