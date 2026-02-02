-- Script para probar actualización directa de cargos problemáticos

-- 1. Primero, ver un usuario de ejemplo para obtener su ID
SELECT id, full_name, rank, role FROM users LIMIT 5;

-- 2. Intentar actualizar directamente con los cargos problemáticos
-- IMPORTANTE: Reemplaza 'TU_USER_ID_AQUI' con un ID real de la consulta anterior

-- Probar Pro-Tesorero(a)
-- UPDATE users 
-- SET rank = 'Pro-Tesorero(a)' 
-- WHERE id = 'TU_USER_ID_AQUI';

-- Verificar si se guardó
-- SELECT id, full_name, rank FROM users WHERE id = 'TU_USER_ID_AQUI';

-- Probar Pro-Secretario(a)
-- UPDATE users 
-- SET rank = 'Pro-Secretario(a)' 
-- WHERE id = 'TU_USER_ID_AQUI';

-- Verificar si se guardó
-- SELECT id, full_name, rank FROM users WHERE id = 'TU_USER_ID_AQUI';

-- 3. Ver todos los cargos únicos en la BD
SELECT DISTINCT rank FROM users ORDER BY rank;
