-- =====================================================
-- IMPORTACIÓN MASIVA DE PAGOS - VERSIÓN SIMPLIFICADA
-- Ejecuta SOLO las secciones que necesites, en orden
-- =====================================================

-- =====================================================
-- PASO 1: INSERTAR TUS DATOS AQUÍ
-- =====================================================

-- Reemplaza estos ejemplos con tus 71 usuarios reales
-- Formato: (rut, mes, año, monto, fecha_pago, método, comprobante, notas)

-- IMPORTANTE: Ejecuta SOLO esta sección primero (Paso 1 + Paso 2)
INSERT INTO treasury_payments (
    quota_id,
    user_id,
    amount,
    payment_date,
    payment_method,
    receipt_number,
    notes,
    registered_by
)
SELECT 
    q.id,
    u.id,
    data.amount,
    data.payment_date,
    data.payment_method,
    data.receipt_number,
    data.notes,
    (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
FROM (
    VALUES
        -- AQUÍ VAN TUS DATOS - Ejemplo:
        ('12345678-9', 1, 2025, 4000, '2025-01-15'::date, 'transfer', 'TR001', 'Pago enero'),
        ('98765432-1', 1, 2025, 2000, '2025-01-18'::date, 'cash', NULL, 'Aspirante')
        -- ... agrega más filas aquí (separa con coma)
        -- IMPORTANTE: La última fila NO lleva coma al final
) AS data(user_rut, month, year, amount, payment_date, payment_method, receipt_number, notes)
INNER JOIN users u ON u.rut = data.user_rut
INNER JOIN treasury_monthly_quotas q ON q.user_id = u.id 
    AND q.month = data.month 
    AND q.year = data.year;

-- =====================================================
-- PASO 2: GENERAR CUOTAS (si aún no existen)
-- =====================================================

-- Ejecuta esto ANTES del Paso 1 si no has generado las cuotas
-- Descomenta las líneas que necesites:

-- SELECT * FROM generate_monthly_quotas(1, 2025);  -- Enero 2025
-- SELECT * FROM generate_monthly_quotas(2, 2025);  -- Febrero 2025
-- SELECT * FROM generate_monthly_quotas(3, 2025);  -- Marzo 2025
-- ... continúa para cada mes que necesites

-- =====================================================
-- PASO 3: VERIFICAR RESULTADOS
-- =====================================================

-- Ejecuta esto DESPUÉS de insertar para verificar:

-- Ver cuántos pagos se insertaron
SELECT COUNT(*) as pagos_insertados FROM treasury_payments;

-- Ver resumen por usuario
SELECT 
    u.full_name,
    u.rut,
    COUNT(p.id) as pagos,
    SUM(p.amount) as total_pagado
FROM users u
LEFT JOIN treasury_payments p ON p.user_id = u.id
WHERE u.payment_start_date IS NOT NULL
GROUP BY u.id, u.full_name, u.rut
ORDER BY pagos DESC, u.full_name;

-- Ver estado de cuotas por mes
SELECT 
    month,
    year,
    COUNT(*) FILTER (WHERE status = 'paid') as pagados,
    COUNT(*) FILTER (WHERE status = 'pending') as pendientes,
    COUNT(*) as total
FROM treasury_monthly_quotas
WHERE year = 2025
GROUP BY year, month
ORDER BY year, month;

-- =====================================================
-- CÓMO CONVERTIR TU EXCEL A SQL
-- =====================================================

/*
Si tienes Excel con columnas: RUT | Mes | Año | Monto | Fecha | Método | Comprobante | Notas

1. En Excel, crea una columna nueva con esta fórmula:
   =CONCATENAR("('", A2, "', ", B2, ", ", C2, ", ", D2, ", '", E2, "'::date, '", F2, "', '", G2, "', '", H2, "'),")

2. Arrastra la fórmula hacia abajo para todas las filas

3. Copia el resultado y pégalo en la sección VALUES del INSERT arriba

4. IMPORTANTE: Elimina la coma de la ÚLTIMA fila

Ejemplo de resultado:
('12345678-9', 1, 2025, 4000, '2025-01-15'::date, 'transfer', 'TR001', 'Pago enero'),
('98765432-1', 2, 2025, 2000, '2025-02-10'::date, 'cash', '', 'Pago febrero')
*/

-- =====================================================
-- TROUBLESHOOTING
-- =====================================================

-- Error: "quota_id" no existe
-- Solución: No has generado las cuotas para ese mes/año
-- Ejecuta generate_monthly_quotas para crear las cuotas primero

-- Error: "user_id" no existe  
-- Solución: El RUT no existe en la tabla users
-- Verifica el RUT y corrígelo

-- Verificar qué usuarios NO tienen cuotas para un mes específico:
/*
SELECT 
    u.full_name,
    u.rut,
    q.id as tiene_cuota_enero
FROM users u
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id 
    AND q.month = 1 
    AND q.year = 2025
WHERE u.payment_start_date IS NOT NULL
  AND q.id IS NULL;
*/

-- =====================================================
-- EJEMPLO COMPLETO CON 3 USUARIOS
-- =====================================================

/*
-- Primero, generar cuotas de enero 2025
SELECT * FROM generate_monthly_quotas(1, 2025);

-- Luego, insertar los pagos (copia desde VALUES hasta el final)
INSERT INTO treasury_payments (quota_id, user_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT q.id, u.id, data.amount, data.payment_date, data.payment_method, data.receipt_number, data.notes, (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
FROM (VALUES
    ('12345678-9', 1, 2025, 4000, '2025-01-15'::date, 'transfer', 'TR001', 'Pago enero'),
    ('98765432-1', 1, 2025, 2000, '2025-01-18'::date, 'cash', '', 'Aspirante'),
    ('11111111-1', 1, 2025, 4000, '2025-01-20'::date, 'transfer', 'TR003', 'Pago enero')
) AS data(user_rut, month, year, amount, payment_date, payment_method, receipt_number, notes)
INNER JOIN users u ON u.rut = data.user_rut
INNER JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.month = data.month AND q.year = data.year;

-- Verificar
SELECT COUNT(*) FROM treasury_payments;
*/
