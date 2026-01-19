-- ============================================
-- SISTEMA DE GESTIÓN INTEGRAL SEXTA COMPAÑÍA
-- Esquema de Base de Datos PostgreSQL (Supabase)
-- ============================================

-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. TABLA: users (Bomberos)
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  rut VARCHAR(12) UNIQUE NOT NULL,
  victor_number VARCHAR(10) UNIQUE NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  gender CHAR(1) CHECK (gender IN ('M', 'F')) NOT NULL,
  marital_status VARCHAR(20) CHECK (marital_status IN ('single', 'married')) NOT NULL,
  rank VARCHAR(100) NOT NULL,
  role VARCHAR(20) CHECK (role IN ('admin', 'officer', 'firefighter')) NOT NULL DEFAULT 'firefighter',
  email VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para búsquedas comunes
CREATE INDEX idx_users_gender ON users(gender);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_full_name ON users(full_name);

-- RLS Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden ver todos los perfiles"
ON users FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Solo admin puede insertar usuarios"
ON users FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Admin puede actualizar cualquier usuario"
ON users FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================
-- 2. TABLA: act_types (Tipos de Acto)
-- ============================================
CREATE TABLE act_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) UNIQUE NOT NULL,
  category VARCHAR(20) CHECK (category IN ('efectiva', 'abono')) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice
CREATE INDEX idx_act_types_active ON act_types(is_active);

-- RLS Policies
ALTER TABLE act_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver tipos de acto activos"
ON act_types FOR SELECT
TO authenticated
USING (is_active = TRUE);

CREATE POLICY "Solo admin puede gestionar tipos de acto"
ON act_types FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Datos iniciales
INSERT INTO act_types (name, category) VALUES
  ('Incendio', 'efectiva'),
  ('Rescate', 'efectiva'),
  ('Academia', 'efectiva'),
  ('Capacitación', 'abono'),
  ('Servicio Especial', 'abono'),
  ('Ceremonia', 'abono');

-- ============================================
-- 3. TABLA: permissions (Solicitudes de Permiso)
-- ============================================
CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT NOT NULL,
  status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Índices
CREATE INDEX idx_permissions_user ON permissions(user_id);
CREATE INDEX idx_permissions_status ON permissions(status);
CREATE INDEX idx_permissions_dates ON permissions(start_date, end_date);

-- RLS Policies
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven sus propias solicitudes"
ON permissions FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Oficiales ven todas las solicitudes"
ON permissions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role IN ('officer', 'admin')
  )
);

CREATE POLICY "Usuarios pueden crear solicitudes"
ON permissions FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Oficiales pueden aprobar/rechazar"
ON permissions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role IN ('officer', 'admin')
  )
);

-- ============================================
-- 4. TABLA: attendance_events (Eventos de Asistencia)
-- ============================================
CREATE TABLE attendance_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  act_type_id UUID NOT NULL REFERENCES act_types(id),
  event_date DATE NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_attendance_events_date ON attendance_events(event_date);
CREATE INDEX idx_attendance_events_type ON attendance_events(act_type_id);

-- RLS Policies
ALTER TABLE attendance_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver eventos"
ON attendance_events FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Todos pueden crear eventos"
ON attendance_events FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

CREATE POLICY "Oficiales pueden modificar eventos"
ON attendance_events FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role IN ('officer', 'admin')
  )
);

-- ============================================
-- 5. TABLA: attendance_records (Registros de Asistencia)
-- ============================================
CREATE TABLE attendance_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES attendance_events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) CHECK (status IN ('present', 'absent', 'licencia')) NOT NULL,
  is_locked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

-- Índices
CREATE INDEX idx_attendance_records_event ON attendance_records(event_id);
CREATE INDEX idx_attendance_records_user ON attendance_records(user_id);
CREATE INDEX idx_attendance_records_status ON attendance_records(status);

-- RLS Policies
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver registros"
ON attendance_records FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Todos pueden crear registros"
ON attendance_records FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Oficiales pueden modificar registros"
ON attendance_records FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role IN ('officer', 'admin')
  )
);

-- ============================================
-- 6. TABLA: shift_configurations (Configuración de Guardias)
-- ============================================
CREATE TABLE shift_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  period_name VARCHAR(100) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  registration_start DATE NOT NULL,
  registration_end DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT valid_period CHECK (end_date >= start_date),
  CONSTRAINT valid_registration CHECK (registration_end >= registration_start)
);

-- Índice
CREATE INDEX idx_shift_configs_dates ON shift_configurations(start_date, end_date);

-- RLS Policies
ALTER TABLE shift_configurations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver configuraciones"
ON shift_configurations FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Solo oficiales pueden gestionar configuraciones"
ON shift_configurations FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role IN ('officer', 'admin')
  )
);

-- ============================================
-- 7. TABLA: shift_registrations (Inscripciones a Guardias)
-- ============================================
CREATE TABLE shift_registrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  config_id UUID NOT NULL REFERENCES shift_configurations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shift_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(config_id, user_id, shift_date)
);

