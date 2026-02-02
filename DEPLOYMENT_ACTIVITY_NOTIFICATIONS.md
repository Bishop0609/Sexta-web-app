# Guía de Despliegue: Sistema de Notificaciones para Actividades

## 📋 Resumen

Este documento describe los pasos para desplegar el sistema completo de notificaciones por email para actividades.

---

## ✅ Pre-requisitos

Antes de comenzar, aseg rate de tener:

1. ✅ Cuenta de Supabase con proyecto activo
2. ✅ API Key de Resend configurada (`RESEND_API_KEY`)
3. ✅ Supabase CLI install instalado: `npm install -g supabase`
4. ✅ Acceso a la terminal/PowerShell

---

## 🚀 Paso 1: Verificar Tablas de Base de Datos

Asegúrate de que estas tablas existan:

```sql
-- Verificar tabla activities
SELECT * FROM activities LIMIT 1;

-- Verificar tabla sent_reminders
SELECT * FROM sent_reminders LIMIT 1;
```

Si `sent_reminders` no existe, ejecuta:

```bash
supabase db push supabase_email_notifications.sql
```

O desde el SQL Editor en Supabase Dashboard, ejecuta el contenido de `supabase_email_notifications.sql`.

---

## 🚀 Paso 2: Desplegar Edge Functions

### 2.1 Iniciar sesión en Supabase CLI

```powershell
supabase login
```

### 2.2 Vincular tu proyecto

```powershell
# Reemplaza [PROJECT_REF] con tu referencia de proyecto
supabase link --project-ref [PROJECT_REF]
```

Puedes encontrar tu `PROJECT_REF` en: Supabase Dashboard > Settings > API > Project URL

Ejemplo: Si tu URL es `https://abcdefgh.supabase.co`, tu PROJECT_REF es `abcdefgh`

### 2.3 Desplegar función `send-email` (actualizada)

```powershell
cd c:\Sexta_app
supabase functions deploy send-email
```

**Salida esperada**:
```
Deploying send-email (project ref: [PROJECT_REF])
...
Deployed send-email successfully ✓
```

### 2.4 Desplegar función `send-activity-reminders` (nueva)

```powershell
supabase functions deploy send-activity-reminders
```

**Salida esperada**:
```
Deploying send-activity-reminders (project ref: [PROJECT_REF])
...
Deployed send-activity-reminders successfully ✓
```

### 2.5 Verificar que las funciones estén activas

Ve a: Supabase Dashboard > Edge Functions

Deberías ver:
- ✅ `send-email` (updated)
- ✅ `send-activity-reminders` (new)

---

## 🚀 Paso 3: Configurar Variables de Entorno

Las Edge Functions necesitan estas variables:

1. Ve a: Supabase Dashboard > Settings > Edge Functions
2. Verifica que existan:
   - ✅ `RESEND_API_KEY` = tu API key de Resend
   - ✅ `SUPABASE_URL` = (automático)
   - ✅ `SUPABASE_SERVICE_ROLE_KEY` = (automático)

Si falta `RESEND_API_KEY`, agrégala manualmente.

---

## 🚀 Paso 4: Configurar Cron Job

### 4.1 Obtener Service Role Key

1. Ve a: Supabase Dashboard > Settings > API
2. Copia el `service_role` key (secret)

### 4.2 Obtener Project Ref

Tu Project URL es: `https://[PROJECT_REF].supabase.co`

Extrae `[PROJECT_REF]` de ahí.

### 4.3 Ejecutar SQL para configurar cron

1. Abre `supabase_activity_reminders_cron.sql`
2. Reemplaza `[PROJECT_REF]` con tu valor real
3. Ve a: Supabase Dashboard > SQL Editor
4. Pega y ejecuta el SQL

**IMPORTANTE**: Primero configura el service role key:

```sql
ALTER DATABASE postgres SET app.settings.service_role_key = 'tu-service-role-key-aqui';
```

Luego ejecuta la creación del cron:

```sql
SELECT cron.schedule(
  'send-activity-reminders',
  '0 11,18,23 * * *',
  $$
  SELECT net.http_post(
    url := 'https://TU-PROJECT-REF.supabase.co/functions/v1/send-activity-reminders',
    headers := jsonb_build_object(
      'Authorization', 
      'Bearer ' || current_setting('app.settings.service_role_key')
    )
  );
  $$
);
```

