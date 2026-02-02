-- =====================================================
-- VERIFICACIÓN DE CONSISTENCIA DE RUT (K mayúscula/minúscula)
-- =====================================================
-- PostgreSQL es CASE-SENSITIVE para VARCHAR por defecto
-- Si tienes RUTs con 'k' y 'K', son diferentes valores
-- =====================================================

-- =====================================================
-- PASO 1: Detectar RUTs con 'k' minúscula
-- =====================================================
SELECT 
    rut,
    full_name,
    CASE 
        WHEN rut LIKE '%k' THEN '⚠️ k minúscula'
        WHEN rut LIKE '%K' THEN '✓ K mayúscula'
        ELSE '✓ Sin K'
    END as tipo_k
FROM users
WHERE rut LIKE '%k' OR rut LIKE '%K'
ORDER BY rut;

-- =====================================================
-- PASO 2: Buscar posibles duplicados por RUT
-- =====================================================
-- Detecta si hay dos RUTs que solo difieren en la K
WITH rut_normalized AS (
    SELECT 
        id,
        rut,
        full_name,
        UPPER(rut) as rut_upper
    FROM users
)
SELECT 
    r1.rut as rut_1,
    r1.full_name as nombre_1,
    r2.rut as rut_2,
    r2.full_name as nombre_2,
    '⚠️ POSIBLE DUPLICADO (solo difiere en K)' as problema
FROM rut_normalized r1
JOIN rut_normalized r2 ON r1.rut_upper = r2.rut_upper AND r1.id != r2.id
ORDER BY r1.rut;

-- =====================================================
-- PASO 3: Normalizar todos los RUTs a mayúscula (SOLUCIÓN)
-- =====================================================
-- ⚠️ NO EJECUTAR SIN REVISAR PRIMERO
-- Este script cambiará todas las 'k' a 'K'
/*
UPDATE users
SET rut = UPPER(rut)
WHERE rut LIKE '%k';

-- Verificar resultado
SELECT COUNT(*) as ruts_normalizados
FROM users
WHERE rut LIKE '%K';
*/

-- =====================================================
-- PASO 4: Crear función para normalizar RUT
-- =====================================================
-- Esta función se puede usar en búsquedas y comparaciones
CREATE OR REPLACE FUNCTION normalize_rut(p_rut TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN UPPER(TRIM(p_rut));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Ejemplo de uso:
-- SELECT * FROM users WHERE normalize_rut(rut) = normalize_rut('12345678-k');

-- =====================================================
-- PASO 5: Verificar si afecta búsquedas en Excel
-- =====================================================
-- Si tu Excel tiene '12345678-k' y la BD tiene '12345678-K',
-- PostgreSQL NO los encontrará como iguales:

-- Esta query NO encontrará nada si el RUT en BD es '12345678-K':
-- SELECT * FROM users WHERE rut = '12345678-k';

-- Esta query SÍ encontrará (case-insensitive):
-- SELECT * FROM users WHERE UPPER(rut) = UPPER('12345678-k');

-- =====================================================
-- PASO 6: Verificar impacto en tesorería
-- =====================================================
-- Si estás haciendo match entre Excel y BD por RUT,
-- y tienen diferente capitalización, NO coincidirán

SELECT 
    u.rut,
    u.full_name,
    COUNT(q.id) as cuotas_2025,
    SUM(q.expected_amount - q.paid_amount) as deuda
FROM users u
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
WHERE u.payment_start_date IS NOT NULL
  AND (u.rut LIKE '%k' OR u.rut LIKE '%K')
GROUP BY u.id, u.rut, u.full_name
ORDER BY u.rut;

-- =====================================================
-- RECOMENDACIÓN
-- =====================================================
-- 1. Ejecuta PASO 1 para ver qué RUTs tienen 'k'
-- 2. Ejecuta PASO 2 para buscar duplicados
-- 3. Si encuentras inconsistencias:
--    a) Normaliza TODOS los RUTs a mayúscula (PASO 3)
--    b) Actualiza tu Excel también a mayúsculas
-- 4. En el futuro, usa la función normalize_rut() en búsquedas
-- =====================================================

-- =====================================================
-- RESPUESTA CORTA:
-- =====================================================
-- SÍ, '12345678-k' y '12345678-K' son DIFERENTES en PostgreSQL
-- Esto puede causar discrepancias entre Excel y el sistema
-- SOLUCIÓN: Normaliza todo a mayúsculas
-- =====================================================
