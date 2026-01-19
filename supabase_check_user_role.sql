-- ============================================
-- VERIFICAR ROL DE USUARIO ADMIN
-- ============================================

-- 1. Ver TODOS los usuarios con sus roles
SELECT 
  id,
  rut,
  full_name,
  role,
  email,
  created_at
FROM users 
ORDER BY role, full_name;

-- 2. Verificar específicamente el usuario admin
SELECT 
  id,
  rut,
  victor_number,
  full_name,
  role,
  email
FROM users 
WHERE role = 'admin';

-- 3. Contar usuarios por rol
SELECT 
  role,
  COUNT(*) as cantidad
FROM users 
GROUP BY role
ORDER BY role;

-- 4. Si NO hay usuarios admin, este query mostrará el problema
SELECT 
  'PROBLEMA: No hay usuarios con rol admin' as alerta
WHERE NOT EXISTS (SELECT 1 FROM users WHERE role = 'admin');

-- 5. Verificar si el rol está en mayúsculas o con espacios
SELECT 
  id,
  rut,
  full_name,
  role,
  LENGTH(role) as longitud_rol,
  ASCII(SUBSTRING(role FROM 1 FOR 1)) as primer_caracter_ascii
FROM users;
