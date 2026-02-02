-- =====================================================
-- DIAGNÓSTICO: Diferencia entre pagos y cuotas pagadas
-- =====================================================

-- 1. Ver cuotas con estado "partial" (pagadas parcialmente)
-- Estas NO aparecen como "pagadas" porque el monto no alcanza el esperado
SELECT 
    u.full_name,
    u.rut,
    q.month,
    q.year,
    q.expected_amount as esperado,
    q.paid_amount as pagado,
    q.status,
    q.expected_amount - q.paid_amount as falta
FROM treasury_monthly_quotas q
JOIN users u ON u.id = q.user_id
WHERE q.status = 'partial'
  AND q.year = 2025
ORDER BY u.full_name, q.year, q.month;

-- 2. Ver cuántos pagos hay por cada estado de cuota
SELECT 
    q.status as estado_cuota,
    COUNT(DISTINCT q.id) as cuotas,
    COUNT(p.id) as pagos
FROM treasury_monthly_quotas q
LEFT JOIN treasury_payments p ON p.quota_id = q.id
WHERE q.year IN (2025, 2026)
GROUP BY q.status
ORDER BY q.status;

-- 3. Ver usuarios con múltiples pagos para la misma cuota
SELECT 
    u.full_name,
    u.rut,
    q.month,
    q.year,
    COUNT(p.id) as cantidad_pagos,
    SUM(p.amount) as total_pagado,
    q.expected_amount as esperado,
    q.status
FROM treasury_payments p
JOIN treasury_monthly_quotas q ON q.id = p.quota_id
JOIN users u ON u.id = p.user_id
WHERE q.year IN (2025, 2026)
GROUP BY u.id, u.full_name, u.rut, q.id, q.month, q.year, q.expected_amount, q.status
HAVING COUNT(p.id) > 1
ORDER BY u.full_name, q.year, q.month;

-- 4. Ver casos donde el pago no coincide con el monto esperado
SELECT 
    u.full_name,
    u.rut,
    q.month,
    q.year,
    p.amount as monto_pagado,
    q.expected_amount as monto_esperado,
    p.amount - q.expected_amount as diferencia,
    q.status,
    p.receipt_number
FROM treasury_payments p
JOIN treasury_monthly_quotas q ON q.id = p.quota_id
JOIN users u ON u.id = p.user_id
WHERE p.amount != q.expected_amount
  AND q.year IN (2025, 2026)
ORDER BY diferencia, u.full_name;

-- 5. Resumen general por mes
SELECT 
    q.month,
    q.year,
    COUNT(DISTINCT q.id) as total_cuotas,
    COUNT(DISTINCT q.id) FILTER (WHERE q.status = 'paid') as cuotas_pagadas,
    COUNT(DISTINCT q.id) FILTER (WHERE q.status = 'partial') as cuotas_parciales,
    COUNT(DISTINCT q.id) FILTER (WHERE q.status = 'pending') as cuotas_pendientes,
    COUNT(p.id) as total_pagos,
    SUM(q.expected_amount) as monto_esperado_total,
    SUM(q.paid_amount) as monto_recaudado_total
FROM treasury_monthly_quotas q
LEFT JOIN treasury_payments p ON p.quota_id = q.id
WHERE q.year IN (2025, 2026)
GROUP BY q.year, q.month
ORDER BY q.year, q.month;

-- =====================================================
-- EXPLICACIÓN DE LA DIFERENCIA
-- =====================================================

/*
La diferencia entre "444 pagos" y "384 cuotas pagadas" puede deberse a:

1. PAGOS PARCIALES:
   - Usuario pagó $3000 cuando debía $4000
   - Usuario pagó $1000 cuando debía $2000
   - La cuota queda en estado "partial", NO "paid"

2. MÚLTIPLES PAGOS PARA UNA CUOTA:
   - Usuario pagó $2000 + $2000 = $4000 total
   - 2 registros de pago, pero 1 sola cuota marcada como "paid"

3. CUOTAS AÚN NO ALCANZADAS:
   - Si el monto total de pagos < monto esperado
   - La cuota NO se marca como "paid"

CUOTA SE MARCA COMO "PAID" CUANDO:
- paid_amount >= expected_amount

CUOTA SE MARCA COMO "PARTIAL" CUANDO:
- 0 < paid_amount < expected_amount

CUOTA SE MARCA COMO "PENDING" CUANDO:
- paid_amount = 0
*/
