import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/guard_availability_model.dart';
import 'package:sexta_app/models/guard_registration_period_model.dart';
import 'package:sexta_app/models/guard_roster_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/providers/user_provider.dart';
import 'package:sexta_app/services/guard_registration_period_service.dart';
import 'package:sexta_app/services/guard_roster_service.dart';
import 'package:sexta_app/services/holiday_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/guard_calendar_picker.dart';

/// Screen for users to register their availability for night guards
class GuardAvailabilityScreen extends ConsumerStatefulWidget {
  const GuardAvailabilityScreen({super.key});

  @override
  ConsumerState<GuardAvailabilityScreen> createState() =>
      _GuardAvailabilityScreenState();
}

class _GuardAvailabilityScreenState
    extends ConsumerState<GuardAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  final _guardRosterService = GuardRosterService();
  final _periodService = GuardRegistrationPeriodService();
  final _holidayService = HolidayService();

  late TabController _tabController;

  // ── Nocturna ─────────────────────────────────────────────────────────────
  List<DateTime> _selectedDates = [];
  bool _registerAsDriver = false;
  bool _isLoading = false;
  bool _isSaving = false;

  List<GuardAvailability> _existingAvailability = [];
  UserModel? _currentUser;
  GuardRegistrationPeriod? _activePeriod;
  Map<String, Map<String, dynamic>> _dateCapacity = {};

  // ── FDS ────────────────────────────────────────────────────────────────
  List<DateTime> _fdsSelectedDates = [];
  bool _fdsRegisterAsDriver = false;
  bool _fdsIsSaving = false;
  // Por fecha seleccionada: Map<dateKey, Set<'AM'|'PM'>>
  Map<String, Set<String>> _fdsPeriods = {};
  // Inscripciones existentes FDS
  List<GuardAvailability> _fdsExistingAvailability = [];
  // Capacidad por turno: Map<'AM'|'PM', Map<dateStr, Map>>
  Map<String, Map<String, Map<String, dynamic>>> _fdsCapacity = {};
  // Feriados del año (cacheado)
  List<DateTime> _holidays = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Carga de datos ────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = ref.read(currentUserProvider);
      final activePeriod = await _periodService.getActivePeriod();

      if (_currentUser != null) {
        final startDate = activePeriod?.periodStart ?? DateTime.now();
        final availability = await _guardRosterService.getUserAvailability(
          _currentUser!.id,
          startDate: startDate,
        );

        if (activePeriod != null) {
          // Capacidad nocturna
          final capacityList = await _guardRosterService.getRangeCapacity(
            activePeriod.periodStart,
            activePeriod.periodEnd,
          );
          final capacityMap = <String, Map<String, dynamic>>{};
          for (var item in capacityList) {
            final dateStr = item['date'] as String?;
            if (dateStr != null) capacityMap[dateStr] = item;
          }

          // Cargar feriados
          final holidays = await _holidayService.getHolidayDates(activePeriod.periodStart.year);

          // Capacidad FDS AM y PM
          final fdsCapAm = await _guardRosterService.getRangeCapacity(
            activePeriod.periodStart,
            activePeriod.periodEnd,
            guardType: 'fds',
            shiftPeriod: 'AM',
          );

          final fdsCapPm = await _guardRosterService.getRangeCapacity(
            activePeriod.periodStart,
            activePeriod.periodEnd,
            guardType: 'fds',
            shiftPeriod: 'PM',
          );

          final fdsCapMap = <String, Map<String, Map<String, dynamic>>>{
            'AM': {for (var i in fdsCapAm) if (i['date'] != null) i['date'] as String: i},
            'PM': {for (var i in fdsCapPm) if (i['date'] != null) i['date'] as String: i},
          };

          // Inscripciones FDS del usuario
          final allAvail = await _guardRosterService.getUserAvailability(
            _currentUser!.id,
            startDate: startDate,
          );
          final fdsAvail = allAvail.where((a) => a.guardType == 'fds').toList();

          setState(() {
            _existingAvailability = availability.where((a) => a.guardType == 'nocturna').toList();
            _activePeriod = activePeriod;
            _dateCapacity = capacityMap;
            _holidays = holidays;
            _fdsCapacity = fdsCapMap;
            _fdsExistingAvailability = fdsAvail;
          });
        } else {
          setState(() {
            _existingAvailability = availability.where((a) => a.guardType == 'nocturna').toList();
            _activePeriod = activePeriod;
          });
        }
      } else {
        setState(() => _activePeriod = activePeriod);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar disponibilidad: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── HELPERS de fecha ──────────────────────────────────────────────────────

  bool _isFdsDay(DateTime date) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return true;
    }
    return _holidays.any((h) =>
        h.year == date.year && h.month == date.month && h.day == date.day);
  }

  String _fdsDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Nocturna save ─────────────────────────────────────────────────────────

  Future<void> _saveAvailability() async {
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos una fecha')),
      );
      return;
    }
    if (_currentUser == null) return;
    setState(() => _isSaving = true);

    int saved = 0;
    final List<Map<String, String>> rejections = [];

    try {
      for (final date in _selectedDates) {
        if (_activePeriod != null) {
          if (date.isBefore(_activePeriod!.periodStart) ||
              date.isAfter(_activePeriod!.periodEnd
                  .add(const Duration(days: 1))
                  .subtract(const Duration(seconds: 1)))) {
            continue;
          }
        }
        try {
          await _guardRosterService.registerAvailability(
            userId: _currentUser!.id,
            date: date,
            isDriver: _registerAsDriver,
          );
          saved++;
        } catch (e) {
          final raw = e.toString().replaceFirst('Exception: ', '');
          rejections.add({
            'date': DateFormat('EEEE dd/MM/yyyy', 'es_ES').format(date),
            'reason': raw,
          });
        }
      }

      setState(() {
        _selectedDates = [];
        _registerAsDriver = false;
      });
      await _loadData();

      if (!mounted) return;

      if (saved > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disponibilidad registrada: $saved fecha(s)'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      }
      if (rejections.isNotEmpty) _showAvailabilityErrorDialog(rejections);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── FDS save ──────────────────────────────────────────────────────────────

  Future<void> _saveFdsAvailability() async {
    if (_fdsSelectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un día FDS')),
      );
      return;
    }
    // Verificar que al menos un turno esté seleccionado en total
    bool anyPeriod = false;
    for (final d in _fdsSelectedDates) {
      final periods = _fdsPeriods[_fdsDateKey(d)] ?? {};
      if (periods.isNotEmpty) {
        anyPeriod = true;
        break;
      }
    }
    if (!anyPeriod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un turno (AM o PM)')),
      );
      return;
    }
    if (_currentUser == null) return;
    setState(() => _fdsIsSaving = true);

    int saved = 0;
    try {
      for (final date in _fdsSelectedDates) {
        final periods = _fdsPeriods[_fdsDateKey(date)] ?? {};
        for (final period in ['AM', 'PM']) {
          if (!periods.contains(period)) continue;
          try {
            await _guardRosterService.registerFdsAvailability(
              userId: _currentUser!.id,
              date: date,
              shiftPeriod: period,
              isDriver: _fdsRegisterAsDriver,
            );
            saved++;
          } catch (_) {}
        }
      }

      setState(() {
        _fdsSelectedDates = [];
        _fdsPeriods = {};
        _fdsRegisterAsDriver = false;
      });
      await _loadData();

      if (!mounted) return;
      if (saved > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FDS: $saved turno(s) registrado(s)'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fdsIsSaving = false);
    }
  }

  // ── Dialogs/helpers ───────────────────────────────────────────────────────

  void _showAvailabilityErrorDialog(List<Map<String, String>> rejections) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No se pudieron guardar algunas fechas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Las siguientes fechas no fueron registradas:',
                  style: TextStyle(color: Colors.black87)),
              const SizedBox(height: 12),
              ...rejections.map((r) {
                final isMaq = r['reason']!.toLowerCase().contains('maquinista');
                final icon = isMaq ? Icons.local_shipping : Icons.bed;
                final color = isMaq ? Colors.blue.shade700 : Colors.red.shade700;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['date']!,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(_friendlyReason(r['reason']!),
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _friendlyReason(String raw) {
    if (raw.toLowerCase().contains('maquinista')) {
      return 'Ya existe un maquinista inscrito para este día. Solo puede haber un maquinista por guardia.';
    }
    if (raw.toLowerCase().contains('hombres')) {
      return 'El cupo de camas para la guardia masculina está completo para este día.';
    }
    if (raw.toLowerCase().contains('mujeres')) {
      return 'El cupo de camas para la guardia femenina está completo para este día.';
    }
    if (raw.toLowerCase().contains('día completo') || raw.toLowerCase().contains('dia completo')) {
      return 'La guardia de este día ya tiene el máximo de personas permitidas (10/10).';
    }
    return raw;
  }

  Future<void> _deleteAvailability(GuardAvailability availability) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Eliminar disponibilidad del ${DateFormat('dd/MM/yyyy').format(availability.availableDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _guardRosterService.removeAvailability(availability.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilidad eliminada'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscribir Disponibilidad'),
        backgroundColor: AppTheme.institutionalRed,
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activePeriod == null
              ? _buildNoPeriodState()
              : Column(
                  children: [
                    Material(
                      color: AppTheme.institutionalRed,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        tabs: const [
                          Tab(icon: Icon(Icons.nightlight_round), text: 'Nocturna'),
                          Tab(icon: Icon(Icons.wb_sunny), text: 'Diurna FDS'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _tabController.index == 0
                          ? _buildNocturnaTab()
                          : _buildFdsTab(),
                    ),
                  ],
                ),
    );
  }

  // ── Tab Nocturna (sin cambios) ────────────────────────────────────────────

  Widget _buildNocturnaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodBanner(),
          const SizedBox(height: 16),
          _buildNocturnaInstructions(),
          const SizedBox(height: 24),
          Text('Seleccionar Fechas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          GuardCalendarPicker(
            selectedDates: _selectedDates,
            onDatesChanged: (dates) => setState(() => _selectedDates = dates),
            minDate: _activePeriod!.periodStart,
            maxDate: _activePeriod!.periodEnd,
            dateCapacity: _dateCapacity,
            userGender: _currentUser?.gender == Gender.male
                ? 'M'
                : (_currentUser?.gender == Gender.female ? 'F' : null),
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: _registerAsDriver,
            onChanged: (v) => setState(() => _registerAsDriver = v ?? false),
            title: const Text('Me inscribo como Maquinista'),
            subtitle: const Text('Marque esta opción si puede cumplir el rol de maquinista'),
            activeColor: AppTheme.navyBlue,
          ),
          if (_registerAsDriver && _selectedDates.isNotEmpty)
            ..._buildDriverWarnings(),
          const SizedBox(height: 16),
          ..._buildWeeklyValidation(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving || _selectedDates.isEmpty ? null : _saveAvailability,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving
                  ? 'Guardando...'
                  : 'Guardar Disponibilidad (${_selectedDates.length})'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ),
          const SizedBox(height: 32),
          _buildNocturnaInscriptions(),
        ],
      ),
    );
  }

  // ── Tab FDS ────────────────────────────────────────────────────────────────

  Widget _buildFdsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodBanner(),
          const SizedBox(height: 16),
          _buildFdsInstructions(),
          const SizedBox(height: 24),
          Text('Seleccionar Días FDS', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Solo aparecen seleccionables los sábados, domingos y festivos del período.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildFdsCalendar(),
          const SizedBox(height: 16),
          // Turno selector por cada fecha
          if (_fdsSelectedDates.isNotEmpty) ...[
            Text('Seleccionar Turno(s)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._fdsSelectedDates.map((d) => _buildFdsTurnoSelector(d)),
            const SizedBox(height: 16),
          ],
          CheckboxListTile(
            value: _fdsRegisterAsDriver,
            onChanged: (v) => setState(() => _fdsRegisterAsDriver = v ?? false),
            title: const Text('Soy Maquinista'),
            subtitle: const Text('Marque si puede conducir el carro'),
            activeColor: AppTheme.navyBlue,
          ),
          const SizedBox(height: 8),
          ..._buildFdsWeeklyValidation(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fdsIsSaving || _fdsSelectedDates.isEmpty ? null : _saveFdsAvailability,
              icon: _fdsIsSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_fdsIsSaving
                  ? 'Guardando...'
                  : 'Guardar FDS (${_fdsSelectedDates.length} día(s))'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildFdsInscriptions(),
        ],
      ),
    );
  }

  Widget _buildFdsCalendar() {
    if (_activePeriod == null) return const SizedBox.shrink();
    final start = _activePeriod!.periodStart;
    final end = _activePeriod!.periodEnd;

    // Generar días con patrón seguro (sin Duration)
    final allDays = <DateTime>[];
    int totalDays = end.difference(start).inDays + 1;
    for (int i = 0; i < totalDays; i++) {
      allDays.add(DateTime(start.year, start.month, start.day + i));
    }

    // Organizar en semanas
    final weeks = <List<DateTime?>>[];
    final firstWeekday = start.weekday;
    List<DateTime?> currentWeek = List<DateTime?>.generate(firstWeekday - 1, (_) => null);
    for (final d in allDays) {
      currentWeek.add(d);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) currentWeek.add(null);
      weeks.add(currentWeek);
    }

    final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Column(
      children: [
        Row(
          children: dayLabels.map((l) {
            return Expanded(
              child: Center(
                child: Text(l,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: (l == 'S' || l == 'D')
                            ? Colors.blue.shade700
                            : Colors.grey)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        ...weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: week.map((day) {
                if (day == null) return const Expanded(child: SizedBox());
                final selectable = _isFdsDay(day);
                final key = _fdsDateKey(day);
                final isSelected = _fdsSelectedDates.any((d) =>
                    d.year == day.year && d.month == day.month && d.day == day.day);

                final totalAm = int.tryParse(_fdsCapacity['AM']?[key]?['total']?.toString() ?? '0') ?? 0;
                final totalPm = int.tryParse(_fdsCapacity['PM']?[key]?['total']?.toString() ?? '0') ?? 0;

                Color bg;
                if (!selectable) {
                  bg = Colors.grey.shade200;
                } else if (isSelected) {
                  bg = Colors.blue.shade200;
                } else if (totalAm >= 10 && totalPm >= 10) {
                  bg = Colors.red.shade100;
                } else if (totalAm >= 8 || totalPm >= 8) {
                  bg = Colors.orange.shade100;
                } else {
                  bg = Colors.green.shade50;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: selectable
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _fdsSelectedDates.removeWhere((d) =>
                                    d.year == day.year &&
                                    d.month == day.month &&
                                    d.day == day.day);
                                _fdsPeriods.remove(key);
                              } else {
                                _fdsSelectedDates.add(day);
                                _fdsPeriods[key] = {};
                              }
                            });
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? Border.all(color: Colors.blue.shade700, width: 2)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: selectable ? Colors.black87 : Colors.grey.shade400,
                            ),
                          ),
                          if (selectable) ...[
                            Text(
                              'AM:$totalAm',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: totalAm >= 10 ? Colors.red : Colors.green.shade800),
                            ),
                            Text(
                              'PM:$totalPm',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: totalPm >= 10 ? Colors.red : Colors.green.shade800),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFdsTurnoSelector(DateTime date) {
    final key = _fdsDateKey(date);
    final periods = _fdsPeriods[key] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('EEE dd/MM', 'es_ES').format(date),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            _turnoChip('AM', key, periods),
            const SizedBox(width: 8),
            _turnoChip('PM', key, periods),
          ],
        ),
      ),
    );
  }

  Widget _turnoChip(String period, String key, Set<String> selected) {
    final isOn = selected.contains(period);
    return FilterChip(
      label: Text(period),
      selected: isOn,
      onSelected: (v) {
        setState(() {
          final set = _fdsPeriods[key] ?? {};
          if (v) {
            set.add(period);
          } else {
            set.remove(period);
          }
          _fdsPeriods[key] = set;
        });
      },
      selectedColor: Colors.blue.shade200,
      checkmarkColor: Colors.blue.shade900,
    );
  }

  List<Widget> _buildFdsWeeklyValidation() {
    if (_currentUser == null || _fdsSelectedDates.isEmpty) return [];
    // Para FDS: mínimo 1 guardia por semana (cualquier turno)
    final weekGroups = <DateTime, int>{};
    for (final date in _fdsSelectedDates) {
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final key = _fdsDateKey(date);
      final periods = _fdsPeriods[key] ?? {};
      weekGroups[weekKey] = (weekGroups[weekKey] ?? 0) + periods.length;
    }

    final violations = <String>[];
    for (final entry in weekGroups.entries) {
      if (entry.value < 1) {
        violations.add('Semana del ${DateFormat('dd/MM').format(entry.key)}: sin turnos seleccionados');
      }
    }
    if (violations.isEmpty) return [];

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.yellow.shade700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.yellow.shade900, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Aviso mínimo semanal FDS:',
                  style: TextStyle(color: Colors.yellow.shade900, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...violations.map((v) => Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Text('• $v',
                      style: TextStyle(color: Colors.yellow.shade900, fontSize: 13)),
                )),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildFdsInscriptions() {
    final filtered = _fdsExistingAvailability.where((a) {
      if (_activePeriod == null) return false;
      return !a.availableDate.isBefore(_activePeriod!.periodStart) &&
          !a.availableDate.isAfter(_activePeriod!.periodEnd);
    }).toList();

    // Agrupar por fecha
    final Map<String, List<GuardAvailability>> byDate = {};
    for (final a in filtered) {
      final key = _fdsDateKey(a.availableDate);
      byDate.putIfAbsent(key, () => []).add(a);
    }
    final sortedKeys = byDate.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Mis Inscripciones FDS', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text('${sortedKeys.length} día(s)',
                style: TextStyle(color: AppTheme.navyBlue, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        if (sortedKeys.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No hay inscripciones FDS',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              ),
            ),
          )
        else
          ...sortedKeys.map((key) {
            final items = byDate[key]!;
            final date = items.first.availableDate;
            final periodLabels = items.map((a) => a.shiftPeriod ?? '—').join(', ');
            final hasMaq = items.any((a) => a.isDriver);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.wb_sunny, color: Colors.blue.shade700),
                ),
                title: Text(DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(date)),
                subtitle: Text(
                  hasMaq ? '🚒 Maquinista • $periodLabels' : periodLabels,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map((a) => IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: 'Eliminar ${a.shiftPeriod}',
                    onPressed: () => _deleteAvailability(a),
                  )).toList(),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Nocturna sub-widgets ───────────────────────────────────────────────────

  Widget _buildPeriodBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.efectivaColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.efectivaColor),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.efectivaColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inscripciones Abiertas',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.efectivaColor)),
                Text(_activePeriod!.periodLabel,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNocturnaInstructions() {
    return Card(
      color: AppTheme.navyBlue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text('Instrucciones',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.navyBlue,
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Seleccione las fechas en las que está disponible para guardia nocturna\n'
              '2. Marque "Maquinista" si puede cumplir ese rol\n'
              '3. Presione "Guardar Disponibilidad"\n'
              '4. Puede eliminar inscripciones desde la lista inferior',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFdsInstructions() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text('Instrucciones FDS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '1. Seleccione los días sábado, domingo o festivo\n'
              '2. Para cada día elija el turno: AM (mañana) o PM (tarde), o ambos\n'
              '3. Marque "Soy Maquinista" si corresponde\n'
              '4. Presione "Guardar FDS"',
              style: TextStyle(fontSize: 14, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNocturnaInscriptions() {
    final filteredInscriptions = _existingAvailability.where((inscription) {
      if (_activePeriod == null) return false;
      return !inscription.availableDate.isBefore(_activePeriod!.periodStart) &&
          !inscription.availableDate.isAfter(_activePeriod!.periodEnd);
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Text('Mis Inscripciones', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text('${filteredInscriptions.length} fecha(s)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.navyBlue,
                      fontWeight: FontWeight.bold,
                    )),
          ],
        ),
        const SizedBox(height: 16),
        if (filteredInscriptions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No hay inscripciones registradas',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              ),
            ),
          )
        else
          ...filteredInscriptions.map((availability) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.navyBlue.withOpacity(0.1),
                  child: Icon(
                    availability.isDriver ? Icons.local_shipping : Icons.person,
                    color: AppTheme.navyBlue,
                  ),
                ),
                title: Text(DateFormat('EEEE, dd MMMM yyyy', 'es_ES')
                    .format(availability.availableDate)),
                subtitle: Text(availability.isDriver
                    ? 'Inscrito como Maquinista'
                    : 'Inscrito como Bombero'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteAvailability(availability),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── noPeriod ──────────────────────────────────────────────────────────────

  Widget _buildNoPeriodState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text('No hay período de inscripción abierto',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('El capitán debe abrir el período para poder inscribir disponibilidad.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Validaciones Nocturna ─────────────────────────────────────────────────

  List<Widget> _buildDriverWarnings() {
    final warnings = <Widget>[];
    for (final date in _selectedDates) {
      final dateKey = _fdsDateKey(date);
      final capacity = _dateCapacity[dateKey];
      if (capacity != null) {
        final hasDriver = capacity['has_driver'] as bool? ?? false;
        if (hasDriver) {
          warnings.add(
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade900, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ya hay maquinista para ${DateFormat('dd/MM').format(date)}',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    return warnings;
  }

  List<Widget> _buildWeeklyValidation() {
    if (_currentUser == null || _selectedDates.isEmpty) return [];

    final weekGroups = <DateTime, List<DateTime>>{};
    for (final date in _selectedDates) {
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = DateTime(weekStart.year, weekStart.month, weekStart.day);
      weekGroups.putIfAbsent(weekKey, () => []).add(date);
    }

    int minRequired = 0;
    if (_currentUser!.maritalStatus == MaritalStatus.single) {
      minRequired = 2;
    } else if (_currentUser!.maritalStatus == MaritalStatus.married) {
      minRequired = 1;
    }
    if (minRequired == 0) return [];

    final violations = <String>[];
    for (final entry in weekGroups.entries) {
      if (entry.value.length < minRequired) {
        final weekLabel = DateFormat('dd/MM').format(entry.key);
        violations.add(
            'Semana del $weekLabel tiene ${entry.value.length} guardia(s) (mínimo $minRequired)');
      }
    }
    if (violations.isEmpty) return [];

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.yellow.shade700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.yellow.shade900, size: 20),
                const SizedBox(width: 8),
                Text('No cumples el mínimo semanal:',
                    style: TextStyle(
                        color: Colors.yellow.shade900, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ...violations.map((v) => Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Text('• $v',
                      style: TextStyle(color: Colors.yellow.shade900, fontSize: 13)),
                )),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];
  }
}
