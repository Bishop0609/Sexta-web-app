-- =====================================================
-- CORRECCIÓN DEFINITIVA: Limpiar y Redistribuir Pagos
-- Descripción: Borra todo rastro de pagos 2025 para Javiera y 2026 para Nicole
--              e inserta los pagos distribuidos correctamente.
-- =====================================================

-- INSTRUCCIONES:
-- Ejecuta este script TODO DE UNA VEZ

-- =====================================================
-- PASO 1: BORRAR PAGOS Y CUOTAS INCORRECTAS/DUPLICADAS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Eliminando pagos existentes para Javiera (2025) y Nicole (2026)...';

    -- 1.1 Eliminar pagos de Javiera 2025
    DELETE FROM treasury_payments
    WHERE quota_id IN (
        SELECT q.id
        FROM treasury_monthly_quotas q
        JOIN users u ON q.user_id = u.id
        WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
          AND q.year = 2025
    );

    -- 1.2 Eliminar pagos de Nicole 2026
    DELETE FROM treasury_payments
    WHERE quota_id IN (
        SELECT q.id
        FROM treasury_monthly_quotas q
        JOIN users u ON q.user_id = u.id
        WHERE u.full_name = 'Nicole Alejandra Castellón Villanueva'
          AND q.year = 2026
    );

    -- 1.3 Reiniciar estados de cuotas a 'pending' y paid_amount a 0
    UPDATE treasury_monthly_quotas
    SET paid_amount = 0, status = 'pending'
    WHERE id IN (
        SELECT q.id
        FROM treasury_monthly_quotas q
        JOIN users u ON q.user_id = u.id
        WHERE (u.full_name = 'Javiera Isidora Moraga Vergara' AND q.year = 2025)
           OR (u.full_name = 'Nicole Alejandra Castellón Villanueva' AND q.year = 2026)
    );

    RAISE NOTICE 'Limpieza completada.';
END $$;

-- =====================================================
-- PASO 2: REDISTRIBUIR JAVIERA MORAGA ($24.000 / 12 meses)
-- =====================================================

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

    -- Buscar quién registrará
    SELECT id INTO v_registered_by
    FROM users
    WHERE rank IN ('Tesorero(a)', 'Pro-Tesorero(a)', 'Capitán(a)', 'Director(a)')
    LIMIT 1;

    -- Validación
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró el usuario Javiera Moraga';
    END IF;
    IF v_registered_by IS NULL THEN
         v_registered_by := v_user_id;
    END IF;

    RAISE NOTICE 'Insertando distribución para Javiera Moraga...';

    -- Distribuir $24.000 comenzando en ENERO 2025
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

    RAISE NOTICE 'Distribución completada para Javiera Moraga.';
END $$;

-- =====================================================
-- PASO 3: REDISTRIBUIR NICOLE CASTELLON ($10.000 / 2 meses)
-- =====================================================

DO $$
DECLARE
    v_user_id UUID;
    v_registered_by UUID;
BEGIN
    -- Obtener ID de Nicole
    SELECT id INTO v_user_id
    FROM users
    WHERE full_name = 'Nicole Alejandra Castellón Villanueva'
    LIMIT 1;

    -- Si no se encuentra Nicole, saltar este paso
    IF v_user_id IS NULL THEN
        RAISE NOTICE 'No se encontró a Nicole Castellon - saltando corrección';
        RETURN;
    END IF;

    SELECT id INTO v_registered_by
    FROM users
    WHERE rank IN ('Tesorero(a)', 'Pro-Tesorero(a)', 'Capitán(a)', 'Director(a)')
    LIMIT 1;

    IF v_registered_by IS NULL THEN
         v_registered_by := v_user_id;
    END IF;

    RAISE NOTICE 'Insertando distribución para Nicole Castellon...';

    -- Distribuir $10.000 comenzando en FEBRERO 2026
    PERFORM distribute_payment_to_months(
        p_user_id := v_user_id,
        p_total_amount := 10000,
        p_starting_month := 2,
        p_starting_year := 2026,
        p_payment_date := '2026-02-01'::DATE,
        p_payment_method := 'cash',
        p_registered_by := v_registered_by,
        p_receipt_number := NULL,
        p_notes := 'Corrección automática: Pago Feb-Mar 2026'
    );

    RAISE NOTICE 'Distribución completada para Nicole Castellon.';
END $$;

-- =====================================================
-- PASO 4: VERIFICACIÓN FINAL
-- =====================================================

-- Mostrar Javiera
SELECT 
    'JAVIERA FINAL' as check,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
  AND q.year = 2025
ORDER BY q.month;

-- Mostrar Nicole
SELECT 
    'NICOLE FINAL' as check,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
WHERE u.full_name = 'Nicole Alejandra Castellón Villanueva'
  AND q.year = 2026
ORDER BY q.month;

