-- =====================================================
-- DIAGNÓSTICO: ¿Por qué mi usuario aparece como "Pagado"?
-- =====================================================

-- Ejecuta estas queries en orden para entender el problema

-- 1. Verificar tu información básica de usuario
-- REEMPLAZA 'TU_RUT_AQUI' con tu RUT (ej: '12345678-9')
SELECT 
    id,
    full_name,
    rut,
    rank,
    is_student,
    payment_start_date,
    CASE 
        WHEN payment_start_date IS NULL THEN '❌ NO configurado para pagar (por eso muestra "Pagado")'
        WHEN payment_start_date > CURRENT_DATE THEN '⏳ Fecha en el futuro (aún no debe)'
        ELSE '✅ Configurado correctamente'
    END as estado_configuracion
FROM users
WHERE rut = 'TU_RUT_AQUI';

-- 2. Ver tus cuotas generadas
SELECT 
    month,
    year,
    expected_amount,
    paid_amount,
    status,
    forced_paid,
    CASE 
        WHEN forced_paid = TRUE THEN ' (AUTORIZADO MANUALMENTE)'
        ELSE ''
    END as nota
FROM treasury_monthly_quotas
WHERE user_id = (SELECT id FROM users WHERE rut = 'TU_RUT_AQUI')
ORDER BY year, month;

-- 3. Ver tus pagos registrados
SELECT 
    p.amount,
    p.payment_date,
    p.payment_method,
    p.receipt_number,
    q.month,
    q.year
FROM treasury_payments p
JOIN treasury_monthly_quotas q ON q.id = p.quota_id
WHERE p.user_id = (SELECT id FROM users WHERE rut = 'TU_RUT_AQUI')
ORDER BY p.payment_date;

-- 4. Calcular tu deuda real
SELECT * 
FROM calculate_user_debt(
    (SELECT id FROM users WHERE rut = 'TU_RUT_AQUI')
);

-- =====================================================
-- DIAGNÓSTICOS COMUNES
-- =====================================================

/*
CASO 1: payment_start_date es NULL
--------------------------------------
Si la query #1 muestra "NO configurado para pagar", significa que tu usuario
NO tiene configurada una fecha de inicio de pagos.

SOLUCIÓN: Un administrador debe asignar payment_start_date en Gestión de Usuarios.


CASO 2: Todas las cuotas están en forced_paid = TRUE
------------------------------------------------------
Si la query #2 muestra que todas tus cuotas tienen "AUTORIZADO MANUALMENTE",
significa que se ejecutó el script supabase_authorize_partial_payments.sql
que marcó todas las cuotas parciales como "Pagadas".

SOLUCIÓN: Esto fue intencional si se autorizó pagar menos. Si fue un error,
contacta al administrador para revertirlo.


CASO 3: No hay cuotas generadas pero payment_start_date existe
---------------------------------------------------------------
Si la query #2 no muestra resultados pero la #1 muestra fecha de inicio,
significa que no se han generado las cuotas mensuales.

SOLUCIÓN: El tesorero debe generar las cuotas en Tesorería → Registro de Pagos.


CASO 4: Sí tienes pagos registrados
------------------------------------
Si la query #3 muestra pagos, verifica que:
- Los montos sumen el total esperado
- Las fechas estén correctas
- No haya duplicados

*/

-- =====================================================
-- VERIFICACIÓN GLOBAL (SOLO PARA ADMINISTRADORES)
-- =====================================================

-- Ver TODOS los usuarios y su estado de deuda
SELECT 
    u.full_name,
    u.rut,
    u.payment_start_date,
    d.months_owed as meses_deuda,
    d.total_amount as monto_deuda,
    CASE 
        WHEN u.payment_start_date IS NULL THEN 'No paga'
        WHEN d.months_owed = 0 THEN 'Al día'
        WHEN d.months_owed > 0 AND d.months_owed <= 2 THEN 'Deuda leve'
        WHEN d.months_owed > 2 AND d.months_owed <= 6 THEN 'Deuda moderada'
        ELSE 'Deuda grave'
    END as clasificacion
FROM users u
CROSS JOIN LATERAL calculate_user_debt(u.id) d
WHERE u.payment_start_date IS NOT NULL
ORDER BY d.months_owed DESC, u.full_name;

-- Ver cuántos usuarios están en cada estado
SELECT 
    CASE 
        WHEN u.payment_start_date IS NULL THEN 'No paga'
        WHEN d.months_owed = 0 THEN 'Al día'
        WHEN d.months_owed > 0 AND d.months_owed <= 2 THEN 'Deuda leve'
        WHEN d.months_owed > 2 AND d.months_owed <= 6 THEN 'Deuda moderada'
        ELSE 'Deuda grave'
    END as clasificacion,
    COUNT(*) as cantidad,
    SUM(d.total_amount) as deuda_total
FROM users u
CROSS JOIN LATERAL calculate_user_debt(u.id) d
WHERE u.payment_start_date IS NOT NULL
GROUP BY clasificacion
ORDER BY deuda_total DESC;
