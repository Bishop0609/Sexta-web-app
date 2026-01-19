-- ============================================
-- CREAR CONTRASEÑAS PARA USUARIOS EXISTENTES
-- ============================================
-- Este script crea contraseñas temporales para todos los usuarios existentes
-- que no tienen credenciales en auth_credentials

-- Contraseña temporal para todos: "Bombero2024!"
-- Hash SHA-256 con salt: dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:7e8f3c9b2a1d0e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9

-- Ver usuarios sin credenciales
SELECT u.id, u.rut, u.full_name, u.email
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE ac.user_id IS NULL;

-- Insertar credenciales para usuarios existentes
INSERT INTO auth_credentials (user_id, password_hash, requires_password_change)
SELECT 
  u.id,
  'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:7e8f3c9b2a1d0e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9',
  true
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE ac.user_id IS NULL;

-- Verificar que se crearon correctamente
SELECT 
  u.rut,
  u.full_name,
  ac.requires_password_change,
  ac.created_at
FROM users u
JOIN auth_credentials ac ON u.id = ac.user_id
ORDER BY u.full_name;

-- ============================================
-- NOTA IMPORTANTE:
-- ============================================
-- Contraseña temporal para TODOS los usuarios existentes: Bombero2024!
-- Los usuarios deberán cambiarla en el primer login
-- ============================================
