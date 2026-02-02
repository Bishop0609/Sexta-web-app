-- Verificar constraint en columna role
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'users'::regclass
AND contype = 'c'
AND pg_get_constraintdef(oid) LIKE '%role%';

-- Verificar si 'oficial6' es aceptado intentando un update manual (reemplazar ID)
-- UPDATE users SET role = 'oficial6' WHERE id = '...';
