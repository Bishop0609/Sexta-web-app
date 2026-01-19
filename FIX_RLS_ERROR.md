# 🚨 SOLUCIÓN RÁPIDA: Error "Usuario Autenticado"

## ❌ Problema

Estás viendo el error "usuario autenticado" porque **Row Level Security (RLS) está habilitado** en las tablas de Supabase y está bloqueando todas las operaciones.

---

## ✅ Solución (5 minutos)

### Paso 1: Ir a Supabase Dashboard

1. Abrir: https://supabase.com/dashboard
2. Login con tu cuenta
3. Seleccionar tu proyecto

---

### Paso 2: Abrir SQL Editor

1. Panel lateral → Click en **"SQL Editor"**
2. Click en **"+ New query"**

---

### Paso 3: Ejecutar Script para Deshabilitar RLS

**Copiar y pegar el contenido COMPLETO de:**
```
c:\Sexta_app\supabase_make_public.sql
```

**O copiar esto:**

```sql
-- Deshabilitar RLS en TODAS las tablas
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE auth_credentials DISABLE ROW LEVEL SECURITY;
ALTER TABLE act_types DISABLE ROW LEVEL SECURITY;
ALTER TABLE permissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_events DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_configurations DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_registrations DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_attendance DISABLE ROW LEVEL SECURITY;

-- Verificar que RLS está deshabilitada
SELECT 
  tablename,
  rowsecurity as "RLS"
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN (
    'users',
    'auth_credentials',
    'act_types', 
    'permissions', 
    'attendance_events',
    'attendance_records',
    'shift_configurations',
    'shift_registrations',
    'shift_attendance'
  )
ORDER BY tablename;
```

---

### Paso 4: Ejecutar

1. Click en **"Run"** o presionar **Ctrl+Enter**
2. Esperar resultado

**Resultado esperado:**

Una tabla mostrando todas las tablas con `RLS = false`

```
tablename              | RLS
-----------------------+-------
act_types              | false
attendance_events      | false
attendance_records     | false
auth_credentials       | false
permissions            | false
shift_attendance       | false
shift_configurations   | false
shift_registrations    | false
users                  | false
```

✅ Si ves `false` en todas, está listo!

---

### Paso 5: Refrescar la App

1. Ir a tu app en Chrome (donde está corriendo)
2. Presionar **F5** (refresh)
3. **Probar nuevamente:**
   - Login
   - Crear permiso
   - Tomar asistencia

**Ahora debería funcionar sin error "usuario autenticado"**

---

## 🔍 Verificación

**Si aún no funciona, verificar en consola del navegador (F12):**

1. Abrir DevTools (F12)
2. Ir a pestaña "Console"
3. Buscar errores rojos
4. **Errores comunes:**
   - `JWT expired` → Hacer logout y login de nuevo
   - `CORS error` → Verificar allowed origins en Supabase
   - `relation does not exist` → Tabla no existe en BD

---

## ⚠️ IMPORTANTE

**Esto es para DESARROLLO/TESTING solamente.**

RLS deshabilitado significa que:
- ✅ Todas las operaciones funcionan
- ❌ No hay control de acceso a nivel de base de datos
- ⚠️ Cualquier usuario puede ver/modificar cualquier dato

**Para PRODUCCIÓN REAL:**
- Necesitarás crear políticas de RLS apropiadas
- O mantener RLS deshabilitado si es app interna de confianza

---

## 📞 Si Persiste el Error

**Probar esto:**

```sql
-- Ver si hay políticas activas que estén bloqueando
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  cmd as command,
  qual
FROM pg_policies
WHERE schemaname = 'public';

-- Si aparecen políticas, eliminarlas:
DROP POLICY IF EXISTS "policy_name" ON table_name;
```

---

**¡Ejecuta el script SQL y deberías estar listo!** 🚀
