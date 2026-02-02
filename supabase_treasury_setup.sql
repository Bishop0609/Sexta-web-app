-- =====================================================
-- MIGRACIÓN: Sistema de Tesorería
-- Descripción: Agrega soporte para gestión de cuotas mensuales
-- Fecha: 2026-01-24
-- =====================================================

-- =====================================================
-- PASO 1: Agregar columnas a tabla users
-- =====================================================

-- Agregar campo para indicar si el usuario es estudiante (paga cuota reducida)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_student BOOLEAN DEFAULT FALSE;

-- Agregar campo para fecha de inicio de pagos
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS payment_start_date DATE;

-- Comentarios para documentación
COMMENT ON COLUMN users.is_student IS 'Indica si el usuario es estudiante (paga cuota reducida de $2,500 en lugar de $5,000)';
COMMENT ON COLUMN users.payment_start_date IS 'Fecha desde la cual el usuario debe comenzar a pagar cuotas mensuales. NULL significa que no paga cuotas.';

-- =====================================================
-- PASO 2: Crear tabla de cuotas mensuales
-- =====================================================

CREATE TABLE IF NOT EXISTS treasury_monthly_quotas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2025),
  expected_amount INTEGER NOT NULL CHECK (expected_amount > 0),
  paid_amount INTEGER DEFAULT 0 CHECK (paid_amount >= 0),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'partial')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT unique_user_month_year UNIQUE(user_id, month, year)
);

-- Comentarios
COMMENT ON TABLE treasury_monthly_quotas IS 'Registro de cuotas mensuales esperadas para cada usuario';
COMMENT ON COLUMN treasury_monthly_quotas.expected_amount IS 'Monto que el usuario debe pagar ($5,000 estándar, $2,500 para estudiantes/aspirantes/postulantes)';
COMMENT ON COLUMN treasury_monthly_quotas.paid_amount IS 'Monto total pagado para esta cuota';
COMMENT ON COLUMN treasury_monthly_quotas.status IS 'Estado: pending (sin pagar), paid (pagado completo), partial (pago parcial)';

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_treasury_quotas_user ON treasury_monthly_quotas(user_id);
CREATE INDEX IF NOT EXISTS idx_treasury_quotas_period ON treasury_monthly_quotas(year, month);
CREATE INDEX IF NOT EXISTS idx_treasury_quotas_status ON treasury_monthly_quotas(status);
CREATE INDEX IF NOT EXISTS idx_treasury_quotas_user_period ON treasury_monthly_quotas(user_id, year, month);

-- =====================================================
-- PASO 3: Crear tabla de pagos
-- =====================================================

CREATE TABLE IF NOT EXISTS treasury_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quota_id UUID NOT NULL REFERENCES treasury_monthly_quotas(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method VARCHAR(50) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'transfer', 'other')),
  receipt_number VARCHAR(100),
  notes TEXT,
  registered_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Comentarios
COMMENT ON TABLE treasury_payments IS 'Registro de pagos realizados por los usuarios';
COMMENT ON COLUMN treasury_payments.quota_id IS 'Referencia a la cuota mensual que se está pagando';
COMMENT ON COLUMN treasury_payments.payment_method IS 'Método de pago: cash (efectivo), transfer (transferencia), other (otro)';
COMMENT ON COLUMN treasury_payments.registered_by IS 'Usuario (tesorero) que registró el pago';

-- Índices
CREATE INDEX IF NOT EXISTS idx_treasury_payments_quota ON treasury_payments(quota_id);
CREATE INDEX IF NOT EXISTS idx_treasury_payments_user ON treasury_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_treasury_payments_date ON treasury_payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_treasury_payments_registered_by ON treasury_payments(registered_by);

-- =====================================================
-- PASO 4: Crear función para actualizar updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar updated_at automáticamente
DROP TRIGGER IF EXISTS update_treasury_quotas_updated_at ON treasury_monthly_quotas;
CREATE TRIGGER update_treasury_quotas_updated_at
    BEFORE UPDATE ON treasury_monthly_quotas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_treasury_payments_updated_at ON treasury_payments;
CREATE TRIGGER update_treasury_payments_updated_at
    BEFORE UPDATE ON treasury_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PASO 5: Crear función para actualizar estado de cuota
-- =====================================================

CREATE OR REPLACE FUNCTION update_quota_status()
RETURNS TRIGGER AS $$
DECLARE
    quota_record RECORD;
    total_paid INTEGER;
BEGIN
    -- Obtener la cuota relacionada
    SELECT * INTO quota_record 
    FROM treasury_monthly_quotas 
    WHERE id = NEW.quota_id;
    
    -- Calcular total pagado para esta cuota
    SELECT COALESCE(SUM(amount), 0) INTO total_paid
    FROM treasury_payments
    WHERE quota_id = NEW.quota_id;
    
    -- Actualizar paid_amount y status
    UPDATE treasury_monthly_quotas
    SET 
        paid_amount = total_paid,
        status = CASE
            WHEN total_paid = 0 THEN 'pending'
            WHEN total_paid >= expected_amount THEN 'paid'
            ELSE 'partial'
        END
    WHERE id = NEW.quota_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar estado de cuota cuando se registra un pago
DROP TRIGGER IF EXISTS update_quota_on_payment ON treasury_payments;
CREATE TRIGGER update_quota_on_payment
    AFTER INSERT OR UPDATE ON treasury_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_quota_status();

