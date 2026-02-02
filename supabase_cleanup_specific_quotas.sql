-- =====================================================
-- LIMPIEZA DE CUOTAS 2025 - USUARIOS ESPECÍFICOS
-- =====================================================

-- 1. Martín Ignacio Bernal González (RUT 22026759-8)
-- Inicio: Feb 2025 -> Eliminar Enero
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '22026759-8'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 2;

-- 2. Vicente Gabriel Hernández Hidalgo (RUT 27731075-9)
-- Inicio: Mayo 2025 -> Eliminar Enero-Abril
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '27731075-9'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 5;

-- 3. Vicente Thomas Bernal González (RUT 22691434-K)
-- Inicio: Mayo 2025 -> Eliminar Enero-Abril
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '22691434-K'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 5;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================
SELECT 
    u.full_name,
    COUNT(q.id) as total_cuotas_reales
FROM users u
JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
WHERE u.rut IN ('22026759-8', '27731075-9', '22691434-K')
GROUP BY u.full_name;
