-- =====================================================
-- COMPLETAR CUOTAS FALTANTES 2026 + INSERTAR PAGOS
-- =====================================================
-- Usuario RUT 7266367-5 solo tiene cuotas para ene-feb 2026
-- Necesita cuotas mar-dic 2026 para insertar pagos TR456-TR465
-- =====================================================

-- =====================================================
-- PASO 1: Verificar cuotas actuales del usuario
-- =====================================================
SELECT u.id, u.full_name, u.rut, q.year, q.month, q.expected_amount
FROM users u
LEFT JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2026
WHERE u.rut = '7266367-5'
ORDER BY q.month;

-- =====================================================
-- PASO 2: Generar cuotas faltantes (meses 3-12 de 2026)
-- =====================================================
INSERT INTO treasury_monthly_quotas (user_id, year, month, expected_amount, paid_amount, status)
SELECT 
    u.id,
    2026,
    m.month_num,
    5000,  -- Monto base para 2026
    0,
    'pending'
FROM users u
CROSS JOIN (
    SELECT generate_series(3, 12) as month_num
) m
WHERE u.rut = '7266367-5'
  AND NOT EXISTS (
      SELECT 1 
      FROM treasury_monthly_quotas q2 
      WHERE q2.user_id = u.id 
        AND q2.year = 2026 
        AND q2.month = m.month_num
  );

-- =====================================================
-- PASO 3: Verificar que se crearon las 10 cuotas faltantes
-- =====================================================
SELECT COUNT(*) as cuotas_creadas
FROM treasury_monthly_quotas q
JOIN users u ON u.id = q.user_id
WHERE u.rut = '7266367-5'
  AND q.year = 2026;

-- Debe devolver 12 (si solo tenía 2, ahora debe tener 12)

-- =====================================================
-- PASO 4: INSERTAR los 10 pagos TR456-TR465
-- =====================================================

-- TR456 - Marzo 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-03-01'::DATE,
    'cash',
    'TR456',
    'Pago marzo 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 3;

-- TR457 - Abril 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-04-01'::DATE,
    'cash',
    'TR457',
    'Pago abril 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 4;

-- TR458 - Mayo 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-05-01'::DATE,
    'cash',
    'TR458',
    'Pago mayo 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 5;

-- TR459 - Junio 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-06-01'::DATE,
    'cash',
    'TR459',
    'Pago junio 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 6;

-- TR460 - Julio 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-07-01'::DATE,
    'cash',
    'TR460',
    'Pago julio 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 7;

-- TR461 - Agosto 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-08-01'::DATE,
    'cash',
    'TR461',
    'Pago agosto 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 8;

-- TR462 - Septiembre 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-09-01'::DATE,
    'cash',
    'TR462',
    'Pago septiembre 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 9;

-- TR463 - Octubre 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-10-01'::DATE,
    'cash',
    'TR463',
    'Pago octubre 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 10;

-- TR464 - Noviembre 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-11-01'::DATE,
    'cash',
    'TR464',
    'Pago noviembre 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 11;

-- TR465 - Diciembre 2026
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    u.id,
    q.id,
    5000,
    '2026-12-01'::DATE,
    'cash',
    'TR465',
    'Pago diciembre 2026',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM users u
CROSS JOIN treasury_monthly_quotas q
WHERE u.rut = '7266367-5'
  AND q.user_id = u.id
  AND q.year = 2026
  AND q.month = 12;

-- =====================================================
-- PASO 5: Verificar que se insertaron los 10 pagos
-- =====================================================
SELECT COUNT(*) as pagos_insertados
FROM treasury_payments
WHERE receipt_number IN (
    'TR456', 'TR457', 'TR458', 'TR459', 'TR460',
    'TR461', 'TR462', 'TR463', 'TR464', 'TR465'
);

-- Debe devolver 10

-- =====================================================
-- PASO 6: Verificar total final de pagos
-- =====================================================
SELECT COUNT(*) as total_pagos
FROM treasury_payments;

-- Debe devolver 465 (444 originales + 12 Juan Pablo + 10 RUT 7266367-5 = 466)

-- =====================================================
-- PASO 7: Verificar que NO falten TRs
-- =====================================================
WITH numeros_esperados AS (
    SELECT 'TR' || LPAD(n::TEXT, 3, '0') as receipt_esperado
    FROM generate_series(3, 467) n
),
numeros_existentes AS (
    SELECT receipt_number
    FROM treasury_payments
    WHERE receipt_number LIKE 'TR%'
)
SELECT COUNT(*) as receipts_faltantes
FROM numeros_esperados ne
LEFT JOIN numeros_existentes nx ON ne.receipt_esperado = nx.receipt_number
WHERE nx.receipt_number IS NULL;

-- Debe devolver 0

-- =====================================================
-- INSTRUCCIONES:
-- =====================================================
-- 
-- 1. Ejecuta PASO 1 para ver cuotas actuales
-- 
-- 2. Ejecuta PASO 2 para crear cuotas faltantes (meses 3-12)
-- 
-- 3. Ejecuta PASO 3: Debe devolver 12 cuotas totales
-- 
-- 4. Ejecuta PASO 4: Todos los INSERT de pagos
-- 
-- 5. Ejecuta PASO 5: Debe devolver 10 pagos insertados
-- 
-- 6. Ejecuta PASO 6: Debe devolver 466 pagos totales
--    (444 + 12 Juan Pablo + 10 RUT 7266367-5)
-- 
-- 7. Ejecuta PASO 7: Debe devolver 0 (sin faltantes)
-- 
-- =====================================================