-- =====================================================
-- PASO 6: Función para calcular monto de cuota esperado
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
    expected_quota INTEGER;
BEGIN
    -- Obtener información del usuario
    SELECT rank, is_student INTO user_rank, user_is_student
    FROM users
    WHERE id = p_user_id;
    
    -- Calcular cuota según reglas:
    -- - Aspirantes y Postulantes: $2,500
    -- - Estudiantes: $2,500
    -- - Resto: $5,000
    IF user_rank IN ('Aspirante', 'Postulante') OR user_is_student THEN
        expected_quota := 2500;
    ELSE
        expected_quota := 5000;
    END IF;
    
    RETURN expected_quota;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PASO 7: Función para generar cuotas de un mes
-- =====================================================

CREATE OR REPLACE FUNCTION generate_monthly_quotas(
    p_month INTEGER,
    p_year INTEGER
)
RETURNS TABLE(
    user_id UUID,
    user_name VARCHAR,
    quota_amount INTEGER,
    status VARCHAR
) AS $$
DECLARE
    user_record RECORD;
    quota_amount INTEGER;
    quota_exists BOOLEAN;
BEGIN
    -- Iterar sobre todos los usuarios activos
    FOR user_record IN 
        SELECT id, full_name, payment_start_date
        FROM users
        WHERE payment_start_date IS NOT NULL
          AND payment_start_date <= make_date(p_year, p_month, 1)
    LOOP
        -- Calcular cuota esperada
        quota_amount := calculate_expected_quota(user_record.id, p_month, p_year);
        
        -- Verificar si ya existe la cuota
        SELECT EXISTS(
            SELECT 1 FROM treasury_monthly_quotas
            WHERE treasury_monthly_quotas.user_id = user_record.id
              AND month = p_month
              AND year = p_year
        ) INTO quota_exists;
        
        -- Si no existe, crear la cuota
        IF NOT quota_exists THEN
            INSERT INTO treasury_monthly_quotas (user_id, month, year, expected_amount)
            VALUES (user_record.id, p_month, p_year, quota_amount);
            
            -- Retornar información
            user_id := user_record.id;
            user_name := user_record.full_name;
            status := 'created';
            RETURN NEXT;
        ELSE
            -- Ya existe
            user_id := user_record.id;
            user_name := user_record.full_name;
            status := 'exists';
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PASO 8: Función para calcular deuda de un usuario
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_user_debt(p_user_id UUID)
RETURNS TABLE(
    months_owed INTEGER,
    total_amount INTEGER,
    pending_quotas JSONB
) AS $$
DECLARE
    current_month INTEGER;
    current_year INTEGER;
    user_start_date DATE;
BEGIN
    -- Obtener mes y año actual
    current_month := EXTRACT(MONTH FROM CURRENT_DATE);
    current_year := EXTRACT(YEAR FROM CURRENT_DATE);
    
    -- Obtener fecha de inicio de pagos del usuario
    SELECT payment_start_date INTO user_start_date
    FROM users
    WHERE id = p_user_id;
    
    -- Si no tiene fecha de inicio, no debe cuotas
    IF user_start_date IS NULL THEN
        months_owed := 0;
        total_amount := 0;
        pending_quotas := '[]'::JSONB;
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Calcular deudas (cuotas pendientes hasta el mes ANTERIOR al actual)
    SELECT 
        COUNT(*)::INTEGER,
        COALESCE(SUM(expected_amount - paid_amount), 0)::INTEGER,
        COALESCE(
            JSONB_AGG(
                JSONB_BUILD_OBJECT(
                    'month', month,
                    'year', year,
                    'expected', expected_amount,
                    'paid', paid_amount,
                    'owed', expected_amount - paid_amount
                )
            ),
            '[]'::JSONB
        )
    INTO months_owed, total_amount, pending_quotas
    FROM treasury_monthly_quotas
    WHERE user_id = p_user_id
      AND status != 'paid'
      AND (
          year < current_year 
          OR (year = current_year AND month < current_month)
      );
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

-- Verificar que las tablas se crearon correctamente
DO $$
BEGIN
    RAISE NOTICE 'Verificando tablas...';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'treasury_monthly_quotas') THEN
        RAISE NOTICE '✓ Tabla treasury_monthly_quotas creada';
    ELSE
        RAISE EXCEPTION '✗ Error: Tabla treasury_monthly_quotas no existe';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'treasury_payments') THEN
        RAISE NOTICE '✓ Tabla treasury_payments creada';
    ELSE
        RAISE EXCEPTION '✗ Error: Tabla treasury_payments no existe';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_student') THEN
        RAISE NOTICE '✓ Columna users.is_student agregada';
    ELSE
        RAISE EXCEPTION '✗ Error: Columna users.is_student no existe';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'payment_start_date') THEN
        RAISE NOTICE '✓ Columna users.payment_start_date agregada';
    ELSE
        RAISE EXCEPTION '✗ Error: Columna users.payment_start_date no existe';
    END IF;
    
    RAISE NOTICE 'Migración completada exitosamente!';
END $$;

-- =====================================================
-- EJEMPLO DE USO
-- =====================================================

-- Generar cuotas para enero 2026
-- SELECT * FROM generate_monthly_quotas(1, 2026);

-- Calcular deuda de un usuario específico
-- SELECT * FROM calculate_user_debt('user-uuid-here');
