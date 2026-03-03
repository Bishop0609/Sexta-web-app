-- =====================================================
-- CORRECCIÓN SOLO PARA JAVIERA MORAGA
-- =====================================================

-- PASO 1: Limpiar pagos existentes de Javiera 2025
DO $$
BEGIN
    RAISE NOTICE 'Eliminando pagos existentes de Javiera 2025...';

    DELETE FROM treasury_payments
    WHERE quota_id IN (
        SELECT q.id
        FROM treasury_monthly_quotas q
        JOIN users u ON q.user_id = u.id
        WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
          AND q.year = 2025
    );

    -- Reiniciar estados de cuotas
    UPDATE treasury_monthly_quotas
    SET paid_amount = 0, status = 'pending'
    WHERE id IN (
        SELECT q.id
        FROM treasury_monthly_quotas q
        JOIN users u ON q.user_id = u.id
        WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
          AND q.year = 2025
    );

    RAISE NOTICE 'Limpieza completada para Javiera.';
END $$;

-- PASO 2: Redistribuir $24.000 desde Enero 2025
DO $$
DECLARE
    v_user_id UUID;
    v_registered_by UUID;
BEGIN
    -- Obtener ID de Javiera
    SELECT id INTO v_user_id
    FROM users
    WHERE full_name = 'Javiera Isidora Moraga Vergara'
    LIMIT 1;

    -- Buscar tesorero
    SELECT id INTO v_registered_by
    FROM users
    WHERE rank IN ('Tesorero(a)', 'Pro-Tesorero(a)', 'Capitán(a)', 'Director(a)')
    LIMIT 1;

    -- Validación
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró a Javiera Isidora Moraga Vergara';
    END IF;
    
    IF v_registered_by IS NULL THEN
        v_registered_by := v_user_id;
    END IF;

    RAISE NOTICE 'Usuario Javiera encontrado: %', v_user_id;
    RAISE NOTICE 'Registrado por: %', v_registered_by;
    RAISE NOTICE 'Distribuyendo $24.000 desde Enero 2025...';

    -- Distribuir el pago
    PERFORM distribute_payment_to_months(
        p_user_id := v_user_id,
        p_total_amount := 24000,
        p_starting_month := 1,
        p_starting_year := 2025,
        p_payment_date := '2025-02-01'::DATE,
        p_payment_method := 'cash',
        p_registered_by := v_registered_by,
        p_receipt_number := NULL,
        p_notes := 'Corrección automática: Pago anual 2025'
    );

    RAISE NOTICE 'Distribución completada para Javiera.';
END $$;

-- PASO 3: Verificar resultados
SELECT 
    'JAVIERA - Resultado Final' as check,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status,
    COUNT(p.id) as num_payments
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
LEFT JOIN treasury_payments p ON q.id = p.quota_id
WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
  AND q.year = 2025
GROUP BY q.month, q.year, q.expected_amount, q.paid_amount, q.status
ORDER BY q.month;
