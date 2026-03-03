-- ============================================================================
-- EXPORTAR ASISTENCIAS FEBRERO 2026 - LISTADO DE NOMBRES
-- Selecciona este código y ejecútalo para ver los nombres
-- ============================================================================

SELECT 
    TO_CHAR(ae.event_date, 'DD/MM/YYYY') as fecha,
    ae.subtype as clave,
    u.full_name as voluntario,
    u.rut
FROM attendance_events ae
JOIN attendance_records ar ON ae.id = ar.event_id -- Corregido: ae.id en vez de ae.event_id
JOIN users u ON ar.user_id = u.id
JOIN act_types at ON ae.act_type_id = at.id
WHERE at.name = 'Emergencia'
  AND ae.event_date >= '2026-02-01'
  AND ar.status = 'present'
ORDER BY ae.event_date, ae.subtype, u.full_name;
