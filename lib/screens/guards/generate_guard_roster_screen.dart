import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/guard_roster_model.dart';
import 'package:sexta_app/models/guard_availability_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/providers/user_provider.dart';
import 'package:sexta_app/services/guard_roster_service.dart';
import 'package:sexta_app/services/holiday_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/user_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/guard_position_selector.dart';

class DayAssignment {
  String? maquinistaId;
  String? obacId;
  List<String?> bomberoIds;

  DayAssignment({
    this.maquinistaId,
    this.obacId,
    List<String?>? bomberoIds,
  }) : bomberoIds = bomberoIds ?? List.filled(8, null);

  int get totalAssigned {
    int count = 0;
    if (maquinistaId != null) count++;
    if (obacId != null) count++;
    count += bomberoIds.where((id) => id != null).length;
    return count;
  }

  Map<String, int> getGenderDistribution(Map<String, UserModel> usersMap) {
    int males = 0;
    int females = 0;

    void countGender(String? userId) {
      if (userId == null) return;
      final user = usersMap[userId];
      if (user == null) return;
      if (user.gender == Gender.male) {
        males++;
      } else if (user.gender == Gender.female) {
        females++;
      }
    }

    countGender(maquinistaId);
    countGender(obacId);
    for (var id in bomberoIds) {
      countGender(id);
    }

    return {'males': males, 'females': females};
  }
}

class GenerateGuardRosterScreen extends ConsumerStatefulWidget {
  const GenerateGuardRosterScreen({super.key});

  @override
  ConsumerState<GenerateGuardRosterScreen> createState() =>
      _GenerateGuardRosterScreenState();
}

