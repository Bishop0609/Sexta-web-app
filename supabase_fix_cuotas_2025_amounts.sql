-- =====================================================
-- CORRECCIÓN: Recalcular montos de cuotas 2025
-- =====================================================
-- PROBLEMA: Cuotas generadas con montos incorrectos
-- VALORES CORRECTOS 2025:
--   $4,000 - Base general (todos los bomberos)
--   $2,000 - Estudiantes
--   $2,000 - Aspirantes/Postulantes
--   $1,000 - Aspirantes/Postulantes + Estudiantes (ambos)
-- =====================================================

-- =====================================================
-- PASO 1: VERIFICAR cuántas cuotas están mal
-- =====================================================
SELECT 
    COUNT(*) as total_cuotas,
    COUNT(DISTINCT q.user_id) as total_usuarios,
    
    -- Por categoría
    SUM(CASE WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN 1 ELSE 0 END) as postulante_estudiante,
    SUM(CASE WHEN u.is_student AND u.rank NOT IN ('Aspirante', 'Postulante') THEN 1 ELSE 0 END) as solo_estudiante,
    SUM(CASE WHEN u.rank IN ('Aspirante', 'Postulante') AND NOT u.is_student THEN 1 ELSE 0 END) as solo_postulante,
    SUM(CASE WHEN u.rank NOT IN ('Aspirante', 'Postulante') AND NOT COALESCE(u.is_student, FALSE) THEN 1 ELSE 0 END) as base_general,
    
    -- Cuotas con monto incorrecto
    SUM(CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student AND q.expected_amount != 1000 THEN 1
        WHEN u.is_student AND u.rank NOT IN ('Aspirante', 'Postulante') AND q.expected_amount != 2000 THEN 1
        WHEN u.rank IN ('Aspirante', 'Postulante') AND NOT u.is_student AND q.expected_amount != 2000 THEN 1
        WHEN u.rank NOT IN ('Aspirante', 'Postulante') AND NOT COALESCE(u.is_student, FALSE) AND q.expected_amount != 4000 THEN 1
        ELSE 0
    END) as cuotas_incorrectas
FROM treasury_monthly_quotas q
JOIN users u ON u.id = q.user_id
WHERE q.year = 2025;

-- =====================================================
-- PASO 2: VER EJEMPLOS de cada categoría
-- =====================================================
-- Ver cómo quedarían los montos corregidos
SELECT 
    u.full_name,
    u.rut,
    u.rank,
    u.is_student,
    q.month,
    q.expected_amount as monto_actual,
    
    -- Lógica de cuota correcta 2025
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN 1000
        WHEN u.is_student THEN 2000
        WHEN u.rank IN ('Aspirante', 'Postulante') THEN 2000
        ELSE 4000
    END as monto_correcto,
    
    -- Categoría
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN 'Postulante+Estudiante ($1,000)'
        WHEN u.is_student THEN 'Estudiante ($2,000)'
        WHEN u.rank IN ('Aspirante', 'Postulante') THEN 'Postulante ($2,000)'
        ELSE 'Base general ($4,000)'
    END as categoria,
    
    q.paid_amount as pagado,
    q.status as status_actual,
    
    -- Nuevo status después de corrección
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN
            CASE WHEN q.paid_amount >= 1000 THEN 'paid'
                 WHEN q.paid_amount > 0 THEN 'partial'
                 ELSE 'pending'
            END
        WHEN u.is_student OR u.rank IN ('Aspirante', 'Postulante') THEN
            CASE WHEN q.paid_amount >= 2000 THEN 'paid'
                 WHEN q.paid_amount > 0 THEN 'partial'
                 ELSE 'pending'
            END
        ELSE
            CASE WHEN q.paid_amount >= 4000 THEN 'paid'
                 WHEN q.paid_amount > 0 THEN 'partial'
                 ELSE 'pending'
            END
    END as nuevo_status
    
FROM treasury_monthly_quotas q
JOIN users u ON u.id = q.user_id
WHERE q.year = 2025
  AND (
      -- Casos incorrectos
      (u.rank IN ('Aspirante', 'Postulante') AND u.is_student AND q.expected_amount != 1000)
      OR (u.is_student AND u.rank NOT IN ('Aspirante', 'Postulante') AND q.expected_amount != 2000)
      OR (u.rank IN ('Aspirante', 'Postulante') AND NOT u.is_student AND q.expected_amount != 2000)
      OR (u.rank NOT IN ('Aspirante', 'Postulante') AND NOT COALESCE(u.is_student, FALSE) AND q.expected_amount != 4000)
  )
ORDER BY categoria, u.full_name, q.month
LIMIT 100;

-- =====================================================
-- PASO 3: ACTUALIZAR los montos incorrectos
-- =====================================================
-- ⚠️ EJECUTA ESTO SOLO DESPUÉS DE REVISAR PASO 2

UPDATE treasury_monthly_quotas q
SET 
    expected_amount = CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN 1000
        WHEN u.is_student THEN 2000
        WHEN u.rank IN ('Aspirante', 'Postulante') THEN 2000
        ELSE 4000
    END,
    status = CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN
            CASE WHEN paid_amount >= 1000 THEN 'paid'
                 WHEN paid_amount > 0 THEN 'partial'
                 ELSE 'pending'
            END
        WHEN u.is_student OR u.rank IN ('Aspirante', 'Postulante') THEN
            CASE WHEN paid_amount >= 2000 THEN 'paid'
                 WHEN paid_amount > 0 THEN 'partial'
                 ELSE 'pending'
            END
        ELSE
            CASE WHEN paid_amount >= 4000 THEN 'paid'
                 WHEN paid_amount > 0 THEN 'partial'
                 ELSE 'pending'
            END
    END
