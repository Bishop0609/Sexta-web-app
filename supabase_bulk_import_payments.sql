-- =====================================================
-- SCRIPT: Carga Masiva de Pagos desde Excel
-- Descripción: Template para importar pagos históricos
-- Fecha: 2026-01-25
-- =====================================================

-- PASO 1: Preparar datos del Excel
-- =====================================================

/*
Tu Excel debe tener las siguientes columnas (en este orden):

user_rut         | month | year | amount | payment_date  | payment_method | receipt_number | notes
-----------------|-------|------|--------|---------------|----------------|----------------|------------------
12345678-9       | 1     | 2025 | 5000   | 2025-01-15    | transfer       | TR12345        | Pago Enero
98765432-1       | 2     | 2025 | 2500   | 2025-02-10    | cash           |                | Aspirante

COLUMNAS REQUERIDAS:
- user_rut: RUT del usuario (formato: 12345678-9)
- month: Número del mes (1-12)
- year: Año (2025, 2026, etc.)
- amount: Monto pagado ($5000, $2500, etc.)
- payment_date: Fecha del pago (formato: YYYY-MM-DD)
- payment_method: Método de pago (cash, transfer, other)
- receipt_number: Número de comprobante (opcional, puede estar vacío)
- notes: Notas adicionales (opcional)

IMPORTANTE:
- No incluir encabezados en el CSV
- Usar punto y coma (;) como separador
- Fechas en formato YYYY-MM-DD
- payment_method debe ser exactamente: cash, transfer, o other
*/

-- PASO 2: Crear tabla temporal para importación
-- =====================================================

DROP TABLE IF EXISTS temp_payment_imports;

CREATE TEMP TABLE temp_payment_imports (
    user_rut VARCHAR(12) NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    receipt_number VARCHAR(100),
    notes TEXT
);

-- PASO 3: Importar datos desde CSV
-- =====================================================

/*
En Supabase SQL Editor, no puedes usar COPY directamente.
Tendrás que insertar los datos manualmente con INSERT statements.

Opción A: Si tienes pocos registros (menos de 50), usa INSERT directo:
*/

-- Ejemplo de INSERTs manuales (reemplaza con tus datos reales):
INSERT INTO temp_payment_imports (user_rut, month, year, amount, payment_date, payment_method, receipt_number, notes)
VALUES 
    ('12345678-9', 1, 2025, 5000, '2025-01-15', 'transfer', 'TR001', 'Pago cuota enero'),
    ('98765432-1', 1, 2025, 2500, '2025-01-18', 'cash', NULL, 'Aspirante - enero'),
    ('11111111-1', 2, 2025, 5000, '2025-02-10', 'transfer', 'TR002', 'Pago cuota febrero');
    -- ... agregar más filas aquí

/*
Opción B: Si tienes muchos registros, convierte tu Excel a SQL INSERT statements:
1. En Excel, crea una columna con fórmula:
   =CONCATENATE("('", A2, "', ", B2, ", ", C2, ", ", D2, ", '", E2, "', '", F2, "', '", G2, "', '", H2, "'),")
2. Copia los resultados
3. Pégalos después del VALUES en el INSERT de arriba
*/

-- PASO 4: Verificar datos importados
-- =====================================================

-- Ver cuántos registros se importaron
SELECT COUNT(*) as total_registros 
FROM temp_payment_imports;

-- Ver los datos importados
SELECT * FROM temp_payment_imports
ORDER BY year, month, user_rut;

-- Verificar que todos los RUTs existan en la tabla users
SELECT 
    t.user_rut,
    u.full_name
FROM temp_payment_imports t
LEFT JOIN users u ON u.rut = t.user_rut
WHERE u.id IS NULL;

-- Si la query anterior retorna filas, significa que hay RUTs que no existen
-- Debes corregir esos RUTs antes de continuar

-- PASO 5: Generar cuotas mensuales (si no existen)
-- =====================================================

-- Primero, genera las cuotas para todos los meses que aparecen en tus pagos
-- Ejecuta esto para cada mes/año único en tus datos:

SELECT * FROM generate_monthly_quotas(1, 2025);  -- Enero 2025
SELECT * FROM generate_monthly_quotas(2, 2025);  -- Febrero 2025
-- ... repite para cada mes

-- O usa este query dinámico:
DO $$
DECLARE
    month_year RECORD;
