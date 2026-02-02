-- =====================================================
-- DIAGNÓSTICO DE DISCREPANCIAS EN CUOTAS 2025
-- =====================================================
-- Este script te ayuda a identificar diferencias entre
-- el sistema y tu Excel de cuotas.
--
-- INSTRUCCIONES:
-- 1. Ejecuta cada query por separado en Supabase SQL Editor
-- 2. Compara los resultados con tu Excel
-- 3. Identifica casos específicos de discrepancia
-- =====================================================

-- =====================================================
-- QUERY 1: Resumen general de cuotas 2025
-- =====================================================
-- Compara estos totales con tu Excel
SELECT 
    COUNT(DISTINCT user_id) as total_usuarios_con_cuotas,
    COUNT(*) as total_cuotas_generadas,
    SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) as cuotas_pagadas,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as cuotas_pendientes,
    SUM(CASE WHEN status = 'partial' THEN 1 ELSE 0 END) as cuotas_parciales,
    SUM(expected_amount) as total_esperado,
    SUM(paid_amount) as total_pagado,
    SUM(expected_amount - paid_amount) as total_adeudado
FROM treasury_monthly_quotas
WHERE year = 2025;

-- =====================================================
-- QUERY 2: Detalle por usuario para 2025
-- =====================================================
-- Este reporte muestra EXACTAMENTE lo que debería aparecer
-- en el reporte de morosidad
SELECT 
    u.full_name as nombre,
    u.rut,
    u.rank as cargo,
    u.payment_start_date as inicio_pagos,
    u.is_student as es_estudiante,
    
    -- Cuotas del año
    COUNT(q.id) as meses_con_cuota_generada,
    SUM(q.expected_amount) as total_esperado_2025,
    SUM(q.paid_amount) as total_pagado_2025,
    SUM(q.expected_amount - q.paid_amount) as total_adeudado_2025,
    
    -- Deuda usando la función del sistema
    d.months_owed as meses_morosos_sistema,
    d.total_amount as deuda_sistema,
    
    -- Comparación
    CASE 
        WHEN SUM(q.expected_amount - q.paid_amount) != d.total_amount THEN '⚠️ DISCREPANCIA'
        ELSE '✓ OK'
    END as estado_validacion
    
FROM users u
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
CROSS JOIN LATERAL calculate_user_debt(u.id) d
WHERE u.payment_start_date IS NOT NULL
GROUP BY u.id, u.full_name, u.rut, u.rank, u.payment_start_date, u.is_student, d.months_owed, d.total_amount
ORDER BY u.rank, u.full_name;

-- =====================================================
-- QUERY 3: Usuarios con discrepancias detectadas
-- =====================================================
-- Identifica automáticamente usuarios con problemas
WITH user_summary AS (
    SELECT 
        u.id,
        u.full_name,
        u.rut,
        u.payment_start_date,
        COUNT(q.id) as cuotas_generadas,
        SUM(q.expected_amount - q.paid_amount) as deuda_manual,
        d.total_amount as deuda_sistema,
        d.months_owed as meses_morosos
    FROM users u
    LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
    CROSS JOIN LATERAL calculate_user_debt(u.id) d
    WHERE u.payment_start_date IS NOT NULL
    GROUP BY u.id, u.full_name, u.rut, u.payment_start_date, d.total_amount, d.months_owed
)
SELECT 
    full_name,
    rut,
    payment_start_date,
    cuotas_generadas,
    deuda_manual,
    deuda_sistema,
    meses_morosos,
    deuda_manual - deuda_sistema as diferencia,
    CASE 
        WHEN cuotas_generadas = 0 THEN '❌ Sin cuotas generadas'
        WHEN deuda_manual != deuda_sistema THEN '⚠️ Deuda no coincide'
        WHEN payment_start_date > '2025-01-01' AND cuotas_generadas < 12 THEN '⚠️ Faltan cuotas'
        ELSE '✓ OK'
    END as problema
FROM user_summary
WHERE deuda_manual != deuda_sistema 
   OR cuotas_generadas = 0
   OR (payment_start_date <= '2025-01-01' AND cuotas_generadas < EXTRACT(MONTH FROM CURRENT_DATE))
ORDER BY full_name;

