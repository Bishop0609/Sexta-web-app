-- ============================================
-- CREAR CREDENCIALES PARA TODOS LOS USUARIOS
-- ============================================

-- Hash correcto para contraseña: Bombero2024!
-- dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566

-- 1. Ver usuarios sin credenciales
SELECT u.rut, u.full_name, u.email
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE ac.user_id IS NULL
ORDER BY u.full_name;

-- 2. Insertar credenciales para TODOS los usuarios sin credenciales
INSERT INTO auth_credentials (user_id, password_hash, requires_password_change)
SELECT 
  u.id,
  'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566',
  true
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE ac.user_id IS NULL;

-- 3. Verificar que todos tienen credenciales ahora
SELECT 
  u.rut,
  u.full_name,
  CASE 
    WHEN ac.user_id IS NOT NULL THEN 'CON CREDENCIALES ✓'
    ELSE 'SIN CREDENCIALES ✗'
  END as estado,
  ac.requires_password_change as debe_cambiar_password
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
ORDER BY u.full_name;

-- ============================================
-- RESULTADO ESPERADO:
-- ============================================
-- Todos los usuarios tendrán:
-- - Contraseña temporal: Bombero2024!
-- - Obligados a cambiarla en primer login
-- ============================================