BEGIN
    -- Generar cuotas para cada mes/año único en los datos importados
    FOR month_year IN 
        SELECT DISTINCT month, year 
        FROM temp_payment_imports 
        ORDER BY year, month
    LOOP
        RAISE NOTICE 'Generando cuotas para mes % año %', month_year.month, month_year.year;
        PERFORM generate_monthly_quotas(month_year.month, month_year.year);
    END LOOP;
END $$;

-- PASO 6: Insertar pagos (el paso principal)
-- =====================================================

-- Este script insertará los pagos automáticamente
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
    q.id AS quota_id,
    u.id AS user_id,
    t.amount,
    t.payment_date,
    t.payment_method,
    t.receipt_number,
    t.notes,
    (SELECT id FROM users WHERE role = 'admin' LIMIT 1) AS registered_by  -- Se registra como admin
FROM temp_payment_imports t
INNER JOIN users u ON u.rut = t.user_rut
INNER JOIN treasury_monthly_quotas q ON q.user_id = u.id 
    AND q.month = t.month 
    AND q.year = t.year
WHERE q.id IS NOT NULL;

-- Verificar cuántos pagos se insertaron
SELECT COUNT(*) as pagos_insertados FROM treasury_payments;

-- PASO 7: Verificación final
-- =====================================================

-- Ver resumen de pagos por usuario
SELECT 
    u.full_name,
    u.rut,
    COUNT(p.id) as pagos_realizados,
    SUM(p.amount) as total_pagado
FROM users u
LEFT JOIN treasury_payments p ON p.user_id = u.id
WHERE u.payment_start_date IS NOT NULL
GROUP BY u.id, u.full_name, u.rut
ORDER BY pagos_realizados DESC;

-- Ver cuotas pagadas vs pendientes por mes
SELECT 
    month,
    year,
    COUNT(*) FILTER (WHERE status = 'paid') as pagados,
    COUNT(*) FILTER (WHERE status = 'pending') as pendientes,
    COUNT(*) FILTER (WHERE status = 'partial') as parciales,
    COUNT(*) as total
FROM treasury_monthly_quotas
WHERE year = 2025
GROUP BY year, month
ORDER BY year, month;

-- Ver usuarios con deuda
SELECT 
    u.full_name,
    d.months_owed,
    d.total_amount
FROM users u
CROSS JOIN LATERAL calculate_user_debt(u.id) d
WHERE u.payment_start_date IS NOT NULL
  AND d.months_owed > 0
ORDER BY d.months_owed DESC, u.full_name;

-- PASO 8: Limpiar tabla temporal
-- =====================================================

DROP TABLE temp_payment_imports;

-- =====================================================
-- TROUBLESHOOTING
-- =====================================================

-- Problema: No se insertaron algunos pagos
-- Solución: Verifica que las cuotas existan para esos meses
SELECT 
    t.user_rut,
    t.month,
    t.year,
    u.full_name,
    q.id as quota_exists
FROM temp_payment_imports t
INNER JOIN users u ON u.rut = t.user_rut
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id 
    AND q.month = t.month 
    AND q.year = t.year
WHERE q.id IS NULL;

-- Si hay filas, genera las cuotas faltantes para esos meses/años

-- Problema: Pagos duplicados
-- Solución: Elimina pagos duplicados (solo si te equivocaste)
DELETE FROM treasury_payments
WHERE id IN (
    SELECT id
    FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id, quota_id, payment_date ORDER BY created_at DESC) as rn
        FROM treasury_payments
    ) t
    WHERE rn > 1
);

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

/*
FLUJO RECOMENDADO:

1. Exporta tu Excel a CSV con punto y coma (;) como separador
2. Convierte el CSV a SQL INSERTs usando Excel o un script
3. Ejecuta los INSERTs en la tabla temp_payment_imports
4. Verifica que todos los RUTs existan
5. Genera cuotas para todos los meses necesarios
6. Ejecuta el INSERT INTO treasury_payments
7. Verifica resultados
8. Limpia tabla temporal

VALIDACIONES PREVIAS:
- Todos los user_rut deben existir en la tabla users
- payment_method debe ser: cash, transfer, o other
- month debe estar entre 1 y 12
- year debe ser >= 2025
- amount debe ser > 0
- payment_date debe tener formato válido YYYY-MM-DD

DESPUÉS DE IMPORTAR:
- El trigger update_quota_status actualizará automáticamente el estado de cada cuota
- Las cuotas cambiarán a 'paid' si amount >= expected_amount
- Refresca la app para ver los cambios
*/
