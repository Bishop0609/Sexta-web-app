-- =====================================================
-- SCRIPT: Carga Masiva de Fechas de Inicio de Pago
-- Descripción: Establece payment_start_date = 2025-01-01 para todos los usuarios
-- Fecha: 2026-01-25
-- =====================================================

-- OPCIÓN 1: Actualizar TODOS los usuarios
-- ⚠️ CUIDADO: Esto establecerá la fecha para TODOS los usuarios, incluyendo admin
UPDATE users 
SET payment_start_date = '2025-01-01'
WHERE payment_start_date IS NULL;

-- Ver cuántos usuarios serán afectados (ejecuta esto ANTES de hacer el UPDATE arriba)
SELECT COUNT(*) as usuarios_sin_fecha
FROM users 
WHERE payment_start_date IS NULL;

-- =====================================================
-- OPCIÓN 2: Actualizar solo usuarios específicos (MÁS SEGURO)
-- =====================================================

-- Actualizar solo bomberos normales (excluir admin y roles especiales si es necesario)
UPDATE users 
SET payment_start_date = '2025-01-01'
WHERE payment_start_date IS NULL
  AND role NOT IN ('admin'); -- Excluir admin

-- Ver usuarios que serán afectados ANTES de actualizar
SELECT id, full_name, rut, rank, role
FROM users 
WHERE payment_start_date IS NULL
  AND role NOT IN ('admin')
ORDER BY full_name;

-- =====================================================
-- OPCIÓN 3: Actualizar solo usuarios activos/bomberos
-- =====================================================

-- Si quieres ser más selectivo, actualiza solo ciertos rangos
UPDATE users 
SET payment_start_date = '2025-01-01'
WHERE payment_start_date IS NULL
  AND rank NOT IN ('Aspirante', 'Postulante'); -- Excluir aspirantes y postulantes si no deben pagar aún

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

-- Ver todos los usuarios con sus fechas de inicio de pago
SELECT 
    full_name,
    rut,
    rank,
    role,
    payment_start_date,
    is_student
FROM users
ORDER BY payment_start_date NULLS LAST, full_name;

-- Contar usuarios por estado de payment_start_date
SELECT 
    CASE 
        WHEN payment_start_date IS NULL THEN 'Sin fecha (no paga)'
        ELSE 'Con fecha de pago'
    END as estado,
    COUNT(*) as cantidad
FROM users
GROUP BY 
    CASE 
        WHEN payment_start_date IS NULL THEN 'Sin fecha (no paga)'
        ELSE 'Con fecha de pago'
    END;

-- =====================================================
-- REVERTIR CAMBIOS (si es necesario)
-- =====================================================

-- Si necesitas revertir, ejecuta esto:
-- UPDATE users SET payment_start_date = NULL WHERE payment_start_date = '2025-01-01';

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

/*
INSTRUCCIONES DE USO:

1. PRIMERO ejecuta las consultas SELECT para ver qué usuarios serán afectados
2. LUEGO ejecuta el UPDATE que prefieras (Opción 1, 2 o 3)
3. FINALMENTE ejecuta las verificaciones para confirmar

RECOMENDACIÓN:
- Usa la Opción 2 (excluir admin) para mayor seguridad
- Después de actualizar, puedes modificar manualmente los usuarios 
  que necesiten otra fecha diferente a 2025-01-01

SIGUIENTE PASO:
- Después de actualizar las fechas, debes generar las cuotas mensuales
  desde el módulo de Tesorería para cada mes desde enero 2025 hasta el mes actual
*/
