-- =====================================================
-- DETALLE CUOTAS 2026
-- =====================================================

-- 1. Detalle Javiera (¿Por qué debe 10.000?)
SELECT 
    'JAVIERA' as usuario,
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

-- 2. Detalle Nicole (¿Por qué debe 5.000?)
SELECT 
    'NICOLE' as usuario,
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
