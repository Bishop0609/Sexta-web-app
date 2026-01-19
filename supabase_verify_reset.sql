-- ==============================================
-- VERIFICAR RESET EXITOSO
-- ==============================================

-- 1. Ver usuarios (debe ser solo 1)
SELECT COUNT(*) as total_usuarios FROM users;

-- 2. Ver el admin
SELECT u.rut, u.full_name, u.role, u.email
FROM users u;

-- 3. Verificar credenciales del admin
SELECT 
  u.rut,
  u.full_name,
  ac.password_hash IS NOT NULL as tiene_credenciales,
  ac.requires_password_change
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id;

-- 4. Ver que tablas están vacías
SELECT 
  'permissions' as tabla, COUNT(*) as registros FROM permissions
UNION ALL
SELECT 'attendance_events', COUNT(*) FROM attendance_events
UNION ALL
SELECT 'shift_attendances', COUNT(*) FROM shift_attendances
UNION ALL
SELECT 'shift_registrations', COUNT(*) FROM shift_registrations;

-- ==============================================
-- ✅ RESULTADO ESPERADO:
-- ==============================================
-- users: 1 (12345678-9)
-- auth_credentials: 1 (del admin)
-- Todas las demás tablas: 0 registros
-- ==============================================
