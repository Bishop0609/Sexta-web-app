-- =====================================================
-- CRON JOB: Recordatorios Automáticos de Actividades
-- =====================================================
-- Este cron job se ejecuta 3 veces al día para enviar
-- recordatorios de actividades 24h y 48h antes
-- =====================================================

-- IMPORTANTE: Reemplaza [PROJECT_REF] con tu referencia de proyecto de Supabase
-- Puedes encontrarla en: Settings > API > Project URL
-- Ejemplo: https://abcdefghijklmn.supabase.co

-- =====================================================
-- OPCIÓN 1: 3 Ejecuciones Diarias (RECOMENDADO)
-- =====================================================
-- Ejecuta a las 8 AM, 2 PM y 8 PM (hora Chile)
-- Esto es: 11:00, 18:00 y 23:00 UTC

SELECT cron.schedule(
  'send-activity-reminders',           -- Nombre del job
  '0 11,18,23 * * *',                 -- Cron expression: 11 AM, 6 PM, 11 PM UTC
  $$
  SELECT net.http_post(
    url := 'https://[PROJECT_REF].supabase.co/functions/v1/send-activity-reminders',
    headers := jsonb_build_object(
      'Authorization', 
      'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  $$
);

-- =====================================================
-- OPCIÓN 2: 2 Ejecuciones Diarias (MÁS ECONÓMICO)
-- =====================================================
-- Ejecuta a las 9 AM y 6 PM (hora Chile)
-- Esto es: 12:00 y 21:00 UTC
-- SOLO DESCOMENTA SI PREFIERES ESTA OPCIÓN

/*
SELECT cron.schedule(
  'send-activity-reminders',
  '0 12,21 * * *',
  $$
  SELECT net.http_post(
    url := 'https://[PROJECT_REF].supabase.co/functions/v1/send-activity-reminders',
    headers := jsonb_build_object(
      'Authorization', 
      'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  $$
);
*/

-- =====================================================
-- CONFIGURAR SERVICE ROLE KEY
-- =====================================================
-- IMPORTANTE: Necesitas configurar el service role key en las settings de Supabase
-- 1. Ve a: Settings > API > service_role key (secret)
-- 2. Copia la clave
-- 3. Ejecuta (reemplazando [TU_SERVICE_ROLE_KEY]):

-- ALTER DATABASE postgres SET app.settings.service_role_key = '[TU_SERVICE_ROLE_KEY]';

-- =====================================================
-- VERIFICAR CRON JOB
-- =====================================================
-- Para ver todos los cron jobs activos:

SELECT * FROM cron.job;

-- Para ver el historial de ejecuciones:

SELECT * FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-activity-reminders')
ORDER BY start_time DESC 
LIMIT 10;

-- =====================================================
-- ELIMINAR CRON JOB (si necesitas)
-- =====================================================
-- Si necesitas eliminar el cron job:

-- SELECT cron.unschedule('send-activity-reminders');

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================
--
-- 1. ZONA HORARIA: Los horarios están en UTC. Chile está en UTC-3 o UTC-4
--    según la estación del año. Ajusta los horarios si es necesario.
--
-- 2. PRIMERA EJECUCIÓN: El cron se ejecutará en el próximo horario
--    programado después de crearlo.
--
-- 3. LOGS: Puedes ver los logs en el Dashboard de Supabase:
--    Edge Functions > send-activity-reminders > Logs
--
-- 4. TESTING: Puedes invocar manualmente la función para probar:
--    curl -X POST https://[PROJECT_REF].supabase.co/functions/v1/send-activity-reminders \
--      -H "Authorization: Bearer [SERVICE_ROLE_KEY]"
--
-- 5. COSTO: Este cron job está incluido en el plan gratuito de Supabase
--    y no genera costos adicionales.
--
