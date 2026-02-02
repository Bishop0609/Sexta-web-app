-- =====================================================
-- NORMALIZAR RUT DE MINÚSCULA A MAYÚSCULA
-- =====================================================
-- Este script corrige el único RUT con 'k' minúscula
-- Las relaciones de tesorería NO se afectan porque usan UUID
-- =====================================================

-- =====================================================
-- PASO 1: VERIFICAR el RUT antes de cambiar
-- =====================================================
-- Ejecuta esto PRIMERO para confirmar qué RUT vas a cambiar
SELECT 
    id,
    rut as rut_actual,
    UPPER(rut) as rut_normalizado,
    full_name,
    rank,
    -- Verificar que tiene cuotas (esto NO se perderá)
    (SELECT COUNT(*) FROM treasury_monthly_quotas WHERE user_id = users.id) as cuotas_existentes,
    -- Verificar que tiene pagos (esto NO se perderá)
    (SELECT COUNT(*) FROM treasury_payments WHERE user_id = users.id) as pagos_existentes
FROM users
WHERE rut LIKE '%k'  -- Solo los que tienen 'k' minúscula
ORDER BY rut;

-- =====================================================
-- PASO 2: ACTUALIZAR el RUT a mayúscula
-- =====================================================
-- ⚠️ SOLO ejecuta esto DESPUÉS de verificar PASO 1
UPDATE users
SET rut = UPPER(rut)
WHERE rut LIKE '%k';

-- =====================================================
-- PASO 3: VERIFICAR que se actualizó correctamente
-- =====================================================
-- Debe mostrar el RUT con 'K' mayúscula
SELECT 
    rut,
    full_name,
    -- Verificar que las cuotas SIGUEN AHÍ
    (SELECT COUNT(*) FROM treasury_monthly_quotas WHERE user_id = users.id) as cuotas_existentes,
    -- Verificar que los pagos SIGUEN AHÍ
    (SELECT COUNT(*) FROM treasury_payments WHERE user_id = users.id) as pagos_existentes,
    '✓ Normalizado' as estado
FROM users
WHERE rut LIKE '%K'  -- Ahora debe aparecer con K mayúscula
ORDER BY rut;

-- =====================================================
-- PASO 4: Verificar que NO quedaron RUTs con minúscula
-- =====================================================
-- Debe devolver 0 filas
SELECT 
    rut,
    full_name,
    '⚠️ AÚN CON MINÚSCULA' as alerta
FROM users
WHERE rut LIKE '%k';

-- Si devuelve filas, ejecuta nuevamente PASO 2

-- =====================================================
-- RESUMEN
-- =====================================================
-- ✅ Solo se cambia la tabla 'users'
-- ✅ Las cuotas y pagos NO se pierden (usan user_id UUID)
-- ✅ Todas las relaciones siguen funcionando
-- ✅ Después de esto, tu Excel y la BD coincidirán
-- =====================================================
