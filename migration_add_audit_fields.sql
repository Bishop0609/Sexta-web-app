-- ============================================
-- MIGRACIÓN: Agregar campos de auditoría
-- ============================================
-- Fecha: 2026-01-15
-- Propósito: Agregar campos modified_by y modified_at a attendance_events
--            para trackear quién editó cada evento por última vez
-- ============================================

-- Agregar columnas de auditoría a attendance_events
ALTER TABLE attendance_events
ADD COLUMN IF NOT EXISTS modified_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS modified_at TIMESTAMP WITH TIME ZONE;

-- Comentarios para documentación
COMMENT ON COLUMN attendance_events.modified_by IS 'Usuario que modificó el evento por última vez';
COMMENT ON COLUMN attendance_events.modified_at IS 'Fecha y hora de la última modificación';

-- Verificación
-- Ejecutar después de aplicar esta migración:
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'attendance_events'
-- AND column_name IN ('modified_by', 'modified_at');
