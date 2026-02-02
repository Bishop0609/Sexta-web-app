-- =====================================================
-- CORRECCIÓN DE FECHAS DE INICIO DE CUOTAS 2025
-- =====================================================
-- Elimina las cuotas generadas para meses ANTERIORES
-- a la fecha de inicio indicada por el usuario.
-- =====================================================

-- 1. Ángelo Cristian Póstigo Rojo (RUT 15050916-5)
-- Inicio: 01.03.2025 -> Eliminar Enero y Febrero (Meses < 3)
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '15050916-5'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 3;

-- 2. Gabriel Alexander Olivares Cornejo (RUT 21562316-5)
-- Inicio: 01.05.2025 -> Eliminar Enero a Abril (Meses < 5)
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '21562316-5'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 5;

-- 3. Hans Antonio Jaime Zapata (RUT 22378557-3)
-- Inicio: 01.06.2025 -> Eliminar Enero a Mayo (Meses < 6)
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '22378557-3'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 6;

-- 4. Manuel Joseph Andrés Brant Araya (RUT 21844261-7)
-- Inicio: 01.05.2025 -> Eliminar Enero a Abril (Meses < 5)
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '21844261-7'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 5;

-- 5. Martín Ignacio Bernal González (RUT 22026759-8)
-- Inicio: 01.02.2025 -> Eliminar Enero (Mes < 2)
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '22026759-8'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 2;

-- 6. Tania Belén Rojas Araya (RUT 17016081-9)
-- Inicio: 01.06.2025 -> Eliminar Enero a Mayo (Meses < 6)
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '17016081-9'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 6;

-- 7. Vicente Gabriel Hernández Hidalgo (RUT 27731075-9)
-- Inicio: 01.05.2025 -> Eliminar Enero a Abril (Meses < 5)
DELETE FROM treasury_monthly_quotas
USING users
WHERE treasury_monthly_quotas.user_id = users.id
  AND users.rut = '27731075-9'
  AND treasury_monthly_quotas.year = 2025
  AND treasury_monthly_quotas.month < 5;

-- 8. Vicente Thomas Bernal González (RUT 22691434-K)
-- Inicio: 01.05.2025 -> Eliminar Enero a Abril (Meses < 5)
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
    COUNT(q.id) as cuotas_restantes,
    MIN(q.month) as mes_inicio_real
FROM users u
JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
WHERE u.rut IN (
    '15050916-5', '21562316-5', '22378557-3', '21844261-7',
    '22026759-8', '17016081-9', '27731075-9', '22691434-K'
)
GROUP BY u.full_name
ORDER BY u.full_name;
