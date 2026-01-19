-- Script para limpiar los rangos (quitar paréntesis y la "a")
-- Ejecutar en Supabase SQL Editor

-- Primero quitar paréntesis
UPDATE users 
SET rank = REPLACE(REPLACE(rank, '(', ''), ')', '')
WHERE rank LIKE '%(%';

-- Ahora quitar la "a" al final de Director, Secretario, Tesorero
UPDATE users 
SET rank = CASE
  WHEN rank = 'Directora' THEN 'Director'
  WHEN rank = 'Secretarioa' THEN 'Secretario'
  WHEN rank = 'Secretaria' THEN 'Secretario'
  WHEN rank = 'Tesoreroa' THEN 'Tesorero'
  WHEN rank = 'Tesorera' THEN 'Tesorero'
  ELSE rank
END
WHERE rank IN ('Directora', 'Secretarioa', 'Secretaria', 'Tesoreroa', 'Tesorera');

-- Verificar cambios
SELECT rank, COUNT(*) as cantidad
FROM users
GROUP BY rank
ORDER BY rank;
