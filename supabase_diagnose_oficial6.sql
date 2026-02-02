-- Script para diagnosticar problema con rol oficial6

-- 1. Ver roles únicos actualmente en la BD
SELECT DISTINCT role FROM users ORDER BY role;

-- 2. Ver si hay algún CHECK constraint en la columna role
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'users'::regclass
AND contype = 'c'
AND pg_get_constraintdef(oid) LIKE '%role%';

-- 3. Intentar actualizar directamente un usuario con oficial6
-- Reemplaza 'USER_ID_AQUI' con un ID real
-- UPDATE users SET role = 'oficial6' WHERE id = 'USER_ID_AQUI';

-- 4. Ver un usuario de ejemplo para probar
SELECT id, full_name, rank, role FROM users LIMIT 3;

-- 5. Verificar el tipo de dato de la columna role
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'users' 
AND column_name = 'role';
