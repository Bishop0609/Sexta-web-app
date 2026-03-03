-- =====================================================
-- DIAGNÓSTICO: Recordatorios de Actividades
-- =====================================================
-- Ejecuta estas queries en el SQL Editor de Supabase
-- para diagnosticar por qué no se enviaron los recordatorios

-- =====================================================
-- 1. VERIFICAR CRON JOB
-- =====================================================

-- Ver si el cron job existe y está activo
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  database
FROM cron.job
WHERE jobname = 'send-activity-reminders';

-- Si no aparece nada, el cron job NO está configurado ❌

-- =====================================================
-- 2. VER HISTORIAL DE EJECUCIONES
-- =====================================================

-- Ver las últimas 20 ejecuciones del cron job
SELECT 
  runid,
  jobid,
  start_time,
  end_time,
  status,
  return_message,
  (end_time - start_time) as duration
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-activity-reminders')
ORDER BY start_time DESC
LIMIT 20;

-- Buscar específicamente la ejecución del 2 de febrero a las 23:00 UTC (8 PM Chile)
SELECT 
  runid,
  start_time,
  status,
  return_message
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-activity-reminders')
  AND start_time >= '2026-02-02 22:00:00'::timestamp
  AND start_time <= '2026-02-03 00:00:00'::timestamp
ORDER BY start_time DESC;

-- =====================================================
-- 3. VERIFICAR SERVICE ROLE KEY
-- =====================================================

-- Ver si está configurada la service role key
SHOW app.settings.service_role_key;

-- Si sale error o vacío, necesitas configurarla ❌

-- =====================================================
-- 4. VER ACTIVIDADES PRÓXIMAS
-- =====================================================

-- Ver todas las actividades de los próximos 3 días
SELECT 
  id,
  title,
  activity_type,
  activity_date,
  start_time,
  notify_24h,
  notify_48h,
  notify_groups,
  created_at
FROM activities
WHERE activity_date >= CURRENT_DATE
  AND activity_date <= CURRENT_DATE + INTERVAL '3 days'
ORDER BY activity_date, start_time;

-- =====================================================
-- 5. VERIFICAR RECORDATORIOS YA ENVIADOS
-- =====================================================

-- Ver qué recordatorios se han enviado
SELECT 
  id,
  reminder_type,
  reference_id,
  reference_date,
  recipient_count,
  sent_at
FROM sent_reminders
ORDER BY sent_at DESC
LIMIT 20;

-- Ver si se envió recordatorio para una actividad específica
-- (Reemplaza [ACTIVITY_ID] con el ID de la actividad)
SELECT * FROM sent_reminders
WHERE reference_id = [ACTIVITY_ID];

-- =====================================================
-- 6. SIMULAR BÚSQUEDA DE ACTIVIDADES (24H)
-- =====================================================

-- Esta query simula lo que hace la Edge Function
-- para encontrar actividades que necesitan recordatorio de 24h

-- Calcular ventana de tiempo (23-25 horas desde ahora)
WITH time_window AS (
  SELECT 
    (NOW() + INTERVAL '23 hours')::timestamp AS window_start,
    (NOW() + INTERVAL '25 hours')::timestamp AS window_end
)
SELECT 
  a.id,
  a.title,
  a.activity_date,
  a.start_time,
  a.notify_24h,
  tw.window_start,
  tw.window_end,
  -- Mostrar si la actividad está en la ventana
  CASE 
    WHEN a.activity_date::timestamp >= tw.window_start 
     AND a.activity_date::timestamp <= tw.window_end 
    THEN '✅ EN VENTANA'
    ELSE '❌ FUERA DE VENTANA'
  END as status
FROM activities a
CROSS JOIN time_window tw
WHERE a.notify_24h = true
  AND a.activity_date >= CURRENT_DATE
  AND a.activity_date <= CURRENT_DATE + INTERVAL '2 days'
ORDER BY a.activity_date, a.start_time;

-- =====================================================
-- 7. PROBLEMA POTENCIAL: COMPARACIÓN DE FECHAS
-- =====================================================

-- ⚠️ PROBLEMA IDENTIFICADO:
-- La Edge Function compara activity_date (solo fecha) con timestamps (fecha + hora)
-- Esto puede causar que NO se encuentren actividades

-- Ejemplo del problema:
-- Si activity_date = '2026-02-04' (sin hora)
-- Y window_start = '2026-02-04 23:00:00'
-- PostgreSQL convierte '2026-02-04' a '2026-02-04 00:00:00'
-- Por lo tanto: '2026-02-04 00:00:00' NO es >= '2026-02-04 23:00:00' ❌

-- Ver actividades con este problema:
SELECT 
  id,
  title,
  activity_date,
  activity_date::timestamp as activity_timestamp,
  (NOW() + INTERVAL '24 hours')::timestamp as target_time,
  -- Mostrar si hay problema de comparación
  CASE 
    WHEN activity_date::timestamp < (NOW() + INTERVAL '23 hours')::timestamp
    THEN '❌ PROBLEMA: Fecha convertida a medianoche es anterior a ventana'
    ELSE '✅ OK'
  END as comparison_issue
FROM activities
WHERE activity_date = (CURRENT_DATE + INTERVAL '1 day')::date
  AND notify_24h = true;

-- =====================================================
-- 8. SOLUCIÓN: CREAR CRON JOB (si no existe)
-- =====================================================

-- Si el cron job no existe, ejecuta esto:
/*
SELECT cron.schedule(
  'send-activity-reminders',
  '0 11,18,23 * * *',  -- 8 AM, 2 PM, 8 PM Chile (UTC-3)
  $$
  SELECT net.http_post(
    url := 'https://taizxujpxyutpjcworti.supabase.co/functions/v1/send-activity-reminders',
    headers := jsonb_build_object(
      'Authorization', 
      'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  $$
);
*/

-- =====================================================
-- 9. CONFIGURAR SERVICE ROLE KEY (si no está)
-- =====================================================

-- Si la service role key no está configurada, ejecuta esto:
/*
ALTER DATABASE postgres SET app.settings.service_role_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzY0Njc5MCwiZXhwIjoyMDgzMjIyNzkwfQ.kpR9aMyIGNz8AbPX2A9iR47s0-MVgPGSYeetm9ZOPSY';
*/

-- =====================================================
-- 10. TEST MANUAL DE LA EDGE FUNCTION
-- =====================================================

-- Puedes invocar manualmente la función desde PowerShell:
/*
$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzY0Njc5MCwiZXhwIjoyMDgzMjIyNzkwfQ.kpR9aMyIGNz8AbPX2A9iR47s0-MVgPGSYeetm9ZOPSY"
}

Invoke-RestMethod -Uri "https://taizxujpxyutpjcworti.supabase.co/functions/v1/send-activity-reminders" -Method POST -Headers $headers
*/
