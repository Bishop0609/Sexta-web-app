-- Script para actualizar cargos con (a) a versión sin (a)

-- 1. Ver usuarios con cargos problemáticos
SELECT id, full_name, rank, role 
FROM users 
WHERE rank IN ('Pro-Tesorero(a)', 'Pro-Secretario(a)');

-- 2. Actualizar Pro-Tesorero(a) → Pro-Tesorero
UPDATE users 
SET rank = 'Pro-Tesorero' 
WHERE rank = 'Pro-Tesorero(a)';

-- 3. Actualizar Pro-Secretario(a) → Pro-Secretario
UPDATE users 
SET rank = 'Pro-Secretario' 
WHERE rank = 'Pro-Secretario(a)';

-- 4. Verificar que se actualizaron correctamente
SELECT id, full_name, rank, role 
FROM users 
WHERE rank IN ('Pro-Tesorero', 'Pro-Secretario')
ORDER BY rank, full_name;

-- 5. Ver todos los cargos únicos en la BD
SELECT DISTINCT rank FROM users ORDER BY rank;
