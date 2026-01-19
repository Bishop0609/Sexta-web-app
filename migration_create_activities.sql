-- ============================================
-- MIGRACIÓN: Calendario de Actividades
-- ============================================
-- Fecha: 2026-01-18
-- Propósito: Crear tabla para gestionar actividades semanales
--            (academias, reuniones, citaciones)
-- ============================================

-- Crear tabla de actividades
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  activity_type VARCHAR(50) CHECK (activity_type IN 
    ('academia_compania', 'academia_cuerpo', 'reunion_ordinaria', 
     'reunion_extraordinaria', 'citacion_compania', 'citacion_cuerpo', 'other')
  ) NOT NULL,
  activity_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  location VARCHAR(255),
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para búsquedas eficientes
CREATE INDEX idx_activities_date ON activities(activity_date);
CREATE INDEX idx_activities_type ON activities(activity_type);
CREATE INDEX idx_activities_created_by ON activities(created_by);

-- RLS Policies
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Todos pueden ver actividades
CREATE POLICY "Todos pueden ver actividades"
ON activities FOR SELECT
TO authenticated
USING (true);

-- Solo admin/officer pueden crear
CREATE POLICY "Solo oficiales pueden crear actividades"
ON activities FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role IN ('officer', 'admin')
  )
);

-- Solo admin/officer pueden actualizar
CREATE POLICY "Solo oficiales pueden actualizar actividades"
ON activities FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role IN ('officer', 'admin')
  )
);

-- Solo admin/officer pueden eliminar
CREATE POLICY "Solo oficiales pueden eliminar actividades"
ON activities FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role IN ('officer', 'admin')
  )
);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_activities_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER activities_updated_at
BEFORE UPDATE ON activities
FOR EACH ROW
EXECUTE FUNCTION update_activities_updated_at();

-- Comentarios
COMMENT ON TABLE activities IS 'Actividades programadas visibles en el calendario semanal';
COMMENT ON COLUMN activities.activity_type IS 'Tipo de actividad: academia (compañía/cuerpo), reunión (ordinaria/extraordinaria), citación (compañía/cuerpo)';
COMMENT ON COLUMN activities.activity_date IS 'Fecha de la actividad';
COMMENT ON COLUMN activities.start_time IS 'Hora de inicio (opcional)';
COMMENT ON COLUMN activities.end_time IS 'Hora de término (opcional)';

-- Datos de ejemplo (opcional, comentar si no se desea)
/*
INSERT INTO activities (title, description, activity_type, activity_date, start_time, end_time, location, created_by)
VALUES 
  ('Academia de Comunicaciones', 'Capacitación en uso de radios', 'academia_compania', '2026-02-15', '19:00', '21:00', 'Cuartel', (SELECT id FROM users WHERE role = 'admin' LIMIT 1)),
  ('Reunión Ordinaria', 'Reunión mensual de compañía', 'reunion_ordinaria', '2026-02-20', '20:00', '22:00', 'Cuartel', (SELECT id FROM users WHERE role = 'admin' LIMIT 1));
*/
