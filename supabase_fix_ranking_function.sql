-- ============================================================================
-- FIX RANKING ASISTENCIA - DROP & RECREATE
-- ============================================================================

-- 1. Eliminar función anterior (para evitar conflictos de tipo de retorno)
DROP FUNCTION IF EXISTS get_attendance_ranking(INT);

-- 2. Crear nueva función corregida
CREATE OR REPLACE FUNCTION get_attendance_ranking(limit_count INT)
RETURNS TABLE (
  total_emergencies INT,
  emergencies_attended INT,
  user_id UUID,
  full_name VARCHAR,
  rank VARCHAR,
  attendance_pct NUMERIC
) AS $$
DECLARE
    v_start_date DATE;
    v_total_emergencies INT;
BEGIN
    -- Definir inicio del año actual (01/01/2026)
    v_start_date := date_trunc('year', CURRENT_DATE)::DATE;

    -- Calcular el total de emergencias del año (universo)
    SELECT COUNT(*) INTO v_total_emergencies
    FROM attendance_events ae
    JOIN act_types at ON ae.act_type_id = at.id
    WHERE at.name = 'Emergencia'
      AND ae.event_date >= v_start_date;

    IF v_total_emergencies = 0 THEN
        v_total_emergencies := 1; -- Evitar división por cero
    END IF;

    RETURN QUERY
    SELECT 
        v_total_emergencies::INT AS total_emergencies,
        COUNT(ar.user_id)::INT AS emergencies_attended,
        u.id,
        u.full_name,
        u.rank,
        ROUND((COUNT(ar.user_id)::NUMERIC / v_total_emergencies) * 100, 2) AS attendance_pct
    FROM users u
    JOIN attendance_records ar ON u.id = ar.user_id
    JOIN attendance_events ae ON ar.event_id = ae.id
    JOIN act_types at ON ae.act_type_id = at.id
    WHERE at.name = 'Emergencia'
      AND ae.event_date >= v_start_date
      AND ar.status = 'present'
    GROUP BY u.id, u.full_name, u.rank
    HAVING COUNT(ar.user_id) > 0
    ORDER BY attendance_pct DESC, u.full_name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
