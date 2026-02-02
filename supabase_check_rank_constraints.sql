-- Script para verificar y corregir problemas con cargos en la tabla users

-- 1. Ver todos los cargos únicos actualmente en la base de datos
SELECT DISTINCT rank FROM users ORDER BY rank;

-- 2. Verificar si hay algún CHECK constraint en la columna rank
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'users'::regclass
AND contype = 'c'  -- CHECK constraints
AND pg_get_constraintdef(oid) LIKE '%rank%';

-- 3. Intentar actualizar un usuario con los nuevos cargos para ver si hay error
-- (Reemplaza 'USER_ID_AQUI' con un ID real de usuario para probar)
-- UPDATE users SET rank = 'Pro-Tesorero(a)' WHERE id = 'USER_ID_AQUI';
-- UPDATE users SET rank = 'Pro-Secretario(a)' WHERE id = 'USER_ID_AQUI';

-- 4. Ver si hay triggers que puedan estar interfiriendo
SELECT 
    tgname AS trigger_name,
    tgtype,
    proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'users'::regclass;
