-- Ver estado actual de Javiera después del script
SELECT 
    'JAVIERA - Estado Actual' as info,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status,
    COUNT(p.id) as num_payments
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
LEFT JOIN treasury_payments p ON q.id = p.quota_id
WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
  AND q.year = 2025
GROUP BY q.month, q.year, q.expected_amount, q.paid_amount, q.status
ORDER BY q.month;

-- Ver si hay algún pago registrado para Javiera en 2025
SELECT 
    'JAVIERA - Pagos 2025' as info,
    p.id,
    p.amount,
    p.payment_date,
    p.notes,
    q.month,
    q.year
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
LEFT JOIN treasury_payments p ON q.id = p.quota_id
WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
  AND q.year = 2025
ORDER BY q.month;
