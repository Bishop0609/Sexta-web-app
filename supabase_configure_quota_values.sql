-- =====================================================
-- CONFIGURACIÓN: Valores de Cuotas 2025 y 2026
-- Descripción: Establece los valores correctos de cuotas mensuales
-- Fecha: 2026-01-25
-- =====================================================

-- VALORES CORRECTOS:
-- 2025: $4,000 estándar / $2,000 reducida (estudiantes/aspirantes/postulantes)
-- 2026: $5,000 estándar / $2,500 reducida

-- =====================================================
-- CONFIGURAR CUOTAS 2025
-- =====================================================

-- Insertar o actualizar configuración de 2025
INSERT INTO treasury_quota_config (year, standard_quota, reduced_quota)
VALUES (2025, 4000, 2000)
ON CONFLICT (year) 
DO UPDATE SET 
    standard_quota = 4000,
    reduced_quota = 2000,
    updated_at = NOW();

-- =====================================================
-- CONFIGURAR CUOTAS 2026
-- =====================================================

-- Insertar o actualizar configuración de 2026
INSERT INTO treasury_quota_config (year, standard_quota, reduced_quota)
VALUES (2026, 5000, 2500)
ON CONFLICT (year) 
DO UPDATE SET 
    standard_quota = 5000,
    reduced_quota = 2500,
    updated_at = NOW();

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

-- Ver configuraciones actuales
SELECT 
    year,
    standard_quota,
    reduced_quota,
    created_at,
    updated_at
FROM treasury_quota_config
ORDER BY year;

-- =====================================================
-- ACTUALIZAR CUOTAS EXISTENTES (OPCIONAL)
-- =====================================================

-- Si ya generaste cuotas para 2025 con valores incorrectos ($5,000/$2,500),
-- puedes actualizarlas con este script:

-- ADVERTENCIA: Esto actualizará TODAS las cuotas de 2025
-- Solo ejecuta esto si estás seguro que las cuotas de 2025 tienen valores incorrectos

/*
-- Actualizar cuotas de bomberos para 2025 ($5,000 → $4,000)
UPDATE treasury_monthly_quotas
SET expected_amount = 4000
WHERE year = 2025 
  AND expected_amount = 5000;

-- Actualizar cuotas de estudiantes/aspirantes para 2025 ($2,500 → $2,000)
UPDATE treasury_monthly_quotas
SET expected_amount = 2000
WHERE year = 2025 
  AND expected_amount = 2500;

-- Verificar cambios
SELECT 
    year,
    expected_amount,
    COUNT(*) as cantidad
FROM treasury_monthly_quotas
WHERE year = 2025
GROUP BY year, expected_amount;
*/

-- =====================================================
-- CONFIGURAR AÑOS FUTUROS (TEMPLATE)
-- =====================================================

-- Para configurar valores de años futuros, usa este template:
/*
INSERT INTO treasury_quota_config (year, standard_quota, reduced_quota)
VALUES (2027, 6000, 3000)  -- Ajusta los valores según necesidad
ON CONFLICT (year) 
DO UPDATE SET 
    standard_quota = 6000,
    reduced_quota = 3000,
    updated_at = NOW();
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

/*
VALORES HISTÓRICOS:
- 2025: $4,000 / $2,000
- 2026: $5,000 / $2,500
- Años futuros: A definir según necesidad

PROCESO RECOMENDADO:
1. Configurar valores de cuotas ANTES de generar cuotas mensuales
2. Si ya generaste cuotas con valor incorrecto:
   - Opción A: Eliminar y regenerar
   - Opción B: Actualizar con UPDATE (ver arriba)
3. Para años futuros, configurar a comienzo del año

QUIÉN APLICA QUÉ CUOTA:
- Cuota Estándar: Bomberos, Voluntarios, etc.
- Cuota Reducida: Estudiantes, Aspirantes, Postulantes
  (determinado por rank o campo is_student)
*/
