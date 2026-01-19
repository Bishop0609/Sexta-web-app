-- Limpiar sufijo "a" que quedó en algunos cargos después de remover paréntesis
-- Esto corrige cargos como "Bombero a", "Directora", "Secretarioa", etc.

UPDATE users
SET rank = TRIM(REGEXP_REPLACE(rank, '\s*a$', '', 'i'))
WHERE rank ~ '\s+a$' OR rank ~ 'a$';

-- Verificar cambios
SELECT DISTINCT rank, COUNT(*) as total
FROM users
GROUP BY rank
ORDER BY rank;
