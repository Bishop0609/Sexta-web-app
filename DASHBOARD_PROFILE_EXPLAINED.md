# 📊 Explicación: Dashboard Principal vs Mi Perfil

## 🏠 DASHBOARD PRINCIPAL (Pantalla de Inicio)
**Ubicación:** `lib/screens/dashboard/dashboard_screen.dart`

### ¿Qué muestra?

#### 1️⃣ **"Mi Desempeño"** (Datos PERSONALES del usuario logueado)
- **Gráfico de torta** con tus asistencias:
  - % Lista Efectiva (ej: incendios, rescates)
  - % Abonos (ej: capacitaciones, ceremonias)
- **Conteo total** de asistencias registradas

#### 2️⃣ **"Asistencia Compañía - Últimos 6 Meses"** (Datos GENERALES de toda la compañía)
- **Gráfico de barras** mostrando asistencias por mes de TODOS los bomberos
- Dos barras por mes: Efectiva (verde) y Abono (azul)

#### 3️⃣ **"Top 10 Asistencia"** (Ranking GENERAL)
- Lista de los 10 bomberos con mejor % de asistencia
- Visible para TODOS los usuarios

#### 4️⃣ **"Alertas de Asistencia"** (Solo Admin/Oficiales) ⚠️
- Lista de bomberos con baja asistencia (<70%)
- **BLOQUEADO para Bomberos normales** - muestra mensaje "Esta sección está disponible solo para oficiales"

### ⏱️ ¿Por qué es LENTO?

El Dashboard hace **5 consultas a la base de datos**:

1. ✅ `getUserProfile(userId)` - RÁPIDA
2. ✅ `calculateIndividualStats(userId)` - RÁPIDA
3. ❌ `calculateCompanyMonthlyStats()` - **MUY LENTA** (descarga todos los eventos y los procesa en el celular)
4. ✅ `getAttendanceRanking()` - RÁPIDA (usa RPC)
5. ❌ `getLowAttendanceAlerts()` - **EXTREMADAMENTE LENTA** (itera TODOS los usuarios uno por uno)

**Problema principal:** Las consultas #3 y #5 procesan datos en el cliente (Flutter) en lugar de en el servidor (Supabase).

---

## 👤 MI PERFIL
**Ubicación:** `lib/screens/profile/profile_screen.dart`

### ¿Qué debería mostrar?

#### 1️⃣ **Datos Personales**
- Nombre Completo
- RUT
- Número Victor
- Registro Compañía
- Cargo
- Email
- Estado Civil
- Género
- Rol (Admin/Oficial/Bombero)

#### 2️⃣ **Mis Estadísticas**
- Mismo gráfico de torta que en Dashboard
- Solo datos PERSONALES del usuario

#### 3️⃣ **Historial de Asistencias** (últimas 20)
- Fecha del acto
- Tipo de acto (Incendio, Rescate, etc.)
- Estado (Presente, Ausente, Licencia)

#### 4️⃣ **Mis Permisos**
- Todas las solicitudes de permiso (aprobadas, rechazadas, pendientes)
- Con fechas y motivos

### 🐛 ¿Por qué NO FUNCIONA?

El Perfil hace **4 consultas en paralelo**:

1. ✅ `getUserProfile(userId)` - OK
2. ✅ `calculateIndividualStats(userId)` - OK
3. ❌ `getUserAttendanceHistory(userId, 20)` - **FALLA** ←  ESTE ES EL PROBLEMA
4. ✅ `getPermissionsByUser(userId)` - OK

**Error probable:** La query de `getUserAttendanceHistory` tiene un problema con el `order()` en SQL. Intenta ordenar por `event.event_date` pero la sintaxis no es válida en Supabase.

---

## 🔧 SOLUCIÓN PROPUESTA

### Para el Dashboard (Lentitud):
1. **Ya creaste el RPC** `get_monthly_stats` - SOLO FALTA EJECUTARLO en Supabase
2. Después actualizar el código Flutter para usarlo

### Para Mi Perfil (Error):
1. Arreglar la query de `getUserAttendanceHistory` en `attendance_service.dart`
2. Cambiar `.order('event.event_date')` por una sintaxis válida

---

## 📝 RESUMEN RÁPIDO

| Pantalla | Muestra | Problema Actual |
|----------|---------|----------------|
| **Dashboard** | Datos míos + datos de compañía + ranking | LENTO (consultas no optimizadas) |
| **Mi Perfil** | Solo datos míos + historial + permisos | NO CARGA (error en query SQL) |
