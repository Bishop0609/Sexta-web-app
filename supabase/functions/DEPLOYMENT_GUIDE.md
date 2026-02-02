# Guía de Deployment: Supabase Edge Function para Emails

## 📋 Prerrequisitos

1. **Supabase CLI instalado**
   ```powershell
   # Instalar via npm
   npm install -g supabase
   
   # O via scoop (Windows)
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   scoop install supabase
   ```

2. **Login en Supabase**
   ```powershell
   supabase login
   ```

## 🚀 Paso 1: Link al Proyecto Supabase

```powershell
cd c:\Sexta_app
supabase link --project-ref taizxujpxyutpjcworti
```

## 🔑 Paso 2: Configurar Variable de Entorno

La Edge Function necesita acceso al `RESEND_API_KEY`. Configúralo en Supabase:

### Opción A: Via Dashboard Web
1. Ve a https://supabase.com/dashboard/project/taizxujpxyutpjcworti
2. Navega a **Settings → Edge Functions → Secrets**
3. Agrega un nuevo secret:
   - **Name**: `RESEND_API_KEY`
   - **Value**: `re_hgBXdLJx_DwFmAgMHNzNMiW96twfiGoqT`

### Opción B: Via CLI
```powershell
supabase secrets set RESEND_API_KEY=re_hgBXdLJx_DwFmAgMHNzNMiW96twfiGoqT --project-ref taizxujpxyutpjcworti
```

## 📦 Paso 3: Deploy la Edge Function

```powershell
cd c:\Sexta_app
supabase functions deploy send-email --project-ref taizxujpxyutpjcworti
```

Deberías ver:
```
Deploying function send-email...
Function deployed successfully!
URL: https://taizxujpxyutpjcworti.supabase.co/functions/v1/send-email
```

## ✅ Paso 4: Verificar Deploy

### Test Manual via cURL (PowerShell)

```powershell
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2NDY3OTAsImV4cCI6MjA4MzIyMjc5MH0.tH7J8RwSjUdGSbPgmmNW-Vof5jV6IIskll1JR0W0faA"
}

$body = @{
    type = "permission_review"
    data = @{
        officerEmail = "tu-email@gmail.com"  # Cambia esto por tu email de prueba
        firefighterName = "Test Bombero"
        startDate = "01/02/2026"
        endDate = "05/02/2026"
        reason = "Vacaciones de prueba"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://taizxujpxyutpjcworti.supabase.co/functions/v1/send-email" -Method POST -Headers $headers -Body $body
```

Si todo funciona, deberías recibir un email en la dirección que especificaste.

## 🔍 Paso 5: Ver Logs

```powershell
supabase functions logs send-email --project-ref taizxujpxyutpjcworti
```

## 🧪 Paso 6: Probar desde Flutter

1. Compila y ejecuta tu app Flutter Web
   ```powershell
   flutter run -d chrome
   ```

2. Intenta crear un permiso desde la interfaz
3. Deberías recibir emails tanto al solicitante como a los oficiales

## ⚠️ Troubleshooting

### Error: "Function not found"
- Verifica que la función esté deployada: `supabase functions list --project-ref taizxujpxyutpjcworti`
- Re-deploy: `supabase functions deploy send-email --project-ref taizxujpxyutpjcworti`

### Error: "RESEND_API_KEY not found"
- Verifica los secrets: `supabase secrets list --project-ref taizxujpxyutpjcworti`
- Vuelve a configurar el secret como se indicó en Paso 2

### Error 401: "Unauthorized"
- Verifica que el token usado en los headers sea el `supabaseAnonKey` correcto
- El token debe venir del login de la app

### Los emails no llegan
- Verifica los logs: `supabase functions logs send-email`
- Revisa que el API key de Resend sea válido
- Verifica que el dominio `notificaciones@sextacoquimbo.cl` esté verificado en Resend

## 📝 Notas Importantes

1. **CORS**: La Edge Function ya tiene CORS configurado para permitir llamadas desde tu app web
2. **Autenticación**: La función valida el JWT de Supabase automáticamente
3. **Rate Limiting**: Resend tiene límites de envío. En el plan gratuito: 100 emails/día

## 🔄 Actualizar la Función

Si haces cambios en `supabase/functions/send-email/index.ts`:

```powershell
supabase functions deploy send-email --project-ref taizxujpxyutpjcworti
```

Los cambios se aplican inmediatamente sin downtime.
