import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/core/utils/responsive_utils.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:intl/intl.dart';

/// Funciones de agrupamiento para registros de asistencia

/// Configuración de categorías para agrupamiento (replicado de take_attendance_screen.dart)
const Map<String, Map<String, dynamic>> attendanceCategories = {
  'OFICIALES DE COMPAÑÍA': {
    'patterns': ['Director', 'Secretari', 'Tesorer', 'Capitán', 'Teniente', 'Ayudante', 'Inspector M.'],
    'orderType': 'hierarchical',
    'hierarchy': {
      'Director': 1,
      'Secretario': 2, 'Secretaria': 2,
      'Tesorero': 3, 'Tesorera': 3,
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

/// Agrupa los registros de asistencia por categoría de rango
/// Retorna un Map donde la clave es el nombre de la categoría y el valor es la lista de registros
Map<String, List<Map<String, dynamic>>> groupAttendanceRecords(List<Map<String, dynamic>> records) {
  final Map<String, List<Map<String, dynamic>>> grouped = {};
  final Set<String> assignedUserIds = {};

  for (var entry in attendanceCategories.entries) {
    final categoryName = entry.key;
    final categoryConfig = entry.value;
    final patterns = categoryConfig['patterns'] as List<dynamic>;
    final orderType = categoryConfig['orderType'] as String;

    // Filtrar usuarios para esta categoría
    final usersInCategory = records.where((record) {
      final user = record['user'];
      final userId = user['id'] as String;

      // Skip if already assigned to another category
      if (assignedUserIds.contains(userId)) return false;

      final rankLower = (user['rank'] as String).toLowerCase();

      // Special logic for "Bomberos Activos"
      if (categoryName == 'BOMBEROS ACTIVOS') {
        final isHonorary = rankLower.contains('honorario');
        final isOfficer = rankLower.contains('director') ||
            rankLower.contains('secretari') ||
            rankLower.contains('tesorer') ||
            rankLower.contains('capitán') ||
            rankLower.contains('teniente') ||
            rankLower.contains('general') ||
            rankLower.contains('inspector');

        final isAyudanteOfficer = rankLower.contains('ayudante') &&
            !rankLower.contains('de comandancia');

        final isVolunteer = rankLower.contains('bombero');

        return isVolunteer && !isHonorary && !isOfficer && !isAyudanteOfficer;
      }

      // For other categories, use pattern matching
      for (final pattern in patterns) {
        final patternLower = (pattern as String).toLowerCase();

        if (patternLower == 'ayudante de comandancia') {
          if (rankLower == patternLower || rankLower.contains('ayudante de comandancia')) {
            return true;
          }
        } else if (patternLower == 'ayudante') {
          if (rankLower.contains('ayudante') && !rankLower.contains('de comandancia')) {
            return true;
          }
        } else {
          if (rankLower.contains(patternLower)) {
            return true;
          }
        }
      }

      return false;
    }).toList();

    if (usersInCategory.isEmpty) continue;

    // Mark users as assigned
    for (var record in usersInCategory) {
      final user = record['user'];
      assignedUserIds.add(user['id'] as String);
    }

    // Sort users within category based on order type
    if (orderType == 'hierarchical') {
      final hierarchy = categoryConfig['hierarchy'] as Map<String, dynamic>;
      usersInCategory.sort((a, b) {
        final userA = a['user'];
        final userB = b['user'];

        final priorityA = hierarchy[userA['rank']] ?? 999;
        final priorityB = hierarchy[userB['rank']] ?? 999;

        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }

        // If same hierarchy level, sort alphabetically
        return (userA['full_name'] as String).compareTo(userB['full_name'] as String);
      });
    } else if (orderType == 'seniority') {
      usersInCategory.sort((a, b) {
        final userA = a['user'];
        final userB = b['user'];

        // Parse registro_compania as integer (lower = older = first)
        final regA = int.tryParse(userA['registro_compania']?.toString() ?? '999999') ?? 999999;
        final regB = int.tryParse(userB['registro_compania']?.toString() ?? '999999') ?? 999999;

        if (regA != regB) {
          return regA.compareTo(regB);
        }

        // If same seniority, sort alphabetically
        return (userA['full_name'] as String).compareTo(userB['full_name'] as String);
      });
    }

    grouped[categoryName] = usersInCategory;
  }

  return grouped;
}

/// Módulo 4: Modificar Asistencias (Solo Admin)
class ModifyAttendanceScreen extends StatefulWidget {
  const ModifyAttendanceScreen({super.key});

  @override
  State<ModifyAttendanceScreen> createState() => _ModifyAttendanceScreenState();
}

class _ModifyAttendanceScreenState extends State<ModifyAttendanceScreen> {
  final _supabase = SupabaseService();
  final _authService = AuthService();
  
  UserModel? _currentUser;
  List<Map<String, dynamic>> _attendanceEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  bool _isLoading = true;
  
  // Filtros
  DateTimeRange? _dateRange;
  String? _selectedActTypeId;
  List<Map<String, dynamic>> _actTypes = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      _showAccessDenied();
      return;
    }

    final user = await _supabase.getUserProfile(userId);
    setState(() => _currentUser = user);

    if (user?.role != UserRole.admin) {
      _showAccessDenied();
      return;
    }

    _loadData();
  }

  void _showAccessDenied() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso denegado. Solo administradores.'),
          backgroundColor: AppTheme.criticalColor,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final actTypes = await _supabase.getAllActTypes();
      final events = await _supabase.getAttendanceEvents();
      
      setState(() {
        _actTypes = actTypes;
        _attendanceEvents = events;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando datos: $e');
    }
  }

  void _applyFilters() {
    var filtered = _attendanceEvents;

    // Filtrar por rango de fechas
    if (_dateRange != null) {
      filtered = filtered.where((event) {
        final eventDate = DateTime.parse(event['event_date']);
        return eventDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               eventDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filtrar por tipo de acto
    if (_selectedActTypeId != null) {
      filtered = filtered.where((event) => event['act_type_id'] == _selectedActTypeId).toList();
    }

    // Ordenar por fecha descendente
    filtered.sort((a, b) => DateTime.parse(b['event_date']).compareTo(DateTime.parse(a['event_date'])));

    setState(() => _filteredEvents = filtered);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.criticalColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser?.role != UserRole.admin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Modificar Asistencias'),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(child: _buildEventsList()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Filtro por fecha
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: _dateRange,
                      );
                      if (picked != null) {
                        setState(() {
                          _dateRange = picked;
                          _applyFilters();
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _dateRange == null
                          ? 'Seleccionar fechas'
                          : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
                    ),
                  ),
                ),
                if (_dateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _dateRange = null;
                      _applyFilters();
                    }),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Filtro por tipo de acto
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Emergencia',
                border: OutlineInputBorder(),
              ),
              value: _selectedActTypeId,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ..._actTypes.map((type) => DropdownMenuItem(
                      value: type['id'],
                      child: Text(type['name']),
                    )),
              ],
              onChanged: (value) => setState(() {
                _selectedActTypeId = value;
                _applyFilters();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_filteredEvents.isEmpty) {
      return const Center(
        child: Text('No se encontraron asistencias'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventDate = DateTime.parse(event['event_date']);
    final actTypeName = _actTypes.firstWhere(
      (type) => type['id'] == event['act_type_id'],
      orElse: () => {'name': 'Desconocido'},
    )['name'];
    final subtype = event['subtype'] as String?;
    final location = event['location'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Row(
          children: [
            Text(actTypeName, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (subtype != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(subtype, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navyBlue)),
              ),
            ],
          ],
        ),
        subtitle: FutureBuilder<Map<String, int>>(
          future: _getEventStats(event['id']),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Cargando...');
            }
            final stats = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy').format(eventDate)),
                  ],
                ),
                if (location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text('Asistentes: ${stats['attendees']} | Permisos: ${stats['permits']}'),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: _getCreatorName(event['created_by']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    return Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Creado por: ${snapshot.data}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
                if (event['modified_by'] != null) ...[
                  const SizedBox(height: 2),
                  FutureBuilder<String>(
                    future: _getCreatorName(event['modified_by']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final modifiedAt = DateTime.parse(event['modified_at']);
                      return Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Editado por: ${snapshot.data} (${DateFormat('dd/MM/yy HH:mm').format(modifiedAt)})',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.people, color: AppTheme.efectivaColor),
              tooltip: 'Ver Asistentes',
              onPressed: () => _showAttendeesDialog(event),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.navyBlue),
              tooltip: 'Editar',
              onPressed: () => _showEditDialog(event),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.criticalColor),
              tooltip: 'Eliminar',
              onPressed: () => _showDeleteConfirmation(event),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getEventStats(String eventId) async {
    try {
      final records = await _supabase.getAttendanceRecordsByEvent(eventId);
      final attendees = records.where((r) => r['status'] == 'present').length;
      final permits = records.where((r) => r['is_locked'] == true).length;
      return {'attendees': attendees, 'permits': permits};
    } catch (e) {
      return {'attendees': 0, 'permits': 0};
    }
  }

  Future<String> _getCreatorName(String userId) async {
    try {
      final user = await _supabase.getUserProfile(userId);
      return user?.fullName ?? 'Desconocido';
    } catch (e) {
      return 'Desconocido';
    }
  }

  Future<void> _showAttendeesDialog(Map<String, dynamic> event) async {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabase.getAttendanceRecordsByEvent(event['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              title: Text('Cargando...'),
              content: SizedBox(
                width: 600,
                height: 400,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          
          final records = snapshot.data ?? [];
          final groupedRecords = groupAttendanceRecords(records);
          
          return AlertDialog(
            title: Text('Asistentes - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(event['event_date']))}'),
            content: SizedBox(
              width: 600,
              child: records.isEmpty
                  ? const Center(child: Text('No hay registros de asistencia'))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (var entry in groupedRecords.entries) ...[
                                // Category header
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                // Users in this category
                                ...entry.value.map((record) {
                                  final user = record['user'];
                                  final status = record['status'] as String;
                                  final isLocked = record['is_locked'] as bool? ?? false;

                                  Color statusColor;
                                  IconData statusIcon;
                                  String statusText;

                                  switch (status) {
                                    case 'present':
                                      statusColor = AppTheme.efectivaColor;
                                      statusIcon = Icons.check_circle;
                                      statusText = 'Presente';
                                      break;
                                    case 'absent':
                                      statusColor = AppTheme.criticalColor;
                                      statusIcon = Icons.cancel;
                                      statusText = 'Ausente';
                                      break;
                                    case 'licencia':
                                      statusColor = Colors.orange;
                                      statusIcon = Icons.lock;
                                      statusText = 'Permiso';
                                      break;
                                    default:
                                      statusColor = Colors.grey;
                                      statusIcon = Icons.help;
                                      statusText = status;
                                  }

                                  return ListTile(
                                    dense: true,
                                    leading: Icon(statusIcon, color: statusColor, size: 20),
                                    title: Text(
                                      user['full_name'] ?? 'Sin nombre',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      user['rank'] ?? 'Sin cargo',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isLocked) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.lock_outline, size: 16, color: Colors.orange),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> event) async {
    final records = await _supabase.getAttendanceRecordsByEvent(event['id']);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => _EditAttendanceDialog(
        event: event,
        records: records,
        actTypes: _actTypes,
        onSave: () {
          _loadData();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Asistencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción NO SE PUEDE DESHACER.',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.criticalColor),
            ),
            const SizedBox(height: 16),
            Text('Se eliminarán:'),
            const SizedBox(height: 8),
            const Text('• El evento de asistencia'),
            const Text('• TODOS los registros de asistencia asociados'),
            const SizedBox(height: 16),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(event['event_date']))}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteEvent(event['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalColor,
            ),
            child: const Text('Eliminar Definitivamente'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _supabase.deleteAttendanceEvent(eventId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asistencia eliminada exitosamente'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      }
    } catch (e) {
      _showError('Error eliminando asistencia: $e');
    }
  }
}

// Dialog de edición
class _EditAttendanceDialog extends StatefulWidget {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> actTypes;
  final VoidCallback onSave;

  const _EditAttendanceDialog({
    required this.event,
    required this.records,
    required this.actTypes,
    required this.onSave,
  });

  @override
  State<_EditAttendanceDialog> createState() => _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends State<_EditAttendanceDialog> {
  final _supabase = SupabaseService();
  final _authService = AuthService();
  late DateTime _selectedDate;
  late String _selectedActTypeId;
  String? _selectedSubtype;
  final TextEditingController _locationController = TextEditingController();
  late List<Map<String, dynamic>> _editableRecords;
  late List<Map<String, dynamic>> _filteredRecords;
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;

  // Mapa de subtipos
  final Map<String, List<String>> _actSubtypes = {
    'Emergencia': ['10-0', '10-1', '10-2', '10-3', '10-4', '10-5', '10-6', '10-7', '10-8', '10-9', '10-10', '10-11', '10-12'],
    'Reunión de Compañía': ['Ordinaria', 'Extraordinaria'],
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.parse(widget.event['event_date']);
    _selectedActTypeId = widget.event['act_type_id'];
    _selectedSubtype = widget.event['subtype'] as String?;
    _locationController.text = widget.event['location'] as String? ?? '';
    _editableRecords = List.from(widget.records);
    _filteredRecords = _editableRecords;
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _editableRecords;
      } else {
        _filteredRecords = _editableRecords.where((record) {
          final userName = (record['user']['full_name'] as String).toLowerCase();
          return userName.contains(query);
        }).toList();
      }
    });
  }

  List<String>? _getSubtypesForActType() {
    final actType = widget.actTypes.firstWhere((t) => t['id'] == _selectedActTypeId, orElse: () => {});
    final name = actType['name'] as String?;
    return name != null ? _actSubtypes[name] : null;
  }

  @override
  Widget build(BuildContext context) {
    final actTypeName = widget.actTypes.firstWhere(
      (type) => type['id'] == _selectedActTypeId,
      orElse: () => {'name': 'Desconocido'},
    )['name'];
    
    // Group filtered records
    final groupedRecords = groupAttendanceRecords(_filteredRecords);

    // Usar diseño responsivo: desktop vs mobile
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopDialog(actTypeName, groupedRecords);
    } else {
      return _buildMobileDialog(actTypeName, groupedRecords);
    }
  }

  // Desktop: AlertDialog scrollable
  Widget _buildDesktopDialog(String actTypeName, Map<String, List<Map<String, dynamic>>> groupedRecords) {
    return AlertDialog(
      title: const Text('Editar Asistencia'),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _buildDialogContent(actTypeName, groupedRecords),
          ),
        ),
      ),
      actions: _buildActions(),
    );
  }

  // Mobile: Fullscreen Scaffold dialog
  Widget _buildMobileDialog(String actTypeName, Map<String, List<Map<String, dynamic>>> groupedRecords) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Asistencia'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (!_isSaving)
              TextButton(
                onPressed: _saveChanges,
                child: const Text('GUARDAR', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildDialogContent(actTypeName, groupedRecords),
          ),
        ),
      ),
    );
  }

  // Contenido común para ambos diseños
  List<Widget> _buildDialogContent(String actTypeName, Map<String, List<Map<String, dynamic>>> groupedRecords) {
    return [
            // Fecha
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ),
            // Tipo de acto
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Emergencia',
                  border: OutlineInputBorder(),
                ),
                value: _selectedActTypeId,
                items: widget.actTypes.map<DropdownMenuItem<String>>((type) => DropdownMenuItem(
                      value: type['id'],
                      child: Text(type['name']),
                    )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedActTypeId = value;
                      _selectedSubtype = null; // Reset subtipo al cambiar tipo
                    });
                  }
                },
              ),
            ),
            
            // Subtipo (condicional)
            if (_getSubtypesForActType() != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedSubtype,
                  decoration: const InputDecoration(
                    labelText: 'Subtipo',
                    border: OutlineInputBorder(),
                  ),
                  items: _getSubtypesForActType()!.map<DropdownMenuItem<String>>((subtype) {
                    return DropdownMenuItem<String>(
                      value: subtype,
                      child: Text(subtype),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedSubtype = value),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ubicación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación / Dirección',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
            const Divider(),
            // Búsqueda de bomberos
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar bombero por nombre...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterRecords();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Registros de Asistencia (${_filteredRecords.length}/${_editableRecords.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            // Lista de registros agrupada
            SizedBox(
              height: 400,
              child: _filteredRecords.isEmpty
                  ? const Center(child: Text('No se encontraron bomberos'))
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (var entry in groupedRecords.entries) ...[
                          // Category header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // Sub-group by status within this category
                          ...() {
                            final categoryRecords = entry.value;
                            
                            // Separate by status: present, locked (licencia), absent
                            final present = categoryRecords.where((r) => r['status'] == 'present').toList();
                            final permits = categoryRecords.where((r) => 
                              r['is_locked'] == true || r['status'] == 'licencia'
                            ).toList();
                            final absent = categoryRecords.where((r) => 
                              r['status'] == 'absent' && (r['is_locked'] != true)
                            ).toList();
                            
                            List<Widget> statusWidgets = [];
                            
                            // Add present users
                            if (present.isNotEmpty) {
                              statusWidgets.add(
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, top: 4, bottom: 2),
                                  child: Text(
                                    'Presentes (${present.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                              statusWidgets.addAll(present.map((record) => _buildRecordTile(record)));
                            }
                            
                            // Add locked/permit users
                            if (permits.isNotEmpty) {
                              statusWidgets.add(
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, top: 4, bottom: 2),
                                  child: Text(
                                    'Con Licencia (${permits.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                              statusWidgets.addAll(permits.map((record) => _buildRecordTile(record)));
                            }
                            
                            // Add absent users
                            if (absent.isNotEmpty) {
                              statusWidgets.add(
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, top: 4, bottom: 2),
                                  child: Text(
                                    'Ausentes (${absent.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                              statusWidgets.addAll(absent.map((record) => _buildRecordTile(record)));
                            }
                            
                            return statusWidgets;
                          }(),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
    ];
  }

  // Acciones para desktop dialog
  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Guardar'),
      ),
    ];
  }
  
  Widget _buildRecordTile(Map<String, dynamic> record) {
    // Find the real index in _editableRecords
    final realIndex = _editableRecords.indexWhere(
      (r) => r['id'] == record['id'],
    );
    
    if (realIndex == -1) return const SizedBox.shrink();
    
    final user = record['user'];
    final isLocked = record['is_locked'] == true;
    final status = record['status'];

    return ListTile(
      dense: true,
      leading: Icon(
        isLocked ? Icons.lock : Icons.person,
        color: isLocked ? AppTheme.warningColor : null,
        size: 20,
      ),
      title: Text(
        user['full_name'],
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        user['rank'] ?? 'Sin cargo',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked)
            IconButton(
              icon: const Icon(Icons.lock_open, color: AppTheme.navyBlue),
              tooltip: 'Desbloquear',
              onPressed: () {
                setState(() {
                  _editableRecords[realIndex]['is_locked'] = false;
                  _editableRecords[realIndex]['status'] = 'absent';
                  _filterRecords(); // Refrescar filtro
                });
              },
            )
          else
            DropdownButton<String>(
              value: status,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'present', child: Text('Presente')),
                DropdownMenuItem(value: 'absent', child: Text('Ausente')),
              ],
              onChanged: (newStatus) {
                if (newStatus != null) {
                  setState(() {
                    _editableRecords[realIndex]['status'] = newStatus;
                    _filterRecords(); // Refrescar filtro
                  });
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // Actualizar evento
      await _supabase.updateAttendanceEvent(
        widget.event['id'],
        _selectedDate,
        _selectedActTypeId,
        _authService.currentUserId!,
        subtype: _selectedSubtype,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );

      // Actualizar cada registro en lote (batch update)
      final List<Future> updates = [];
      for (final record in _editableRecords) {
        updates.add(_supabase.updateAttendanceRecord2(
          record['id'],
          record['status'],
          record['is_locked'] ?? false,
        ));
      }
      
      // Esperar a que todas las actualizaciones terminen en paralelo
      await Future.wait(updates);

      widget.onSave();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando cambios: $e'),
            backgroundColor: AppTheme.criticalColor,
          ),
        );
      }
      setState(() => _isSaving = false);
    }
  }
}
