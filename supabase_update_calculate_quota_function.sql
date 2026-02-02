-- Script para actualizar la función calculate_expected_quota
-- Para soportar fechas de estudiante y cuota especial 2025

CREATE OR REPLACE FUNCTION calculate_expected_quota(
    p_user_id UUID,
    p_month INTEGER,
    p_year INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    user_rank VARCHAR(50);
    user_is_student BOOLEAN;
    user_student_start DATE;
    user_student_end DATE;
    expected_quota INTEGER;
    postulant_student_quota_config INTEGER;
    reduced_quota_config INTEGER;
    standard_quota_config INTEGER;
    is_active_student BOOLEAN;
    month_date DATE;
BEGIN
    -- Obtener información del usuario
    SELECT rank, is_student, student_start_date, student_end_date
    INTO user_rank, user_is_student, user_student_start, user_student_end
    FROM users
    WHERE id = p_user_id;
   
    -- Obtener configuración de cuotas para el año
    SELECT 
        COALESCE(postulant_student_quota, reduced_quota) as postulant_student,
        reduced_quota,
        standard_quota
    INTO 
        postulant_student_quota_config,
        reduced_quota_config,
        standard_quota_config
    FROM treasury_quota_config
    WHERE year = p_year;
   
    -- Si no existe configuración para el año, usar la más reciente
    IF NOT FOUND THEN
        SELECT 
            COALESCE(postulant_student_quota, reduced_quota) as postulant_student,
            reduced_quota,
            standard_quota
        INTO 
            postulant_student_quota_config,
            reduced_quota_config,
            standard_quota_config
        FROM treasury_quota_config
        ORDER BY year DESC
        LIMIT 1;
    END IF;
   
    -- Determinar si es estudiante activo en el mes especificado
    is_active_student := FALSE;
    
    IF user_is_student THEN
        -- Si no hay fecha de inicio, usar el flag is_student directamente
        IF user_student_start IS NULL THEN
            is_active_student := TRUE;
        ELSE
            -- Fecha del primer día del mes a evaluar
            month_date := make_date(p_year, p_month, 1);
           
            -- Debe haber iniciado antes o durante el mes
            IF month_date >= DATE_TRUNC('month', user_student_start) THEN
                -- Si no hay fecha de fin, es estudiante actualmente
                IF user_student_end IS NULL THEN
                    is_active_student := TRUE;
                ELSE
                    -- Debe terminar después o durante el mes
                    IF month_date <= DATE_TRUNC('month', user_student_end) THEN
                        is_active_student := TRUE;
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
   
    -- REGLA 1 (Solo 2025): Postulante + Estudiante Activo = cuota especial
    IF p_year = 2025 AND 
       user_rank = 'Postulante' AND 
       is_active_student AND
       postulant_student_quota_config IS NOT NULL THEN
        expected_quota := postulant_student_quota_config;
   
    -- REGLA 2: Aspirantes, Postulantes, Estudiantes Activos = cuota reducida
    ELSIF user_rank IN ('Aspirante', 'Postulante') OR is_active_student THEN
        expected_quota := reduced_quota_config;
   
    -- REGLA 3: Resto = cuota estándar
    ELSE
        expected_quota := standard_quota_config;
    END IF;
   
    RETURN expected_quota;
END;
$$ LANGUAGE plpgsql;

-- Prueba: Verificar que la función funciona correctamente
-- Ejemplo: Para un postulante estudiante en 2025
COMMENT ON FUNCTION calculate_expected_quota(UUID, INTEGER, INTEGER) IS
'Calcula la cuota mensual esperada para un usuario según:
1. Año 2025 + Postulante + Estudiante Activo = postulant_student_quota (ej: $1000)
2. Aspirante/Postulante/Estudiante Activo = reduced_quota (ej: $2000)
3. Resto = standard_quota (ej: $4000)

La determinación de "Estudiante Activo" considera:
- Si is_student = false -> NO es estudiante
- Si is_student = true y student_start_date IS NULL -> Es estudiante (por compatibilidad)
- Si is_student = true y student_start_date IS NOT NULL -> Verifica si el mes está dentro del rango [student_start_date, student_end_date]
  (Si student_end_date IS NULL, significa que actualmente es estudiante)
';
