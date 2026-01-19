# Guía de Implementación Módulos 3-10

Esta guía te explica el patrón para implementar los módulos restantes basándote en los ejemplos ya creados.

## ✅ Módulos Ya Implementados

###  Módulo 1: Solicitud de Permisos ✅
- Formulario con date pickers
- Validación
- Guardado en BD
- Email a oficiales

### Módulo 2: Gestión de Permisos ✅  
- Lista de solicitudes pendientes
- Botones aprobar/rechazar
- Email al bombero

### Módulo 3: Tomar Asistencia ✅
**LÓGICA CRÍTICA IMPLEMENTADA:**
- Auto-crosscheck de licencias aprobadas
- DataTable densa con switch toggles
- Registros bloqueados con🔒
- Indicadores visuales de estado

### Módulo 6: Inscripción Guardia ✅
**LÓGICA CRÍTICA IMPLEMENTADA:**
- Calendario con table_calendar
- Validación cupo 6M/4F
- Barras de progreso de cupo

---

## ⏳ Módulos Restantes (Patrón de Implementación)

### Módulo 4: Modificar Asistencia

**Patrón:**
```dart
1. Lista de eventos pasados (getAttendanceEvents())
2. Al hacer clic → Cargar attendanceRecords de ese evento
3. Mostrar tabla editable (similar a Módulo 3)
4. Validación: Solo Officer/Admin puede editar
5. Validación: Solo Admin puede modificar registros con isLocked=true
6. Usar: attendanceService.updateAttendanceRecord()
```

**UI Sugerida:**
- Card con lista de eventos (fecha + tipo de acto)
- Al seleccionar evento → Mostrar DataTable editable
- Switch para cambiar present/absent
- Advertencia si intenta editar registro bloqueado

---

### Módulo 5: Configuración Guardia

**Patrón:**
```dart
1. CRUD simple de shift_configurations
2. Form con:
   - period_name (TextField)
   - start_date, end_date (DatePickers)
   - registration_start, registration_end (DatePickers)
3. Validación: end_date >= start_date
4. Lista de configuraciones existentes con botones Editar/Eliminar
```

**UI Sugerida:**
- Card con formulario arriba
- DataTable con configs abajo
- Botones: Crear, Editar, Eliminar

---

### Módulo 7: Generar Rol de Guardia

**Patrón:**
```dart
1. Selector de shift_configuration
2. Selector de semana (DatePicker)
3. Botón "Calcular Cumplimiento"
   - Llama shiftService.calculateShiftCompliance()
   - Muestra tabla con:
     * Nombre
     * Estado civil
     * Requerido (2 o 1/semana)
     * Promedio actual
     * ✅/⚠️ cumple/no cumple
4. Botón "Generar PDF"
   - Llama shiftService.generateShiftSchedulePDF()
   - Abre vista de impresión
```

**UI Sugerida:**
- Card superior: Selectors + Botón calcular
- Card medio: Tabla de cumplimiento con colores
- Card inferior: Botón PDF + preview

---

### Módulo 8: Asistencia Guardia

**Patrón:**
```dart
1. Selector de fecha (default: hoy)
2. Mostrar roster de guardia para esa fecha
   - shiftService.getShiftAttendance(date)
3. CheckIn de cada bombero (checkbox)
4. Botón "Agregar Reemplazo":
   - Modal: Seleccionar bomber original + reemplazo
   - shiftService.registerReplacement()
5. Botón "Agregar Extra":
   - TextField: número Victor
   - shiftService.registerExtraFirefighter()
```

**UI Sugerida:**
- Card fecha
- Lista de bomberos con checkbox check-in
- Botones flotantes: "+ Reemplazo", "+ Extra"

---

### Módulo 9: Gestión de Usuarios

**Patrón:**
```dart
1. DataTable con todos los usuarios
2. Botón "Agregar Usuario" → Modal/Screen con form:
   - RUT (TextField con validación)
   - Victor Number (TextField)
  - Full Name
   - Gender (Dropdown: M/F)
   - Marital Status (Dropdown: single/married)
   - Rank (TextField)
   - Role (Dropdown: admin/officer/firefighter)
   - Email
3. Botones Editar/Eliminar por fila
4. CRUD: supabase.createUser(), updateUser(), deleteUser()
```