class _GenerateGuardRosterScreenState
    extends ConsumerState<GenerateGuardRosterScreen>
    with SingleTickerProviderStateMixin {
  final GuardRosterService _rosterService = GuardRosterService();
  final UserService _userService = UserService();
  final SupabaseService _supabaseService = SupabaseService();
  final HolidayService _holidayService = HolidayService();

  late TabController _tabController;

  // ── Nocturna ─────────────────────────────────────────────────────────────
  DateTime _currentWeekStart = DateTime.now();
  final Map<int, DayAssignment> _weekAssignments = {};
  Map<DateTime, List<GuardAvailability>> _weeklyAvailability = {};
  Map<String, UserModel> _usersMap = {};
  GuardRosterWeekly? _weeklyRoster;
  List<UserModel> _allUsers = [];
  // userId -> Set de dateKeys 'yyyy-MM-dd' con permiso aprobado en la semana
  Map<String, Set<String>> _permisosMap = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGenerating = false;
  bool _isPublishing = false;

  // ── FDS ────────────────────────────────────────────────────────────────
  DateTime _fdsWeekStart = DateTime.now();
  // Map<dayIndex dentro de la semana, Map<'AM'|'PM', DayAssignment>>
  final Map<int, Map<String, DayAssignment>> _fdsAssignments = {};
  Map<DateTime, List<GuardAvailability>> _fdsAvailabilityAm = {};
  Map<DateTime, List<GuardAvailability>> _fdsAvailabilityPm = {};
  GuardRosterWeekly? _fdsWeeklyRoster;
  List<DateTime> _holidays = [];
  bool _fdsIsLoading = false;
  bool _fdsIsSaving = false;
  bool _fdsIsGenerating = false;
  bool _fdsIsPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentWeekStart = _rosterService.getWeekStart(DateTime.now());
    _currentWeekStart = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
    _fdsWeekStart = _currentWeekStart;
    _initializeWeekAssignments();
    _initializeFdsAssignments();
    _loadData();
    _loadFdsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeWeekAssignments() {
    for (int i = 0; i < 7; i++) {
      _weekAssignments[i] = DayAssignment();
    }
  }

  void _initializeFdsAssignments() {
    _fdsAssignments.clear();
    for (int i = 0; i < 7; i++) {
      _fdsAssignments[i] = {
        'AM': DayAssignment(),
        'PM': DayAssignment(),
      };
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final users = await _userService.getAllUsers();
      _allUsers = users;
      _usersMap = {for (var u in _allUsers) u.id: u};

      final weekEnd = _rosterService.getWeekEnd(_currentWeekStart);
      _weeklyRoster = await _rosterService.getWeeklyRoster(_currentWeekStart);

      _weeklyAvailability = await _rosterService.getWeeklyAvailability(_currentWeekStart);

      // Cargar permisos aprobados que se solapan con la semana
      final permisosRaw = await _supabaseService
          .getApprovedPermissionsBetweenDates(_currentWeekStart, weekEnd);
      final newPermisosMap = <String, Set<String>>{};
      for (final p in permisosRaw) {
        final userId = p['user_id'] as String?;
        if (userId == null) continue;
        final start = DateTime.tryParse(p['start_date'] as String? ?? '');
        final end = DateTime.tryParse(p['end_date'] as String? ?? '');
        if (start == null || end == null) continue;
        // Marcar cada día de la semana cubierto por el permiso
        for (int i = 0; i < 7; i++) {
          final day = _currentWeekStart.add(Duration(days: i));
          if (!day.isBefore(start) && !day.isAfter(end)) {
            final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
            newPermisosMap.putIfAbsent(userId, () => {}).add(key);
          }
        }
      }
      _permisosMap = newPermisosMap;

      if (_weeklyRoster != null) {
        final dailyRosters = await _rosterService
            .getDailyRostersForWeek(_weeklyRoster!.id ?? '');
        for (var daily in dailyRosters) {
          final dayIndex = daily.guardDate.difference(_currentWeekStart).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            _weekAssignments[dayIndex] = DayAssignment(
              maquinistaId: daily.maquinistaId,
              obacId: daily.obacId,
              bomberoIds: List<String?>.from(daily.bomberoIds ?? []),
            );
            while (_weekAssignments[dayIndex]!.bomberoIds.length < 8) {
              _weekAssignments[dayIndex]!.bomberoIds.add(null);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeWeek(int delta) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7 * delta));
      _currentWeekStart = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
      _initializeWeekAssignments();
    });
    _loadData();
  }

  void _changeFdsWeek(int delta) {
    setState(() {
      _fdsWeekStart = _fdsWeekStart.add(Duration(days: 7 * delta));
      _fdsWeekStart = DateTime(_fdsWeekStart.year, _fdsWeekStart.month, _fdsWeekStart.day);
      _initializeFdsAssignments();
    });
    _loadFdsData();
  }

  void _goToCurrentWeek() {
    final now = DateTime.now();
    final currentWeek = _rosterService.getWeekStart(now);
    if (_currentWeekStart != currentWeek) {
      setState(() {
        _currentWeekStart = currentWeek;
        _currentWeekStart = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
        _initializeWeekAssignments();
      });
      _loadData();
    }
  }

  String _formatWeekRange() {
    final weekEnd = _rosterService.getWeekEnd(_currentWeekStart);
    final formatter = DateFormat('dd MMM', 'es');
    return '${formatter.format(_currentWeekStart)} - ${formatter.format(weekEnd)} ${_currentWeekStart.year}';
  }

  String _formatFdsWeekRange() {
    final weekEnd = _rosterService.getWeekEnd(_fdsWeekStart);
    final formatter = DateFormat('dd MMM', 'es');
    return '${formatter.format(_fdsWeekStart)} - ${formatter.format(weekEnd)} ${_fdsWeekStart.year}';
  }

  String _formatUserName(UserModel user) {
    return user.fullName;
  }

  bool _isUserAvailable(String userId, int dayIndex) {
    final date = _currentWeekStart.add(Duration(days: dayIndex));
    final targetDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    for (var entry in _weeklyAvailability.entries) {
      final entryDate = '${entry.key.year}-${entry.key.month.toString().padLeft(2, '0')}-${entry.key.day.toString().padLeft(2, '0')}';
      if (entryDate == targetDate) {
        return entry.value.any((a) => a.userId == userId);
      }
    }
    return false;
  }

  bool _userHasPermiso(String userId, int dayIndex) {
    final date = _currentWeekStart.add(Duration(days: dayIndex));
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _permisosMap[userId]?.contains(key) ?? false;
  }

  bool _userHasPermisoAnyDay(String userId) {
    return _permisosMap.containsKey(userId) && _permisosMap[userId]!.isNotEmpty;
  }

  Future<void> _selectUserForPosition(
      int dayIndex, String position, int? bomberoIndex) async {
    final assignment = _weekAssignments[dayIndex]!;
    String? currentUserId;
    
    if (position == 'maquinista') {
      currentUserId = assignment.maquinistaId;
    } else if (position == 'obac') {
      currentUserId = assignment.obacId;
    } else if (position == 'bombero' && bomberoIndex != null) {
      currentUserId = assignment.bomberoIds[bomberoIndex];
    }
    
    // Si la celda ya tiene un usuario, mostrar opciones
    if (currentUserId != null) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Opciones'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'change'),
              child: const Row(
                children: [
                  Icon(Icons.swap_horiz),
                  SizedBox(width: 8),
                  Text('Cambiar bombero'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'clear'),
              child: const Row(
                children: [
                  Icon(Icons.clear, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Quitar asignación', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      );
      
      if (action == 'clear' && mounted) {
        setState(() {
          if (position == 'maquinista') {
            assignment.maquinistaId = null;
          } else if (position == 'obac') {
            assignment.obacId = null;
          } else if (position == 'bombero' && bomberoIndex != null) {
            assignment.bomberoIds[bomberoIndex] = null;
          }
        });
        return;
      } else if (action != 'change') {
        return;
      }
    }
    
    // Abrir selector de usuario
    final result = await showUserSelectorDialog(
      context: context,
      users: _allUsers,
      title: 'Seleccionar Bombero',
    );

    if (result != null && mounted) {
      // Verificar si el bombero seleccionado tiene permiso aprobado para ese día
      if (_userHasPermiso(result, dayIndex)) {
        final date = _currentWeekStart.add(Duration(days: dayIndex));
        final fechaStr = DateFormat('EEEE dd/MM/yyyy', 'es_ES').format(date);
        final usuario = _usersMap[result];
        final nombreCompleto = usuario?.fullName ?? 'Este bombero';
        final continuar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.event_busy, color: Colors.orange.shade700, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Permiso aprobado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              '$nombreCompleto tiene un permiso aprobado para el $fechaStr.\n\n'
              '¿Desea asignarlo de todas formas?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Asignar de todas formas'),
              ),
            ],
          ),
        );
        if (continuar != true || !mounted) return;
      }

      setState(() {
        if (position == 'maquinista') {
          assignment.maquinistaId = result;
        } else if (position == 'obac') {
          assignment.obacId = result;
        } else if (position == 'bombero' && bomberoIndex != null) {
          assignment.bomberoIds[bomberoIndex] = result;
        }
      });
    }
  }

  Widget _buildUserCell(int dayIndex, String position, int? bomberoIndex) {
    final assignment = _weekAssignments[dayIndex]!;
    String? userId;

    if (position == 'maquinista') {
      userId = assignment.maquinistaId;
    } else if (position == 'obac') {
      userId = assignment.obacId;
    } else if (position == 'bombero' && bomberoIndex != null) {
      userId = assignment.bomberoIds[bomberoIndex];
    }

    final user = userId != null ? _usersMap[userId] : null;
    final isAvailable = userId != null ? _isUserAvailable(userId, dayIndex) : true;
    final tienePermiso = userId != null ? _userHasPermiso(userId, dayIndex) : false;

    Color backgroundColor;
    if (user == null) {
      backgroundColor = Colors.white;
    } else if (tienePermiso) {
      backgroundColor = Colors.purple.shade100;
    } else if (isAvailable) {
      backgroundColor = const Color(0xFFC8E6C9);
    } else {
      backgroundColor = const Color(0xFFFFE082);
    }

    return InkWell(
      onTap: () => _selectUserForPosition(dayIndex, position, bomberoIndex),
      child: Container(
        width: 100,
        height: 44,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: tienePermiso ? Colors.purple.shade300 : Colors.grey.shade300,
            width: tienePermiso ? 1.5 : 1.0,
          ),
          color: backgroundColor,
        ),
        child: user != null
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    _formatUserName(user),
                    style: const TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tienePermiso)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Icon(
                        Icons.event_busy,
                        size: 12,
                        color: Colors.purple.shade700,
                      ),
                    ),
                ],
              )
            : Text(
                '(vacío)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
      ),
    );
  }

  Widget _buildTotalRow(int dayIndex) {
    final assignment = _weekAssignments[dayIndex]!;
    final total = assignment.totalAssigned;
    final cuposLibres = 10 - total;
    
    // Determinar color y texto
    Color color;
    String text;
    
    if (total >= 10) {
      color = Colors.red;
      text = '10/10 (Completo)';
    } else {
      text = '$total/10 ($cuposLibres cupos)';
      
      if (total >= 8) {
        color = Colors.green;
      } else if (total >= 5) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
    }

    return Container(
      width: 100,
      height: 44,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300), // Borde gris claro
        color: Colors.grey.shade100, // Fondo gris muy claro
      ),
      child: Center( // Center content
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold, 
            color: color
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildGenderRow(int dayIndex) {
    final assignment = _weekAssignments[dayIndex]!;
    final dist = assignment.getGenderDistribution(_usersMap);
    final males = dist['males'] ?? 0;
    final females = dist['females'] ?? 0;
    final compliant = males <= 6 && females <= 4;

    return Container(
      width: 100,
      height: 44,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade100,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${males}H/${females}M',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Icon(
            compliant ? Icons.check_circle : Icons.warning,
            color: compliant ? Colors.green : Colors.orange,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildRosterGrid() {
    final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final positions = [
      'Maquinista',
      'OBAC',
      'Bombero 1',
      'Bombero 2',
      'Bombero 3',
      'Bombero 4',
      'Bombero 5',
      'Bombero 6',
      'Bombero 7',
      'Bombero 8',
      'Total',
      'Género',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna fija de labels
          SizedBox(
            width: 100,
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: AppTheme.institutionalRed,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Posición',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                ...positions.map((pos) {
                  return Container(
                    height: 44,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade200,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      pos,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Columnas de días
          ...List.generate(7, (dayIndex) {
            return SizedBox(
              width: 100,
              child: Column(
                children: [
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: AppTheme.institutionalRed,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      weekdays[dayIndex],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _buildUserCell(dayIndex, 'maquinista', null),
                  _buildUserCell(dayIndex, 'obac', null),
                  ...List.generate(
                      8, (i) => _buildUserCell(dayIndex, 'bombero', i)),
                  _buildTotalRow(dayIndex),
                  _buildGenderRow(dayIndex),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompliancePanel() {
    final complianceData = <Map<String, dynamic>>[];

    for (var user in _allUsers) {
      // Verificar si el usuario está asignado en algún día
      int assigned = 0;
      for (var assignment in _weekAssignments.values) {
        if (assignment.maquinistaId == user.id) assigned++;
        if (assignment.obacId == user.id) assigned++;
        if (assignment.bomberoIds.contains(user.id)) assigned++;
      }
      
      // Verificar si es honorario/postulante/aspirante
      final rankLower = user.rank.toLowerCase();
      final isExcluded = rankLower.contains('honorario') || 
                         rankLower.contains('postulante') || 
                         rankLower.contains('aspirante');
      
      // Si es excluido y no está asignado, saltar
      if (isExcluded && assigned == 0) continue;
      
      int minRequired = 0;
      String civilStatus = '';
      bool isHonorario = false;

      if (isExcluded) {
        isHonorario = true;
        civilStatus = 'Honorario';
        minRequired = 0;
      } else if (user.maritalStatus == MaritalStatus.single) {
        minRequired = 2;
        civilStatus = 'Soltero';
      } else if (user.maritalStatus == MaritalStatus.married) {
        minRequired = 1;
        civilStatus = 'Casado';
      } else {
        isHonorario = true;
        civilStatus = 'Honorario';
      }

      complianceData.add({
        'user': user,
        'civilStatus': civilStatus,
        'minRequired': minRequired,
        'assigned': assigned,
        'balance': isHonorario ? 0 : (assigned - minRequired),
        'isHonorario': isHonorario,
      });
    }

    complianceData.sort((a, b) {
      if (a['isHonorario'] && !b['isHonorario']) return 1;
      if (!a['isHonorario'] && b['isHonorario']) return -1;
      if (a['isHonorario'] && b['isHonorario']) return 0;

      final balA = a['balance'] as int;
      final balB = b['balance'] as int;
      if (balA < 0 && balB >= 0) return -1;
      if (balA >= 0 && balB < 0) return 1;
      if (balA < 0 && balB < 0) return balA.compareTo(balB);
      if (balA == 0 && balB > 0) return -1;
      if (balA > 0 && balB == 0) return 1;
      return balA.compareTo(balB);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Cumplimiento Semanal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 32,
                  columnSpacing: 8,
                  horizontalMargin: 8,
                  columns: const [
                    DataColumn(label: Text('Nombre', style: TextStyle(fontSize: 11))),
                    DataColumn(label: SizedBox(width: 55, child: Text('E. Civil', style: TextStyle(fontSize: 11)))),
                    DataColumn(label: SizedBox(width: 30, child: Text('Mín', style: TextStyle(fontSize: 11)))),
                    DataColumn(label: SizedBox(width: 30, child: Text('Asig', style: TextStyle(fontSize: 11)))),
                    DataColumn(label: SizedBox(width: 30, child: Text('Bal', style: TextStyle(fontSize: 11)))),
                    DataColumn(label: SizedBox(width: 30, child: Text('Perm', style: TextStyle(fontSize: 11)))),
                  ],
                  rows: complianceData.map((data) {
                    final user = data['user'] as UserModel;
                    final isHonorario = data['isHonorario'] as bool;
                    final balance = data['balance'] as int;
                    final tienePermiso = _userHasPermisoAnyDay(user.id);

                    Color? rowColor;
                    if (tienePermiso) {
                      rowColor = Colors.purple.shade50;
                    } else if (isHonorario) {
                      rowColor = Colors.grey.shade200;
                    } else if (balance < 0) {
                      rowColor = Colors.red.shade100;
                    } else if (balance == 0) {
                      rowColor = Colors.green.shade100;
                    } else {
                      rowColor = Colors.blue.shade100;
                    }

                    return DataRow(
                      color: WidgetStateProperty.all(rowColor),
                      cells: [
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(_formatUserName(user), style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(data['civilStatus'], style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(isHonorario ? '—' : '${data['minRequired']}', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text('${data['assigned']}', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(isHonorario ? '—' : '$balance', style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        DataCell(
                          tienePermiso
                              ? Tooltip(
                                  message: 'Tiene permiso aprobado esta semana',
                                  child: Icon(Icons.event_busy, size: 16, color: Colors.purple.shade700),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAuto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar Automáticamente'),
        content: const Text(
            '¿Deseas generar el rol automáticamente? Esto sobrescribirá cualquier asignación manual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isGenerating = true);

    try {
      if (_weeklyRoster == null) {
        final weekEnd = _rosterService.getWeekEnd(_currentWeekStart);
        final currentUser = ref.read(currentUserProvider);
       _weeklyRoster = await _rosterService.createWeeklyRoster(
        weekStart: _currentWeekStart,
        weekEnd: weekEnd,
        createdBy: currentUser?.id ?? '',
); 
      }

      // Eliminar asignaciones diarias existentes para regenerar
      if (_weeklyRoster?.id != null) {
        await Supabase.instance.client
            .from('guard_roster_daily')
            .delete()
            .eq('roster_week_id', _weeklyRoster!.id!);
      }

      await _rosterService.generateWeeklyRoster(
      rosterWeekId: _weeklyRoster!.id ?? '',
      weekStart: _currentWeekStart,
      allUsers: _allUsers,
);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol generado exitosamente')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _saveRoster() async {
    // Validar género antes de guardar
    final genderViolations = <String>[];
    for (int i = 0; i < 7; i++) {
      final assignment = _weekAssignments[i]!;
      final dist = assignment.getGenderDistribution(_usersMap);
      final males = dist['males'] ?? 0;
      final females = dist['females'] ?? 0;
      
      if (males > 6 || females > 4) {
        final weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        genderViolations.add('- ${weekdays[i]}: ${males}H/${females}M');
      }
    }

    if (genderViolations.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alerta de Género'),
          content: Text(
            'Los siguientes días exceden el límite 6H/4M:\n${genderViolations.join('\n')}\n\n¿Desea continuar de todas formas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    setState(() => _isSaving = true);

    try {
      if (_weeklyRoster == null) {
        final weekEnd2 = _rosterService.getWeekEnd(_currentWeekStart);
        final currentUser2 = ref.read(currentUserProvider);
        _weeklyRoster = await _rosterService.createWeeklyRoster(
         weekStart: _currentWeekStart,
         weekEnd: weekEnd2,
         createdBy: currentUser2?.id ?? '',
);
      }

      for (int i = 0; i < 7; i++) {
        final date = _currentWeekStart.add(Duration(days: i));
        final assignment = _weekAssignments[i]!;

        await _rosterService.saveDailyRoster(
          rosterWeekId: _weeklyRoster!.id ?? '',
          guardDate: date,
          maquinistaId: assignment.maquinistaId,
          obacId: assignment.obacId,
          bomberoIds: assignment.bomberoIds.whereType<String>().toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol guardado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ── FDS LOGIC ────────────────────────────────────────────────────────────

  Future<void> _loadFdsData() async {
    setState(() => _fdsIsLoading = true);
    try {
      final holidays = await _holidayService.getHolidayDates(_fdsWeekStart.year);
      _fdsWeeklyRoster = await _rosterService.getWeeklyRoster(_fdsWeekStart, guardType: 'fds');
      _fdsAvailabilityAm = await _rosterService.getWeeklyAvailability(
        _fdsWeekStart, guardType: 'fds', shiftPeriod: 'AM');
      _fdsAvailabilityPm = await _rosterService.getWeeklyAvailability(
        _fdsWeekStart, guardType: 'fds', shiftPeriod: 'PM');

      _initializeFdsAssignments();

      if (_fdsWeeklyRoster != null) {
        final dailyRosters =
            await _rosterService.getDailyRostersForWeek(_fdsWeeklyRoster!.id ?? '');
        for (var daily in dailyRosters) {
          final dayIndex = daily.guardDate.difference(_fdsWeekStart).inDays;
          if (dayIndex < 0 || dayIndex >= 7) continue;
          final period = daily.shiftPeriod ?? 'AM';
          if (period != 'AM' && period != 'PM') continue;
          _fdsAssignments[dayIndex]![period] = DayAssignment(
            maquinistaId: daily.maquinistaId,
            obacId: daily.obacId,
            bomberoIds: List<String?>.from(daily.bomberoIds),
          );
          while (_fdsAssignments[dayIndex]![period]!.bomberoIds.length < 8) {
            _fdsAssignments[dayIndex]![period]!.bomberoIds.add(null);
          }
        }
      }

      setState(() => _holidays = holidays);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos FDS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _fdsIsLoading = false);
    }
  }

  bool _isFdsDay(DateTime date) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) return true;
    return _holidays.any((h) =>
        h.year == date.year && h.month == date.month && h.day == date.day);
  }

  bool _isFdsUserAvailable(
      String userId, int dayIndex, String period) {
    final avail =
        period == 'AM' ? _fdsAvailabilityAm : _fdsAvailabilityPm;
    final date = _fdsWeekStart.add(Duration(days: dayIndex));
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    for (var entry in avail.entries) {
      final eKey =
          '${entry.key.year}-${entry.key.month.toString().padLeft(2, '0')}-${entry.key.day.toString().padLeft(2, '0')}';
      if (eKey == key) return entry.value.any((a) => a.userId == userId);
    }
    return false;
  }

  Future<void> _selectFdsUserForPosition(
      int dayIndex, String period, String position, int? bomberoIndex) async {
    final assignment = _fdsAssignments[dayIndex]![period]!;
    String? currentUserId;
    if (position == 'maquinista') currentUserId = assignment.maquinistaId;
    else if (position == 'obac') currentUserId = assignment.obacId;
    else if (position == 'bombero' && bomberoIndex != null)
      currentUserId = assignment.bomberoIds[bomberoIndex];

    if (currentUserId != null) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Opciones'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'change'),
              child: const Row(children: [
                Icon(Icons.swap_horiz), SizedBox(width: 8), Text('Cambiar bombero')
              ]),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'clear'),
              child: const Row(children: [
                Icon(Icons.clear, color: Colors.red),
                SizedBox(width: 8),
                Text('Quitar asignación', style: TextStyle(color: Colors.red))
              ]),
            ),
          ],
        ),
      );
      if (action == 'clear' && mounted) {
        setState(() {
          if (position == 'maquinista') assignment.maquinistaId = null;
          else if (position == 'obac') assignment.obacId = null;
          else if (position == 'bombero' && bomberoIndex != null)
            assignment.bomberoIds[bomberoIndex] = null;
        });
        return;
      } else if (action != 'change') return;
    }

    final result = await showUserSelectorDialog(
      context: context,
      users: _allUsers,
      title: 'Seleccionar Bombero',
    );
    if (result != null && mounted) {
      setState(() {
        if (position == 'maquinista') assignment.maquinistaId = result;
        else if (position == 'obac') assignment.obacId = result;
        else if (position == 'bombero' && bomberoIndex != null)
          assignment.bomberoIds[bomberoIndex] = result;
      });
    }
  }

  Widget _buildFdsUserCell(
      int dayIndex, String period, String position, int? bomberoIndex) {
    final assignment = _fdsAssignments[dayIndex]![period]!;
    String? userId;
    if (position == 'maquinista') userId = assignment.maquinistaId;
    else if (position == 'obac') userId = assignment.obacId;
    else if (position == 'bombero' && bomberoIndex != null)
      userId = assignment.bomberoIds[bomberoIndex];

    final user = userId != null ? _usersMap[userId] : null;
    final isAvail = userId != null ? _isFdsUserAvailable(userId, dayIndex, period) : true;

    final bg = user == null
        ? Colors.white
        : (isAvail ? const Color(0xFFC8E6C9) : const Color(0xFFFFE082));

    return InkWell(
      onTap: () =>
          _selectFdsUserForPosition(dayIndex, period, position, bomberoIndex),
      child: Container(
        width: 90,
        height: 44,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: bg,
        ),
        child: user != null
            ? Text(_formatUserName(user),
                style: const TextStyle(fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)
            : Text('(vacío)',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildFdsTotalCell(int dayIndex, String period) {
    final a = _fdsAssignments[dayIndex]![period]!;
    final total = a.totalAssigned;
    final color = total >= 10
        ? Colors.red
        : total >= 8
            ? Colors.green
            : total >= 5
                ? Colors.orange
                : Colors.red;
    return Container(
      width: 90,
      height: 44,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100),
      child: Center(
        child: Text('$total/10',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildFdsRosterGrid(List<int> fdsDayIndexes) {
    final positions = [
      'Maquinista', 'OBAC',
      'Bombero 1', 'Bombero 2', 'Bombero 3', 'Bombero 4',
      'Bombero 5', 'Bombero 6', 'Bombero 7', 'Bombero 8',
      'Total',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna labels
          SizedBox(
            width: 90,
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.blue.shade700,
                  ),
                  alignment: Alignment.center,
                  child: const Text('Posición',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12)),
                ),
                ...positions.map((pos) => Container(
                      height: 44,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade200,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(pos,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    )),
              ],
            ),
          ),
          // Por cada día FDS, 2 columnas AM/PM
          ...fdsDayIndexes.expand((dayIndex) {
            final date = _fdsWeekStart.add(Duration(days: dayIndex));
            final dayLabel = DateFormat('EEE dd/MM', 'es_ES').format(date);
            return ['AM', 'PM'].map((period) {
              return SizedBox(
                width: 90,
                child: Column(
                  children: [
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.blue.shade700,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayLabel\n$period',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _buildFdsUserCell(dayIndex, period, 'maquinista', null),
                    _buildFdsUserCell(dayIndex, period, 'obac', null),
                    ...List.generate(8,
                        (i) => _buildFdsUserCell(dayIndex, period, 'bombero', i)),
                    _buildFdsTotalCell(dayIndex, period),
                  ],
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFdsCompliancePanel() {
    final complianceData = <Map<String, dynamic>>[];
    for (var user in _allUsers) {
      int assigned = 0;
      for (final dayMap in _fdsAssignments.values) {
        for (final a in dayMap.values) {
          if (a.maquinistaId == user.id) assigned++;
          if (a.obacId == user.id) assigned++;
          if (a.bomberoIds.contains(user.id)) assigned++;
        }
      }
      final rankLower = user.rank.toLowerCase();
      final isExcluded = rankLower.contains('honorario') ||
          rankLower.contains('postulante') ||
          rankLower.contains('aspirante');
      if (isExcluded && assigned == 0) continue;

      int minRequired = 0;
      String civilStatus = '';
      bool isHonorario = false;
      if (isExcluded) {
        isHonorario = true;
        civilStatus = 'Honorario';
      } else if (user.maritalStatus == MaritalStatus.single) {
        minRequired = 1;
        civilStatus = 'Soltero';
      } else if (user.maritalStatus == MaritalStatus.married) {
        minRequired = 1;
        civilStatus = 'Casado';
      } else {
        isHonorario = true;
        civilStatus = 'Honorario';
      }

      complianceData.add({
        'user': user,
        'civilStatus': civilStatus,
        'minRequired': minRequired,
        'assigned': assigned,
        'balance': isHonorario ? 0 : (assigned - minRequired),
        'isHonorario': isHonorario,
      });
    }

    complianceData.sort((a, b) {
      if (a['isHonorario'] && !b['isHonorario']) return 1;
      if (!a['isHonorario'] && b['isHonorario']) return -1;
      final balA = a['balance'] as int;
      final balB = b['balance'] as int;
      if (balA < 0 && balB >= 0) return -1;
      if (balA >= 0 && balB < 0) return 1;
      return balA.compareTo(balB);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Cumplimiento FDS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 32,
                  columnSpacing: 8,
                  horizontalMargin: 8,
                  columns: const [
                    DataColumn(label: Text('Nombre', style: TextStyle(fontSize: 11))),
                    DataColumn(label: SizedBox(width: 50, child: Text('Estado', style: TextStyle(fontSize: 11)))),
                    DataColumn(label: SizedBox(width: 30, child: Text('Mín', style: TextStyle(fontSize: 11)))),
                    DataColumn(label: SizedBox(width: 30, child: Text('Asig', style: TextStyle(fontSize: 11)))),
                    DataColumn(label: SizedBox(width: 30, child: Text('Bal', style: TextStyle(fontSize: 11)))),
                  ],
                  rows: complianceData.map((data) {
                    final user = data['user'] as UserModel;
                    final isHonorario = data['isHonorario'] as bool;
                    final balance = data['balance'] as int;

                    Color? rowColor;
                    if (isHonorario) rowColor = Colors.grey.shade200;
                    else if (balance < 0) rowColor = Colors.red.shade100;
                    else if (balance == 0) rowColor = Colors.green.shade100;
                    else rowColor = Colors.blue.shade100;

                    return DataRow(
                      color: WidgetStateProperty.all(rowColor),
                      cells: [
                        DataCell(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(_formatUserName(user), style: const TextStyle(fontSize: 11)),
                        )),
                        DataCell(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(data['civilStatus'], style: const TextStyle(fontSize: 11)),
                        )),
                        DataCell(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(isHonorario ? '—' : '${data['minRequired']}',
                              style: const TextStyle(fontSize: 11)),
                        )),
                        DataCell(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text('${data['assigned']}', style: const TextStyle(fontSize: 11)),
                        )),
                        DataCell(Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(isHonorario ? '—' : '$balance',
                              style: const TextStyle(fontSize: 11)),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateFdsAuto(List<int> fdsDayIndexes) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar FDS Automáticamente'),
        content: const Text('¿Generar el rol FDS? Esto sobrescribirá asignaciones manuales.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Generar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _fdsIsGenerating = true);
    try {
      if (_fdsWeeklyRoster == null) {
        final weekEnd = _rosterService.getWeekEnd(_fdsWeekStart);
        final currentUser = ref.read(currentUserProvider);
        _fdsWeeklyRoster = await _rosterService.createWeeklyRoster(
          weekStart: _fdsWeekStart,
          weekEnd: weekEnd,
          createdBy: currentUser?.id ?? '',
          guardType: 'fds',
        );
      }

      // Autoasignar por día y turno
      for (final dayIndex in fdsDayIndexes) {
        for (final period in ['AM', 'PM']) {
          final avail = period == 'AM' ? _fdsAvailabilityAm : _fdsAvailabilityPm;
          final date = _fdsWeekStart.add(Duration(days: dayIndex));
          final dateKey = DateTime(date.year, date.month, date.day);

          List<GuardAvailability> available = [];
          for (var entry in avail.entries) {
            final ek = DateTime(entry.key.year, entry.key.month, entry.key.day);
            if (ek == dateKey) { available = List.from(entry.value); break; }
          }
          if (available.isEmpty) continue;

          final drivers = available.where((a) => a.isDriver).toList();
          String? maquinistaId;
          if (drivers.isNotEmpty) {
            maquinistaId = drivers.first.userId;
            available.removeWhere((a) => a.userId == maquinistaId);
          }

          // OBAC: mayor rango
          String? obacId;
          final rankPriority = ['Capitán', 'Teniente 1', 'Teniente 2', 'Teniente 3'];
          for (final rank in rankPriority) {
            final officer = available.cast<GuardAvailability?>().firstWhere(
                  (a) => (_usersMap[a?.userId]?.rank ?? '').contains(rank),
                  orElse: () => null,
                );
            if (officer != null) { obacId = officer.userId; break; }
          }
          if (obacId == null && available.isNotEmpty) obacId = available.first.userId;
          if (obacId != null) available.removeWhere((a) => a.userId == obacId);

          final bomberoIds = available.take(8).map((a) => a.userId).toList();

          // Guardar en estado local
          setState(() {
            _fdsAssignments[dayIndex]![period] = DayAssignment(
              maquinistaId: maquinistaId,
              obacId: obacId,
              bomberoIds: List<String?>.from(bomberoIds)
                ..addAll(List.filled(8 - bomberoIds.length, null)),
            );
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol FDS generado. Presione Guardar para persistir.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar FDS: $e')));
    } finally {
      if (mounted) setState(() => _fdsIsGenerating = false);
    }
  }

  Future<void> _saveFdsRoster(List<int> fdsDayIndexes) async {
    setState(() => _fdsIsSaving = true);
    try {
      if (_fdsWeeklyRoster == null) {
        final weekEnd = _rosterService.getWeekEnd(_fdsWeekStart);
        final currentUser = ref.read(currentUserProvider);
        _fdsWeeklyRoster = await _rosterService.createWeeklyRoster(
          weekStart: _fdsWeekStart,
          weekEnd: weekEnd,
          createdBy: currentUser?.id ?? '',
          guardType: 'fds',
        );
      }
      for (final dayIndex in fdsDayIndexes) {
        final date = _fdsWeekStart.add(Duration(days: dayIndex));
        for (final period in ['AM', 'PM']) {
          final a = _fdsAssignments[dayIndex]![period]!;
          await _rosterService.saveDailyRoster(
            rosterWeekId: _fdsWeeklyRoster!.id ?? '',
            guardDate: date,
            maquinistaId: a.maquinistaId,
            obacId: a.obacId,
            bomberoIds: a.bomberoIds.whereType<String>().toList(),
            shiftPeriod: period,
          );
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol FDS guardado exitosamente')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar FDS: $e')));
    } finally {
      if (mounted) setState(() => _fdsIsSaving = false);
    }
  }

  Future<void> _publishFdsRoster(List<int> fdsDayIndexes) async {
    if (_fdsWeeklyRoster == null || _fdsWeeklyRoster!.status != 'draft') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay rol FDS en borrador para publicar')));
      return;
    }
    setState(() => _fdsIsPublishing = true);
    try {
      await _saveFdsRoster(fdsDayIndexes);
      await _rosterService.publishWeeklyRoster(_fdsWeeklyRoster!.id ?? '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rol FDS publicado exitosamente')));
        await _loadFdsData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar FDS: $e')));
    } finally {
      if (mounted) setState(() => _fdsIsPublishing = false);
    }
  }

  Future<void> _publishRoster() async {
    if (_weeklyRoster == null || _weeklyRoster!.status != 'draft') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay rol en borrador para publicar')),
      );
      return;
    }

    // Validar género antes de publicar
    final genderViolations = <String>[];
    for (int i = 0; i < 7; i++) {
      final assignment = _weekAssignments[i]!;
      final dist = assignment.getGenderDistribution(_usersMap);
      final males = dist['males'] ?? 0;
      final females = dist['females'] ?? 0;
      
      if (males > 6 || females > 4) {
        final weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        genderViolations.add('- ${weekdays[i]}: ${males}H/${females}M');
      }
    }

    if (genderViolations.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alerta de Género'),
          content: Text(
            'Los siguientes días exceden el límite 6H/4M:\n${genderViolations.join('\n')}\n\n¿Desea continuar de todas formas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    setState(() => _isPublishing = true);

    try {
      await _saveRoster();
      await _rosterService.publishWeeklyRoster(_weeklyRoster!.id ?? '');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol publicado exitosamente')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Rol de Guardia'),
        backgroundColor: AppTheme.institutionalRed,
        bottom: TabBar(
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
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNocturnaTab(),
                _buildFdsTab(),
              ],
            ),
    );
  }

  Widget _buildNocturnaTab() {
    return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de semana
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeWeek(-1),
                      ),
                      Text(
                        _formatWeekRange(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeWeek(1),
                      ),
                    ],
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _goToCurrentWeek,
                      child: const Text('Semana actual'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateAuto,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Generar Auto'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveRoster,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: (_isPublishing ||
                                _weeklyRoster == null ||
                                _weeklyRoster!.status != 'draft')
                            ? null
                            : _publishRoster,
                        icon: _isPublishing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.publish),
                        label: const Text('Publicar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Layout side-by-side o vertical según ancho
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        // Layout vertical para pantallas angostas
                        return Column(
                          children: [
                            _buildRosterGrid(),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 400,
                              child: _buildCompliancePanel(),
                            ),
                          ],
                        );
                      } else {
                        // Layout horizontal para pantallas anchas
                        return SizedBox(
                          height: 600,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildRosterGrid(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildCompliancePanel(),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
    );
  }
  Widget _buildFdsTab() {
    // Calcular días FDS de la semana
    final fdsDayIndexes = List.generate(7, (i) {
      final d = _fdsWeekStart.add(Duration(days: i));
      return _isFdsDay(d) ? i : -1;
    }).where((i) => i >= 0).toList();

    return _fdsIsLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de semana FDS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeFdsWeek(-1)),
                    Text(_formatFdsWeekRange(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeFdsWeek(1)),
                  ],
                ),
                Center(
                  child: Text(
                    _fdsWeeklyRoster != null
                        ? 'Estado: ${_fdsWeeklyRoster!.status}'
                        : 'Sin rol FDS',
                    style: TextStyle(
                        color: _fdsWeeklyRoster?.status == 'published'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                // Botones FDS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _fdsIsGenerating
                          ? null
                          : () => _generateFdsAuto(fdsDayIndexes),
                      icon: _fdsIsGenerating
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: const Text('Generar Auto'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _fdsIsSaving
                          ? null
                          : () => _saveFdsRoster(fdsDayIndexes),
                      icon: _fdsIsSaving
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: (_fdsIsPublishing ||
                              _fdsWeeklyRoster == null ||
                              _fdsWeeklyRoster!.status != 'draft')
                          ? null
                          : () => _publishFdsRoster(fdsDayIndexes),
                      icon: _fdsIsPublishing
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.publish),
                      label: const Text('Publicar'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Grilla o mensaje vacío
                if (fdsDayIndexes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No hay días FDS en esta semana',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            _buildFdsRosterGrid(fdsDayIndexes),
                            const SizedBox(height: 24),
                            SizedBox(
                                height: 400,
                                child: _buildFdsCompliancePanel()),
                          ],
                        );
                      } else {
                        return SizedBox(
                          height: 600,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: _buildFdsRosterGrid(fdsDayIndexes)),
                              const SizedBox(width: 16),
                              Expanded(
                                  flex: 1,
                                  child: _buildFdsCompliancePanel()),
                            ],
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          );
  }
}
