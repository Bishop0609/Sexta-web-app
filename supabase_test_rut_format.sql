-- ============================================
-- TEST: VERIFICAR BÚSQUEDA POR RUT
-- ============================================

-- ¿Cómo están los RUTs guardados en la BD?
SELECT rut, full_name
FROM users
ORDER BY rut;

-- Ver si el usuario existe con diferentes formatos
SELECT rut, full_name, id
FROM users
WHERE rut = '12345678-9'
   OR rut = '123456789'
   OR rut LIKE '%12345678%';

-- Ver usuario específico con credenciales
SELECT 
  u.rut,
  u.full_name,
  u.id,
  ac.password_hash,
  ac.requires_password_change
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE u.rut LIKE '%12345678%';

-- ============================================
-- SOLUCIÓN TEMPORAL: RESETEAR SOLO ESTE USUARIO
-- ============================================

-- Si quieres volver a Bombero2024! para este usuario:
UPDATE auth_credentials 
SET 
  password_hash = 'dwKZ1TdPMDhE8M_wQXJZ8dqTb7P3PwJqvN2ySxwVDyc=:10f5897648e18c14c92dc8c2e0c70f4cca9e05e0235720770d0b682c665df566',
  requires_password_change = true,
  password_changed_at = NULL
WHERE user_id = (SELECT id FROM users WHERE rut = '12345678-9' OR rut = '123456789');
