# 🔐 Guía de Configuración de Autenticación

## ✅ Cambios Realizados

### 1. **main.dart** - Corregido
- ✅ Cambiado de Service Role Key a **Anon Key** (seguro)
- ✅ Inicializa `AuthService` completo con sistema de contraseñas

### 2. **login_screen.dart** - Mejorado
- ✅ Login con RUT + Contraseña
- ✅ Botón "¿Olvidaste tu contraseña?" agregado
- ✅ Muestra información de contacto con administrador

### 3. **change_password_screen.dart** - Funcional
- ✅ Flujo de cambio de contraseña obligatorio
- ✅ Validación de requisitos de seguridad
- ✅ Navegación automática al dashboard después de cambiar

### 4. **Sistema de Passwords** - Implementado
- ✅ Password genérica: `Bombero2024!`
- ✅ Hash generado correctamente compatible con AuthService
- ✅ Script SQL creado: `supabase_setup_passwords.sql`

---

## 📋 Pasos para Activar el Sistema

### Paso 1: Ejecutar SQL en Supabase

1. **Ir a Supabase Dashboard**
   - URL: https://supabase.com/dashboard
   - Login con tu cuenta
   - Seleccionar proyecto: `taizxujpxyutpjcworti`

2. **Abrir SQL Editor**
   - Panel lateral → Click en "SQL Editor"
   - Click en "+ New query"

3. **Copiar y pegar el contenido de:**
   ```
   c:\Sexta_app\supabase_setup_passwords.sql
   ```

4. **Ejecutar el script**
   - Click en "Run" o presionar Ctrl+Enter
   - Esperar que termine (debería tomar ~1 segundo)

5. **Verificar resultado**
   - Deberías ver tablas con:
     - Lista de usuarios SIN credenciales (antes)
     - Lista de usuarios CON credenciales (después)
     - Resumen final

**Resultado esperado:**
```
✅ Script ejecutado correctamente - Password genérica: Bombero2024!
```

---

### Paso 2: Probar el Login Localmente

#### A. Iniciar la aplicación

```powershell
# En PowerShell
cd c:\Sexta_app
flutter run -d chrome
```

#### B. Abrir en navegador
- Automáticamente abrirá Chrome
- O manualmente: `http://localhost:XXXXX/login`

#### C. Probar login con usuario de prueba

**Credenciales de prueba:**
- **RUT:** (cualquier RUT de tu base de datos)
- **Password:** `Bombero2024!`

**Ejemplo con admin:**
- RUT: `12345678-9`
- Password: `Bombero2024!`

#### D. Flujo esperado:

1. ✅ Ingresar RUT y password
2. ✅ Click "INGRESAR"
3. ✅ **Redirige automáticamente a `/change-password`**
4. ✅ Pantalla "Cambiar Contraseña" aparece
5. ✅ Campos:
   - Contraseña Temporal: `Bombero2024!`
   - Nueva Contraseña: (tu nueva contraseña)
   - Confirmar: (repetir nueva contraseña)
6. ✅ Click "CAMBIAR CONTRASEÑA"
7. ✅ Mensaje de éxito
8. ✅ Redirige a Dashboard `/`

---

### Paso 3: Verificar Funcionalidad Completa

#### Checklist de Pruebas:

**Login:**
- [ ] Login con RUT + password funciona
- [ ] Login con password incorrecta muestra error
- [ ] Login con RUT inexistente muestra error
- [ ] Botón "¿Olvidaste tu contraseña?" muestra diálogo

**Cambio de Contraseña:**
- [ ] Redirige automáticamente después de primer login
- [ ] Validaciones funcionan (min 8 chars, mayúscula, número, especial)
- [ ] Password temporal incorrecta muestra error
- [ ] Contraseñas no coincidentes muestra error
- [ ] Cambio exitoso redirige a dashboard

**Sesión:**
- [ ] Sesión se mantiene después de refresh (F5)
- [ ] Drawer muestra nombre de usuario correcto
- [ ] Logout funciona
- [ ] Después de logout, redirige a /login