**UI Sugerida:**
- Botón "+ Nuevo Usuario" arriba
- DataTable densa con acciones
- Dialog para crear/editar

---

### Módulo 10: Configuración Tipos de Acto

**Patrón:**
```dart
1. DataTable con act_types
2. Columnas:
   - Nombre
   - Categoría (badge: Efectiva verde / Abono azul)
   - Activo (checkbox)
   - Acciones
3. Form crear/editar:
   - name (TextField)
   - category (Radio buttons: Efectiva / Abono) ⭐
   - is_active (Switch)
4. CRUD: supabase.createActType(), updateActType(), deleteActType()
```

**UI Sugerida:**
- Form inline arriba para crear
- DataTable abajo para listar
- Badges de color por categoría

---

## 🎨 Patrón UI General

Todos los módulos siguen esta estructura:

```dart
class MyModuleScreen extends StatefulWidget {
  @override
  State<MyModuleScreen> createState() => _MyModuleScreenState();
}

class _MyModuleScreenState extends State<MyModuleScreen> {
  // Services
  final _supabase = SupabaseService();
  final _specificService = SpecificService();
  
  // State
  bool _isLoading = false;
  List<Map<String, dynamic>> _data = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getData();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }
  
  Future<void> _performAction() async {
    // Validaciones
    // Llamar service
    // Mostrar feedback
    // Refresh data
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.criticalColor),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Módulo')),
      drawer: const AppDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Cards con contenido
              ],
            ),
          ),
    );
  }
}
```

---

## 🔑 Servicios Disponibles

Todos estos métodos ya están implementados y listos para usar:

### SupabaseService
```dart
// Users
getAllUsers()
getUserProfile(userId)
createUser(user)
updateUser(userId, updates)
deleteUser(userId)

// Act Types
getAllActTypes()
createActType(actType)
updateActType(id, updates)

// Permissions
getPermissionsByStatus(status)
updatePermissionStatus(id, status, reviewedBy)

// Attendance
createAttendanceEvent(event)
createAttendanceRecords(records)
getAttendanceEvents()
getAttendanceRecordsByEvent(eventId)
updateAttendanceRecord(id, updates)

// Shifts
getShiftConfigurations()
createShiftConfiguration(config)
getShiftRegistrations(configId, date?)
createShiftRegistration(reg)
deleteShiftRegistration(id)
getShiftAttendance(date)
createShiftAttendance(attendance)
```

### AttendanceService
```dart
hasApprovedLicense(userId, date)
prepareAttendanceList(users, date) // ⭐ Auto-crosscheck
createAttendanceEvent(...)
calculateIndividualStats(userId)
calculateCompanyMonthlyStats()
getAttendanceRanking(limit)
getLowAttendanceAlerts(threshold)
```

### ShiftService
```dart
validateShiftRegistration(date, userId) // ⭐ Cupo 6M/4F
registerForShift(configId, userId, date)
calculateShiftCompliance(configId) // ⭐ Algoritmo
generateShiftSchedulePDF(configId, weekStart) // ⭐ PDF
checkInShift(date, userId)
registerReplacement(date, originalId, replacementId)
registerExtraFirefighter(date, userId)
```

### EmailService
```dart
sendPermissionRequestNotification(...)
sendPermissionDecisionNotification(...)
sendShiftAssignmentNotification(...)
```

---

## 📝 Checklist de Implementación

Para cada módulo:

- [ ] Crear StatefulWidget screen
- [ ] Injecctar services necesarios
- [ ] Implementar _loadData() en initState
- [ ] Crear UI con Cards según patrón
- [ ] Implementar acciones (crear, editar, eliminar)
- [ ] Añadir validaciones
- [ ] Mostrar feedback visual (Snackbars)
- [ ] Manejo de loading states
- [ ] Manejo de errores
- [ ] Probar flujo completo

---

## 🚀 Próximos Pasos

1. **Usa los módulos 3 y 6 como referencia** - Cópialos y adáptalos
2. **Empieza por los más simples** - Módulos 4, 5, 9, 10 son CRUD básicos
3. **Luego los complejos** - Módulos 7 y 8 requieren más lógica
4. **Prueba en Chrome** - `flutter run -d chrome`

---

**Todos los servicios críticos ya están implementados. Solo falta conectar la UI! 🎯**
