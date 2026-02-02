-- =====================================================
-- DIAGNÓSTICO: Pagos Faltantes de Juan Pablo Quezada
-- =====================================================
-- Problema: Los pagos insertados masivamente no aparecen en la BD
-- =====================================================

-- =====================================================
-- PASO 1: Ver la estructura de treasury_payments
-- =====================================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'treasury_payments'
ORDER BY ordinal_position;

-- =====================================================
-- PASO 2: Verificar formato de inserción
-- =====================================================
-- El formato de la imagen era:
-- ('20898179-K', month, year, amount, date, payment_method, transaction_ref, notes)
-- 
-- Pero la tabla treasury_payments espera:
-- (user_id UUID, quota_id UUID, amount, payment_date, payment_method, transaction_reference, notes)
--
-- ❌ ERROR: Se insertó con RUT, no con user_id UUID

-- =====================================================
-- PASO 3: Ver user_id de Juan Pablo
-- =====================================================
SELECT id as user_id, full_name, rut
FROM users
WHERE rut = '20898179-K';

-- Este es el UUID correcto: efea3b9f-5d88-405f-9fd7-534feb6615e7

-- =====================================================
-- PASO 4: Ver quota_ids de Juan Pablo para 2025
-- =====================================================
SELECT id as quota_id, user_id, month, year, expected_amount
FROM treasury_monthly_quotas
WHERE user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND year = 2025
ORDER BY month;

-- =====================================================
-- PASO 5: INSERTAR pagos correctamente
-- =====================================================
-- Necesitamos hacer JOIN entre mes y quota_id

-- Para enero (mes 1)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-01-01'::DATE,
    'cash',
    'TR221',
    'Pago enero 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 1;

-- Para febrero (mes 2)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-02-01'::DATE,
    'cash',
    'TR222',
    'Pago febrero 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 2;

-- Para marzo (mes 3)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-03-01'::DATE,
    'cash',
    'TR223',
    'Pago marzo 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 3;

-- Para abril (mes 4)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-04-01'::DATE,
    'cash',
    'TR224',
    'Pago abril 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 4;

-- Para mayo (mes 5)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-05-01'::DATE,
    'cash',
    'TR225',
    'Pago mayo 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 5;

-- Para junio (mes 6)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-06-01'::DATE,
    'cash',
    'TR226',
    'Pago junio 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 6;

-- Para julio (mes 7)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-07-01'::DATE,
    'cash',
    'TR227',
    'Pago julio 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 7;

-- Para agosto (mes 8)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-08-01'::DATE,
    'cash',
    'TR228',
    'Pago agosto 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 8;

-- Para septiembre (mes 9)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-09-01'::DATE,
    'cash',
    'TR229',
    'Pago septiembre 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 9;

-- Para octubre (mes 10)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-10-01'::DATE,
    'cash',
    'TR230',
    'Pago octubre 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 10;

-- Para noviembre (mes 11)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-11-01'::DATE,
    'cash',
    'TR231',
    'Pago noviembre 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 11;

-- Para diciembre (mes 12)
INSERT INTO treasury_payments (user_id, quota_id, amount, payment_date, payment_method, transaction_reference, notes)
SELECT 
    'efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID,
    q.id,
    4000,
    '2025-12-01'::DATE,
    'cash',
    'TR232',
    'Pago diciembre 2025'
FROM treasury_monthly_quotas q
WHERE q.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND q.year = 2025
  AND q.month = 12;

-- =====================================================
-- PASO 6: Verificar que se insertaron correctamente
-- =====================================================
SELECT p.amount, p.payment_date, p.transaction_reference, p.notes
FROM treasury_payments p
WHERE p.user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
ORDER BY p.payment_date;

-- =====================================================
-- PASO 7: Ver cuotas actualizadas
-- =====================================================
SELECT month, expected_amount, paid_amount, status
FROM treasury_monthly_quotas
WHERE user_id = 'efea3b9f-5d88-405f-9fd7-534feb6615e7'
  AND year = 2025
ORDER BY month;

-- =====================================================
-- PASO 8: Verificar deuda final
-- =====================================================
SELECT calculate_user_debt('efea3b9f-5d88-405f-9fd7-534feb6615e7'::UUID);

-- Debería devolver: (0, 0, []) - Sin deuda
