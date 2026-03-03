-- ============================================================================
-- LIMPIEZA DE DATOS DUPLICADOS - ENERO 2026
-- Elimina todos los eventos de asistencia de enero 2026 para volver a cargar
-- ============================================================================

DO $$
DECLARE
    v_deleted_events INT;
    v_deleted_records INT;
BEGIN
    -- Contar registros antes de eliminar
    SELECT COUNT(*) INTO v_deleted_records
    FROM attendance_records ar
    JOIN attendance_events ae ON ar.event_id = ae.id
    WHERE ae.event_date >= '2026-01-01' 
      AND ae.event_date < '2026-02-01';
    
    SELECT COUNT(*) INTO v_deleted_events
    FROM attendance_events
    WHERE event_date >= '2026-01-01' 
      AND event_date < '2026-02-01';
    
    RAISE NOTICE 'Eliminando % eventos y % registros de enero 2026...', v_deleted_events, v_deleted_records;
    
    -- Eliminar eventos (los registros se eliminan automáticamente por CASCADE)
    DELETE FROM attendance_events
    WHERE event_date >= '2026-01-01' 
      AND event_date < '2026-02-01';
    
    RAISE NOTICE '✅ Limpieza completada';
    RAISE NOTICE 'Ahora puedes ejecutar el script de carga nuevamente';
END $$;
