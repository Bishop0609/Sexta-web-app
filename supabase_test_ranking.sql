-- ============================================================================
-- TEST: Verificar qué está devolviendo la función de ranking
-- ============================================================================

-- 1. Ver qué emergencias existen en 2026
SELECT 
    ae.id,
    ae.event_date,
    at.name as tipo,
    COUNT(ar.id) as total_registros,
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END) as presentes
FROM attendance_events ae
JOIN act_types at ON ae.act_type_id = at.id
LEFT JOIN attendance_records ar ON ae.id = ar.event_id
WHERE at.name = 'Emergencia'
  AND ae.event_date >= '2026-01-01'
GROUP BY ae.id, ae.event_date, at.name
ORDER BY ae.event_date
LIMIT 10;

-- 2. Probar la función directamente
SELECT * FROM get_attendance_ranking(10);

-- 3. Ver registros de asistencia para emergencias de un usuario específico
SELECT 
    u.full_name,
    ae.event_date,
    ar.status,
    at.name as tipo
FROM attendance_records ar
JOIN users u ON ar.user_id = u.id
JOIN attendance_events ae ON ar.event_id = ae.id
JOIN act_types at ON ae.act_type_id = at.id
WHERE at.name = 'Emergencia'
  AND ae.event_date >= '2026-01-01'
  AND u.full_name LIKE '%Gunther%'
ORDER BY ae.event_date
LIMIT 20;