### 4.4 Verificar que el cron esté activo

```sql
SELECT * FROM cron.job WHERE jobname = 'send-activity-reminders';
```

Deberías ver una fila con:
- `jobname`: send-activity-reminders
- `schedule`: 0 11,18,23 * * *
- `active`: true

---

## 🚀 Paso 5: Probar el Sistema

### 5.1 Probar notificaciones inmediatas

1. En la app Flutter, crea una nueva actividad
2. Marca ✅ "Enviar ahora"
3. Selecciona "Todos los bomberos"
4. Guarda

**Verificación**:
- Los usuarios deben recibir un email inmediatamente
- Revisa los logs: Supabase Dashboard > Edge Functions > send-email > Logs

### 5.2 Probar recordatorios automáticos (manual)

Puedes invocar la función manualmente para probar:

```powershell
curl -X POST https://TU-PROJECT-REF.supabase.co/functions/v1/send-activity-reminders `
  -H "Authorization: Bearer TU-SERVICE-ROLE-KEY"
```

**Verificación**:
- Revisa los logs: Edge Functions > send-activity-reminders > Logs
- Deberías ver: "Buscando actividades para recordatorios..."

### 5.3 Probar recordatorios reales (con actividad programada)

1. Crea una actividad para dentro de 25 horas
2. Marca ✅ "Recordatorio 24h"
3. Espera a que el cron se ejecute (próxima ejecución: 11:00, 18:00 o 23:00 UTC)

**Verificación**:
- Revisa `sent_reminders`:
  ```sql
  SELECT * FROM sent_reminders ORDER BY sent_at DESC LIMIT 10;
  ```
- Deberías ver un registro con `reminder_type = 'activity_24h'`

---

## 🚀 Paso 6: Desplegar App Flutter

Si hiciste cambios en el código Flutter (`manage_activities_screen.dart`):

```powershell
cd c:\Sexta_app
flutter build apk  # Para Android
# o
flutter build ios  # Para iOS
```

Luego distribuye la nueva versión a los usuarios.

---

## 📊 Monitoreo y Logs

### Ver logs de Edge Functions

```powershell
# Logs de send-email
supabase functions logs send-email

# Logs de send-activity-reminders
supabase functions logs send-activity-reminders
```

O desde el Dashboard: Edge Functions > [nombre] > Logs

### Ver historial del cron

```sql
SELECT * FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-activity-reminders')
ORDER BY start_time DESC 
LIMIT 20;
```

### Ver recordatorios enviados

```sql
SELECT * FROM sent_reminders 
ORDER BY sent_at DESC 
LIMIT 50;
```

---

## 🔧 Troubleshooting

### Problema: Los emails no se envían

**Solución**:
1. Verifica que `RESEND_API_KEY` esté configurada
2. Revisa los logs de `send-email`
3. Verifica que los usuarios tengan emails válidos

### Problema: El cron no se ejecuta

**Solución**:
1. Verifica que el cron esté activo:
   ```sql
   SELECT * FROM cron.job WHERE jobname = 'send-activity-reminders';
   ```
2. Revisa el historial:
   ```sql
   SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 5;
   ```
3. Verifica que el service role key esté configurado:
   ```sql
   SELECT current_setting('app.settings.service_role_key');
   ```

### Problema: Se envían duplicados

**Solución**:
- Verifica la restricción UNIQUE en `sent_reminders`:
  ```sql
  SELECT * FROM information_schema.table_constraints 
  WHERE table_name = 'sent_reminders' AND constraint_type = 'UNIQUE';
  ```
- Debería haber una restricción en `(reminder_type, reference_id)`

---

## ✅ Checklist Final

- [ ] Tablas `activities` y `sent_reminders` existen
- [ ] Edge Function `send-email` desplegada
- [ ] Edge Function `send-activity-reminders` desplegada
- [ ] Variables de entorno configuradas
- [ ] Cron job creado y activo
- [ ] Probado con actividad de prueba
- [ ] Logs muestran ejecuciones exitosas
- [ ] App Flutter actualizada (si corresponde)

---

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs primero
2. Verifica la configuración paso a paso
3. Consulta la documentación de Supabase: https://supabase.com/docs
