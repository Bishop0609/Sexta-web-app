-- =====================================================
-- SOLUCIÓN ALTERNATIVA: Cron Job con Service Role Key Directa
-- =====================================================
-- Como no podemos configurar app.settings.service_role_key,
-- vamos a recrear el cron job con la key directamente en el código

-- PASO 1: Eliminar el cron job actual
SELECT cron.unschedule('send-activity-reminders');

-- PASO 2: Crear nuevo cron job con la service role key directa
SELECT cron.schedule(
  'send-activity-reminders',
  '0 11,18,23 * * *',  -- 8 AM, 3 PM, 8 PM Chile (UTC-3)
  $$
  SELECT net.http_post(
    url := 'https://taizxujpxyutpjcworti.supabase.co/functions/v1/send-activity-reminders',
    headers := jsonb_build_object(
      'Authorization', 
      'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzY0Njc5MCwiZXhwIjoyMDgzMjIyNzkwfQ.kpR9aMyIGNz8AbPX2A9iR47s0-MVgPGSYeetm9ZOPSY'
    )
  );
  $$
);

-- PASO 3: Verificar que se creó correctamente
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  command
FROM cron.job
WHERE jobname = 'send-activity-reminders';

-- Deberías ver el job con la Authorization header incluida en el command

-- =====================================================
-- PASO 4: Test Manual (Opcional)
-- =====================================================
-- Puedes probar manualmente que la Edge Function funciona:

/*
PowerShell:

$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzY0Njc5MCwiZXhwIjoyMDgzMjIyNzkwfQ.kpR9aMyIGNz8AbPX2A9iR47s0-MVgPGSYeetm9ZOPSY"
}

Invoke-RestMethod -Uri "https://taizxujpxyutpjcworti.supabase.co/functions/v1/send-activity-reminders" -Method POST -Headers $headers
*/

-- =====================================================
-- NOTAS
-- =====================================================
-- ✅ Esta solución funciona porque la service role key está
--    directamente en el código del cron job
-- ✅ El cron se ejecutará automáticamente 3 veces al día
-- ✅ Los recordatorios se enviarán cuando haya actividades
--    en las próximas 24-48 horas