-- Índices
CREATE INDEX idx_shift_regs_config ON shift_registrations(config_id);
CREATE INDEX idx_shift_regs_user ON shift_registrations(user_id);
CREATE INDEX idx_shift_regs_date ON shift_registrations(shift_date);

-- RLS Policies
ALTER TABLE shift_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver inscripciones"
ON shift_registrations FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Usuarios pueden inscribirse"
ON shift_registrations FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuarios pueden cancelar su inscripción"
ON shift_registrations FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ============================================
-- 8. TABLA: shift_attendance (Asistencia a Guardias)  
-- ============================================
CREATE TABLE shift_attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shift_date DATE NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  checked_in BOOLEAN DEFAULT FALSE,
  replacement_user_id UUID REFERENCES users(id),
  is_extra BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_shift_attendance_date ON shift_attendance(shift_date);
CREATE INDEX idx_shift_attendance_user ON shift_attendance(user_id);

-- RLS Policies
ALTER TABLE shift_attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver asistencia de guardia"
ON shift_attendance FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Todos pueden registrar asistencia"
ON shift_attendance FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Todos pueden actualizar asistencia"
ON shift_attendance FOR UPDATE
TO authenticated
USING (true);

-- ============================================
-- FUNCIONES Y VISTAS ÚTILES
-- ============================================

-- Función para obtener ranking de asistencia
CREATE OR REPLACE FUNCTION get_attendance_ranking(limit_count INT)
RETURNS TABLE (
  user_id UUID,
  full_name VARCHAR,
  rank VARCHAR,
  attendance_pct NUMERIC,
  total_events INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.full_name,
    u.rank,
    ROUND((COUNT(CASE WHEN ar.status = 'present' THEN 1 END)::NUMERIC / 
           NULLIF(COUNT(*), 0)) * 100, 2) AS attendance_pct,
    COUNT(*)::INT AS total_events
  FROM users u
  JOIN attendance_records ar ON u.id = ar.user_id
  GROUP BY u.id, u.full_name, u.rank
  HAVING COUNT(*) > 0
  ORDER BY attendance_pct DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vista para estadísticas rápidas
CREATE OR REPLACE VIEW attendance_stats AS
SELECT 
  u.id AS user_id,
  u.full_name,
  u.rank,
  COUNT(DISTINCT ae.id) AS total_events,
  COUNT(CASE WHEN ar.status = 'present' AND at.category = 'efectiva' THEN 1 END) AS efectiva_count,
  COUNT(CASE WHEN ar.status = 'present' AND at.category = 'abono' THEN 1 END) AS abono_count,
  COUNT(CASE WHEN ar.status = 'present' THEN 1 END) AS total_present,
  COUNT(CASE WHEN ar.status = 'licencia' THEN 1 END) AS total_licencia
FROM users u
LEFT JOIN attendance_records ar ON u.id = ar.user_id
LEFT JOIN attendance_events ae ON ar.event_id = ae.id
LEFT JOIN act_types at ON ae.act_type_id = at.id
GROUP BY u.id, u.full_name, u.rank;

-- ============================================
-- TRIGGERS para validaciones
-- ============================================

-- Trigger para validar cupo de guardia
CREATE OR REPLACE FUNCTION validate_shift_quota()
RETURNS TRIGGER AS $$
DECLARE
  male_count INT;
  female_count INT;
  user_gender CHAR(1);
BEGIN
  -- Obtener género del usuario
  SELECT gender INTO user_gender
  FROM users
  WHERE id = NEW.user_id;

  -- Contar registros existentes por género para esa fecha
  SELECT COUNT(*) INTO male_count
  FROM shift_registrations sr
  JOIN users u ON sr.user_id = u.id
  WHERE sr.shift_date = NEW.shift_date
    AND u.gender = 'M';

  SELECT COUNT(*) INTO female_count
  FROM shift_registrations sr
  JOIN users u ON sr.user_id = u.id
  WHERE sr.shift_date = NEW.shift_date
    AND u.gender = 'F';

  -- Validar cupos
  IF user_gender = 'M' AND male_count >= 6 THEN
    RAISE EXCEPTION 'Cupo de hombres completo para esta fecha (máx: 6)';
  END IF;

  IF user_gender = 'F' AND female_count >= 4 THEN
    RAISE EXCEPTION 'Cupo de mujeres completo para esta fecha (máx: 4)';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_shift_quota
BEFORE INSERT ON shift_registrations
FOR EACH ROW
EXECUTE FUNCTION validate_shift_quota();

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON TABLE users IS 'Bomberos del sistema con roles de acceso';
COMMENT ON TABLE act_types IS 'Tipos de actos con clasificación Efectiva/Abono';
COMMENT ON TABLE permissions IS 'Solicitudes de permisos (licencias)';
COMMENT ON TABLE attendance_events IS 'Eventos donde se toma asistencia';
COMMENT ON TABLE attendance_records IS 'Registros individuales de asistencia';
COMMENT ON TABLE shift_configurations IS 'Configuración de períodos de guardia';
COMMENT ON TABLE shift_registrations IS 'Inscripciones de bomberos a guardias';
COMMENT ON TABLE shift_attendance IS 'Asistencia real a guardias nocturnas';
