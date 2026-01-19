-- Función RPC para obtener estadísticas mensuales de asistencia
-- Optimiza la carga del dashboard al realizar la agregación en el servidor

CREATE OR REPLACE FUNCTION get_monthly_stats()
RETURNS TABLE (
  month text,
  year int,
  month_num int,
  efectiva_count bigint,
  abono_count bigint
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH monthly_data AS (
    SELECT
      to_char(ae.event_date, 'YYYY-MM') as month_key,
      EXTRACT(YEAR FROM ae.event_date)::int as year_val,
      EXTRACT(MONTH FROM ae.event_date)::int as month_val,
      at.category,
      COUNT(*) as count
    FROM attendance_events ae
    JOIN attendance_records ar ON ae.id = ar.event_id
    JOIN act_types at ON ae.act_type_id = at.id
    WHERE 
      ar.status = 'present'
      AND ae.event_date >= (CURRENT_DATE - INTERVAL '6 months')
    GROUP BY 1, 2, 3, 4
  )
  SELECT
    m.month_key as month,
    m.year_val as year,
    m.month_val as month_num,
    COALESCE(SUM(CASE WHEN m.category = 'efectiva' THEN m.count ELSE 0 END), 0)::bigint as efectiva_count,
    COALESCE(SUM(CASE WHEN m.category = 'abono' THEN m.count ELSE 0 END), 0)::bigint as abono_count
  FROM monthly_data m
  GROUP BY m.month_key, m.month_val, m.year_val
  ORDER BY m.month_key;
END;
$$;