FROM users u
WHERE q.user_id = u.id
  AND q.year = 2025
  AND (
      -- Solo actualizar los incorrectos
      (u.rank IN ('Aspirante', 'Postulante') AND u.is_student AND q.expected_amount != 1000)
      OR (u.is_student AND u.rank NOT IN ('Aspirante', 'Postulante') AND q.expected_amount != 2000)
      OR (u.rank IN ('Aspirante', 'Postulante') AND NOT u.is_student AND q.expected_amount != 2000)
      OR (u.rank NOT IN ('Aspirante', 'Postulante') AND NOT COALESCE(u.is_student, FALSE) AND q.expected_amount != 4000)
  );

-- =====================================================
-- PASO 4: VERIFICAR resultado
-- =====================================================
-- Debe mostrar 0 cuotas incorrectas
SELECT 
    COUNT(*) as cuotas_aun_incorrectas
FROM treasury_monthly_quotas q
JOIN users u ON u.id = q.user_id
WHERE q.year = 2025
  AND (
      (u.rank IN ('Aspirante', 'Postulante') AND u.is_student AND q.expected_amount != 1000)
      OR (u.is_student AND u.rank NOT IN ('Aspirante', 'Postulante') AND q.expected_amount != 2000)
      OR (u.rank IN ('Aspirante', 'Postulante') AND NOT u.is_student AND q.expected_amount != 2000)
      OR (u.rank NOT IN ('Aspirante', 'Postulante') AND NOT COALESCE(u.is_student, FALSE) AND q.expected_amount != 4000)
  );

-- Si devuelve 0, ¡todo está correcto! ✅

-- =====================================================
-- PASO 5: Resumen por categoría
-- =====================================================
SELECT 
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN 'Postulante+Estudiante ($1,000)'
        WHEN u.is_student THEN 'Estudiante ($2,000)'
        WHEN u.rank IN ('Aspirante', 'Postulante') THEN 'Postulante ($2,000)'
        ELSE 'Base general ($4,000)'
    END as categoria,
    
    COUNT(DISTINCT u.id) as usuarios,
    COUNT(q.id) as total_cuotas,
    AVG(q.expected_amount) as promedio_cuota_esperada,
    SUM(q.expected_amount) as total_esperado,
    SUM(q.paid_amount) as total_pagado,
    SUM(q.expected_amount - q.paid_amount) as deuda_total,
    
    -- Distribución de estados
    SUM(CASE WHEN q.status = 'paid' THEN 1 ELSE 0 END) as pagadas,
    SUM(CASE WHEN q.status = 'partial' THEN 1 ELSE 0 END) as parciales,
    SUM(CASE WHEN q.status = 'pending' THEN 1 ELSE 0 END) as pendientes
    
FROM treasury_monthly_quotas q
JOIN users u ON u.id = q.user_id
WHERE q.year = 2025
GROUP BY categoria
ORDER BY categoria;

-- =====================================================
-- PASO 6: Listado completo para comparar con Excel
-- =====================================================
SELECT 
    u.full_name as nombre,
    u.rut,
    u.rank as cargo,
    u.is_student as estudiante,
    
    -- Categoría asignada
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN 'Postulante+Estudiante'
        WHEN u.is_student THEN 'Estudiante'
        WHEN u.rank IN ('Aspirante', 'Postulante') THEN 'Postulante'
        ELSE 'General'
    END as categoria,
    
    -- Cuota mensual que debe pagar
    CASE 
        WHEN u.rank IN ('Aspirante', 'Postulante') AND u.is_student THEN 1000
        WHEN u.is_student THEN 2000
        WHEN u.rank IN ('Aspirante', 'Postulante') THEN 2000
        ELSE 4000
    END as cuota_mensual,
    
    -- Deuda usando función del sistema
    d.months_owed as meses_morosos,
    d.total_amount as deuda_total,
    
    -- Resumen 2025
    COUNT(q.id) as meses_con_cuota,
    SUM(q.expected_amount) as total_esperado_2025,
    SUM(q.paid_amount) as total_pagado_2025,
    SUM(q.expected_amount - q.paid_amount) as total_adeudado_2025
    
FROM users u
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
CROSS JOIN LATERAL calculate_user_debt(u.id) d
WHERE u.payment_start_date IS NOT NULL
GROUP BY 
    u.id, u.full_name, u.rut, u.rank, u.is_student, 
    d.months_owed, d.total_amount
ORDER BY u.full_name;

-- =====================================================
-- INSTRUCCIONES:
-- =====================================================
-- 
-- 1. Ejecuta PASO 1: Ver resumen de cuotas incorrectas
-- 
-- 2. Ejecuta PASO 2: Ver ejemplos de cómo quedarían
--    👀 REVISA que los montos sean:
--       - $1,000 para Postulantes+Estudiantes
--       - $2,000 para solo Estudiantes o solo Postulantes
--       - $4,000 para el resto
-- 
-- 3. SI PASO 2 se ve correcto → Ejecuta PASO 3
-- 
-- 4. Ejecuta PASO 4: Debe devolver 0
-- 
-- 5. Ejecuta PASO 5: Ver resumen por categoría
-- 
-- 6. Ejecuta PASO 6: Exporta a CSV y compara con Excel
-- 
-- =====================================================
-- IMPORTANTE - Sobre los ABONOS:
-- =====================================================
-- ✅ Los pagos parciales YA registrados NO se pierden
-- ✅ Solo se actualiza el monto "esperado"
-- ✅ El monto "pagado" se mantiene intacto
-- ✅ El status se recalcula automáticamente
-- 
-- Ejemplo: Un bombero que debe $4,000 y abonó $2,000
--   - expected_amount = $4,000 (sin cambios)
--   - paid_amount = $2,000 (sin cambios)
--   - status = "partial" (sin cambios)
-- =====================================================
