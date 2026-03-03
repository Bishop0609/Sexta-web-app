-- =====================================================
-- DIAGNÓSTICO: Estado de Deuda 2026
-- =====================================================

-- 1. Ver cuotas de Javiera en 2026
SELECT 
    'JAVIERA 2026' as user_name,
    month,
    year,
    expected_amount,
    paid_amount,
    status
FROM treasury_monthly_quotas q
JOIN users u ON q.user_id = u.id
WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
  AND q.year = 2026
ORDER BY month;

-- 2. Ver cuotas de Nicole en 2026
SELECT 
    'NICOLE 2026' as user_name,
    month,
    year,
    expected_amount,
    paid_amount,
    status
FROM treasury_monthly_quotas q
JOIN users u ON q.user_id = u.id
WHERE u.full_name = 'Nicole Alejandra Castellón Villanueva'
  AND q.year = 2026
ORDER BY month;

-- 3. Calcular deuda total según la función del sistema (si existe)
-- O manualmente sumando pending/partial
SELECT 
    u.full_name,
    SUM(q.expected_amount - q.paid_amount) as deuda_calculada
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
WHERE (u.full_name = 'Javiera Isidora Moraga Vergara' OR u.full_name = 'Nicole Alejandra Castellón Villanueva')
  AND q.status != 'paid'
  AND q.year <= 2026  -- Incluir deudas pasadas si las hay
GROUP BY u.full_name;
