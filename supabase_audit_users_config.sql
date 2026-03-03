-- =====================================================
-- AUDITORÍA DE CONFIGURACIÓN DE USUARIOS
-- =====================================================

SELECT 
    full_name as "Nombre",
    rank as "Cargo",
    CASE 
        WHEN payment_start_date IS NULL THEN 'FALTA FECHA INICIO' 
        ELSE TO_CHAR(payment_start_date, 'DD/MM/YYYY') 
    END as "Inicio Cuotas",
    CASE 
        WHEN is_student = true THEN 'SI' 
        ELSE 'NO' 
    END as "Es Estudiante",
    CASE 
        WHEN is_student = true AND student_start_date IS NULL THEN 'FALTA FECHA ESTUDIANTE'
        WHEN is_student = true THEN TO_CHAR(student_start_date, 'DD/MM/YYYY')
        ELSE '-'
    END as "Inicio Estudiante",
    -- Verificamos si tienen cuotas generadas para saber si es URGENTE
    (SELECT COUNT(*) FROM treasury_monthly_quotas WHERE user_id = u.id) as "Cuotas Existentes"
FROM users u
WHERE 
    -- Casos a detectar:
    (payment_start_date IS NULL)                          -- 1. No tienen fecha de inicio de cuotas
    OR 
    (is_student = true AND student_start_date IS NULL)    -- 2. Son estudiantes sin fecha de inicio
ORDER BY 
    "Cuotas Existentes" DESC, -- Primero los que ya tienen movimientos (Prioridad Alta)
    full_name ASC;
