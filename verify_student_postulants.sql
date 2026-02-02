-- Verificando datos de los 3 usuarios problematicos
SELECT 
    full_name, 
    rut, 
    rank, 
    is_student,
    -- Check their current quota amounts for 2025
    (SELECT STRING_AGG(DISTINCT expected_amount::text, ', ') 
     FROM treasury_monthly_quotas q 
     WHERE q.user_id = u.id AND q.year = 2025) as montos_2025
FROM users u
WHERE rut IN (
    '22026759-8', -- Martín Bernal
    '27731075-9', -- Vicente Hernández
    '22691434-K'  -- Vicente Bernal
);
