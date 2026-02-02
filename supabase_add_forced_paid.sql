-- =====================================================
-- MIGRACIÓN: Soporte para Pagos Parciales Autorizados
-- Descripción: Agrega flag forced_paid y actualiza trigger
-- Fecha: 2026-01-25
-- =====================================================

-- 1. Agregar columna forced_paid a la tabla de cuotas
ALTER TABLE treasury_monthly_quotas
ADD COLUMN IF NOT EXISTS forced_paid BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN treasury_monthly_quotas.forced_paid IS 'Indica si la cuota fue marcada manualmente como pagada (autorizada) aunque el monto no cubra el total';

-- 2. Actualizar función del trigger para respetar forced_paid
CREATE OR REPLACE FUNCTION update_quota_status()
RETURNS TRIGGER AS $$
DECLARE
    quota_record RECORD;
    total_paid INTEGER;
    is_forced BOOLEAN;
BEGIN
    -- Obtener la cuota relacionada y su estado forced_paid
    SELECT * INTO quota_record 
    FROM treasury_monthly_quotas 
    WHERE id = NEW.quota_id;
    
    -- Calcular total pagado para esta cuota
    SELECT COALESCE(SUM(amount), 0) INTO total_paid
    FROM treasury_payments
    WHERE quota_id = NEW.quota_id;
    
    -- Actualizar paid_amount y status
    -- Si forced_paid es TRUE, siempre es 'paid'
    UPDATE treasury_monthly_quotas
    SET 
        paid_amount = total_paid,
        status = CASE
            WHEN forced_paid = TRUE THEN 'paid'  -- Prioridad al flag manual
            WHEN total_paid = 0 THEN 'pending'
            WHEN total_paid >= expected_amount THEN 'paid'
            ELSE 'partial'
        END,
        updated_at = NOW()
    WHERE id = NEW.quota_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear función RPC para marcar cuota como forzada desde la app
CREATE OR REPLACE FUNCTION mark_quota_as_forced_paid(p_quota_id UUID, p_forced BOOLEAN)
RETURNS VOID AS $$
BEGIN
    UPDATE treasury_monthly_quotas
    SET 
        forced_paid = p_forced,
        -- Forzar actualización de status inmediatamente
        status = CASE 
            WHEN p_forced = TRUE THEN 'paid'
            ELSE status -- Si se desmarca, el trigger recalculará correctamente en el próximo pago, 
                        -- pero por seguridad podríamos recalcular aquí.
                        -- Por simplicidad, dejaremos que el trigger maneje updates futuros o recálculo manual.
        END,
        updated_at = NOW()
    WHERE id = p_quota_id;
    
    -- Si se desmarca (FALSE), necesitamos recalcular el estado real basado en pagos
    IF p_forced = FALSE THEN
        -- Truco: Disparar el trigger update_quota_status simulando un update
        -- O llamar lógica de cálculo. Más simple: Update dummy para disparar trigger si existiera en la tabla quotas.
        -- Pero el trigger está en la tabla PAYMENTS.
        -- Así que recalculamos manual:
        UPDATE treasury_monthly_quotas q
        SET status = CASE
            WHEN (SELECT COALESCE(SUM(amount), 0) FROM treasury_payments WHERE quota_id = q.id) >= q.expected_amount THEN 'paid'
            WHEN (SELECT COALESCE(SUM(amount), 0) FROM treasury_payments WHERE quota_id = q.id) > 0 THEN 'partial'
            ELSE 'pending'
        END
        WHERE id = p_quota_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================
/*
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'treasury_monthly_quotas' AND column_name = 'forced_paid';
*/
