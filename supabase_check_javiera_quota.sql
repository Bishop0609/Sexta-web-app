-- Verificar la cuota esperada que calcula el sistema para Javiera
SELECT 
    'Cuota calculada para Javiera' as info,
    calculate_expected_quota(
        (SELECT id FROM users WHERE full_name = 'Javiera Isidora Moraga Vergara'),
        2,  -- Febrero
        2025
    ) as cuota_calculada;

-- Ver información básica de Javiera
SELECT 
    'Configuración de Javiera' as info,
    u.full_name,
    u.rank,
    u.is_student,
    u.student_start_date,
    u.student_end_date
FROM users u
WHERE u.full_name = 'Javiera Isidora Moraga Vergara';

-- Ver las cuotas esperadas en la tabla (esto es lo importante)
SELECT 
    'Cuotas en tabla' as info,
    month,
    year,
    expected_amount,
    paid_amount,
    status
FROM treasury_monthly_quotas
WHERE user_id = (SELECT id FROM users WHERE full_name = 'Javiera Isidora Moraga Vergara')
  AND year = 2025
ORDER BY month;
