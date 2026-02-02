-- =====================================================
-- CORRECCIÓN DE MONTO CUOTA 2025
-- =====================================================
-- El usuario Vicente Gabriel Hernández Hidalgo (Postulante Estudiante)
-- tiene cuotas de 2.000 pero deben ser de 1.000.
-- Los otros dos usuarios (Martín y Vicente Thomas) ya tienen cuotas de 1.000.
-- =====================================================

UPDATE treasury_monthly_quotas
SET expected_amount = 1000
FROM users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '27731075-9' -- Vicente Gabriel Hernández Hidalgo
  AND treasury_monthly_quotas.year = 2025;

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================
SELECT 
    u.full_name,
    q.year,
    COUNT(q.id) as total_cuotas,
    STRING_AGG(DISTINCT q.expected_amount::text, ', ') as montos
FROM users u
JOIN treasury_monthly_quotas q ON q.user_id = u.id
WHERE u.rut IN ('27731075-9', '22026759-8', '22691434-K')
  AND q.year = 2025
GROUP BY u.full_name, q.year;
