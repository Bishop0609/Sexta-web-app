-- ============================================
-- DIAGNÓSTICO: ¿QUÉ PASÓ CON LAS CREDENCIALES?
-- ============================================

-- 1. Ver TODAS las credenciales actuales
SELECT 
  u.rut,
  u.full_name,
  ac.user_id,
  ac.password_hash,
  ac.requires_password_change,
  ac.password_changed_at,
  ac.created_at
FROM users u
JOIN auth_credentials ac ON u.id = ac.user_id
ORDER BY ac.created_at DESC;

-- 2. ¿Hay duplicados? (NO DEBERÍA HABER)
SELECT user_id, COUNT(*) as count
FROM auth_credentials
GROUP BY user_id
HAVING COUNT(*) > 1;

-- 3. Ver específicamente el usuario 12345678-9
SELECT 
  u.rut,
  u.full_name,
  ac.password_hash,
  ac.requires_password_change,
  ac.password_changed_at,
  ac.created_at,
  LENGTH(ac.password_hash) as hash_length
FROM users u
JOIN auth_credentials ac ON u.id = ac.user_id
WHERE u.rut = '12345678-9';

-- ============================================
-- SOLUCIÓN: ELIMINAR DUPLICADOS SI EXISTEN
-- ============================================

-- Si hay duplicados, eliminar y volver a crear
DELETE FROM auth_credentials;

-- Insertar credenciales correctas para TODOS
INSERT INTO auth_credentials (user_id, password_hash, requires_password_change)
SELECT 
  id,
  'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566',
  true
FROM users;

-- Verificar
SELECT COUNT(*) as total_usuarios, 
       (SELECT COUNT(*) FROM auth_credentials) as total_credenciales
FROM users;
