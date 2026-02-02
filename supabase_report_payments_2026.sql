-- =====================================================
-- REPORTE DE PAGOS 2026
-- =====================================================
-- Muestra todos los pagos asociados a cuotas del año 2026
-- Ordenados por Usuario y Mes
-- =====================================================

SELECT 
    u.full_name as nombre,
    u.rut,
    q.month as mes_cuota,
    p.amount as monto_pagado,
    p.receipt_number as nro_recibo,
    TO_CHAR(p.payment_date, 'DD/MM/YYYY') as fecha_pago,
    p.payment_method as metodo,
    p.registered_by as registrado_por
FROM treasury_payments p
JOIN treasury_monthly_quotas q ON p.quota_id = q.id
JOIN users u ON p.user_id = u.id
WHERE q.year = 2026
ORDER BY u.full_name, q.month;

-- =====================================================
-- RESUMEN 2026
-- =====================================================
SELECT 
    COUNT(*) as total_pagos,
    SUM(p.amount) as total_recaudado,
    COUNT(DISTINCT p.user_id) as usuarios_con_pagos_2026
FROM treasury_payments p
JOIN treasury_monthly_quotas q ON p.quota_id = q.id
WHERE q.year = 2026;
