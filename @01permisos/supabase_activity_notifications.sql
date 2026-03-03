-- =====================================================
-- MIGRACIÓN: Agregar opciones de notificación a actividades
-- =====================================================

-- Agregar columnas para configuración de notificaciones
ALTER TABLE activities 
  ADD COLUMN IF NOT EXISTS notify_now BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_24h BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_48h BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_groups TEXT[] DEFAULT ARRAY['all'];

-- Comentarios
COMMENT ON COLUMN activities.notify_now IS 'Enviar notificación inmediatamente al crear/modificar';
COMMENT ON COLUMN activities.notify_24h IS 'Enviar recordatorio 24 horas antes';
COMMENT ON COLUMN activities.notify_48h IS 'Enviar recordatorio 48 horas antes';
COMMENT ON COLUMN activities.notify_groups IS 'Grupos a notificar: all, officers, discipline_council, applicants, active_firefighters, honorary_firefighters';

-- Actualizar actividades existentes para que tengan valores por defecto
UPDATE activities 
SET 
  notify_now = true,
  notify_24h = true,
  notify_48h = true,
  notify_groups = ARRAY['all']
WHERE notify_now IS NULL;
