-- Agregar campos de auditoría a la tabla activities
-- Similar a lo que se hizo con attendance_events

-- 1. Agregar columnas de auditoría
ALTER TABLE activities
ADD COLUMN IF NOT EXISTS modified_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS modified_at TIMESTAMP WITH TIME ZONE;

-- 2. Crear trigger para actualizar modified_at automáticamente
CREATE OR REPLACE FUNCTION update_activities_modified_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.modified_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Aplicar trigger en UPDATE
DROP TRIGGER IF EXISTS update_activities_modified_at_trigger ON activities;
CREATE TRIGGER update_activities_modified_at_trigger
BEFORE UPDATE ON activities
FOR EACH ROW
EXECUTE FUNCTION update_activities_modified_at();

-- 4. Verificar estructura
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'activities' 
  AND column_name IN ('created_by', 'created_at', 'modified_by', 'modified_at')
ORDER BY ordinal_position;
