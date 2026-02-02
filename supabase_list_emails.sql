-- =====================================================
-- Script para listar todos los correos electrónicos
-- =====================================================

-- Listar todos los emails únicos con conteo de usuarios
SELECT 
  email,
  COUNT(*) as cantidad_usuarios,
  STRING_AGG(full_name, ', ' ORDER BY full_name) as usuarios
FROM users
WHERE email IS NOT NULL
GROUP BY email
ORDER BY cantidad_usuarios DESC, email;

-- Listar todos los usuarios con sus emails
SELECT 
  full_name,
  email,
  rank,
  role
FROM users
ORDER BY email, full_name;
