-- =====================================================
-- DIAGNÓSTICO: Ver estado actual de pagos de Javiera y Nicole
-- =====================================================

-- Ver TODOS los pagos de Javiera Moraga
SELECT 
    u.full_name,
    p.id as payment_id,
    p.amount,
    p.payment_date,
    p.payment_method,
    p.notes,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
LEFT JOIN treasury_payments p ON q.id = p.quota_id
WHERE u.full_name ILIKE '%javiera%moraga%'
  AND q.year = 2025
ORDER BY q.month, p.payment_date;

-- Ver TODOS los pagos de Nicole Castellon
SELECT 
    u.full_name,
    p.id as payment_id,
    p.amount,
    p.payment_date,
    p.payment_method,
    p.notes,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
LEFT JOIN treasury_payments p ON q.id = p.quota_id
WHERE u.full_name ILIKE '%nicole%castellon%'
  AND q.year = 2026
ORDER BY q.month, p.payment_date;

-- Resumen de cuotas de Javiera
SELECT 
    month,
    year,
    expected_amount,
    paid_amount,
    status,
    (SELECT COUNT(*) FROM treasury_payments WHERE quota_id = q.id) as num_payments
FROM treasury_monthly_quotas q
WHERE user_id = (SELECT id FROM users WHERE full_name ILIKE '%javiera%moraga%' LIMIT 1)
  AND year = 2025
ORDER BY month;
