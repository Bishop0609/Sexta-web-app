-- =====================================================
-- REPORTE DE DEUDA 2025: 12 Usuarios Específicos
-- =====================================================

SELECT 
    u.full_name,
    u.rut,
    
    -- 1. Valor Base de Cuota (tomamos el de enero como ref)
    (SELECT expected_amount 
     FROM treasury_monthly_quotas q 
     WHERE q.user_id = u.id AND q.year = 2025 AND q.month = 1) as valor_cuota_mensual,
    
    -- 2. Cuotas Pagadas (status = 'paid')
    COUNT(CASE WHEN q.status = 'paid' THEN 1 END) as cant_cuotas_pagadas,
    
    -- Cuotas Parciales
    COUNT(CASE WHEN q.status = 'partial' THEN 1 END) as cant_cuotas_parciales,
    
    -- Pagado Total ($)
    SUM(COALESCE(q.paid_amount, 0)) as total_pagado,
    
    -- 3. Deuda Total ($)
    SUM(q.expected_amount) - SUM(COALESCE(q.paid_amount, 0)) as total_adeudado,
    
    -- Estado General
    CASE 
        WHEN SUM(q.expected_amount) - SUM(COALESCE(q.paid_amount, 0)) = 0 THEN 'AL DÍA'
        ELSE 'DEUDA PENDIENTE'
    END as estado

FROM users u
JOIN treasury_monthly_quotas q ON q.user_id = u.id AND q.year = 2025
WHERE u.rut IN (
    '21373938-7', -- Javiera Moraga
    '22337684-3', -- Paula Ramírez
    '15571013-6', -- Paulo Morales
    '22026759-8', -- Martín Bernal
    '27979718-3', -- Karla Meza
    '15050916-5', -- Ángelo Póstigo
    '21844261-7', -- Manuel Brant
    '27731075-9', -- Vicente Hernández
    '22691434-K', -- Vicente Bernal
    '21562316-5', -- Gabriel Olivares
    '17016081-9', -- Tania Rojas
    '22378557-3'  -- Hans Zapata
)
GROUP BY u.id, u.full_name, u.rut
ORDER BY u.full_name;
