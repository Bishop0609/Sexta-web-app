-- =====================================================
-- SOLUCIÓN: Configurar Service Role Key
-- =====================================================
-- Ejecuta este comando en el SQL Editor de Supabase

ALTER DATABASE postgres SET app.settings.service_role_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzY0Njc5MCwiZXhwIjoyMDgzMjIyNzkwfQ.kpR9aMyIGNz8AbPX2A9iR47s0-MVgPGSYeetm9ZOPSY';

-- =====================================================
-- VERIFICAR QUE SE CONFIGURÓ CORRECTAMENTE
-- =====================================================

SHOW app.settings.service_role_key;

-- Debería mostrar la clave configurada

-- =====================================================
-- OPCIONAL: Test manual de la Edge Function
-- =====================================================
-- Después de configurar la key, puedes probar manualmente
-- desde PowerShell:

/*
$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzY0Njc5MCwiZXhwIjoyMDgzMjIyNzkwfQ.kpR9aMyIGNz8AbPX2A9iR47s0-MVgPGSYeetm9ZOPSY"
}

Invoke-RestMethod -Uri "https://taizxujpxyutpjcworti.supabase.co/functions/v1/send-activity-reminders" -Method POST -Headers $headers
*/
