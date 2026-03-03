-- =====================================================
-- CORRECCIÓN CONFIGURACIÓN JAVIERA
-- =====================================================

DO $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT id INTO v_user_id 
    FROM users 
    WHERE full_name = 'Javiera Isidora Moraga Vergara';

    -- 1. Actualizar configuración de usuario
    UPDATE users
    SET 
        payment_start_date = '2025-01-01'::DATE, -- Asignar fecha de inicio
        is_student = true,                       -- Marcar como estudiante
        student_start_date = '2025-01-01'::DATE, -- Fecha inicio estudiante
        student_end_date = '2026-12-31'::DATE    -- Opcional: fecha fin (ej. 2 años)
    WHERE id = v_user_id;

    RAISE NOTICE 'Configuración de Javiera actualizada: Fecha inicio 2025-01-01, Estudiante = TRUE';

    -- 2. Limpiar la inconsistencia recalculando
    -- (Nota: La inconsistencia debería desaparecer sola al tener payment_start_date)
    
END $$;

-- Verificar cómo quedó
SELECT full_name, payment_start_date, is_student, student_start_date
FROM users
WHERE full_name = 'Javiera Isidora Moraga Vergara';
