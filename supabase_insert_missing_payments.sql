-- =====================================================
-- INSERTAR PAGOS FALTANTES: 21 registros
-- =====================================================
-- TR221-TR232: Juan Pablo Quezada (RUT 20898179-K)
-- TR456-TR465: Usuario con RUT 7266367-5
-- =====================================================

-- =====================================================
-- PASO 1: Obtener user_id de ambos usuarios Y admin
-- =====================================================
-- Usuarios con pagos faltantes
SELECT id, full_name, rut
FROM users
WHERE rut IN ('20898179-K', '7266367-5');

-- Usuario admin (para registered_by)
SELECT id, full_name, email
FROM users
WHERE role = 'admin'
LIMIT 1;

-- NOTA: Copia el UUID del admin y úsalo en la variable de abajo
-- O ejecuta todo el script de una vez y usará el admin automáticamente

-- =====================================================
-- PASO 2: INSERTAR pagos de Juan Pablo Quezada
-- TR221 a TR232 (12 pagos de 2025)
-- user_id: efea3b9f-5d88-405f-9fd7-534feb6615e7
-- =====================================================

-- TR221 - Enero 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-01-01'::DATE,
    'cash',
    'TR221',
    'Pago enero 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 1;

-- TR222 - Febrero 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-02-01'::DATE,
    'cash',
    'TR222',
    'Pago febrero 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 2;

-- TR223 - Marzo 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-03-01'::DATE,
    'cash',
    'TR223',
    'Pago marzo 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 3;

-- TR224 - Abril 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-04-01'::DATE,
    'cash',
    'TR224',
    'Pago abril 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 4;

-- TR225 - Mayo 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-05-01'::DATE,
    'cash',
    'TR225',
    'Pago mayo 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 5;

-- TR226 - Junio 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-06-01'::DATE,
    'cash',
    'TR226',
    'Pago junio 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 6;

-- TR227 - Julio 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-07-01'::DATE,
    'cash',
    'TR227',
    'Pago julio 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 7;

-- TR228 - Agosto 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-08-01'::DATE,
    'cash',
    'TR228',
    'Pago agosto 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 8;

-- TR229 - Septiembre 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-09-01'::DATE,
    'cash',
    'TR229',
    'Pago septiembre 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 9;

-- TR230 - Octubre 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-10-01'::DATE,
    'cash',
    'TR230',
    'Pago octubre 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 10;

-- TR231 - Noviembre 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-11-01'::DATE,
    'cash',
    'TR231',
    'Pago noviembre 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 11;

-- TR232 - Diciembre 2025
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, receipt_number, notes, registered_by)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-12-01'::DATE,
    'cash',
    'TR232',
    'Pago diciembre 2025',
    '5b21e3c9-48f6-48af-928c-2287abd23f9f'::UUID
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 12;

-- =====================================================
-- PASO 3: INSERTAR pagos del usuario RUT 7266367-5
-- TR456 a TR465 (10 pagos de 2026)
-- NOTA: Primero necesitas obtener el user_id de PASO 1
-- Reemplaza 'USER_ID_AQUI' con el UUID correcto
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
-- PASO 4: VERIFICAR que se insertaron correctamente
-- =====================================================
SELECT COUNT(*) as total_insertados
FROM treasury_payments
WHERE receipt_number IN (
    'TR221', 'TR222', 'TR223', 'TR224', 'TR225', 'TR226',
    'TR227', 'TR228', 'TR229', 'TR230', 'TR231', 'TR232',
    'TR456', 'TR457', 'TR458', 'TR459', 'TR460',
    'TR461', 'TR462', 'TR463', 'TR464', 'TR465'
);

-- Debe devolver 21

-- =====================================================
-- PASO 5: Verificar total de pagos
-- =====================================================
SELECT COUNT(*) as total_pagos_final
FROM treasury_payments;

-- Debe devolver 465 (444 + 21)

-- =====================================================
-- PASO 6: Verificar que no falte ningún TR entre 003 y 467
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
-- 1. Ejecuta PASO 1 para confirmar los user_id
-- 
-- 2. Ejecuta todos los INSERT de PASO 2 y PASO 3
--    (puedes copiar y pegar todo junto)
-- 
-- 3. Ejecuta PASO 4: Debe devolver 21
-- 
-- 4. Ejecuta PASO 5: Debe devolver 465
-- 
-- 5. Ejecuta PASO 6: Debe devolver 0 (sin faltantes)
-- 
-- =====================================================
