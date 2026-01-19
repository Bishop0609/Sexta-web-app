-- ============================================
-- CREAR CONTRASEÑAS PARA TODOS LOS USUARIOS
-- Password genérica: Bombero2024!
-- ============================================

-- 1. Ver usuarios sin credenciales
SELECT 
  u.id,
  u.full_name,
  u.rut,
  u.role,
  CASE WHEN ac.user_id IS NULL THEN '❌ Sin credenciales' ELSE '✅ Tiene credenciales' END as estado
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
ORDER BY u.full_name;

-- 2. CREAR contraseñas para TODOS los usuarios que no tienen
-- Password: Bombero2024!
-- Hash pre-calculado con salt: BomberoSalt2024SecureRandom32Chars
-- Formato: salt:hash (compatible con AuthService.verifyPassword)

INSERT INTO auth_credentials (user_id, password_hash, requires_password_change)
SELECT 
  u.id,
  'BomberoSalt2024SecureRandom32Chars:4884ef92943b6da4fbc65e67af41cc2aeac9cd2ae4e32e1cf1e54bb627527c42' as password_hash,
  true  -- Forzar cambio de contraseña en primer login
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE ac.user_id IS NULL;  -- Solo usuarios sin credenciales

-- 3. Verificar que se crearon
SELECT 
  u.full_name,
  u.rut,
  u.role,
  '✅ Credenciales creadas' as estado,
  ac.requires_password_change as debe_cambiar_password,
  LEFT(ac.password_hash, 40) || '...' as password_hash_preview
FROM users u
JOIN auth_credentials ac ON u.id = ac.user_id
ORDER BY u.full_name;

-- 4. Resumen
SELECT 
  COUNT(*) as total_usuarios,
  (SELECT COUNT(*) FROM auth_credentials) as usuarios_con_credenciales,
  (SELECT COUNT(*) FROM auth_credentials WHERE requires_password_change = true) as deben_cambiar_password
FROM users;

-- ============================================
-- INFORMACIÓN IMPORTANTE
-- ============================================
-- Password genérica: Bombero2024!
-- 
-- Al primer login, los usuarios deberán:
-- 1. Ingresar con su RUT
-- 2. Ingresar password: Bombero2024!
-- 3. Serán redirigidos a pantalla de cambio de contraseña
-- 4. Crear una nueva contraseña personal
-- 
-- Requisitos de nueva contraseña:
-- - Mínimo 8 caracteres
-- - Al menos 1 mayúscula
-- - Al menos 1 número
-- - Al menos 1 caracter especial (!@#$%&*)
-- ============================================

SELECT '✅ Script ejecutado correctamente - Password genérica: Bombero2024!' as resultado;
