-- =====================================================
-- FUNCIÓN: Distribución Automática de Pagos
-- Descripción: Distribuye un pago a múltiples meses consecutivos
-- Fecha: 2026-02-07
-- =====================================================

CREATE OR REPLACE FUNCTION distribute_payment_to_months(
    p_user_id UUID,
    p_total_amount INTEGER,
    p_starting_month INTEGER,
    p_starting_year INTEGER,
    p_payment_date DATE,
    p_payment_method VARCHAR,
    p_registered_by UUID,
    p_receipt_number VARCHAR DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE(
    quota_id UUID,
    month INTEGER,
    year INTEGER,
    amount_applied INTEGER,
    status VARCHAR,
    was_created BOOLEAN
) AS $$
DECLARE
    remaining_amount INTEGER;
    current_month INTEGER;
    current_year INTEGER;
    quota_amount INTEGER;
    quota_record RECORD;
    quota_exists BOOLEAN;
    payment_id UUID;
BEGIN
    remaining_amount := p_total_amount;
    current_month := p_starting_month;
    current_year := p_starting_year;
    
    -- Iterar mientras haya dinero restante
    WHILE remaining_amount > 0 LOOP
        -- Calcular cuota esperada para este mes
        quota_amount := calculate_expected_quota(p_user_id, current_month, current_year);
        
        -- Verificar si existe la cuota para este mes
        SELECT EXISTS(
            SELECT 1 FROM treasury_monthly_quotas tmq
            WHERE tmq.user_id = p_user_id
              AND tmq.month = current_month
              AND tmq.year = current_year
        ) INTO quota_exists;
        
        -- Si no existe, crearla
        IF NOT quota_exists THEN
            INSERT INTO treasury_monthly_quotas (user_id, month, year, expected_amount)
            VALUES (p_user_id, current_month, current_year, quota_amount)
            RETURNING id INTO quota_record;
            
            quota_id := quota_record.id;
            was_created := TRUE;
        ELSE
            -- Obtener la cuota existente
            SELECT tmq.id INTO quota_record
            FROM treasury_monthly_quotas tmq
            WHERE tmq.user_id = p_user_id
              AND tmq.month = current_month
              AND tmq.year = current_year;
            
            quota_id := quota_record.id;
            was_created := FALSE;
        END IF;
        
        -- Determinar cuánto aplicar a esta cuota
        -- (el mínimo entre lo que queda y lo que se necesita)
        IF remaining_amount >= quota_amount THEN
            amount_applied := quota_amount;
        ELSE
            amount_applied := remaining_amount;
        END IF;
        
        -- Registrar el pago para esta cuota
        INSERT INTO treasury_payments (
            quota_id,
            user_id,
            amount,
            payment_date,
            payment_method,
            receipt_number,
            notes,
            registered_by
        ) VALUES (
            quota_id,
            p_user_id,
            amount_applied,
            p_payment_date,
            p_payment_method,
            p_receipt_number,
            CASE 
                WHEN p_notes IS NOT NULL THEN p_notes || ' (Distribución automática)'
                ELSE 'Distribución automática de pago'
            END,
            p_registered_by
        );
        
        -- Restar el monto aplicado
        remaining_amount := remaining_amount - amount_applied;
        
        -- Retornar información de esta cuota
        month := current_month;
        year := current_year;
        status := CASE
            WHEN amount_applied >= quota_amount THEN 'paid'
            ELSE 'partial'
        END;
        RETURN NEXT;
        
        -- Avanzar al siguiente mes
        IF current_month = 12 THEN
            current_month := 1;
            current_year := current_year + 1;
        ELSE
            current_month := current_month + 1;
        END IF;
        
        -- Límite de seguridad: no más de 24 meses
        IF (current_year - p_starting_year) * 12 + (current_month - p_starting_month) > 24 THEN
            RAISE EXCEPTION 'El pago excede el límite de 24 meses. Verifique el monto ingresado.';
        END IF;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Comentarios
COMMENT ON FUNCTION distribute_payment_to_months IS 'Distribuye un pago a múltiples meses consecutivos, creando cuotas si no existen';

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Función distribute_payment_to_months creada exitosamente';
END $$;
