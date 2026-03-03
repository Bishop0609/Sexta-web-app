-- ============================================================================
-- DIAGNÓSTICO DE DUPLICADOS - ENERO 2026
-- Verificar si hay registros duplicados y en qué eventos
-- ============================================================================

-- 1. Verificar si hay usuarios con múltiples registros en el MISMO evento
SELECT 
    ae.event_date,
    ae.subtype,
    at.name as tipo_evento,
    u.full_name,
    u.rut,
    COUNT(*) as num_registros,
    STRING_AGG(ar.status, ', ') as estados
FROM attendance_records ar
JOIN attendance_events ae ON ar.event_id = ae.id
JOIN act_types at ON ae.act_type_id = at.id
JOIN users u ON ar.user_id = u.id
WHERE ae.event_date >= '2026-01-01' 
  AND ae.event_date < '2026-02-01'
GROUP BY ae.id, ae.event_date, ae.subtype, at.name, u.id, u.full_name, u.rut
HAVING COUNT(*) > 1
ORDER BY ae.event_date, u.full_name
LIMIT 50;

-- 2. Contar total de eventos de enero 2026
SELECT 
    at.name as tipo,
    COUNT(*) as total_eventos
FROM attendance_events ae
JOIN act_types at ON ae.act_type_id = at.id
WHERE ae.event_date >= '2026-01-01' 
  AND ae.event_date < '2026-02-01'
GROUP BY at.name;

-- 3. Ver eventos específicos del 01-01-2026 (donde vimos duplicados de Gunther)
SELECT 
    ae.id,
    ae.event_date,
    ae.subtype,
    at.name as tipo,
    COUNT(DISTINCT ar.user_id) as usuarios_unicos,
    COUNT(ar.id) as total_registros
FROM attendance_events ae
JOIN act_types at ON ae.act_type_id = at.id
LEFT JOIN attendance_records ar ON ae.id = ar.event_id
WHERE ae.event_date = '2026-01-01'
GROUP BY ae.id, ae.event_date, ae.subtype, at.name
ORDER BY ae.subtype;
