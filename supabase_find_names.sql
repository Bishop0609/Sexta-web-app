-- Buscar el nombre exacto de Nicole
SELECT id, full_name, rut, rank
FROM users
WHERE full_name ILIKE '%nicole%'
   OR full_name ILIKE '%castellon%';

-- Buscar el nombre exacto de Javiera (para confirmar)
SELECT id, full_name, rut, rank
FROM users
WHERE full_name ILIKE '%javiera%'
   OR full_name ILIKE '%moraga%';
