-- =====================================================
-- FIX: Función calculate_user_debt mejorada
-- Descripción: Calcula deuda basándose en payment_start_date 
--              aunque no se hayan generado las cuotas
-- Fecha: 2026-01-25
-- =====================================================

-- Eliminar la función anterior
DROP FUNCTION IF EXISTS calculate_user_debt(UUID);

-- Crear función mejorada que calcula deuda real
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
    
    -- Calcular cuota mensual esperada
    IF user_rank IN ('Aspirante', 'Postulante') OR user_is_student THEN
        expected_monthly_quota := 2500;
    ELSE
        expected_monthly_quota := 5000;
    END IF;
    
    -- Calcular meses desde inicio hasta el mes ANTERIOR al actual
    -- (El mes actual no se considera deuda aún)
    months_since_start := (
        (current_year - EXTRACT(YEAR FROM user_start_date)) * 12 +
        (current_month - EXTRACT(MONTH FROM user_start_date))
    );
    
    -- Si la fecha de inicio es después del día 1 del mes, ese mes no cuenta como completo
    -- Solo contamos meses completos que ya pasaron
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
    
    -- La deuda es: meses desde inicio - meses pagados
    months_debt := GREATEST(months_since_start - paid_months, 0);
    total_debt := months_debt * expected_monthly_quota;
    
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

-- Ejemplo de prueba (reemplaza 'user-uuid-here' con un UUID real)
-- SELECT * FROM calculate_user_debt('user-uuid-here');

-- Probar con todos los usuarios que tienen payment_start_date
-- SELECT 
--     u.full_name,
--     u.payment_start_date,
--     d.*
-- FROM users u
-- CROSS JOIN LATERAL calculate_user_debt(u.id) d
-- WHERE u.payment_start_date IS NOT NULL
-- ORDER BY d.months_owed DESC, u.full_name;

-- =====================================================
-- NOTAS
-- =====================================================

/*
CAMBIOS PRINCIPALES:

1. Ahora calcula la deuda basándose en:
   - Meses transcurridos desde payment_start_date
   - Meses que efectivamente ha pagado (cuotas con status = 'paid')
   - Deuda = meses transcurridos - meses pagados

2. Si no existen cuotas generadas en treasury_monthly_quotas:
   - Aún así calcula los meses adeudados
   - Genera una lista estimada de cuotas pendientes
   - Incluye nota indicando que son estimaciones

3. Solo cuenta meses COMPLETOS que ya pasaron:
   - El mes actual NO se considera deuda
   - Si payment_start_date es después del día 1, ese mes no cuenta

EJEMPLO:
- Usuario con payment_start_date = 2025-01-01
- Fecha actual = 2026-01-25
- Meses transcurridos = 12 meses (enero 2025 a diciembre 2025)
- Enero 2026 NO cuenta porque es el mes actual
- Si no ha pagado nada = 12 meses adeudados
- Si pagó 5 meses = 7 meses adeudados
*/
