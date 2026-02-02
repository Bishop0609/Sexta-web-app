-- =====================================================
-- TABLA: sent_reminders
-- Propósito: Rastrear recordatorios enviados para evitar duplicados
-- =====================================================

CREATE TABLE IF NOT EXISTS sent_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reminder_type VARCHAR(50) NOT NULL, 
  -- Tipos: 'activity_24h', 'activity_48h', 'shift_24h', 'shift_48h', 'treasury_reminder'
  reference_id UUID NOT NULL, 
  -- ID de la actividad, guardia, o cuota referenciada
  reference_date TIMESTAMPTZ NOT NULL, 
  -- Fecha del evento al que se refiere el recordatorio
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  recipient_count INTEGER DEFAULT 0, 
  -- Cuántos usuarios recibieron el email
  
  -- Evita que se envíe el mismo recordatorio dos veces
  UNIQUE(reminder_type, reference_id)
);

-- Índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_sent_reminders_type_ref 
  ON sent_reminders(reminder_type, reference_id);

-- Índice para limpiar recordatorios antiguos
CREATE INDEX IF NOT EXISTS idx_sent_reminders_sent_at 
  ON sent_reminders(sent_at);

COMMENT ON TABLE sent_reminders IS 'Registro de recordatorios por email enviados para evitar duplicados';
COMMENT ON COLUMN sent_reminders.reminder_type IS 'Tipo de recordatorio: activity_24h, activity_48h, shift_24h, shift_48h, treasury_reminder';
COMMENT ON COLUMN sent_reminders.reference_id IS 'UUID del evento (actividad, guardia, cuota) al que se refiere';
COMMENT ON COLUMN sent_reminders.reference_date IS 'Fecha/hora del evento original';
COMMENT ON COLUMN sent_reminders.recipient_count IS 'Cantidad de usuarios que recibieron el recordatorio';