-- =====================================================
-- QUERY 4: Detalle mensual de un usuario específico
-- =====================================================
-- REEMPLAZA 'NOMBRE_USUARIO' con el nombre del bombero
-- que tiene discrepancia según tu Excel
-- Este query muestra mes por mes qué está pasando
SELECT 
    u.full_name,
    u.rut,
    u.payment_start_date,
    u.is_student,
    q.month as mes,
    q.year as año,
    q.expected_amount as monto_esperado,
    q.paid_amount as monto_pagado,
    q.expected_amount - q.paid_amount as deuda_mes,
    q.status as estado,
    
    -- Pagos registrados
    (
        SELECT COUNT(*) 
        FROM treasury_payments p 
        WHERE p.quota_id = q.id
    ) as cantidad_pagos,
    
    (
        SELECT STRING_AGG(
            amount::TEXT || ' (' || TO_CHAR(payment_date, 'DD/MM/YYYY') || ')',
            ', '
        )
        FROM treasury_payments p 
        WHERE p.quota_id = q.id
    ) as detalle_pagos

FROM users u
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id
WHERE u.full_name ILIKE '%NOMBRE_USUARIO%'  -- ⬅️ CAMBIA ESTO
  AND q.year = 2025
ORDER BY q.month;

-- =====================================================
-- QUERY 5: Verificar cuotas esperadas vs generadas
-- =====================================================
-- Este query calcula cuántas cuotas DEBERÍAN tener cada usuario
WITH expected_months AS (
    SELECT 
        u.id as user_id,
        u.full_name,
        u.payment_start_date,
        -- Calcular meses que deberían tener cuotas desde payment_start_date hasta hoy
        CASE 
            WHEN payment_start_date IS NULL THEN 0
            WHEN payment_start_date > CURRENT_DATE THEN 0
            WHEN EXTRACT(YEAR FROM payment_start_date) > 2025 THEN 0
            WHEN EXTRACT(YEAR FROM payment_start_date) = 2025 THEN
                LEAST(EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER, 12) - EXTRACT(MONTH FROM payment_start_date)::INTEGER + 1
            ELSE
                LEAST(EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER, 12)
        END as meses_esperados_2025
    FROM users u
    WHERE payment_start_date IS NOT NULL
),
generated_months AS (
    SELECT 
        user_id,
        COUNT(*) as meses_generados_2025
    FROM treasury_monthly_quotas
    WHERE year = 2025
    GROUP BY user_id
)
SELECT 
    em.full_name,
    em.payment_start_date,
    em.meses_esperados_2025,
    COALESCE(gm.meses_generados_2025, 0) as meses_generados_2025,
    em.meses_esperados_2025 - COALESCE(gm.meses_generados_2025, 0) as diferencia,
    CASE 
        WHEN em.meses_esperados_2025 != COALESCE(gm.meses_generados_2025, 0) THEN '⚠️ FALTAN CUOTAS'
        ELSE '✓ OK'
    END as estado
FROM expected_months em
LEFT JOIN generated_months gm ON gm.user_id = em.user_id
WHERE em.meses_esperados_2025 != COALESCE(gm.meses_generados_2025, 0)
ORDER BY em.full_name;

-- =====================================================
-- QUERY 6: Análisis de cuota esperada (2500 vs 5000)
-- =====================================================
-- Verifica que las cuotas tengan el monto correcto
SELECT 
    u.full_name,
    u.rank,
    u.is_student,
    q.month,
    q.expected_amount,
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') OR u.is_student THEN 2500
        ELSE 5000
    END as deberia_ser,
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') OR u.is_student THEN
            CASE WHEN q.expected_amount != 2500 THEN '⚠️ INCORRECTO' ELSE '✓ OK' END
        ELSE
            CASE WHEN q.expected_amount != 5000 THEN '⚠️ INCORRECTO' ELSE '✓ OK' END
    END as validacion
FROM users u
JOIN treasury_monthly_quotas q ON q.user_id = u.id
WHERE q.year = 2025
  AND (
      (u.rank IN ('Aspirante', 'Postulante') OR u.is_student) AND q.expected_amount != 2500
      OR (u.rank NOT IN ('Aspirante', 'Postulante') AND NOT COALESCE(u.is_student, FALSE) AND q.expected_amount != 5000)
  )
ORDER BY u.full_name, q.month;

-- =====================================================
-- INSTRUCCIONES PARA USO:
-- =====================================================
-- 
-- 1. Ejecuta QUERY 1: Compara totales generales con tu Excel
-- 
-- 2. Ejecuta QUERY 2: Exporta a CSV y compara con tu Excel
--    línea por línea
-- 
-- 3. Ejecuta QUERY 3: Identifica automáticamente problemas
-- 
-- 4. Para cada usuario con discrepancia:
--    - Ejecuta QUERY 4 reemplazando el nombre
--    - Verifica los pagos mes por mes
-- 
-- 5. Ejecuta QUERY 5: Verifica cuotas faltantes
-- 
-- 6. Ejecuta QUERY 6: Verifica montos incorrectos
-- 
-- ⚠️ TOMA NOTA de los casos específicos que encuentres
--    para que podamos corregirlos.
-- =====================================================