**Módulos:**
- [ ] Crear permiso funciona (sin error de autenticación)
- [ ] Tomar asistencia funciona
- [ ] Inscribir guardia funciona
- [ ] Todos los módulos guardan datos correctamente

---

## 🔑 Información de Passwords

### Password Genérica (Temporal)
```
Bombero2024!
```

**Características:**
- ✅ Cumple todos los requisitos de seguridad
- ✅ Fácil de recordar y comunicar
- ✅ Forzar cambio en primer login
- ✅ No se puede reusar como nueva contraseña

### Requisitos para Nueva Contraseña

Los usuarios deberán crear una contraseña que cumpla:
- Mínimo 8 caracteres
- Al menos 1 letra mayúscula
- Al menos 1 número  
- Al menos 1 carácter especial (!@#$%&*)

**Ejemplos válidos:**
- `Sexta2026!`
- `Bombero#2026`
- `MiClave$123`

---

## 🚨 Troubleshooting

### Problema: "RUT no encontrado"

**Causa:** El RUT no existe en la base de datos o formato incorrecto

**Solución:**
1. Verificar en Supabase → Table Editor → users
2. Buscar el RUT exacto
3. Formato debe ser: `12345678-9` (con guión)

---

### Problema: "Contraseña incorrecta"

**Causa:** 
- Password genérica no fue creada en BD
- Hash no coincide

**Solución:**
1. Verificar que ejecutaste `supabase_setup_passwords.sql`
2. En SQL Editor, ejecutar:
   ```sql
   SELECT u.rut, u.full_name, ac.password_hash 
   FROM users u
   JOIN auth_credentials ac ON u.id = ac.user_id
   LIMIT 5;
   ```
3. Verificar que password_hash empieza con: `BomberoSalt2024...`

---

### Problema: "No redirige a cambio de contraseña"

**Causa:** Campo `requires_password_change` no está en `true`

**Solución:**
```sql
UPDATE auth_credentials
SET requires_password_change = true
WHERE user_id IN (SELECT id FROM users WHERE rut = '12345678-9');
```

---

### Problema: Error "Usuario sin credenciales configuradas"

**Causa:** La tabla `auth_credentials` no tiene registro para ese usuario

**Solución:**
```sql
-- Verificar usuarios sin credenciales
SELECT u.* FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
WHERE ac.user_id IS NULL;

-- Ejecutar nuevamente el script de passwords
```

---

## 📊 Verificación en Base de Datos

### Ver todos los usuarios con credenciales:

```sql
SELECT 
  u.full_name,
  u.rut,
  u.role,
  u.email,
  CASE 
    WHEN ac.user_id IS NOT NULL THEN '✅ Tiene password'
    ELSE '❌ Sin password'
  END as estado,
  ac.requires_password_change as debe_cambiar
FROM users u
LEFT JOIN auth_credentials ac ON u.id = ac.user_id
ORDER BY u.full_name;
```

### Ver si RLS está deshabilitado (debe estarlo):

```sql
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('users', 'auth_credentials', 'permissions', 'attendance_records')
AND schemaname = 'public';
```

**Resultado esperado:** Todas las tablas con `rowsecurity = false`

---

## 🎯 Próximos Pasos

Una vez que el login funcione correctamente:

1. **Testing exhaustivo**
   - Probar cada módulo
   - Verificar que datos se guarden
   - Probar con diferentes roles (admin, officer, firefighter)

2. **Preparar deployment**
   - Ejecutar `build-deploy.ps1`
   - Subir a iHost.cl
   - Probar en `https://sgi.sextacoquimbo.cl`

3. **Comunicar a usuarios**
   - Informar RUT de cada bombero
   - Comunicar password genérica: `Bombero2024!`
   - Explicar que deben cambiarla al primer login

---

## 📞 Soporte

Si encuentras problemas:

1. **Revisar consola del navegador** (F12 → Console)
2. **Revisar logs en terminal** donde corre `flutter run`
3. **Verificar Supabase Dashboard** → Logs

---

**¡Sistema de autenticación completo listo para probar!** 🚀
