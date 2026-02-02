-- =====================================================
-- FIX: calculate_user_debt con valores dinámicos
-- Descripción: Usa treasury_quota_config en lugar de valores hardcoded
-- Fecha: 2026-01-26
-- =====================================================

DROP FUNCTION IF EXISTS calculate_user_debt(UUID);

CREATE OR REPLACE FUNCTION calculate_user_debt(p_user_id UUID)
RETURNS TABLE(
    months_owed INTEGER,
    total_amount INTEGER,
    pending_quotas JSONB
) AS $$
DECLARE
    current_month INTEGER;
    current_year INTEGER;
    user_start_date DATE;
    user_rank VARCHAR(50);
    user_is_student BOOLEAN;
    expected_monthly_quota INTEGER;
    months_since_start INTEGER;
    paid_months INTEGER;
    quota_record RECORD;
    pending_list JSONB := '[]'::JSONB;
    total_debt INTEGER := 0;
    months_debt INTEGER := 0;
    config_standard INTEGER;
    config_reduced INTEGER;
BEGIN
    -- Obtener mes y año actual
    current_month := EXTRACT(MONTH FROM CURRENT_DATE);
    current_year := EXTRACT(YEAR FROM CURRENT_DATE);
    
    -- Obtener información del usuario
    SELECT payment_start_date, rank, is_student 
    INTO user_start_date, user_rank, user_is_student
    FROM users
    WHERE id = p_user_id;
    
    -- Si no tiene fecha de inicio, no debe cuotas
    IF user_start_date IS NULL THEN
        months_owed := 0;
        total_amount := 0;
        pending_quotas := '[]'::JSONB;
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Si la fecha de inicio es en el futuro, no debe nada
    IF user_start_date > CURRENT_DATE THEN
        months_owed := 0;
        total_amount := 0;
        pending_quotas := '[]'::JSONB;
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Obtener configuración de cuotas del año del payment_start_date
    -- Si no existe, buscar la más reciente
    SELECT standard_quota, reduced_quota
    INTO config_standard, config_reduced
    FROM treasury_quota_config
    WHERE year = EXTRACT(YEAR FROM user_start_date)
    ORDER BY year DESC
    LIMIT 1;
    
    -- Si no hay configuración, usar valores por defecto de 2025
    IF config_standard IS NULL THEN
        config_standard := 4000;
        config_reduced := 2000;
    END IF;
    
    -- Calcular cuota mensual esperada basada en configuración
    IF user_rank IN ('Aspirante', 'Postulante') OR user_is_student THEN
        expected_monthly_quota := config_reduced;
    ELSE
        expected_monthly_quota := config_standard;
    END IF;
    
    -- Calcular meses desde inicio hasta el mes ANTERIOR al actual
    months_since_start := (
        (current_year - EXTRACT(YEAR FROM user_start_date)) * 12 +
        (current_month - EXTRACT(MONTH FROM user_start_date))
    );
    
    -- Si la fecha de inicio es después del día 1 del mes, ese mes no cuenta
    IF EXTRACT(DAY FROM user_start_date) > 1 THEN
        months_since_start := months_since_start - 1;
    END IF;
    
    -- Asegurar que no sea negativo
    IF months_since_start < 0 THEN
        months_since_start := 0;
    END IF;
    
    -- Contar cuántos meses ha pagado (cuotas con status = 'paid')
    SELECT COUNT(*) INTO paid_months
    FROM treasury_monthly_quotas
    WHERE user_id = p_user_id
      AND status = 'paid'
      AND (
          year < current_year 
          OR (year = current_year AND month < current_month)
      );
    
    -- 1. Calcular meses de deuda (lógica original basada en fechas y pagos)
    months_debt := GREATEST(months_since_start - paid_months, 0);

    -- 2. Calcular monto total (lógica nueva basada en SUMA REAL de base de datos)
    SELECT COALESCE(SUM(expected_amount - COALESCE(paid_amount, 0)), 0)
    INTO total_debt
    FROM treasury_monthly_quotas
    WHERE user_id = p_user_id
        AND status != 'paid'
        AND (
            year < current_year 
            OR (year = current_year AND month < current_month)
        );

    -- Si no hay cuotas en BD pero hay meses de deuda (months_debt > 0),
    -- significa que faltan generar cuotas anteriores a la fecha actual.
    -- En ese caso, sumamos la estimación.
    IF total_debt = 0 AND months_debt > 0 THEN
        total_debt := months_debt * expected_monthly_quota;
    END IF;

    -- Construir lista de cuotas pendientes (si existen registros)
    FOR quota_record IN
        SELECT month, year, expected_amount, paid_amount
        FROM treasury_monthly_quotas
        WHERE user_id = p_user_id
          AND status != 'paid'
          AND (
              year < current_year 
              OR (year = current_year AND month < current_month)
          )
        ORDER BY year, month
    LOOP
        pending_list := pending_list || JSONB_BUILD_OBJECT(
            'month', quota_record.month,
            'year', quota_record.year,
            'expected', quota_record.expected_amount,
            'paid', quota_record.paid_amount,
            'owed', quota_record.expected_amount - quota_record.paid_amount
        );
    END LOOP;
    
    -- Si no hay cuotas registradas pero hay deuda, generar lista estimada
    IF months_debt > 0 AND pending_list = '[]'::JSONB THEN
        DECLARE
            calc_year INTEGER := EXTRACT(YEAR FROM user_start_date);
            calc_month INTEGER := EXTRACT(MONTH FROM user_start_date);
            i INTEGER;
        BEGIN
            FOR i IN 1..months_debt LOOP
                pending_list := pending_list || JSONB_BUILD_OBJECT(
                    'month', calc_month,
                    'year', calc_year,
                    'expected', expected_monthly_quota,
                    'paid', 0,
                    'owed', expected_monthly_quota,
                    'note', 'Cuota no generada - estimación basada en payment_start_date'
                );
                
                -- Avanzar al siguiente mes
                calc_month := calc_month + 1;
                IF calc_month > 12 THEN
                    calc_month := 1;
                    calc_year := calc_year + 1;
                END IF;
                
                -- Detenerse si llegamos al mes actual
                IF calc_year = current_year AND calc_month >= current_month THEN
                    EXIT;
                END IF;
            END LOOP;
        END;
    END IF;
    
    months_owed := months_debt;
    total_amount := total_debt;
    pending_quotas := pending_list;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

/*
-- Probar con un usuario específico
SELECT * FROM calculate_user_debt('user-uuid-here');

-- Ver todos los usuarios con deuda
SELECT 
    u.full_name,
    u.payment_start_date,
    d.*
FROM users u
CROSS JOIN LATERAL calculate_user_debt(u.id) d
WHERE u.payment_start_date IS NOT NULL
ORDER BY d.months_owed DESC, u.full_name;
*/

-- =====================================================
-- CAMBIOS EN ESTA VERSIÓN
-- =====================================================

/*
MEJORAS:
1. Ahora consulta treasury_quota_config para obtener valores dinámicos
2. Usa la configuración del año de payment_start_date
3. Si no hay config, usa valores por defecto de 2025 ($4000/$2000)
4. Elimina valores hardcoded de $5000/$2500

NOTA: Si cambias las cuotas en el futuro, solo necesitas actualizar
treasury_quota_config, no esta función.
*/
