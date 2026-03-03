import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/models/guard_attendance_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/services/guard_attendance_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/searchable_user_selector.dart';

/// Screen for registering FDS (Weekend/Holiday) guard attendance
/// Composition: Maq1 + Maq2 + OBAC + 10 Bomberos = 13 people total
class GuardFdsAttendanceScreen extends StatefulWidget {
  const GuardFdsAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<GuardFdsAttendanceScreen> createState() => _GuardFdsAttendanceScreenState();
}

class _GuardFdsAttendanceScreenState extends State<GuardFdsAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guardService = GuardAttendanceService();
  final _supabaseService = SupabaseService();

  // Form fields
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String _selectedPeriod = 'AM';
  String? _maquinista1Id;
  String? _maquinista2Id;
  String? _obacId;
  final List<String?> _bomberoIds = List.filled(10, null);
  final TextEditingController _observationsController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isLoadingUsers = true;
  List<UserModel> _allUsers = [];
  List<GuardAttendanceFds> _history = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadHistory();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _supabaseService.getAllUsers();
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _guardService.getFdsAttendanceHistory(limit: 10);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final filteredHistory = history.where((h) {
        final hDate = DateTime(h.guardDate.year, h.guardDate.month, h.guardDate.day);
        return !hDate.isBefore(yesterdayDate);
      }).toList();
      setState(() => _history = filteredHistory);
    } catch (e) {
      print('Error loading history: $e');
    }
  }



  Future<void> _saveAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate it's a weekend or holiday
    if (!_guardService.isWeekendOrHoliday(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las guardias FDS solo pueden registrarse en fines de semana o feriados'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final allIds = [_maquinista1Id, _maquinista2Id, _obacId, ..._bomberoIds]
        .where((id) => id != null)
        .toList();
    final uniqueIds = allIds.toSet();
    if (uniqueIds.length < allIds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede asignar la misma persona en múltiples posiciones'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _guardService.createFdsAttendance(
        guardDate: _selectedDate,
        shiftPeriod: _selectedPeriod,
        maquinista1Id: _maquinista1Id,
        maquinista2Id: _maquinista2Id,
        obacId: _obacId,
        bomberoIds: _bomberoIds,
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

        // Reset form
        _resetForm();
        _loadHistory();
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
      _selectedDate = DateTime.now();
      _selectedPeriod = 'AM';
      _maquinista1Id = null;
      _maquinista2Id = null;
      _obacId = null;
      for (int i = 0; i < _bomberoIds.length; i++) {
        _bomberoIds[i] = null;
      }
      _observationsController.clear();
    });
  }

  int get _assignedCount {
    int count = 0;
    if (_maquinista1Id != null) count++;
    if (_maquinista2Id != null) count++;
    if (_obacId != null) count++;
    count += _bomberoIds.where((id) => id != null).length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asist. a Guardia FDS (AM/PM)'),
        backgroundColor: Colors.blue,
      ),
      drawer: const AppDrawer(),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Guardias de fin de semana y feriados',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and period selection
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  'Hoy - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedPeriod,
                                decoration: const InputDecoration(
                                  labelText: 'Período',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'AM', child: Text('AM')),
                                  DropdownMenuItem(value: 'PM', child: Text('PM')),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedPeriod = value!);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Personnel section
                        Text(
                          'Personal ($_assignedCount/${AppConstants.maxTotalDayGuard})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Maquinistas
                        SearchableUserSelector(
                          label: 'Maquinista 1',
                          selectedUserId: _maquinista1Id,
                          availableUsers: _allUsers,
                          onChanged: (value) => setState(() => _maquinista1Id = value),
                        ),
                        const SizedBox(height: 16),

                        SearchableUserSelector(
                          label: 'Maquinista 2',
                          selectedUserId: _maquinista2Id,
                          availableUsers: _allUsers,
                          onChanged: (value) => setState(() => _maquinista2Id = value),
                        ),
                        const SizedBox(height: 16),

                        // OBAC
                        SearchableUserSelector(
                          label: 'OBAC (Oficial o Bombero A Cargo)',
                          selectedUserId: _obacId,
                          availableUsers: _allUsers,
                          onChanged: (value) => setState(() => _obacId = value),
                        ),
                        const SizedBox(height: 24),

                        // Bomberos
                        const Text(
                          'Bomberos (hasta 10)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...List.generate(10, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SearchableUserSelector(
                              label: 'Bombero ${index + 1}',
                              selectedUserId: _bomberoIds[index],
                              availableUsers: _allUsers,
                              onChanged: (value) {
                                setState(() => _bomberoIds[index] = value);
                              },
                            ),
                          );
                        }),

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
                              backgroundColor: Colors.blue,
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
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    record.shiftPeriod,
                                    style: const TextStyle(color: Colors.white),
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
                                onTap: () {
                                  // TODO: Navigate to detail/edit screen
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }
}

