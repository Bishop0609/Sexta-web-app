-- Agregar columna de estado a la tabla users
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active' 
CHECK (status IN ('active', 'resigned', 'suspended'));

COMMENT ON COLUMN public.users.status IS 'Estado del usuario: active (activo), resigned (renunciado), suspended (suspendido)';

-- Actualizar función para generar cuotas mensuales (SOLO ACTIVOS)
CREATE OR REPLACE FUNCTION public.generate_monthly_quotas(p_month integer, p_year integer)
 RETURNS TABLE(quota_id uuid, user_id uuid, amount integer, status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user RECORD;
    v_amount INTEGER;
    v_quota_id UUID;
BEGIN
    -- Iterar sobre todos los usuarios ACTIVOS que deben pagar cuota
    FOR v_user IN 
        SELECT u.id, u.rank, u.is_student, u.payment_start_date, u.student_start_date, u.student_end_date
        FROM users u
        WHERE u.payment_start_date IS NOT NULL
        AND u.status = 'active' -- SOLO USUARIOS ACTIVOS
        AND u.payment_start_date <= make_date(p_year, p_month, 28) -- Ya debían estar pagando
    LOOP
        -- Calcular monto esperado usando la función existente
        v_amount := calculate_expected_quota(v_user.id, p_month, p_year);
        
        -- Si el monto es > 0, crear o actualizar la cuota
        IF v_amount > 0 THEN
            INSERT INTO treasury_monthly_quotas (
                user_id,
                month,
                year,
                expected_amount,
                status,
                created_at,
                updated_at
            ) VALUES (
                v_user.id,
                p_month,
                p_year,
                v_amount,
                'pending',
                NOW(),
                NOW()
            )
            ON CONFLICT (user_id, month, year) 
            DO UPDATE SET 
                expected_amount = EXCLUDED.expected_amount,
                updated_at = NOW()
            WHERE treasury_monthly_quotas.status != 'paid'; -- No tocar si ya está pagada
            
            -- Retornar info de la cuota (solo para debug/log)
            SELECT id INTO v_quota_id FROM treasury_monthly_quotas 
            WHERE treasury_monthly_quotas.user_id = v_user.id 
            AND treasury_monthly_quotas.month = p_month 
            AND treasury_monthly_quotas.year = p_year;
            
            quota_id := v_quota_id;
            user_id := v_user.id;
            amount := v_amount;
            status := 'generated';
            RETURN NEXT;
        END IF;
    END LOOP;
    
    RETURN;
END;
$function$;

-- Actualizar función calculate_expected_quota para considerar estado (opcional, pero buena práctica)
CREATE OR REPLACE FUNCTION public.calculate_expected_quota(p_user_id uuid, p_month integer, p_year integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_rank text;
    v_is_student boolean;
    v_payment_start_date date;
    v_student_start_date date;
    v_student_end_date date;
    v_status text;
    v_config_standard integer;
    v_config_reduced integer;
    v_config_postulant_student integer;
    v_target_date date;
    v_is_active_student boolean;
BEGIN
    -- 1. Obtener datos del usuario
    SELECT rank, is_student, payment_start_date, student_start_date, student_end_date, status
    INTO v_rank, v_is_student, v_payment_start_date, v_student_start_date, v_student_end_date, v_status
    FROM users
    WHERE id = p_user_id;

    -- Si no existe o NO ESTÁ ACTIVO, retornar 0
    IF v_rank IS NULL OR v_status != 'active' THEN 
        RETURN 0;
    END IF;

    -- Si no tiene fecha de inicio de pago, retornar 0
    IF v_payment_start_date IS NULL THEN
        RETURN 0;
    END IF;

    -- Fecha objetivo (primer día del mes)
    v_target_date := make_date(p_year, p_month, 1);

    -- Si la fecha objetivo es ANTERIOR a la fecha de inicio de pago, retornar 0
    IF v_target_date < date_trunc('month', v_payment_start_date) THEN
        RETURN 0;
    END IF;

    -- 2. Obtener configuración del año
    SELECT standard_quota, reduced_quota, postulant_student_quota
    INTO v_config_standard, v_config_reduced, v_config_postulant_student
    FROM treasury_quota_config
    WHERE year = p_year
    LIMIT 1;

    -- Si no hay config para el año, buscar la más reciente
    IF v_config_standard IS NULL THEN
        SELECT standard_quota, reduced_quota, postulant_student_quota
        INTO v_config_standard, v_config_reduced, v_config_postulant_student
        FROM treasury_quota_config
        ORDER BY year DESC
        LIMIT 1;
    END IF;

    -- Default si no hay nada
    IF v_config_standard IS NULL THEN
        v_config_standard := 4000;
        v_config_reduced := 2000;
    END IF;

    -- 3. Calcular si es estudiante activo en ese mes
    v_is_active_student := false;
    IF v_is_student THEN
        -- Lógica de fechas de estudiante
        IF v_student_start_date IS NULL THEN
            v_is_active_student := true;
        ELSE
            IF v_target_date >= date_trunc('month', v_student_start_date) THEN
                IF v_student_end_date IS NULL OR v_target_date <= date_trunc('month', v_student_end_date) THEN
                    v_is_active_student := true;
                END IF;
            END IF;
        END IF;
    END IF;

    -- 4. Aplicar reglas de monto
    -- Regla especial 2025: Postulante + Estudiante
    IF p_year = 2025 AND v_rank = 'Postulante' AND v_is_active_student AND v_config_postulant_student IS NOT NULL THEN
        RETURN v_config_postulant_student;
    END IF;

    -- Aspirante o Postulante o Estudiante Activo = Cuota Reducida
    IF v_rank IN ('Aspirante', 'Postulante') OR v_is_active_student THEN
        RETURN v_config_reduced;
    END IF;

    -- Resto = Cuota Estándar
    RETURN v_config_standard;
END;
$function$;
