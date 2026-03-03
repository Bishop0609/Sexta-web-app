-- ============================================================================
-- ACTUALIZACIÓN DE RANKING DE ASISTENCIA
-- Objetivo: Mostrar Top 10 de EMERGENCIAS del AÑO ACTUAL
-- ============================================================================

CREATE OR REPLACE FUNCTION get_attendance_ranking(limit_count INT)
RETURNS TABLE (
  user_id UUID,
  full_name VARCHAR,
  rank VARCHAR,
  attendance_pct NUMERIC,
  total_events INT
) AS $$
DECLARE
    start_of_year DATE;
    total_emergencies INT;
BEGIN
    -- Definir inicio del año actual
    start_of_year := date_trunc('year', CURRENT_DATE)::DATE;

    -- Calcular el total de emergencias del año (universo)
    SELECT COUNT(*) INTO total_emergencies
    FROM attendance_events ae
    JOIN act_types at ON ae.act_type_id = at.id
    WHERE at.name = 'Emergencia'
      AND ae.event_date >= start_of_year;

    -- Retornar ranking
    RETURN QUERY
    SELECT 
      u.id,
      u.full_name,
      u.rank,
      -- Porcentaje = (Asistencias / Total Emergencias del Año) * 100
      CASE 
        WHEN total_emergencies > 0 THEN 
            ROUND((COUNT(ar.user_id)::NUMERIC / total_emergencies) * 100, 2)
        ELSE 0 
      END AS attendance_pct,
      -- Retornamos el total de asistencias del usuario, NO el total de eventos global
      -- (El frontend puede mostrar el total global en el título)
      COUNT(ar.user_id)::INT AS total_events -- Asistencias de este usuario
    FROM users u
    JOIN attendance_records ar ON u.id = ar.user_id
    JOIN attendance_events ae ON ar.event_id = ae.id
    JOIN act_types at ON ae.act_type_id = at.id
    WHERE at.name = 'Emergencia'
      AND ae.event_date >= start_of_year
      AND ar.status = 'present' -- Solo contar asistencias presentes
    GROUP BY u.id, u.full_name, u.rank
    ORDER BY attendance_pct DESC, u.full_name ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
