-- Migration: Add attendance review tracking fields
-- Date: 2026-02-04
-- Description: Adds estado_revision, revisado_por, and fecha_revision to attendance_events table

-- Create enum type for review status if it doesn't exist
DO $$ BEGIN
    CREATE TYPE estado_revision_enum AS ENUM ('pendiente', 'revisada');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add new columns to attendance_events table
ALTER TABLE attendance_events 
ADD COLUMN IF NOT EXISTS estado_revision estado_revision_enum DEFAULT 'pendiente',
ADD COLUMN IF NOT EXISTS revisado_por UUID,
ADD COLUMN IF NOT EXISTS fecha_revision TIMESTAMP WITH TIME ZONE;

-- Add foreign key constraint only if usuarios table exists
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'usuarios') THEN
        ALTER TABLE attendance_events 
        ADD CONSTRAINT fk_attendance_events_revisado_por 
        FOREIGN KEY (revisado_por) REFERENCES usuarios(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_attendance_events_created_at_desc ON attendance_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_events_estado_revision ON attendance_events(estado_revision);
CREATE INDEX IF NOT EXISTS idx_attendance_events_created_by_created_at ON attendance_events(created_by, created_at);

-- Add comments for documentation
COMMENT ON COLUMN attendance_events.estado_revision IS 'Estado de revisión de la asistencia (pendiente/revisada)';
COMMENT ON COLUMN attendance_events.revisado_por IS 'ID del usuario que revisó y aprobó la asistencia';
COMMENT ON COLUMN attendance_events.fecha_revision IS 'Fecha y hora en que se aprobó la revisión';
