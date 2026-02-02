-- =====================================================
-- ANÁLISIS DETALLADO DE LOS 13 USUARIOS PROBLEMÁTICOS
-- =====================================================
-- Este script te ayuda a entender QUÉ tienen de diferente
-- estos 13 usuarios vs tu Excel
-- =====================================================

-- =====================================================
-- PASO 1: Ver los 13 usuarios con problemas
-- =====================================================
-- Ejecuta primero QUERY 3 del script anterior
-- Luego copia/pega los RUTs aquí abajo para análisis detallado

-- =====================================================
-- PASO 2: Análisis detallado de UN usuario específico
-- =====================================================
-- REEMPLAZA '12345678-9' con el RUT del usuario problemático

WITH user_info AS (
    SELECT 
        id,
        full_name,
        rut,
        rank,
        payment_start_date,
        is_student
    FROM users
    WHERE rut = '12345678-9'  -- ⬅️ CAMBIA ESTE RUT
),
monthly_detail AS (
    SELECT 
        q.month,
        q.year,
        q.expected_amount,
        q.paid_amount,
        q.expected_amount - q.paid_amount as owed,
        q.status,
        -- Cuántos pagos tiene registrados
        (SELECT COUNT(*) FROM treasury_payments p WHERE p.quota_id = q.id) as num_payments,
        -- Detalle de pagos
        (SELECT STRING_AGG(amount::TEXT || ' el ' || TO_CHAR(payment_date, 'DD/MM/YYYY'), '; ')
         FROM treasury_payments p WHERE p.quota_id = q.id) as payment_details
    FROM treasury_monthly_quotas q
    WHERE q.user_id = (SELECT id FROM user_info)
      AND q.year = 2025
)
SELECT 
    -- Información del usuario
    (SELECT full_name FROM user_info) as nombre,
    (SELECT rut FROM user_info) as rut,
    (SELECT rank FROM user_info) as cargo,
    (SELECT payment_start_date FROM user_info) as inicio_pagos,
    (SELECT is_student FROM user_info) as estudiante,
    
    -- Resumen de cuotas
    (SELECT COUNT(*) FROM monthly_detail) as meses_generados,
    (SELECT SUM(expected_amount) FROM monthly_detail) as total_esperado,
    (SELECT SUM(paid_amount) FROM monthly_detail) as total_pagado,
    (SELECT SUM(owed) FROM monthly_detail) as total_adeudado,
    
    -- Deuda según función del sistema
    (SELECT months_owed FROM calculate_user_debt((SELECT id FROM user_info))) as meses_morosos_sistema,
    (SELECT total_amount FROM calculate_user_debt((SELECT id FROM user_info))) as deuda_sistema,
    
    -- Comparación
    (SELECT SUM(owed) FROM monthly_detail) - 
    (SELECT total_amount FROM calculate_user_debt((SELECT id FROM user_info))) as DIFERENCIA
;

-- =====================================================
-- PASO 3: Ver detalle mes por mes
-- =====================================================
SELECT 
    u.full_name,
    u.rut,
    q.month as mes,
    q.expected_amount as esperado,
    q.paid_amount as pagado,
    q.expected_amount - q.paid_amount as debe,
    q.status,
    -- Información contexto
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') THEN 'Debería pagar $2,500'
        WHEN u.is_student THEN 'Debería pagar $2,500 (estudiante)'
        ELSE 'Debería pagar $5,000'
    END as nota,
    CASE 
        WHEN q.expected_amount = 2500 AND u.rank NOT IN ('Aspirante', 'Postulante') AND NOT u.is_student THEN '⚠️ INCORRECTO: Debería ser $5,000'
        WHEN q.expected_amount = 5000 AND (u.rank IN ('Aspirante', 'Postulante') OR u.is_student) THEN '⚠️ INCORRECTO: Debería ser $2,500'
        ELSE '✓ Monto correcto'
    END as validacion_monto
FROM users u
JOIN treasury_monthly_quotas q ON q.user_id = u.id
WHERE u.rut = '12345678-9'  -- ⬅️ CAMBIA ESTE RUT
  AND q.year = 2025
ORDER BY q.month;

-- =====================================================
-- PASO 4: Patrones comunes en los 13 usuarios
-- =====================================================
-- Esta query identifica QUÉ tipo de problemas tienen los 13

WITH user_summary AS (
    SELECT 
        u.id,
        u.full_name,
        u.rut,
        u.rank,
        u.is_student,
        u.payment_start_date,
        COUNT(q.id) as cuotas_generadas,
        COALESCE(SUM(q.expected_amount - q.paid_amount), 0) as deuda_manual,
        d.total_amount as deuda_sistema,
        d.months_owed as meses_morosos,
        -- Verificar si tiene cuotas con monto incorrecto
        SUM(CASE 
            WHEN (u.rank IN ('Aspirante', 'Postulante') OR u.is_student) AND q.expected_amount != 2500 THEN 1
            WHEN u.rank NOT IN ('Aspirante', 'Postulante') AND NOT COALESCE(u.is_student, FALSE) AND q.expected_amount != 5000 THEN 1
            ELSE 0
        END) as cuotas_monto_incorrecto
    FROM users u
    LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
    CROSS JOIN LATERAL calculate_user_debt(u.id) d
    WHERE u.payment_start_date IS NOT NULL
    GROUP BY u.id, u.full_name, u.rut, u.rank, u.is_student, u.payment_start_date, d.total_amount, d.months_owed
)
SELECT 
    full_name,
    rut,
    rank,
    is_student,
    payment_start_date,
    cuotas_generadas,
    deuda_manual,
    deuda_sistema,
    deuda_manual - deuda_sistema as diferencia,
    cuotas_monto_incorrecto,
    -- Diagnóstico del problema
    CASE 
        WHEN cuotas_generadas = 0 THEN '❌ Sin cuotas generadas'
        WHEN cuotas_monto_incorrecto > 0 THEN '⚠️ Tiene cuotas con monto incorrecto ($2,500 vs $5,000)'
        WHEN deuda_manual != deuda_sistema THEN '⚠️ Deuda calculada no coincide con sistema'
        WHEN payment_start_date > '2025-01-01' AND cuotas_generadas < EXTRACT(MONTH FROM CURRENT_DATE) - EXTRACT(MONTH FROM payment_start_date) + 1 THEN '⚠️ Faltan cuotas por generar'
        ELSE '❓ Revisar manualmente'
    END as tipo_problema
FROM user_summary
WHERE deuda_manual != deuda_sistema 
   OR cuotas_generadas = 0
   OR cuotas_monto_incorrecto > 0
   OR (payment_start_date <= '2025-01-01' AND cuotas_generadas < EXTRACT(MONTH FROM CURRENT_DATE))
ORDER BY tipo_problema, full_name;

-- =====================================================
-- INSTRUCCIONES:
-- =====================================================
-- 
-- 1. Ejecuta PASO 4 primero - te mostrará el PATRÓN de problemas
-- 
-- 2. Para cada tipo de problema, identifica 1-2 RUTs de ejemplo
-- 
-- 3. Ejecuta PASO 2 y PASO 3 reemplazando el RUT para ver detalle
-- 
-- 4. Compara con tu Excel:
--    - ¿El usuario está en Excel?
--    - ¿Los montos coinciden?
--    - ¿El inicio de pagos es correcto?
-- 
-- 5. Anota los hallazgos y te ayudo a crear el script de corrección
-- =====================================================
