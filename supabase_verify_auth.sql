-- ============================================
-- VERIFICAR CREDENCIALES DE AUTENTICACIÓN
-- ============================================

-- 1. Ver todos los usuarios
SELECT id, rut, full_name, email 
FROM users 
ORDER BY full_name;

-- 2. Ver todas las credenciales
SELECT 
  u.rut,
  u.full_name,
  ac.password_hash,
  ac.requires_password_change,
  ac.failed_attempts,
  ac.created_at
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
ORDER BY u.full_name;

-- 3. Verificar usuario específico 12345678-9
SELECT 
  u.id,
  u.rut,
  u.full_name,
  ac.password_hash,
  ac.requires_password_change
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE u.rut = '12345678-9';

-- 4. Contar usuarios sin credenciales
SELECT COUNT(*) as usuarios_sin_credenciales
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE ac.user_id IS NULL;

-- 5. Ver hash esperado para Bombero2024!
-- Este es el hash que debería estar en la BD:
-- dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:7e8f3c9b2a1d0e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9

-- 6. Si necesitas borrar y recrear credenciales
-- DELETE FROM auth_credentials WHERE user_id IN (SELECT id FROM users WHERE rut = '12345678-9');

-- 7. IMPORTANTE: Revisar formato del RUT
-- Verificar si está con o sin guión
SELECT DISTINCT rut FROM users ORDER BY rut;
