-- =====================================================
-- ELIMINAR PAGO INCORRECTO 2026
-- =====================================================
-- Eliminar pago de $4.000 para RUT 13238728-1 en 2026
-- =====================================================

-- 1. Identificar el pago
SELECT 
    p.id, 
    u.rut, 
    u.full_name, 
    p.amount, 
    p.payment_date 
FROM treasury_payments p
JOIN users u ON p.user_id = u.id
JOIN treasury_monthly_quotas q ON p.quota_id = q.id
WHERE u.rut = '13238728-1'
  AND q.year = 2026
  AND p.amount = 4000;

-- 2. Eliminar el pago
DELETE FROM treasury_payments
WHERE id IN (
    SELECT p.id
    FROM treasury_payments p
    JOIN users u ON p.user_id = u.id
    JOIN treasury_monthly_quotas q ON p.quota_id = q.id
    WHERE u.rut = '13238728-1'
      AND q.year = 2026
      AND p.amount = 4000
);

-- 3. Actualizar el estado de la cuota asociada a 'pending' (si quedó sin pagos)
UPDATE treasury_monthly_quotas
SET status = 'pending',
    paid_amount = 0
FROM users u
WHERE treasury_monthly_quotas.user_id = u.id
  AND u.rut = '13238728-1'
  AND treasury_monthly_quotas.year = 2026
  AND treasury_monthly_quotas.id NOT IN (SELECT quota_id FROM treasury_payments);

-- 4. Verificación
SELECT * FROM treasury_payments p
JOIN users u ON p.user_id = u.id
WHERE u.rut = '13238728-1';
