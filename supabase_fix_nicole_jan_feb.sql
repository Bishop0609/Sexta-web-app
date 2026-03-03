-- =====================================================
-- CORRECCIÓN NICOLE: Mover pagos a Enero-Febrero 2026
-- =====================================================

DO $$
DECLARE
    v_user_id UUID;
    v_registered_by UUID;
BEGIN
    -- 1. Obtener ID de Nicole
    SELECT id INTO v_user_id
    FROM users
    WHERE full_name = 'Nicole Alejandra Castellón Villanueva'
    LIMIT 1;

    -- Validar
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró a Nicole Alejandra Castellón Villanueva';
    END IF;

    -- Buscar un registrador (Tesorero o el mismo usuario)
    SELECT id INTO v_registered_by
    FROM users
    WHERE rank IN ('Tesorero(a)', 'Pro-Tesorero(a)', 'Capitán(a)', 'Director(a)')
    LIMIT 1;
    
    IF v_registered_by IS NULL THEN
        v_registered_by := v_user_id;
    END IF;

    RAISE NOTICE 'Corrigiendo pagos para Nicole Castellón...';

    -- 2. LIMPIEZA: Eliminar pagos existentes de Nicole en 2026
    DELETE FROM treasury_payments
    WHERE quota_id IN (
        SELECT q.id
        FROM treasury_monthly_quotas q
        WHERE q.user_id = v_user_id
          AND q.year = 2026
    );

    -- Reiniciar cuotas de 2026 a 'pending'
    UPDATE treasury_monthly_quotas
    SET paid_amount = 0, status = 'pending'
    WHERE user_id = v_user_id
      AND year = 2026;

    RAISE NOTICE 'Pagos anteriores eliminados.';

    -- 3. REDISTRIBUCIÓN: $10.000 desde ENERO 2026
    -- Esto cubrirá Enero y Febrero (5.000 + 5.000)
    PERFORM distribute_payment_to_months(
        p_user_id := v_user_id,
        p_total_amount := 10000,
        p_starting_month := 1,      -- <--- CAMBIO AQUÍ: Empieza en Enero
        p_starting_year := 2026,
        p_payment_date := '2026-02-01'::DATE,
        p_payment_method := 'cash',
        p_registered_by := v_registered_by,
        p_receipt_number := NULL,
        p_notes := 'Corrección: Pago Enero-Febrero 2026'
    );

    RAISE NOTICE 'Nueva distribución completada (Ene-Feb 2026).';
END $$;

-- 4. VERIFICACIÓN FINAL
SELECT 
    'NICOLE FINAL (CORREGIDO)' as check,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status
FROM treasury_monthly_quotas q
JOIN users u ON q.user_id = u.id
WHERE u.full_name = 'Nicole Alejandra Castellón Villanueva'
  AND q.year = 2026
ORDER BY q.month;
