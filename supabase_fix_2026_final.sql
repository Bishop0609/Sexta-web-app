-- =====================================================
-- CORRECCIÓN FINAL 2026 
-- Ajustada con valores reales: Estudiantes 2026 = $2.500
-- =====================================================

-- 1. CORRECCIÓN NICOLE: Mover pagos a Enero-Febrero 2026
DO $$
DECLARE
    v_user_id UUID;
    v_registered_by UUID;
BEGIN
    SELECT id INTO v_user_id FROM users WHERE full_name = 'Nicole Alejandra Castellón Villanueva';
    
    -- Borrar todos los pagos/cuotas de Nicole 2026 para reiniciar limpio
    DELETE FROM treasury_payments 
    WHERE quota_id IN (SELECT id FROM treasury_monthly_quotas WHERE user_id = v_user_id AND year = 2026);
    
    DELETE FROM treasury_monthly_quotas 
    WHERE user_id = v_user_id AND year = 2026;

    -- Buscar Tesorero
    SELECT id INTO v_registered_by FROM users WHERE rank IN ('Tesorero(a)', 'Pro-Tesorero(a)', 'Capitán(a)') LIMIT 1;
    IF v_registered_by IS NULL THEN v_registered_by := v_user_id; END IF;

    RAISE NOTICE 'Corrigiendo Nicole: Distribuyendo $10.000 desde Enero 2026...';

    -- Insertar ENERO y FEBRERO (distribuir $10.000 comenzando en mes 1)
    -- Al ser cuota estándar ($5.000), cubrirá exactamente 2 meses.
    PERFORM distribute_payment_to_months(
        p_user_id := v_user_id,
        p_total_amount := 10000,
        p_starting_month := 1,      -- Enero
        p_starting_year := 2026,
        p_payment_date := '2026-02-01'::DATE,
        p_payment_method := 'cash',
        p_registered_by := v_registered_by,
        p_receipt_number := NULL,
        p_notes := 'Corrección: Pago Ene-Feb 2026'
    );
END $$;


-- 2. CORRECCIÓN JAVIERA: Generar cuotas 2026 a valor estudiante ($2.500)
DO $$
DECLARE
    v_user_id UUID;
    v_quota_id UUID;
    v_month INTEGER;
BEGIN
    SELECT id INTO v_user_id FROM users WHERE full_name = 'Javiera Isidora Moraga Vergara';

    RAISE NOTICE 'Corrigiendo Javiera: Asegurando cuotas Ene-Feb 2026 a $2.500...';

    -- Asegurar que existan cuotas de Enero(1) y Febrero(2) para 2026 con valor $2.500
    FOR v_month IN 1..2 LOOP
        
        -- Verificar si existe
        SELECT id INTO v_quota_id 
        FROM treasury_monthly_quotas 
        WHERE user_id = v_user_id AND month = v_month AND year = 2026;

        IF v_quota_id IS NOT NULL THEN
            -- Si existe, actualizar valor a $2.500 (Reduced Quota 2026)
            UPDATE treasury_monthly_quotas
            SET expected_amount = 2500
            WHERE id = v_quota_id AND status != 'paid'; -- Solo actualizar si no está pagada (por seguridad)
        ELSE
            -- Si no existe, crearla pendiente por $2.500
            INSERT INTO treasury_monthly_quotas (user_id, month, year, expected_amount, status, paid_amount)
            VALUES (v_user_id, v_month, 2026, 2500, 'pending', 0);
        END IF;

    END LOOP;
END $$;

-- 3. VERIFICACIÓN FINAL
SELECT 
    u.full_name,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status
FROM treasury_monthly_quotas q
JOIN users u ON q.user_id = u.id
WHERE (u.full_name = 'Nicole Alejandra Castellón Villanueva' OR u.full_name = 'Javiera Isidora Moraga Vergara')
  AND q.year = 2026
ORDER BY u.full_name, q.month;
