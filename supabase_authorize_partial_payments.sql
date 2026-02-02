-- =====================================================
-- SCRIPT: Autorizar Pagos Parciales Recibidos
-- Descripción: Marca como "Pagadas" las cuotas que tienen pagos parciales
--              Útil si se autorizaron montos menores al oficial
-- =====================================================

-- 1. Ver qué cuotas se van a afectar (Diagnóstico)
SELECT 
    u.full_name,
    q.month,
    q.year,
    q.expected_amount as valor_oficial,
    q.paid_amount as valor_pagado,
    (q.expected_amount - q.paid_amount) as diferencia_perdonada
FROM treasury_monthly_quotas q
JOIN users u ON u.id = q.user_id
WHERE q.status = 'partial';

-- 2. ACTUALIZAR estados (Ejecutar para "perdonar" la diferencia)
UPDATE treasury_monthly_quotas
SET status = 'paid'
WHERE status = 'partial'
  AND paid_amount > 0; -- Asegurarse que haya pagado ALGO

-- 3. Verificación
SELECT COUNT(*) as cuotas_parciales_restantes
FROM treasury_monthly_quotas
WHERE status = 'partial';

-- =====================================================
-- EXPLICACIÓN
-- =====================================================
/*
Al ejecutar este script:
1. El sistema considerará esas cuotas como PAGADAS COMPLETAMENTE.
2. Ya no aparecerán como deuda en el perfil del usuario.
3. La diferencia de dinero (ej: pagó 1000 de 2000) queda "perdonada" o "autorizada".
4. El registro histórico mostrará el monto real que pagaron (paid_amount), 
   pero el estado será 'paid'.
*/
