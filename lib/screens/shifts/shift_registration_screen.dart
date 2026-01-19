import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/shift_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Módulo 6: Inscripción Guardia con Validación Cupo 6M/4F
class ShiftRegistrationScreen extends StatefulWidget {
  const ShiftRegistrationScreen({super.key});

  @override
  State<ShiftRegistrationScreen> createState() => _ShiftRegistrationScreenState();
}

class _ShiftRegistrationScreenState extends State<ShiftRegistrationScreen> {
  final _supabase = SupabaseService();
  final _authService = AuthService();
  final _shiftService = ShiftService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedConfigId;
  List<Map<String, dynamic>> _configurations = [];
  Map<DateTime, List<dynamic>> _registrations = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadShiftConfigurations();
  }

  Future<void> _loadShiftConfigurations() async {
    try {
      final configs = await _shiftService.getShiftConfigurations();
      setState(() {
        _configurations = configs.map((c) => c.toJson()).toList();
        if (_configurations.isNotEmpty) {
          _selectedConfigId = _configurations.first['id'];
          _loadRegistrations();
        }
      });
    } catch (e) {
      _showError('Error cargando configuraciones: $e');
    }
  }

  Future<void> _loadRegistrations() async {
    if (_selectedConfigId == null) return;

    setState(() => _isLoading = true);

    try {
      final registrations = await _supabase.getShiftRegistrations(_selectedConfigId!);
      
      // Agrupar por fecha
      final Map<DateTime, List<dynamic>> grouped = {};
      for (final reg in registrations) {
        final date = DateTime.parse(reg['shift_date']).toUtc();
        final dateKey = DateTime(date.year, date.month, date.day);
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(reg);
      }

      setState(() {
        _registrations = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando registros: $e');
    }
  }

  Future<void> _registerForShift(DateTime date) async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');
      if (_selectedConfigId == null) throw Exception('No hay configuración seleccionada');

      // VALIDACIÓN CRÍTICA: Verificar cupo de género
      final validation = await _shiftService.validateShiftRegistration(date, userId);
      
      if (validation['canRegister'] != true) {
        _showError(validation['error']);
        setState(() => _isLoading = false);
        return;
      }

      // Registrar
      await _shiftService.registerForShift(
        configId: _selectedConfigId!,
        userId: userId,
        shiftDate: date,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inscripción exitosa para ${DateFormat('dd/MM/yyyy').format(date)}\n'
              'Hombres: ${validation['male_count']}/${6} | '
              'Mujeres: ${validation['female_count']}/${4}'
            ),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
        _loadRegistrations(); // Reload
      }
    } catch (e) {
      _showError('Error al inscribirse: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelRegistration(DateTime date) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    // Buscar el registro del usuario para esta fecha
    final regs = _registrations[date] ?? [];
    final userReg = regs.firstWhere(
      (r) => r['user_id'] == userId,
      orElse: () => null,
    );

    if (userReg == null) return;

    try {
      await _supabase.deleteShiftRegistration(userReg['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscripción cancelada'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      _loadRegistrations();
    } catch (e) {
      _showError('Error al cancelar: $e');
    }
  }

  bool _isUserRegistered(DateTime date) {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    final regs = _registrations[date] ?? [];
    return regs.any((r) => r['user_id'] == userId);
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
        title: const Text('Inscribir Guardia'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading && _configurations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de período
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Período de Guardia',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedConfigId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Período',
                            ),
                            items: _configurations.map((config) {
                              return DropdownMenuItem<String>(
                                value: config['id'] as String,
                                child: Text(
                                  '${config['period_name']} '
                                  '(${DateFormat('dd/MM').format(DateTime.parse(config['start_date']))} - '
                                  '${DateFormat('dd/MM').format(DateTime.parse(config['end_date']))})',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedConfigId = value;
                                _loadRegistrations();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Calendario
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calendario de Guardias',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca un día para inscribirte. Cupo: 6 Hombres / 4 Mujeres',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TableCalendar(
                            firstDay: DateTime.now(),
                            lastDay: DateTime.now().add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            calendarFormat: CalendarFormat.month,
                            eventLoader: (day) {
                              final dateKey = DateTime(day.year, day.month, day.day);
                              return _registrations[dateKey] ?? [];
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            calendarStyle: CalendarStyle(
                              markersMaxCount: 1,
                              markerDecoration: const BoxDecoration(
                                color: AppTheme.navyBlue,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: AppTheme.institutionalRed,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: AppTheme.institutionalRed.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Detalles del día seleccionado
                  if (_selectedDay != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE dd/MM/yyyy', 'es_ES').format(_selectedDay!),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 20),
                            
                            // Cupo actual
                            _buildQuotaStatus(_selectedDay!),
                            const SizedBox(height: 20),
                            
                            // Botón inscribirse/cancelar
                            SizedBox(
                              width: double.infinity,
                              child: _isUserRegistered(_selectedDay!)
                                  ? OutlinedButton.icon(
                                      onPressed: () => _cancelRegistration(_selectedDay!),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Cancelar Inscripción'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.criticalColor,
                                        side: const BorderSide(color: AppTheme.criticalColor),
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: _isLoading 
                                          ? null 
                                          : () => _registerForShift(_selectedDay!),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Inscribirme a esta Guardia'),
                                    ),
                            ),
                            
                            // Lista de inscritos
                            if (_registrations[_selectedDay!] != null) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              Text(
                                'Bomberos Inscritos (${_registrations[_selectedDay!]!.length})',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ..._registrations[_selectedDay!]!.map((reg) {
                                final user = reg['user'];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: user['gender'] == 'M' 
                                        ? AppTheme.abonoColor 
                                        : Colors.pink,
                                    child: Text(
                                      user['gender'],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user['full_name']),
                                  subtitle: Text(user['rank']),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQuotaStatus(DateTime date) {
    final regs = _registrations[date] ?? [];
    final maleCount = regs.where((r) => r['user']['gender'] == 'M').length;
    final femaleCount = regs.where((r) => r['user']['gender'] == 'F').length;
    
    return Column(
      children: [
        _buildQuotaBar(
          'Hombres',
          maleCount,
          6,
          AppTheme.abonoColor,
          Icons.male,
        ),
        const SizedBox(height: 12),
        _buildQuotaBar(
          'Mujeres',
          femaleCount,
          4,
          Colors.pink,
          Icons.female,
        ),
      ],
    );
  }

  Widget _buildQuotaBar(String label, int current, int max, Color color, IconData icon) {
    final percentage = current / max;
    final isFull = current >= max;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              '$label: $current/$max',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isFull ? AppTheme.criticalColor : Colors.black87,
              ),
            ),
            if (isFull) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text('COMPLETO', style: TextStyle(fontSize: 10, color: Colors.white)),
                backgroundColor: AppTheme.criticalColor,
                padding: EdgeInsets.zero,
                labelPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(
              isFull ? AppTheme.criticalColor : color,
            ),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
