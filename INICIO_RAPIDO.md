# 🚀 Guía de Inicio Rápido

## Paso 1: Ejecutar Script de Datos de Prueba

1. Ve a tu proyecto Supabase: https://supabase.com/dashboard
2. Navega a **SQL Editor**
3. Click en **New Query**
4. Copia y pega el contenido de `supabase_test_data.sql`
5. Click en **Run** (o presiona Ctrl+Enter)

**Datos creados:**
- ✅ 15 usuarios (1 admin, 2 oficiales, 12 bomberos)
- ✅ 7 tipos de acto (4 Efectiva, 3 Abono)
- ✅ 3 permisos (1 pendiente, 1 aprobado, 1 rechazado)
- ✅ 3 eventos de asistencia con registros
- ✅ 2 configuraciones de guardia
- ✅ 6 inscripciones de guardia para hoy

---

## Paso 2: Usuarios de Prueba

Dado que no tenemos autenticación implementada aún, puedes simular diferentes usuarios cambiando el `currentUserId` en el código temporalmente.

### Credenciales (para futuro login):

**Admin:**
- Email: `admin@sexta.cl`
- Nombre: Juan Pérez González
- RUT: 12345678-9

**Oficial:**
- Email: `maria@sexta.cl`
- Nombre: María Rodriguez Silva
- RUT: 23456789-0

**Bombero:**
- Email: `ana@sexta.cl`
- Nombre: Ana Martínez Cruz
- RUT: 45678901-2

---

## Paso 3: Probar Módulos

### 📊 Dashboard
1. Navega a `/` (home)
2. Verás:
   - KPI individual (pie chart Efectiva vs Abono)
   - Gráfico últimos 6 meses
   - Top 10 ranking
   - Alertas de baja asistencia

### 🔧 Tipos de Acto (Módulo 10)
1. Navega a `/act-types`
2. Deberías ver 7 tipos creados
3. Prueba crear uno nuevo:
   - Nombre: "Ceremonia"
   - Categoría: **ABONO** ⭐
   - Guardar

**Concepto clave:** 
- **EFECTIVA** = Cuenta para obligación legal
- **ABONO** = Extra/Compensación

### ✏️ Tomar Asistencia (Módulo 3) ⭐
1. Navega a `/take-attendance`
2. Selecciona fecha: **08/01/2026** (hay permiso aprobado este día)
3. Selecciona tipo: **Incendio**
4. Click "Cargar Lista de Asistencia"
5. **Observa:** Pedro Fernández Rojas aparecerá con:
   - Estado: **Licencia** 🔒
   - Candado bloqueado
   - No se puede editar

**Esto es el auto-crosscheck en acción!**

6. Cambia otros bomberos a Presente/Ausente con el switch
7. Click "Guardar Asistencia"

### 📅 Inscribir Guardia (Módulo 6) ⭐
1. Navega a `/shift-registration`
2. Selecciona período: **Enero 2026**
3. En el calendario, haz click en **HOY**
4. Verás:
   - Barras de cupo: Hombres 4/6, Mujeres 2/4
   - Lista de inscritos (6 bomberos ya registrados)
5. Intenta inscribirte (se validará el cupo)

**Prueba el límite:**
- Inscribe más hombres hasta llegar a 6/6
- Intenta inscribir un 7mo → Verás error "Cupo completo"

### 📝 Solicitar Permiso (Módulo 1)
1. Navega a `/request-permission`
2. Completa:
   - Fecha inicio: mañana
   - Fecha fin: pasado mañana
   - Motivo: "Examen médico"
3. Submit
4. Se enviará email a oficiales (si configuraste Resend)

### ✅ Gestionar Permisos (Módulo 2)
1. Navega a `/manage-permissions`
2. Verás 1 permiso pendiente (Ana Martínez)
3. Click ✅ para aprobar o ❌ para rechazar
4. Se enviará email al bombero

---

## Paso 4: Verificar Estadísticas

### Dashboard debe mostrar:
- **Individual KPI**: Porcentajes basados en eventos pasados
- **Gráfico 6 meses**: Barras separadas Efectiva (verde) vs Abono (azul)
- **Ranking**: Ordenado por % asistencia
- **Alertas**: Bomberos con < 70% asistencia

---

## 🔍 Tips de Debugging

### Ver datos en Supabase:
1. Ve a **Table Editor**
2. Navega entre tablas:
   - `users` → Ver todos los bomberos
   - `permissions` → Ver solicitudes
   - `attendance_records` → Ver asistencias
   - `shift_registrations` → Ver guardias

### Row Level Security (RLS):
Las políticas RLS están activas. Si no ves datos, verifica que el `currentUserId` esté configurado correctamente en `SupabaseService`.

**Tip:** Para testing, puedes desactivar RLS temporalmente:
```sql
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- Repetir para otras tablas
```

### Errores comunes:
- **"No data"**: Verifica que `supabase_test_data.sql` se ejecutó correctamente
- **"Permission denied"**: Problema de RLS, verifica user_id actual
- **Email no envía**: Verifica `RESEND_API_KEY` en `app_constants.dart`

---

## 📝 Próximos Pasos

1. ✅ Probar módulos existentes con datos de prueba
2. ⏳ Implementar login/autenticación
3. ⏳ Completar módulos 4, 5, 7, 8, 9 (patrón en `GUIA_MODULOS.md`)
4. ⏳ Ajustar RLS policies según necesidades
5. ⏳ Personalizar emails en `email_service.dart`

---

## 🎯 Funcionalidades Críticas Implementadas

✅ **Auto-crosscheck de Licencias** → Módulo 3
- Verifica permisos aprobados automáticamente
- Bloquea registros con candado 🔒

✅ **Validación Cupo Género** → Módulo 6
- Máximo 6 Hombres / 4 Mujeres por guardia
- Validación dual: Frontend + Trigger SQL

✅ **Categorización Efectiva/Abono** → Módulo 10
- Separa automáticamente en todas las estadísticas
- Gráficos y KPIs diferenciados

---

**¿Dudas?** Revisa `README.md` y `GUIA_MODULOS.md` para más detalles.
