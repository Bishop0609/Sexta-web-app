-- =====================================================
-- FUNCIÓN: Promover a Bombero
-- =====================================================
-- 1. Cambia el cargo a 'Bombero'
-- 2. Quita el estado de estudiante (is_student = false)
-- 3. Recalcula las cuotas FUTURAS (desde la fecha dada)
--    usando la cuota estándar ($4.000 / $5.000)
-- =====================================================

CREATE OR REPLACE FUNCTION promote_to_firefighter(
    p_user_id UUID,
    p_promotion_date DATE
)
RETURNS JSONB AS $$
DECLARE
    affected_quotas INTEGER;
    standard_quota INTEGER;
    promo_year INTEGER;
    promo_month INTEGER;
BEGIN
    -- 1. Actualizar usuario
    UPDATE users 
    SET rank = 'Bombero',
        is_student = FALSE,
        updated_at = NOW()
    WHERE id = p_user_id;

    -- 2. Obtener cuota estándar para el año de promoción
    promo_year := EXTRACT(YEAR FROM p_promotion_date);
    promo_month := EXTRACT(MONTH FROM p_promotion_date);
    
    -- Buscar configuración del año
    SELECT standard_quota INTO standard_quota
    FROM treasury_quota_config
    WHERE year = promo_year;
    
    -- Si no existe config, usar valor por defecto (seguro)
    IF standard_quota IS NULL THEN
        standard_quota := 5000; -- Valor por defecto si no hay config
    END IF;

    -- 3. Actualizar cuotas futuras (PENDIENTES O PARCIALES)
    --    No tocamos las pagadas para mantener historial
    WITH updated_rows AS (
        UPDATE treasury_monthly_quotas
        SET expected_amount = standard_quota,
            updated_at = NOW()
        WHERE user_id = p_user_id
          AND status != 'paid' -- Solo pendientes o parciales
          AND (
              year > promo_year 
              OR (year = promo_year AND month >= promo_month)
          )
        RETURNING id
    )
    SELECT COUNT(*) INTO affected_quotas FROM updated_rows;

    -- 4. Retornar resultado
    RETURN JSONB_BUILD_OBJECT(
        'success', true,
        'standard_quota', standard_quota,
        'quotas_updated', affected_quotas
    );

EXCEPTION WHEN OTHERS THEN
    RETURN JSONB_BUILD_OBJECT(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql;
