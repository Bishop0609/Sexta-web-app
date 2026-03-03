-- Verificación final de Javiera
SELECT 
    month,
    year,
    expected_amount,
    paid_amount,
    status
FROM treasury_monthly_quotas
WHERE user_id = (SELECT id FROM users WHERE full_name = 'Javiera Isidora Moraga Vergara')
  AND year = 2025
ORDER BY month;
