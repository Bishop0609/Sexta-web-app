-- ==============================================
-- VERIFICAR RESET - SOLO TABLAS EXISTENTES
-- ==============================================

-- 1. Ver usuarios (debe ser solo 1)
SELECT rut, full_name, role, email
FROM users;

-- 2. Verificar credenciales del admin
SELECT 
  u.rut,
  u.full_name,
  u.role,
  ac.password_hash IS NOT NULL as tiene_credenciales
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id;

-- 3. Contar registros en tablas principales
SELECT 
  'users' as tabla, COUNT(*) as registros FROM users
UNION ALL
SELECT 'auth_credentials', COUNT(*) FROM auth_credentials
UNION ALL
SELECT 'permissions', COUNT(*) FROM permissions
UNION ALL
SELECT 'attendance_events', COUNT(*) FROM attendance_events;

-- ==============================================
-- ✅ RESULTADO ESPERADO:
-- ==============================================
-- users: 1
-- auth_credentials: 1
-- permissions: 0
-- attendance_events: 0
-- ==============================================
