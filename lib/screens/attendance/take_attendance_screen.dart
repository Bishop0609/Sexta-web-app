import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/services/email_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/models/attendance_record_model.dart';
import 'package:sexta_app/screens/attendance/widgets/attendance_history_tab.dart';
import 'package:intl/intl.dart';

/// Módulo 3: Toma de Asistencia con Auto-Crosscheck de Licencias
class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService();
  final _authService = AuthService();
  final _attendanceService = AttendanceService();
  late TabController _tabController;
  
  UserModel? _currentUser;
  DateTime _selectedDate = DateTime.now();
  String? _selectedActTypeId;
  String? _selectedSubtype;
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _actTypes = [];
  List<Map<String, dynamic>> _attendanceList = [];
  bool _isLoading = false;
  bool _isSaving = false;

  // Modo de asistencia
  String _modoAsistencia = 'manual'; // 'programada' o 'manual'
  List<Map<String, dynamic>> _actividadesProgramadas = [];
  Map<String, dynamic>? _selectedActividadProgramada;
  bool _isLoadingActividades = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _loadActTypes();
    _loadActividadesProgramadas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Mapa de subtipos por tipo de acto
  Map<String, List<String>> get _actSubtypes => {
    'Emergencia': [
      '10-0',
      '10-1',
      '10-2',
      '10-3',
      '10-4',
      '10-5',
      '10-6',
      '10-7',
      '10-8',
      '10-9',
      '10-10',
      '10-11',
      '10-12',
      'INCENDIO',
      '6-16',
      '0-11',
    ],
    'Otra Actividad': [
      'Otra Citación',
      'Trabajo de Comandancia',
      'Trabajo de Compañía',
    ],
  };
  
  Future<void> _loadCurrentUser() async {
    try {
      final userId = _authService.currentUserId;
      if (userId != null) {
        final user = await _supabase.getUserProfile(userId);
        setState(() => _currentUser = user);
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadActTypes() async {
    try {
      final actTypes = await _supabase.getAllActTypes();
      setState(() => _actTypes = actTypes);

      if (_modoAsistencia == 'manual' && _selectedActTypeId == null) {
        final emergencia = _actTypes.firstWhere(
          (t) => t['name'] == 'Emergencia' || t['activity_type_key'] == 'emergencia',
          orElse: () => <String, dynamic>{},
        );
        if (emergencia.isNotEmpty) {
          setState(() => _selectedActTypeId = emergencia['id'] as String);
        }
      }
    } catch (e) {
      _showError('Error cargando tipos de acto: $e');
    }
  }

  Future<void> _loadActividadesProgramadas() async {
    setState(() => _isLoadingActividades = true);
    try {
      final result = await _supabase.client.rpc('get_actividades_futuras_con_permisos');
      final allActividades = List<Map<String, dynamic>>.from(result as List);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final disponibles = allActividades.where((act) {
        final actDateStr = act['activity_date'] as String?;
        if (actDateStr == null) return false;
        final actDate = DateTime.parse(actDateStr);
        final actDay = DateTime(actDate.year, actDate.month, actDate.day);

        if (actDay != today) return false;

        final startTimeStr = act['start_time'] as String?;
        if (startTimeStr != null && startTimeStr.isNotEmpty) {
          final parts = startTimeStr.split(':');
          if (parts.length >= 2) {
            final actDateTime = DateTime(
              actDate.year, actDate.month, actDate.day,
              int.parse(parts[0]), int.parse(parts[1]),
            );
            final disponibleDesde = actDateTime.subtract(const Duration(minutes: 30));
            return now.isAfter(disponibleDesde);
          }
        }
        return true; // Sin hora, disponible todo el día
      }).toList();

      // Verificar cuáles de las actividades disponibles ya tienen asistencia tomada
      final existentes = await _supabase.client
          .from('attendance_events')
          .select('actividad_id')
          .not('actividad_id', 'is', null)
          .inFilter('actividad_id', disponibles.map((a) => a['id']).toList());

      final existentesSet = (existentes as List).map((e) => e['actividad_id'] as String).toSet();

      // Agregar campo 'ya_tomada'
      for (var act in disponibles) {
        act['ya_tomada'] = existentesSet.contains(act['id']);
      }

      setState(() {
        _actividadesProgramadas = disponibles;
        _isLoadingActividades = false;
      });
    } catch (e) {
      setState(() => _isLoadingActividades = false);
    }
  }

  List<String>? _getSubtypesForActType() {
    if (_selectedActTypeId == null) return null;
    final actType = _actTypes.firstWhere((t) => t['id'] == _selectedActTypeId, orElse: () => {});
    final name = actType['name'] as String?;
    return name != null ? _actSubtypes[name] : null;
  }

  Future<void> _loadAttendanceList({String? actividadId}) async {
    if (_selectedActTypeId == null) {
      _showError('Por favor seleccione un tipo de acto');
      return;
    }

    // Validar subtipo obligatorio para Emergencia
    final actType = _actTypes.firstWhere((t) => t['id'] == _selectedActTypeId, orElse: () => {});
    final subtypes = _actSubtypes[actType['name']];
    if (subtypes != null && _selectedSubtype == null) {
      _showError('Debe seleccionar un subtipo para ${actType['name']}');
      return;
    }

    if (_modoAsistencia == 'manual') {
      try {
        final dateStr = _selectedDate.toIso8601String().split('T')[0];
        final actividades = await _supabase.client
            .from('activities')
            .select('id, title')
            .eq('activity_date', dateStr)
            .limit(1);

        if (actividades.isNotEmpty) {
          final nombreActividad = actividades.first['title'] as String;
          final bool? continuar = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Actividad Programada Existente')),
                  ],
                ),
                content: Text(
                  '⚠️ Existe una actividad programada para esta fecha:\n\n'
                  '🔹 "$nombreActividad"\n\n'
                  'Se recomienda usar el modo "Actividad Programada" para vincular los permisos de manera automática.\n\n'
                  '¿Desea continuar con asistencia manual de todas formas?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false), // Ir a Programada
                    child: const Text('Ir a Programada', style: TextStyle(color: AppTheme.navyBlue, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true), // Continuar Manual
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text('Continuar Manual'),
                  ),
                ],
              );
            },
          );

          if (continuar == false) {
            // Cambiar a modo programada y cancelar la carga actual
            setState(() {
              _modoAsistencia = 'programada';
            });
            return;
          }
          // Si continuar == true (o null), sigue el flujo normal
        }
      } catch (e) {
        print('Error verificando actividades en asistencia manual: $e');
      }
    }

    setState(() => _isLoading = true);

    try {
      final users = await _supabase.getAllUsers();
      final attendanceList = await _attendanceService.prepareAttendanceList(
        users,
        _selectedDate,
        actividadId: actividadId ?? (_modoAsistencia == 'programada' && _selectedActividadProgramada != null ? _selectedActividadProgramada!['id'] as String? : null),
      );

      setState(() {
        _attendanceList = attendanceList;
        _isLoading = false;
      });

      final licensedCount = attendanceList.where((u) => u['hasLicense'] == true).length;
      if (licensedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$licensedCount bombero(s) tienen Permiso aprobado para esta fecha'),
            backgroundColor: AppTheme.abonoColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando lista: $e');
    }
  }

  Future<void> _saveAttendance() async {
    if (_attendanceList.isEmpty) {
      _showError('Primero cargue la lista de asistencia');
      return;
    }

    // Validar que al menos 1 asistente esté marcado como presente
    final presentCount = _attendanceList.where((u) => u['status'] == AttendanceStatus.present).length;
    if (presentCount == 0) {
      _showError('Debe marcar al menos un asistente como presente');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      final records = _attendanceList.map((item) {
        final user = item['user'] as UserModel;
        return {
          'userId': user.id,
          'status': (item['status'] as AttendanceStatus).name,
          'isLocked': item['isLocked'] as bool,
        };
      }).toList();

      await _attendanceService.createAttendanceEvent(
        actTypeId: _selectedActTypeId!,
        eventDate: _selectedDate,
        createdBy: userId,
        attendanceRecords: records,
        subtype: _modoAsistencia == 'manual' ? _selectedSubtype : null,
        location: _modoAsistencia == 'manual' && _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        actividadId: _modoAsistencia == 'programada' ? _selectedActividadProgramada!['id'] as String : null,
        modoAsistencia: _modoAsistencia,
      );

      try {
        final actTypeName = _actTypes.firstWhere((t) => t['id'] == _selectedActTypeId)['name'] as String;
        final totals = _calculateTotals();
        await EmailService().sendAttendanceCreatedNotification(
          eventDate: DateFormat('dd/MM/yyyy').format(_selectedDate),
          actType: actTypeName,
          subtype: _selectedSubtype ?? 'N/A',
          location: _locationController.text.trim().isEmpty ? 'N/A' : _locationController.text.trim(),
          createdBy: _currentUser!.fullName,
          totalPresent: totals['present']!,
          totalAbsent: totals['absent']!,
          totalLicencia: totals['permiso']!,
        );
      } catch (emailError) {
        print('Error enviando notificación: $emailError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asistencia guardada exitosamente'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
        setState(() {
          _attendanceList = [];
          _selectedActTypeId = null;
          _selectedActividadProgramada = null;
        });
        await _loadActividadesProgramadas(); // Recargar lista para actualizar el marcador
      }
    } catch (e) {
      _showError('Error guardando asistencia: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, int> _calculateTotals() {
    int present = 0, absent = 0, permiso = 0;
    for (final item in _attendanceList) {
      final status = item['status'] as AttendanceStatus;
      switch (status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.permiso:
          permiso++;
          break;
      }
    }
    return {'present': present, 'absent': absent, 'permiso': permiso};
  }

  void _toggleAttendance(int index) {
    final item = _attendanceList[index];
    
    // No permitir editar si está bloqueado por Permiso
    if (item['isLocked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este registro está bloqueado por Permiso aprobado'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      final currentStatus = item['status'] as AttendanceStatus;
      _attendanceList[index]['status'] = currentStatus == AttendanceStatus.present
          ? AttendanceStatus.absent
          : AttendanceStatus.present;
    });
  }

  Widget _buildDateSelector() {
    // Solo admin y officer pueden seleccionar cualquier fecha
    final canSelectAnyDate = _currentUser?.role == UserRole.admin || 
                             _currentUser?.role == UserRole.officer;
    
    if (!canSelectAnyDate) {
      // Bomberos normales: solo fecha de hoy (sin selector)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: const TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            Tooltip(
              message: 'Solo Admin/Oficiales pueden cambiar la fecha',
              child: Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    
    // Admin/Officer: DatePicker sin restricciones
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020), // Sin límite al pasado
          lastDate: DateTime(2100),  // Sin límite al futuro
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            _attendanceList = []; // Reset lista si cambia fecha
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.navyBlue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: AppTheme.navyBlue),
            const SizedBox(width: 12),
            Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppTheme.navyBlue),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.criticalColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        backgroundColor: AppTheme.institutionalRed,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tomar', icon: Icon(Icons.edit)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          if (_attendanceList.isNotEmpty && _tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveAttendance,
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tomar Asistencia
          _buildTakeAttendanceTab(),
          // Tab 2: Historial
          const AttendanceHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildTakeAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SegmentedButton modo de asistencia
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppTheme.institutionalRed,
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(
                value: 'programada',
                label: Text('Actividad Programada'),
                icon: Icon(Icons.event),
              ),
              ButtonSegment(
                value: 'manual',
                label: Text('Asistencia Emergencias'),
                icon: Icon(Icons.edit_note),
              ),
            ],
            selected: {_modoAsistencia},
            onSelectionChanged: (val) {
              setState(() {
                _modoAsistencia = val.first;
                _attendanceList = [];
                _selectedActividadProgramada = null;
                if (_modoAsistencia == 'programada' && _actividadesProgramadas.isEmpty) {
                  _loadActividadesProgramadas();
                }
                // Preseleccionar Emergencia en modo manual
                if (_modoAsistencia == 'manual') {
                  final emergenciaType = _actTypes.firstWhere(
                    (t) => t['name'] == 'Emergencia' || t['activity_type_key'] == 'emergencia',
                    orElse: () => {},
                  );
                  if (emergenciaType.isNotEmpty) {
                    _selectedActTypeId = emergenciaType['id'] as String;
                  }
                }
              });
            },
          ),
          const SizedBox(height: 16),

          // === MODO PROGRAMADA ===
          if (_modoAsistencia == 'programada') ...[
            if (_isLoadingActividades)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (_actividadesProgramadas.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No hay actividades disponibles en este momento.\nLas actividades aparecen 30 minutos antes de su hora de inicio.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              ...(_actividadesProgramadas.map((act) {
                final title = act['title'] as String? ?? 'Sin título';
                final actTypeName = act['act_type_name'] as String? ?? '';
                final dateStr = act['activity_date'] as String? ?? '';
                final timeStr = act['start_time'] as String? ?? '';
                final permisosCount = act['permisos_aprobados'] as int? ?? 0;

                String emoji = '📅';
                if (actTypeName.contains('Academia')) emoji = '📚';
                else if (actTypeName.contains('Reunión')) emoji = '🤝';
                else if (actTypeName.contains('Citación')) emoji = '📢';

                String fechaDisplay = '';
                if (dateStr.isNotEmpty) {
                  try {
                    fechaDisplay = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
                  } catch (_) {}
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '$fechaDisplay${timeStr.isNotEmpty ? '  ${timeStr.substring(0, 5)}' : ''}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (permisosCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  '🟡 $permisosCount con permiso',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.warningColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: act['ya_tomada'] == true
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.abonoColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.abonoColor.withOpacity(0.3)),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '✅ Asistencia Tomada',
                                  style: TextStyle(
                                    color: AppTheme.abonoColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _isLoading ? null : () {
                                  // Resolver act_type_id desde act_type_name
                                  final actTypeMap = _actTypes.where(
                                    (t) => (t['name'] as String).toLowerCase() == actTypeName.toLowerCase()
                                  ).firstOrNull;

                                  setState(() {
                                    _selectedActividadProgramada = act;
                                    _selectedActTypeId = actTypeMap?['id'] as String? ?? _selectedActTypeId;
                                    // Usar la fecha de la actividad
                                    if (dateStr.isNotEmpty) {
                                      try {
                                        _selectedDate = DateTime.parse(dateStr);
                                      } catch (_) {}
                                    }
                                  });
                                  _loadAttendanceList();
                                },
                                icon: _isLoading && _selectedActividadProgramada?['id'] == act['id']
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.people),
                                label: const Text('Tomar Asistencia'),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              })).toList(),
          ],

          // === MODO MANUAL ===
          if (_modoAsistencia == 'manual')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración del Evento',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    
                    // Fecha
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha del Evento',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              _buildDateSelector(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Tipo de Acto
                    Text(
                      'Tipo de Acto',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedActTypeId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Seleccione tipo de acto',
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'header_emergencia',
                          enabled: false,
                          child: Text('── EMERGENCIA ──', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12)),
                        ),
                        ..._actTypes.where((t) => t['name'] == 'Emergencia' || t['activity_type_key'] == 'emergencia').map((actType) {
                          final category = actType['category'] as String;
                          final color = category == 'efectiva' ? AppTheme.efectivaColor : AppTheme.abonoColor;
                          return DropdownMenuItem<String>(
                            value: actType['id'] as String,
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 12),
                                Text(actType['name'] as String),
                              ],
                            ),
                          );
                        }),
                        DropdownMenuItem<String>(
                          value: 'header_actividades',
                          enabled: false,
                          child: Text('── ACTIVIDADES ──', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12)),
                        ),
                        ..._actTypes.where((t) => t['name'] != 'Emergencia' && t['activity_type_key'] != 'emergencia').map((actType) {
                          final category = actType['category'] as String;
                          final color = category == 'efectiva' ? AppTheme.efectivaColor : AppTheme.abonoColor;
                          return DropdownMenuItem<String>(
                            value: actType['id'] as String,
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 12),
                                Text(actType['name'] as String),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedActTypeId = value;
                          _selectedSubtype = null;
                          _attendanceList = [];
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Subtipo (condicional según tipo de acto)
                    if (_selectedActTypeId != null && _getSubtypesForActType() != null) ...[
                      Text(
                        'Subtipo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSubtype,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Seleccione subtipo',
                        ),
                        items: _getSubtypesForActType()!.map((subtype) {
                          return DropdownMenuItem<String>(
                            value: subtype,
                            child: Text(subtype),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSubtype = value);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Ubicación
                    Text(
                      'Ubicación / Dirección',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Av. Costanera 1234',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _loadAttendanceList,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.people),
                        label: Text(_isLoading ? 'Cargando...' : 'Cargar Lista de Asistencia'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Lista de asistencia AGRUPADA POR CATEGORÍA
          if (_attendanceList.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Lista de Asistencia',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Text(
                          '${_attendanceList.where((u) => u['status'] == AttendanceStatus.present).length}/${_attendanceList.length} presentes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.efectivaColor,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedActividadProgramada != null) ...[
                      const SizedBox(height: 12),
                      Builder(builder: (context) {
                        final act = _selectedActividadProgramada!;
                        final actTypeName = act['act_type_name'] as String? ?? act['activity_type'] as String? ?? '';
                        final title = act['title'] as String? ?? '';
                        final dateRaw = act['activity_date'] as String? ?? '';
                        final timeRaw = act['start_time'] as String?;
                        String fechaDisplay = '';
                        try { fechaDisplay = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateRaw)); } catch (_) {}
                        final timeDisplay = (timeRaw != null && timeRaw.length >= 5) ? ' ${timeRaw.substring(0, 5)}' : '';
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.navyBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.navyBlue.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$actTypeName: $title — $fechaDisplay$timeDisplay',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyBlue),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    
                    // Leyenda
                    Wrap(
                      spacing: 16,
                      children: [
                        _buildLegend(Icons.check_circle, 'Presente', AppTheme.efectivaColor),
                        _buildLegend(Icons.cancel, 'Ausente', Colors.grey),
                        _buildLegend(Icons.event_available, 'Permiso (Bloqueado)', AppTheme.warningColor),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // GRUPOS POR CATEGORÍA
                    ..._buildGroupedAttendanceList(),
                    
                    const SizedBox(height: 20),
                    
                    // Botones cancelar y guardar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _attendanceList = [];
                              });
                            },
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveAttendance,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isSaving ? 'Guardando...' : 'Guardar Asistencia'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Groups attendance by rank category with proper ordering
  List<Widget> _buildGroupedAttendanceList() {
    // Define categories with EXACT rank matching patterns (priority order matters)
    // More specific patterns checked first to avoid duplicates
    final categories = {
      'OFICIALES DE COMPAÑÍA': {
        'patterns': ['Director', 'Secretari', 'Pro-Secretari', 'Tesorer', 'Pro-Tesorer', 'Capitán', 'Teniente', 'Ayudante', 'Inspector M.'],
        'orderType': 'hierarchical',
        'hierarchy': {
          'Director': 1,
          'Secretario': 2, 'Secretaria': 2,
          'Pro-Secretario': 2.5, 'Pro-Secretaria': 2.5, 'Pro-Secretario(a)': 2.5,
          'Tesorero': 3, 'Tesorera': 3,
          'Pro-Tesorero': 3.5, 'Pro-Tesorera': 3.5, 'Pro-Tesorero(a)': 3.5,
          'Capitán': 4,
          'Teniente 1°': 5, 'Teniente 2°': 6, 'Teniente 3°': 7,
          'Ayudante 1°': 8, 'Ayudante 2°': 9,
          'Inspector M. Mayor': 10,
          'Inspector M. Menor': 11,
        },
      },
      'OFICIALES DE CUERPO': {
        'patterns': ['Of. General', 'Inspector de Comandancia', 'Ayudante de Comandancia'],
        'orderType': 'hierarchical',
        'hierarchy': {
          'Of. General': 1,
          'Inspector de Comandancia': 2,
          'Ayudante de Comandancia': 3,
        },
      },
      'MIEMBROS HONORARIOS': {
        'patterns': ['Honorario', 'Miembro Honorario'],
        'orderType': 'seniority',
      },
      'BOMBEROS ACTIVOS': {
        'patterns': ['Bombero'],
        'orderType': 'seniority',
      },
      'ASPIRANTES Y POSTULANTES': {
        'patterns': ['Aspirante', 'Postulante'],
        'orderType': 'seniority',
      },
    };

    List<Widget> groups = [];
    final assignedUsers = <String>{}; // Track assigned users to prevent duplicates

    for (var entry in categories.entries) {
      final categoryName = entry.key;
      final categoryConfig = entry.value as Map<String, dynamic>;
      final patterns = categoryConfig['patterns'] as List<String>;
      final orderType = categoryConfig['orderType'] as String;
      
      // Filter users for this category
      final usersInCategory = _attendanceList.where((item) {
        final user = item['user'] as UserModel;
        final userId = user.id;
        
        // Skip if already assigned to another category
        if (assignedUsers.contains(userId)) return false;
        
        final rankLower = user.rank.toLowerCase();
        
        // Special logic for "Bomberos Activos": must contain "Bombero" 
        // but exclude if already categorized as officer or honorary
        if (categoryName == 'BOMBEROS ACTIVOS') {
          final isHonorary = rankLower.contains('honorario');
          final isOfficer = rankLower.contains('director') || 
                           rankLower.contains('secretari') || 
                           rankLower.contains('tesorer') ||
                           rankLower.contains('capitán') || 
                           rankLower.contains('teniente') || 
                           rankLower.contains('general') ||
                           rankLower.contains('inspector');
          
          // Special case: "Ayudante" without "de Comandancia" is an officer
          final isAyudanteOfficer = rankLower.contains('ayudante') && 
                                    !rankLower.contains('de comandancia');
          
          final isVolunteer = rankLower.contains('bombero');
          
          return isVolunteer && !isHonorary && !isOfficer && !isAyudanteOfficer;
        }
        
        // For other categories, use pattern matching
        // More specific checks first to avoid "Ayudante de Comandancia" duplicate
        for (final pattern in patterns) {
          final patternLower = pattern.toLowerCase();
          
          // Exact or contains match
          if (patternLower == 'ayudante de comandancia') {
            // EXACT match for this specific rank
            if (rankLower == patternLower || rankLower.contains('ayudante de comandancia')) {
              return true;
            }
          } else if (patternLower == 'ayudante') {
            // Only match "Ayudante" if NOT "Ayudante de Comandancia"
            if (rankLower.contains('ayudante') && !rankLower.contains('de comandancia')) {
              return true;
            }
          } else {
            // Regular contains match for other patterns
            if (rankLower.contains(patternLower)) {
              return true;
            }
          }
        }
        
        return false;
      }).toList();

      if (usersInCategory.isEmpty) continue;

      // Mark users as assigned
      for (var item in usersInCategory) {
        final user = item['user'] as UserModel;
        assignedUsers.add(user.id);
      }

      // Sort users within category based on order type
      if (orderType == 'hierarchical') {
        final hierarchyRaw = categoryConfig['hierarchy'] as Map<String, dynamic>;
        final hierarchy = Map<String, int>.from(hierarchyRaw.map((key, value) => MapEntry(key, (value as num).toInt())));
        usersInCategory.sort((a, b) {
          final userA = a['user'] as UserModel;
          final userB = b['user'] as UserModel;
          
          final priorityA = hierarchy[userA.rank] ?? 999;
          final priorityB = hierarchy[userB.rank] ?? 999;
          
          if (priorityA != priorityB) {
            return priorityA.compareTo(priorityB);
          }
          
          // If same hierarchy level, sort alphabetically
          return userA.fullName.compareTo(userB.fullName);
        });
      } else if (orderType == 'seniority') {
        usersInCategory.sort((a, b) {
          final userA = a['user'] as UserModel;
          final userB = b['user'] as UserModel;
          
          // Parse registro_compania as integer (lower = older = first)
          final regA = int.tryParse(userA.registroCompania ?? '999999') ?? 999999;
          final regB = int.tryParse(userB.registroCompania ?? '999999') ?? 999999;
          
          if (regA != regB) {
            return regA.compareTo(regB);
          }
          
          // If same seniority, sort alphabetically
          return userA.fullName.compareTo(userB.fullName);
        });
      }

      groups.add(_buildCategorySection(categoryName, usersInCategory));
      groups.add(const SizedBox(height: 16));
    }

    return groups;
  }

  /// Construye una sección de categoría
  Widget _buildCategorySection(String categoryName, List<Map<String, dynamic>> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de categoría
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Lista de usuarios en esta categoría
        ...users.asMap().entries.map((entry) {
          final globalIndex = _attendanceList.indexOf(entry.value);
          final item = entry.value;
          final user = item['user'] as UserModel;
          final status = item['status'] as AttendanceStatus;
          final isLocked = item['isLocked'] as bool;
          
          return _buildAttendanceRow(globalIndex, user, status, isLocked);
        }).toList(),
      ],
    );
  }

  /// Construye una fila de asistencia
  Widget _buildAttendanceRow(int index, UserModel user, AttendanceStatus status, bool isLocked) {
    Color statusColor;
    IconData statusIcon;
    
    if (status == AttendanceStatus.permiso) {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.lock;
    } else if (status == AttendanceStatus.present) {
      statusColor = AppTheme.efectivaColor;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.cancel;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Checkbox de asistencia
          SizedBox(
            width: 24,
            height: 24,
            child: isLocked
                ? Icon(Icons.lock, size: 18, color: AppTheme.warningColor)
                : Checkbox(
                    value: status == AttendanceStatus.present,
                    onChanged: (_) => _toggleAttendance(index),
                    activeColor: AppTheme.efectivaColor,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Nombre y rango
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (user.rank.isNotEmpty)
                  Text(
                    user.rank,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          
          // Indicador de estado
          Icon(statusIcon, size: 20, color: statusColor),
        ],
      ),
    );
  }

  Widget _buildLegend(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
