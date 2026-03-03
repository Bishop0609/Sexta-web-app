# Sistema de Gestión Integral - Sexta Compañía

ERP web para bomberos construido con Flutter, Supabase, y Riverpod.

## 🚀 Stack Tecnológico

- **Frontend:** Flutter Web
- **Backend:** Supabase (PostgreSQL)
- **Estado:** Riverpod
- **Email:** Brevo API (300 emails/día gratuitos)
- **Gráficos:** fl_chart
- **PDF:** printing & pdf packages

## 📋 Características

### 10 Módulos Principales:

1. ✅ **Solicitud de Permisos** - Formulario con notificación email
2. ✅ **Gestión de Permisos** - Aprobación/Rechazo (Oficiales)
3. ⏳ **Toma de Asistencia** - Con cross-check automático de licencias
4. ⏳ **Modificar Asistencia** - Solo Admin/Oficiales
5. ⏳ **Configuración Guardia** - Períodos y ventanas
6. ⏳ **Inscripción Guardia** - Validación cupo 6M/4F
7. ⏳ **Generar Rol Guardia** - Algoritmo cumplimiento + PDF
8. ⏳ **Asistencia Guardia** - Check-in y reemplazos
9. ⏳ **Gestión de Usuarios** - CRUD bomberos
10. ⏳ **Configuración Global** - Tipos de Acto (Efectiva/Abono)

### ✅ Dashboard Estadístico:
- **KPI Individual:** Pie chart Efectiva vs Abono
- **Gráfico 6 Meses:** Bar chart comparativo
- **Top 10 Ranking:** Mejores asistencias
- **Semáforo:** Alertas de baja asistencia

## ⚙️ Configuración

### 1. Base de Datos Supabase

1. Crear proyecto en https://supabase.com
2. Ejecutar script SQL:
   ```bash
   # Copiar el contenido de supabase_schema.sql
   # y ejecutarlo en el SQL Editor de Supabase
   ```

3. Obtener credenciales:
   - Project URL
   - Anon Key

### 2. API de Email (Brevo)

1. Crear cuenta en https://app.brevo.com/
2. Obtener API Key desde Settings → SMTP & API → API Keys
3. Verificar dominio sextacoquimbo.cl

### 3. Configurar Variables de Entorno

Editar `lib/core/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'TU_SUPABASE_URL';
static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
static const String brevoApiKey = 'TU_BREVO_API_KEY';
```

O usar variables de entorno al ejecutar:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=tu_url \
  --dart-define=SUPABASE_ANON_KEY=tu_key \
  --dart-define=BREVO_API_KEY=tu_brevo_key
```

### 4. Instalar Dependencias

```bash
flutter pub get
```

### 5. Ejecutar Aplicación

```bash
flutter run -d chrome
```

## 🏗️ Arquitectura del Proyecto

```
lib/
├── core/
│   ├── theme/           # Tema institucional (Red #D32F2F, Navy Blue)
│   ├── constants/       # Configuración y constantes
│   └── utils/           # Utilidades
├── models/              # Data models (Freezed)
│   ├── user_model.dart
│   ├── act_type_model.dart
│   ├── permission_model.dart
│   ├── attendance_*.dart
│   └── shift_*.dart
├── services/            # Lógica de negocio
│   ├── supabase_service.dart      # CRUD y queries
│   ├── email_service.dart         # Brevo API
│   ├── attendance_service.dart    # Cross-check licencias
│   └── shift_service.dart         # Validación cupos 6M/4F
├── providers/           # Riverpod providers (TODO)
├── screens/             # Pantallas (10 módulos + dashboard)
└── widgets/             # Componentes reutilizables
    └── app_drawer.dart  # Drawer con menú role-aware
```

## 🔐 Roles y Permisos

- **Admin:** Acceso completo
- **Officer:** Gestión permisos, guardias, modificar asistencia
- **Firefighter:** Solicitar permisos, tomar asistencia, inscribir guardia

## 📊 Lógica Crítica de Asistencia

### Categorización (Efectiva vs Abono)

Cada `act_type` tiene una categoría en BD:
- **EFECTIVA:** Cuenta para obligación legal (Incendios, Rescates, Academia)
- **ABONO:** Cuenta como extra/compensación (Capacitaciones, Servicios Especiales)

Las estadísticas **siempre separan** estos dos conceptos automáticamente mediante joins con `act_types`.

### Cross-Check Automático de Licencias

Al tomar asistencia (Módulo 3):
1. Se carga lista de todos los bomberos
2. Para cada usuario, se verifica si tiene permiso **aprobado** vigente
3. Si tiene licencia → Pre-marca "Licencia" + bloquea edición con candado
4. Solo Admin puede override registros bloqueados

### Validación Cupo de Guardia

Al inscribirse (Módulo 6):
1. Se cuenta registros existentes por género para esa fecha
2. **Hombres:** Máximo 6 por noche
3. **Mujeres:** Máximo 4 por noche  
4. Si se supera → Error, bloquea inscripción

Implementado en:
- Frontend: `ShiftService.validateShiftRegistration()`
- Backend: Trigger SQL `validate_shift_quota()`

### Cumplimiento de Guardias

Algoritmo (Módulo 7):
- **Solteros:** Deben tomar 2 guardias/semana
- **Casados:** Deben tomar 1 guardia/semana

Se calcula promedio semanal y se muestra con indicadores visuales.

## 🧪 Testing

```bash
# Análisis estático
flutter analyze

# Tests (TODO)
flutter test
```

## 📝 Próximos Pasos

1. ⏳ Resolver issue de build_runner con freezed
2. ⏳ Implementar Módulos 3-10 completos
3. ⏳ Crear Riverpod providers
4. ⏳ Implementar autenticación completa
5. ⏳ Testing end-to-end
6. ⏳ Deploy a producción

## 📄 Licencia

Uso interno Sexta Compañía

---

**Desarrollado para la Sexta Compañía de Bomberos**
