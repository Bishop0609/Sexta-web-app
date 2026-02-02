-- ===================================================
-- SCRIPT LISTO PARA EJECUTAR - IMPORTACIÓN DE PAGOS
-- Copia y pega TODO este script en Supabase SQL Editor
-- ===================================================

-- PASO 1: Generar cuotas para 2025 y 2026
DO $$
BEGIN
    -- Generar cuotas para todos los meses de 2025
    FOR i IN 1..12 LOOP
        PERFORM generate_monthly_quotas(i, 2025);
    END LOOP;
    
    -- Generar cuotas para enero-febrero 2026
    PERFORM generate_monthly_quotas(1, 2026);
    PERFORM generate_monthly_quotas(2, 2026);
    
    RAISE NOTICE 'Cuotas generadas exitosamente';
END $$;

-- PASO 2: Insertar TODOS los pagos (467 registros)
-- COPIA Y PEGA los datos que te proporcioné aquí, con este formato:

INSERT INTO treasury_payments (quota_id, user_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT q.id, u.id, data.amount, data.payment_date::date, data.payment_method, data.receipt_number, data.notes, 
       (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
FROM (VALUES
-- PEGA TUS DATOS AQUÍ (desde la primera línea hasta la última)
-- Formato: ('RUT', mes, año, monto, 'fecha', 'metodo', 'comprobante', 'notas')
('7341166-1', 1, 2025, 4000, '2025-01-01', 'cash', 'TR003', 'Pago enero 2025')
-- ... resto de los datos ...
-- IMPORTANTE: LA ÚLTIMA LÍNEA NO LLEVA COMA
) AS data(user_rut, month, year, amount, payment_date, payment_method, receipt_number, notes)
INNER JOIN users u ON u.rut = data.user_rut
INNER JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.month = data.month AND q.year = data.year;

-- PASO 3: Verificar resultados
SELECT 
    'Pagos insertados' as tipo,
    COUNT(*) as cantidad
FROM treasury_payments
UNION ALL
SELECT 
    'Cuotas pagadas' as tipo,
    COUNT(*) as cantidad
FROM treasury_monthly_quotas
WHERE status = 'paid';
