-- ============================================
-- RESET: DEJAR UN SOLO ADMIN Y EMPEZAR LIMPIO
-- ============================================

-- 1. HACER 12345678-9 ADMINISTRADOR
UPDATE users 
SET role = 'admin'
WHERE rut = '12345678-9';

-- Verificar que es admin
SELECT rut, full_name, role 
FROM users 
WHERE rut = '12345678-9';

-- 2. ELIMINAR OTROS USUARIOS (auth_credentials se eliminará automáticamente por CASCADE)
DELETE FROM users 
WHERE rut != '12345678-9';

-- 3. VERIFICAR QUE SOLO QUEDA EL ADMIN
SELECT 
  u.rut,
  u.full_name,
  u.role,
  ac.password_hash IS NOT NULL as tiene_credenciales
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id;

-- Debe mostrar solo 1 usuario: 12345678-9 como admin

-- ============================================
-- ✅ AHORA PUEDES:
-- ============================================
-- 1. Login como 12345678-9 (con tu nueva contraseña)
-- 2. Ir a Gestión de Usuarios
-- 3. Crear nuevos usuarios (se generarán contraseñas automáticamente)
-- 4. Cada nuevo usuario recibirá email con su contraseña temporal
-- ============================================
