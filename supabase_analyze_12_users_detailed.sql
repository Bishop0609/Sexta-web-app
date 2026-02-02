-- =====================================================
-- ANÁLISIS DETALLADO DE LOS 12 BOMBEROS
-- =====================================================
-- Objetivos:
-- 1. Ver su configuración (Estudiante, Rango)
-- 2. Ver sus cuotas 2025 (Monto esperado)
-- 3. Ver sus pagos realizados
-- =====================================================

WITH target_users AS (
    SELECT * FROM users 
    WHERE rut IN (
        '21373938-7', -- Javiera Moraga
        '22337684-3', -- Paula Ramírez
        '15571013-6', -- Paulo Morales
        '22026759-8', -- Martín Bernal
        '27979718-3', -- Karla Meza
        '15050916-5', -- Ángelo Póstigo
        '21844261-7', -- Manuel Brant
        '27731075-9', -- Vicente Hernández
        '22691434-K', -- Vicente Bernal
        '21562316-5', -- Gabriel Olivares
        '17016081-9', -- Tania Rojas
        '22378557-3'  -- Hans Zapata
    )
)
SELECT 
    u.full_name,
    u.rut,
    u.rank,
    u.is_student,
    
    -- Resumen de Cuotas
    COUNT(DISTINCT q.month) as meses_con_cuota,
    MIN(q.expected_amount) as monto_min,
    MAX(q.expected_amount) as monto_max,
    STRING_AGG(DISTINCT q.expected_amount::text, '/') as variables_monto,
    
    -- Resumen de Pagos
    COUNT(DISTINCT p.id) as pagos_realizados,
    COALESCE(SUM(p.amount), 0) as total_pagado,
    STRING_AGG(DISTINCT p.receipt_number, ', ') as recibos
    
FROM target_users u
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
LEFT JOIN treasury_payments p ON p.user_id = u.id AND EXTRACT(YEAR FROM p.payment_date) = 2025
GROUP BY u.id, u.full_name, u.rut, u.rank, u.is_student
ORDER BY u.full_name;

-- =====================================================
-- DETALLE MES A MES (Para ver inicio y huecos)
-- =====================================================
SELECT 
    u.full_name,
    q.month,
    q.expected_amount as debe,
    q.status,
    p.amount as pago,
    p.receipt_number,
    p.payment_date
FROM users u
JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
LEFT JOIN treasury_payments p ON p.quota_id = q.id
WHERE u.rut IN (
        '21373938-7', '22337684-3', '15571013-6', '22026759-8', 
        '27979718-3', '15050916-5', '21844261-7', '27731075-9', 
        '22691434-K', '21562316-5', '17016081-9', '22378557-3'
)
ORDER BY u.full_name, q.month;
