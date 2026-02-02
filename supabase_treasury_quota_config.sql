-- =====================================================
-- ACTUALIZACIÓN: Sistema de Configuración de Cuotas
-- Descripción: Agrega soporte para cuotas variables por año
-- Fecha: 2026-01-24
-- =====================================================

-- =====================================================
-- PASO 1: Crear tabla de configuración de cuotas
-- =====================================================

CREATE TABLE IF NOT EXISTS treasury_quota_config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  year INTEGER NOT NULL UNIQUE CHECK (year >= 2025),
  standard_quota INTEGER NOT NULL CHECK (standard_quota > 0),
  reduced_quota INTEGER NOT NULL CHECK (reduced_quota > 0),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE treasury_quota_config IS 'Configuración de montos de cuotas por año';
COMMENT ON COLUMN treasury_quota_config.standard_quota IS 'Cuota mensual para bomberos normales';
COMMENT ON COLUMN treasury_quota_config.reduced_quota IS 'Cuota mensual para aspirantes, postulantes y estudiantes';

-- Índice
CREATE INDEX IF NOT EXISTS idx_treasury_quota_config_year ON treasury_quota_config(year);

-- Trigger para updated_at
DROP TRIGGER IF EXISTS update_treasury_quota_config_updated_at ON treasury_quota_config;
CREATE TRIGGER update_treasury_quota_config_updated_at
    BEFORE UPDATE ON treasury_quota_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PASO 2: Insertar configuraciones históricas
-- =====================================================

INSERT INTO treasury_quota_config (year, standard_quota, reduced_quota) VALUES
  (2025, 4000, 2000),
  (2026, 5000, 2500)
ON CONFLICT (year) DO UPDATE SET
  standard_quota = EXCLUDED.standard_quota,
  reduced_quota = EXCLUDED.reduced_quota;

-- =====================================================
-- PASO 3: Actualizar función de cálculo de cuota
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_expected_quota(
    p_user_id UUID,
    p_month INTEGER,
    p_year INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    user_rank VARCHAR(50);
    user_is_student BOOLEAN;
    standard_amount INTEGER;
    reduced_amount INTEGER;
    expected_quota INTEGER;
BEGIN
    -- Obtener información del usuario
    SELECT rank, is_student INTO user_rank, user_is_student
    FROM users
    WHERE id = p_user_id;
    
    -- Obtener configuración del año específico
    SELECT standard_quota, reduced_quota INTO standard_amount, reduced_amount
    FROM treasury_quota_config
    WHERE year = p_year;
    
    -- Si no existe configuración para ese año, usar la más reciente
    IF NOT FOUND THEN
        SELECT standard_quota, reduced_quota INTO standard_amount, reduced_amount
        FROM treasury_quota_config
        ORDER BY year DESC
        LIMIT 1;
    END IF;
    
    -- Si aún no hay configuración, usar valores por defecto
    IF standard_amount IS NULL THEN
        standard_amount := 5000;
        reduced_amount := 2500;
    END IF;
    
    -- Calcular cuota según reglas:
    -- - Aspirantes y Postulantes: cuota reducida
    -- - Estudiantes: cuota reducida
    -- - Resto: cuota estándar
    IF user_rank IN ('Aspirante', 'Postulante') OR user_is_student THEN
        expected_quota := reduced_amount;
    ELSE
        expected_quota := standard_amount;
    END IF;
    
    RETURN expected_quota;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PASO 4: Función para obtener configuración de un año
-- =====================================================

CREATE OR REPLACE FUNCTION get_quota_config(p_year INTEGER)
RETURNS TABLE(
    year INTEGER,
    standard_quota INTEGER,
    reduced_quota INTEGER
) AS $$
BEGIN
    -- Intentar obtener configuración del año solicitado
    RETURN QUERY
    SELECT qc.year, qc.standard_quota, qc.reduced_quota
    FROM treasury_quota_config qc
    WHERE qc.year = p_year;
    
    -- Si no existe, retornar la más reciente
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT qc.year, qc.standard_quota, qc.reduced_quota
        FROM treasury_quota_config qc
        ORDER BY qc.year DESC
        LIMIT 1;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PASO 5: Función para crear/actualizar configuración
-- =====================================================

CREATE OR REPLACE FUNCTION upsert_quota_config(
    p_year INTEGER,
    p_standard_quota INTEGER,
    p_reduced_quota INTEGER
)
RETURNS TABLE(
    id UUID,
    year INTEGER,
    standard_quota INTEGER,
    reduced_quota INTEGER
) AS $$
BEGIN
    RETURN QUERY
    INSERT INTO treasury_quota_config (year, standard_quota, reduced_quota)
    VALUES (p_year, p_standard_quota, p_reduced_quota)
    ON CONFLICT (year) DO UPDATE SET
        standard_quota = EXCLUDED.standard_quota,
        reduced_quota = EXCLUDED.reduced_quota,
        updated_at = NOW()
    RETURNING treasury_quota_config.id, treasury_quota_config.year, 
              treasury_quota_config.standard_quota, treasury_quota_config.reduced_quota;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando tabla treasury_quota_config...';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'treasury_quota_config') THEN
        RAISE NOTICE '✓ Tabla treasury_quota_config creada';
    ELSE
        RAISE EXCEPTION '✗ Error: Tabla treasury_quota_config no existe';
    END IF;
    
    -- Verificar datos iniciales
    IF EXISTS (SELECT 1 FROM treasury_quota_config WHERE year = 2025) THEN
        RAISE NOTICE '✓ Configuración 2025 insertada';
    END IF;
    
    IF EXISTS (SELECT 1 FROM treasury_quota_config WHERE year = 2026) THEN
        RAISE NOTICE '✓ Configuración 2026 insertada';
    END IF;
    
    RAISE NOTICE 'Actualización completada exitosamente!';
END $$;

-- =====================================================
-- EJEMPLO DE USO
-- =====================================================

-- Ver configuración actual
-- SELECT * FROM treasury_quota_config ORDER BY year;

-- Obtener configuración de un año específico
-- SELECT * FROM get_quota_config(2026);

-- Actualizar o crear configuración para 2027
-- SELECT * FROM upsert_quota_config(2027, 5500, 2750);
