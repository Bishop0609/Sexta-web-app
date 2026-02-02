-- =====================================================
-- DIAGNÓSTICO COMPLETO: Problemas entre BD y Excel
-- =====================================================
-- Este script identifica discrepancias entre pagos esperados
-- según el Excel de importación y lo que está en la BD
-- =====================================================

-- =====================================================
-- PASO 1: Resumen General de Pagos
-- =====================================================
SELECT 
    COUNT(*) as total_pagos,
    COUNT(DISTINCT user_id) as usuarios_con_pagos,
    MIN(payment_date) as primer_pago,
    MAX(payment_date) as ultimo_pago,
    SUM(amount) as monto_total
FROM treasury_payments;

-- =====================================================
-- PASO 2: Pagos por Usuario (Top 20)
-- =====================================================
SELECT 
    u.full_name,
    u.rut,
    COUNT(p.id) as total_pagos,
    SUM(p.amount) as monto_total_pagado,
    MIN(p.payment_date) as primer_pago,
    MAX(p.payment_date) as ultimo_pago
FROM users u
LEFT JOIN treasury_payments p ON p.user_id = u.id
GROUP BY u.id, u.full_name, u.rut
ORDER BY total_pagos DESC
LIMIT 20;

-- =====================================================
-- PASO 3: Usuarios SIN NINGÚN Pago Registrado
-- =====================================================
SELECT 
    u.full_name,
    u.rut,
    u.rank
FROM users u
LEFT JOIN treasury_payments p ON p.user_id = u.id
WHERE p.id IS NULL
ORDER BY u.full_name;

-- =====================================================
-- PASO 4: Usuarios con Menos de 12 Pagos en 2025
-- =====================================================
-- Esto identifica usuarios que deberían tener 12 pagos
-- pero tienen menos
SELECT 
    u.full_name,
    u.rut,
    COUNT(p.id) as pagos_2025,
    12 - COUNT(p.id) as pagos_faltantes
FROM users u
LEFT JOIN treasury_payments p ON p.user_id = u.id 
    AND EXTRACT(YEAR FROM p.payment_date) = 2025
GROUP BY u.id, u.full_name, u.rut
HAVING COUNT(p.id) < 12
ORDER BY pagos_faltantes DESC, u.full_name;

-- =====================================================
-- PASO 5: Desglose de Pagos por Mes y Año
-- =====================================================
SELECT 
    EXTRACT(YEAR FROM payment_date) as año,
    EXTRACT(MONTH FROM payment_date) as mes,
    COUNT(*) as cantidad_pagos,
    COUNT(DISTINCT user_id) as usuarios_distintos,
    SUM(amount) as monto_total
FROM treasury_payments
GROUP BY año, mes
ORDER BY año, mes;

-- =====================================================
-- PASO 6: Usuarios con Cuotas Pero Sin Pagos
-- =====================================================
-- Usuarios que tienen cuotas creadas pero no pagos asociados
SELECT 
    u.full_name,
    u.rut,
    q.year,
    COUNT(q.id) as cuotas_sin_pago
FROM treasury_monthly_quotas q
JOIN users u ON u.id = q.user_id
LEFT JOIN treasury_payments p ON p.quota_id = q.id
WHERE p.id IS NULL
  AND q.status = 'pending'
GROUP BY u.id, u.full_name, u.rut, q.year
ORDER BY cuotas_sin_pago DESC, u.full_name;

-- =====================================================
-- PASO 7: Verificar Integridad de Cuotas vs Pagos
-- =====================================================
-- Pagos que NO tienen quota_id válido
SELECT 
    p.receipt_number,
    p.payment_date,
    p.amount,
    u.full_name,
    u.rut,
    CASE 
        WHEN p.quota_id IS NULL THEN 'Sin quota_id'
        WHEN q.id IS NULL THEN 'quota_id inválido'
        ELSE 'OK'
    END as estado
FROM treasury_payments p
JOIN users u ON u.id = p.user_id
LEFT JOIN treasury_monthly_quotas q ON q.id = p.quota_id
WHERE p.quota_id IS NULL OR q.id IS NULL
ORDER BY p.payment_date;

-- =====================================================
-- PASO 8: Usuarios de la Imagen (Verificación Manual)
-- =====================================================
-- Lista de usuarios que aparecían en la imagen con problemas
SELECT 
    u.full_name,
    u.rut,
    COUNT(p.id) as pagos_registrados,
    STRING_AGG(p.receipt_number, ', ' ORDER BY p.payment_date) as recibos
FROM users u
LEFT JOIN treasury_payments p ON p.user_id = u.id
WHERE u.full_name IN (
    'Javiera Isidora Moraga Vergara',
    'Paula Fernanda Ramírez Vivanco',
    'Paulo Antonio Morales Escobar',
    'Martín Ignacio Bernal Bustos',
    'Karla Alejandra Meza González',
    'Ángelo Andrés Póstigo Garrido',
    'Manuel Alberto Brant Alarcón',
    'Vicente Andrés Hernández Flores',
    'Vicente Ignacio Bernal Bustos',
    'Gabriel Antonio Olivares Briceño',
    'Tania Alejandra Rojas Flores',
    'Hans Felipe Zapata Rojas'
)
GROUP BY u.id, u.full_name, u.rut
ORDER BY u.full_name;

-- =====================================================
-- PASO 9: Comparación Expected vs Paid por Usuario
-- =====================================================
-- Muestra deuda total vs pagado total por usuario
SELECT 
    u.full_name,
    u.rut,
    SUM(q.expected_amount) as total_esperado,
    SUM(q.paid_amount) as total_pagado,
    SUM(q.expected_amount) - SUM(q.paid_amount) as deuda_pendiente,
    COUNT(CASE WHEN q.status = 'pending' THEN 1 END) as cuotas_pendientes,
    COUNT(CASE WHEN q.status = 'paid' THEN 1 END) as cuotas_pagadas,
    COUNT(CASE WHEN q.status = 'partial' THEN 1 END) as cuotas_parciales
FROM users u
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
GROUP BY u.id, u.full_name, u.rut
HAVING SUM(q.expected_amount) - SUM(q.paid_amount) < SUM(q.expected_amount)
ORDER BY deuda_pendiente ASC;

-- =====================================================
-- INSTRUCCIONES:
-- =====================================================
-- 
-- Ejecuta cada PASO en orden y muéstrame los resultados
-- 
-- PASO 3: Te dirá qué usuarios NO tienen ningún pago
-- PASO 4: Te dirá qué usuarios tienen menos de 12 pagos en 2025
-- PASO 8: Verificará específicamente los usuarios de la imagen
-- 
-- Con estos resultados sabremos exactamente quiénes tienen problemas
-- y podremos crear el script de corrección
-- 
-- =====================================================
