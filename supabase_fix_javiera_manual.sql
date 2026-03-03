-- =====================================================
-- CORRECCIÓN FORZADA: Javiera con $2.000/mes (12 meses)
-- =====================================================

-- PASO 1: Eliminar TODOS los pagos de Javiera 2025
DO $$
BEGIN
    RAISE NOTICE 'Eliminando todos los pagos de Javiera 2025...';
    
    DELETE FROM treasury_payments
    WHERE quota_id IN (
        SELECT q.id
        FROM treasury_monthly_quotas q
        JOIN users u ON q.user_id = u.id
        WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
          AND q.year = 2025
    );
    
    RAISE NOTICE 'Pagos eliminados.';
END $$;

-- PASO 2: Insertar pagos manualmente mes por mes con $2.000
DO $$
DECLARE
    v_user_id UUID;
    v_registered_by UUID;
    v_quota_id UUID;
    v_month INTEGER;
BEGIN
    -- Obtener IDs
    SELECT id INTO v_user_id
    FROM users
    WHERE full_name = 'Javiera Isidora Moraga Vergara';
    
    SELECT id INTO v_registered_by
    FROM users
    WHERE rank IN ('Tesorero(a)', 'Pro-Tesorero(a)', 'Capitán(a)')
    LIMIT 1;
    
    IF v_registered_by IS NULL THEN
        v_registered_by := v_user_id;
    END IF;
    
    RAISE NOTICE 'Insertando 12 pagos de $2.000 para Javiera...';
    
    -- Insertar un pago de $2.000 para cada mes de 2025
    FOR v_month IN 1..12 LOOP
        -- Obtener o crear la cuota para este mes
        SELECT id INTO v_quota_id
        FROM treasury_monthly_quotas
        WHERE user_id = v_user_id
          AND month = v_month
          AND year = 2025;
        
        -- Si no existe la cuota, crearla
        IF v_quota_id IS NULL THEN
            INSERT INTO treasury_monthly_quotas (user_id, month, year, expected_amount)
            VALUES (v_user_id, v_month, 2025, 2000)
            RETURNING id INTO v_quota_id;
            
            RAISE NOTICE 'Cuota creada para mes %', v_month;
        ELSE
            -- Actualizar expected_amount a 2000 si es diferente
            UPDATE treasury_monthly_quotas
            SET expected_amount = 2000
            WHERE id = v_quota_id;
        END IF;
        
        -- Insertar el pago de $2.000
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
            v_quota_id,
            v_user_id,
            2000,
            '2025-02-01'::DATE,
            'cash',
            NULL,
            'Pago anual 2025 - Corrección manual',
            v_registered_by
        );
        
        -- Actualizar el estado de la cuota
        UPDATE treasury_monthly_quotas
        SET paid_amount = 2000,
            status = 'paid'
        WHERE id = v_quota_id;
        
    END LOOP;
    
    RAISE NOTICE '12 pagos de $2.000 insertados correctamente.';
END $$;

-- PASO 3: Verificar resultado final
SELECT 
    'JAVIERA - Resultado Final' as check,
    q.month,
    q.year,
    q.expected_amount,
    q.paid_amount,
    q.status,
    COUNT(p.id) as num_payments,
    SUM(p.amount) as total_pagado
FROM users u
JOIN treasury_monthly_quotas q ON u.id = q.user_id
LEFT JOIN treasury_payments p ON q.id = p.quota_id
WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
  AND q.year = 2025
GROUP BY q.month, q.year, q.expected_amount, q.paid_amount, q.status
ORDER BY q.month;

-- Verificar total
SELECT 
    'TOTAL PAGADO' as info,
    SUM(p.amount) as total
FROM treasury_payments p
JOIN treasury_monthly_quotas q ON p.quota_id = q.id
JOIN users u ON q.user_id = u.id
WHERE u.full_name = 'Javiera Isidora Moraga Vergara'
  AND q.year = 2025;
