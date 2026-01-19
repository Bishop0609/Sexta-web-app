-- ==============================================
-- RESET SIMPLE: SOLO ELIMINAR PERMISSIONS Y USERS
-- ==============================================

-- PASO 1: Hacer 12345678-9 administrador
UPDATE users 
SET role = 'admin'
WHERE rut = '12345678-9';

-- PASO 2: Ver qué permisos existen
SELECT * FROM permissions;

-- PASO 3: Eliminar TODOS los permisos (la tabla causa el problema)
DELETE FROM permissions;

-- PASO 4: Ahora eliminar usuarios (excepto admin)
DELETE FROM users 
WHERE rut != '12345678-9';

-- PASO 5: Verificar resultado
SELECT 
  u.rut,
  u.full_name,
  u.role,
  ac.password_hash IS NOT NULL as tiene_credenciales
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id;

-- Debe mostrar solo: 12345678-9 como admin

-- ==============================================
-- ✅ LISTO - SISTEMA LIMPIO
-- ==============================================
