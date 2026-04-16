import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/models/guard_attendance_model.dart';
import 'package:sexta_app/models/guard_roster_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/services/guard_attendance_service.dart';
import 'package:sexta_app/services/guard_roster_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/searchable_user_selector.dart';
import 'package:sexta_app/services/auth_service.dart';

/// Screen for registering Nocturna (Night) guard attendance
/// ROSTER-BASED: Loads personnel from published roster
/// Time: 23:00 to 08:00 (next day)
/// Date Selection: Today or Yesterday only
class GuardNocturnaAttendanceScreen extends StatefulWidget {
  const GuardNocturnaAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<GuardNocturnaAttendanceScreen> createState() =>
      _GuardNocturnaAttendanceScreenState();
}

enum DateOption { today, yesterday }

enum AttendanceStatus { present, absent, permission, replaced }

class PersonnelAttendance {
  final UserModel user;
  final String role; // 'Maquinista', 'OBAC', 'Bombero'
  AttendanceStatus status;
  UserModel? replacement;

  PersonnelAttendance({
    required this.user,
    required this.role,
    this.status = AttendanceStatus.present,
    this.replacement,
  });
}

class _GuardNocturnaAttendanceScreenState
    extends State<GuardNocturnaAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guardService = GuardAttendanceService();
  final _rosterService = GuardRosterService();
  final _supabaseService = SupabaseService();
  final TextEditingController _observationsController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isLoadingRoster = false;
  DateOption _selectedDateOption = DateOption.today;
  DateTime? _guardDate;
  GuardRosterDaily? _roster;
  List<PersonnelAttendance> _personnel = [];
  List<UserModel> _allUsers = [];
  List<GuardAttendanceNocturna> _history = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDate();
    _loadUsers();
    _loadHistory();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _supabaseService.getAllUsers();
      setState(() => _allUsers = users);
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  void _initializeDate() {
    final now = DateTime.now();
    // If before 08:00 AM, default to yesterday
    if (now.hour < 8) {
      _selectedDateOption = DateOption.yesterday;
    } else {
      _selectedDateOption = DateOption.today;
    }
    _updateGuardDate();
  }

  void _updateGuardDate() {
    final now = DateTime.now();
    if (_selectedDateOption == DateOption.today) {
      _guardDate = DateTime(now.year, now.month, now.day);
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      _guardDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
    }
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    if (_guardDate == null) return;

    setState(() {
      _isLoadingRoster = true;
      _errorMessage = null;
      _personnel = [];
    });

    try {
      // Check if attendance already registered
      final alreadyRegistered = await _guardService.isGuardAlreadyRegistered(
        AppConstants.guardAttendanceNocturnaTable,
        _guardDate!,
        null,
      );

      if (alreadyRegistered) {
        setState(() {
          _errorMessage = 'Guardia ya registrada para esta fecha';
          _isLoadingRoster = false;
        });
        return;
      }

      // Load published roster
      final roster = await _rosterService.getPublishedDailyRosterForDate(_guardDate!);

      if (roster == null) {
        setState(() {
          _errorMessage = 'No hay rol de guardia publicado para esta fecha';
          _isLoadingRoster = false;
        });
        return;
      }

      // Build personnel list
      final personnel = <PersonnelAttendance>[];

      if (roster.maquinista != null) {
        personnel.add(PersonnelAttendance(
          user: roster.maquinista!,
          role: 'Maquinista',
        ));
      }

      if (roster.obac != null) {
        personnel.add(PersonnelAttendance(
          user: roster.obac!,
          role: 'OBAC',
        ));
      }

      if (roster.bomberos != null) {
        for (var bombero in roster.bomberos!) {
          personnel.add(PersonnelAttendance(
            user: bombero,
            role: 'Bombero',
          ));
        }
      }

      setState(() {
        _roster = roster;
        _personnel = personnel;
        _isLoadingRoster = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el rol: $e';
        _isLoadingRoster = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _guardService.getNocturnaAttendanceHistory(limit: 10);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      
      final currentUser = AuthService().currentUser;
      final userRole = currentUser?.role;
      final isPrivileged = userRole == UserRole.admin || userRole == UserRole.oficial3;
      
      final filteredHistory = history.where((h) {
        final hDate = DateTime(h.guardDate.year, h.guardDate.month, h.guardDate.day);
        final isRecent = !hDate.isBefore(yesterdayDate);
        
        if (isPrivileged) {
          return isRecent;
        } else {
          return isRecent && h.createdBy == currentUser?.id;
        }
      }).toList();
      
      setState(() => _history = filteredHistory);
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _showAttendanceDetail(GuardAttendanceNocturna record) async {
    // Cargar records detallados
    final detailedRecord = await _guardService.getNocturnaAttendance(record.guardDate);
    if (detailedRecord == null || !mounted) return;

    final currentUser = AuthService().currentUser;
    final userRole = currentUser?.role;
    final bool isPrivileged = userRole == UserRole.admin || userRole == UserRole.oficial3;
    final bool isCreator = record.createdBy == currentUser?.id;
    
    final now = DateTime.now();
    final hoursSinceCreation = now.difference(record.createdAt).inHours;
    final isEditable = isPrivileged || (isCreator && hoursSinceCreation < 1);

    // Cargar nombres de los usuarios asignados
    final userIds = <String>[];
    if (record.maquinistaId != null) userIds.add(record.maquinistaId!);
    if (record.obacId != null) userIds.add(record.obacId!);
    // Obtener bombero IDs del record
    final bomberoIds = record.bomberoIds.whereType<String>().toList();
    userIds.addAll(bomberoIds);

    // Buscar nombres en _allUsers
    final usersMap = {for (var u in _allUsers) u.id: u};

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Guardia ${DateFormat("dd/MM/yyyy").format(record.guardDate)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (isEditable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Editable', style: TextStyle(fontSize: 12, color: Colors.green)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Solo lectura', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Maquinista
                if (record.maquinistaId != null)
                  _buildDetailRow('Maquinista', usersMap[record.maquinistaId]?.fullName ?? 'Desconocido',
                    _getRecordStatus(detailedRecord.records, record.maquinistaId!)),
                // OBAC
                if (record.obacId != null)
                  _buildDetailRow('OBAC', usersMap[record.obacId]?.fullName ?? 'Desconocido',
                    _getRecordStatus(detailedRecord.records, record.obacId!)),
                // Bomberos
                for (var bId in bomberoIds)
                  _buildDetailRow('Bombero', usersMap[bId]?.fullName ?? 'Desconocido',
                    _getRecordStatus(detailedRecord.records, bId)),
                // Observaciones
                if (record.observations != null && record.observations!.isNotEmpty) ...[
                  const Divider(),
                  Text('Observaciones: ${record.observations}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (isEditable)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _editAttendance(record);
              },
              child: const Text('Editar'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getRecordStatus(List<GuardAttendanceRecord>? records, String userId) {
    if (records == null || records.isEmpty) return 'Sin registro';
    final record = records.where((r) => r.userId == userId).firstOrNull;
    if (record == null) return 'Sin registro';
    switch (record.status) {
      case 'presente': return '✅ Presente';
      case 'ausente': return '❌ Ausente';
      case 'permiso': return '📋 Permiso';
      case 'reemplazado': return '🔄 Reemplazado';
      default: return record.status;
    }
  }

  Widget _buildDetailRow(String position, String name, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(position, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Text(status, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _editAttendance(GuardAttendanceNocturna record) async {
    // Eliminar registro existente y recargar para editar
    try {
      await _guardService.deleteNocturnaAttendance(record.id);
      // Recargar la fecha para que muestre el formulario de nuevo
      setState(() {
        _guardDate = record.guardDate;
        if (record.guardDate.day == DateTime.now().day) {
          _selectedDateOption = DateOption.today;
        } else {
          _selectedDateOption = DateOption.yesterday;
        }
      });
      _loadRoster();
      _loadHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro eliminado. Puede volver a registrar la asistencia.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al editar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate all personnel have status
    final allMarked = _personnel.every((p) => true); // All have default status

    if (!allMarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe marcar el estado de todo el personal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build records data
      final recordsData = _personnel.map((person) {
        String statusStr;
        switch (person.status) {
          case AttendanceStatus.present:
            statusStr = 'presente';
            break;
          case AttendanceStatus.absent:
            statusStr = 'ausente';
            break;
          case AttendanceStatus.permission:
            statusStr = 'permiso';
            break;
          case AttendanceStatus.replaced:
            statusStr = 'reemplazado';
            break;
        }
        
        return {
          'user_id': person.user.id,
          'position': person.role.toLowerCase().contains('extra') ? 'bombero' : person.role.toLowerCase(),
          'status': statusStr,
          'replaced_by_id': person.status == AttendanceStatus.replaced 
              ? person.replacement?.id 
              : null,
          'replaces_user_id': null,
        };
      }).toList();

      // Construir lista completa de bombero_ids (roster + extras)
      final allBomberoIds = <String?>[];
      for (var person in _personnel) {
        if (person.role == 'Bombero' || person.role == 'Bombero (Extra)') {
          allBomberoIds.add(person.user.id);
        }
      }

      await _guardService.createNocturnaAttendance(
        guardDate: _guardDate!,
        rosterWeekId: _roster!.rosterWeekId,
        maquinistaId: _roster!.maquinistaId,
        obacId: _roster!.obacId,
        bomberoIds: allBomberoIds,
        records: recordsData,
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Asistencia guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset and reload
        _resetForm();
        _loadHistory();
        _loadRoster(); // Reload to show "already registered" message
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _observationsController.clear();
      _personnel = [];
      _roster = null;
    });
  }

  Future<void> _addExtraGuardian() async {
    // Filtrar usuarios disponibles
    final availableUsers = _allUsers.where((u) {
      final rank = u.rank.toLowerCase();
      if (rank.contains('postulante') || rank.contains('aspirante')) return false;
      // No mostrar usuarios ya asignados
      final alreadyAssigned = _personnel.any((p) => p.user.id == u.id);
      return !alreadyAssigned;
    }).toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay usuarios disponibles para agregar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = await showDialog<UserModel>(
      context: context,
      builder: (context) => _ExtraGuardianSearchDialog(
        availableUsers: availableUsers,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _personnel.add(PersonnelAttendance(
          user: selected,
          role: 'Bombero (Extra)',
          status: AttendanceStatus.present,
        ));
      });
    }
  }

  Future<void> _selectReplacement(int index) async {
    // Load all users if not loaded
    if (_allUsers.isEmpty) {
      // TODO: Load from supabase service
    }

    final selected = await showDialog<UserModel>(
      context: context,
      builder: (context) => _ReplacementDialog(
        availableUsers: _allUsers,
        currentPerson: _personnel[index].user,
      ),
    );

    if (selected != null) {
      setState(() {
        _personnel[index].replacement = selected;
        _personnel[index].status = AttendanceStatus.replaced;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asist. a Guardia Nocturna'),
        backgroundColor: Colors.indigo,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.indigo.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Guardias nocturnas basadas en el rol publicado\\nHorario: 23:00 - 08:00 hrs',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date selection (Today/Yesterday)
            const Text(
              'Seleccionar Fecha',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<DateOption>(
                    title: const Text('Hoy'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: DateOption.today,
                    groupValue: _selectedDateOption,
                    onChanged: (value) {
                      setState(() => _selectedDateOption = value!);
                      _updateGuardDate();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<DateOption>(
                    title: const Text('Ayer'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(
                        DateTime.now().subtract(const Duration(days: 1)),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: DateOption.yesterday,
                    groupValue: _selectedDateOption,
                    onChanged: (value) {
                      setState(() => _selectedDateOption = value!);
                      _updateGuardDate();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Roster content
            if (_isLoadingRoster)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_personnel.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay personal asignado en el rol'),
                ),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Asignado (${_personnel.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Personnel list
                    ...List.generate(_personnel.length, (index) {
                      return _buildPersonnelCard(index);
                    }),

                    const SizedBox(height: 16),

                    // Add extra guardian button
                    if (_roster != null && _personnel.length < 10)
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _addExtraGuardian,
                          icon: const Icon(Icons.add),
                          label: Text(
                            'Agregar Guardián (${10 - _personnel.length} cupos disponibles)',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            side: BorderSide(color: Colors.indigo.shade300),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Observations
                    TextField(
                      controller: _observationsController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Notas adicionales...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Guardar Asistencia',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // History section
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Historial Reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _history.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No hay registros'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final record = _history[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo,
                            child: const Icon(
                              Icons.nightlight_round,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            DateFormat('dd/MM/yyyy').format(record.guardDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${record.assignedCount} personas asignadas',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showAttendanceDetail(record),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelCard(int index) {
    final person = _personnel[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    person.role,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    person.user.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (person.role == 'Bombero (Extra)')
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Eliminar guardián extra',
                    onPressed: () {
                      setState(() => _personnel.removeAt(index));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Status selection
            Wrap(
              spacing: 8,
              children: [
                _buildStatusChip(
                  index,
                  AttendanceStatus.present,
                  '✅ Presente',
                  Colors.green,
                ),
                _buildStatusChip(
                  index,
                  AttendanceStatus.absent,
                  '❌ Ausente',
                  Colors.red,
                ),
                _buildStatusChip(
                  index,
                  AttendanceStatus.permission,
                  '📋 Permiso',
                  Colors.orange,
                ),
                _buildStatusChip(
                  index,
                  AttendanceStatus.replaced,
                  '🔄 Reemplazado',
                  Colors.blue,
                ),
              ],
            ),

            // Replacement info
            if (person.status == AttendanceStatus.replaced) ...[
              const SizedBox(height: 12),
              if (person.replacement != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reemplazado por: ${person.replacement!.fullName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _selectReplacement(index),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _selectReplacement(index),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Seleccionar reemplazo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    int index,
    AttendanceStatus status,
    String label,
    Color color,
  ) {
    final isSelected = _personnel[index].status == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _personnel[index].status = status;
          if (status != AttendanceStatus.replaced) {
            _personnel[index].replacement = null;
          }
        });
      },
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: Colors.grey.shade900,
      labelStyle: TextStyle(
        color: isSelected ? Colors.grey.shade900 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }
}

/// Dialog for selecting a replacement
class _ReplacementDialog extends StatefulWidget {
  final List<UserModel> availableUsers;
  final UserModel currentPerson;

  const _ReplacementDialog({
    required this.availableUsers,
    required this.currentPerson,
  });

  @override
  State<_ReplacementDialog> createState() => _ReplacementDialogState();
}

class _ReplacementDialogState extends State<_ReplacementDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.availableUsers;
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredUsers = widget.availableUsers;
      } else {
        _filteredUsers = widget.availableUsers.where((user) {
          final fullName = user.fullName.toLowerCase();
          return fullName.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Seleccionar Reemplazo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.firstName[0].toUpperCase()),
                    ),
                    title: Text(user.fullName),
                    subtitle: Text(user.rank),
                    onTap: () => Navigator.pop(context, user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtraGuardianSearchDialog extends StatefulWidget {
  final List<UserModel> availableUsers;
  const _ExtraGuardianSearchDialog({required this.availableUsers});
  @override
  State<_ExtraGuardianSearchDialog> createState() => _ExtraGuardianSearchDialogState();
}

class _ExtraGuardianSearchDialogState extends State<_ExtraGuardianSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.availableUsers;
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = widget.availableUsers;
      } else {
        _filteredUsers = widget.availableUsers.where((user) {
          return user.fullName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Seleccionar Guardián Extra',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Text('${_filteredUsers.length} disponibles', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    title: Text(user.fullName),
                    subtitle: Text(user.rank),
                    onTap: () => Navigator.pop(context, user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
