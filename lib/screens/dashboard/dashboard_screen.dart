import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/models/activity_model.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/permissions/role_permissions.dart';
import 'package:sexta_app/screens/dashboard/widgets/weekly_calendar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _attendanceService = AttendanceService();
  final _supabase = SupabaseService();
  final _authService = AuthService();
  
  bool _isLoading = true;
  UserModel? _currentUser;
  Map<String, dynamic>? _individualKpi;
  List<Map<String, dynamic>> _monthlyStats = [];
  List<Map<String, dynamic>> _ranking = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _weeklyActivities = [];
  List<Map<String, dynamic>> _nextShifts = [];
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final user = await _supabase.getUserProfile(userId);
      
      // Load all data in parallel
      final results = await Future.wait([
        _attendanceService.calculateCitationAndEmergencyStats(userId),
        _attendanceService.calculateMonthlyAttendanceByType(userId),
        _attendanceService.getAttendanceRanking(),
        _attendanceService.getLowAttendanceAlerts(),
        _supabase.getWeeklyActivities(_currentWeekStart, _currentWeekStart.add(const Duration(days: 7))),
        _supabase.getNextUserShifts(userId),
      ]);

      setState(() {
        _currentUser = user;
        _individualKpi = results[0] as Map<String, dynamic>;
        _monthlyStats = results[1] as List<Map<String, dynamic>>;
        _ranking = results[2] as List<Map<String, dynamic>>;
        _alerts = results[3] as List<Map<String, dynamic>>;
        _weeklyActivities = results[4] as List<Map<String, dynamic>>;
        _nextShifts = (results[5] as List<Map<String, dynamic>>?) ?? [];
        _isLoading = false;
      });
      
      // DEBUG: Log loaded data
      debugPrint('✅ Dashboard loaded:');
      debugPrint('  - Ranking first item: ${_ranking.isNotEmpty ? _ranking.first : "Empty"}');
      debugPrint('  - KPIs: $_individualKpi');
      debugPrint('  - Weekly activities: ${_weeklyActivities.length} items');
      debugPrint('  - Activities: $_weeklyActivities');
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: BrandedAppBar(
        title: 'Dashboard - Sistema de Gestión',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Inline)
                  _buildHeader(),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth <= 800) {
                        return Column(children: [const SizedBox(height: 20), _buildNextShiftCard()]);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Buttons (Quick Actions)
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  
                  // 3. Weekly Calendar (Moved up as requested)
                  Text(
                    'Actividades de la Semana',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  WeeklyCalendar(
                    activities: _weeklyActivities,
                    onWeekChanged: (weekStart) async {
                      setState(() => _currentWeekStart = weekStart);
                      final activities = await _supabase.getWeeklyActivities(weekStart, weekStart.add(const Duration(days: 7)));
                      setState(() => _weeklyActivities = activities);
                    },
                    onActivityTap: (activity) => _showActivityDetail(activity),
                  ),
                  const SizedBox(height: 24),

                  // 4. Stats Grid (Citations, Emergencies, Next Guard)
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  
                  // 5. Monthly Chart
                  _buildMonthlyChart(),
                  const SizedBox(height: 24),
                  
                  // 6. Ranking and Alerts
                  _buildBottomSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE d', 'es_ES').format(now);
    final month = DateFormat('MMMM', 'es_ES').format(now);
    final formattedDayOfWeek = dayOfWeek[0].toUpperCase() + dayOfWeek.substring(1);
    final formattedMonth = 'de ${month[0].toUpperCase()}${month.substring(1)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navyBlue, AppTheme.navyBlue.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _currentUser?.initials ?? 'U',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.navyBlue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${_currentUser?.firstName ?? 'Usuario'}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDayOfWeek $formattedMonth',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    // 4 equal buttons in a row for desktop/tablet, or scrollable strip? 
    // User asked "bajo los botones", implying a row. 
    // Let's use a LayoutBuilder for responsiveness.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          // Mobile: 2-column grid layout
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildActionButton('Tomar Asistencia', Icons.checklist, () => context.go('/take-attendance'), color: const Color(0xFFE3F2FD))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton('Solicitar Permiso', Icons.description, () => context.go('/request-permission'), color: const Color(0xFFE8F5E9))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildActionButton('Mi Perfil', Icons.person, () => context.go('/profile'), color: const Color(0xFFFFF8E1))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton('Asist. Guardia Noc', Icons.nightlight_round, () => context.go('/guard-nocturna'), color: const Color(0xFFF3E5F5))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildActionButton('Asist. Guardia FDS', Icons.weekend, () => context.go('/guard-fds'), color: const Color(0xFFFCE4EC))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton('Asist. Guardia Lu-Vi', Icons.calendar_today, () => context.go('/guard-diurna'), color: const Color(0xFFE0F7FA))),
                ],
              ),
            ],
          );
        } else {
          // Desktop: 3-column wrap layout
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (constraints.maxWidth - 36) / 3,
                child: _buildActionButton('Tomar Asistencia', Icons.checklist, () => context.go('/take-attendance'), color: const Color(0xFFE3F2FD)),
              ),
              SizedBox(
                width: (constraints.maxWidth - 36) / 3,
                child: _buildActionButton('Solicitar Permiso', Icons.description, () => context.go('/request-permission'), color: const Color(0xFFE8F5E9)),
              ),
              SizedBox(
                width: (constraints.maxWidth - 36) / 3,
                child: _buildActionButton('Mi Perfil', Icons.person, () => context.go('/profile'), color: const Color(0xFFFFF8E1)),
              ),
              SizedBox(
                width: (constraints.maxWidth - 36) / 3,
                child: _buildActionButton('Asist. Guardia Noc', Icons.nightlight_round, () => context.go('/guard-nocturna'), color: const Color(0xFFF3E5F5)),
              ),
              SizedBox(
                width: (constraints.maxWidth - 36) / 3,
                child: _buildActionButton('Asist. Guardia FDS', Icons.weekend, () => context.go('/guard-fds'), color: const Color(0xFFFCE4EC)),
              ),
              SizedBox(
                width: (constraints.maxWidth - 36) / 3,
                child: _buildActionButton('Asist. Guardia Lu-Vi', Icons.calendar_today, () => context.go('/guard-diurna'), color: const Color(0xFFE0F7FA)),
              ),
            ],
          );
        }
      }
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, {Color? color}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.navyBlue,
        backgroundColor: color,
        side: BorderSide(color: AppTheme.navyBlue.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_individualKpi == null) return const SizedBox.shrink();

    // MES ACTUAL
    final monthCitationPct = (_individualKpi!['month_citation_pct'] as num).toDouble();
    final monthEmergencyPct = (_individualKpi!['month_emergency_pct'] as num).toDouble();
    final monthCitationCount = _individualKpi!['month_citation_count'] as int;
    final monthEmergencyCount = _individualKpi!['month_emergency_count'] as int;
    final monthTotalCitations = _individualKpi!['month_total_citation_events'] as int;
    final monthTotalEmergencies = _individualKpi!['month_total_emergency_events'] as int;
    
    // AÑO ACUMULADO
    final yearCitationPct = (_individualKpi!['year_citation_pct'] as num).toDouble();
    final yearEmergencyPct = (_individualKpi!['year_emergency_pct'] as num).toDouble();
    final yearCitationCount = _individualKpi!['year_citation_count'] as int;
    final yearEmergencyCount = _individualKpi!['year_emergency_count'] as int;
    final yearTotalCitations = _individualKpi!['year_total_citation_events'] as int;
    final yearTotalEmergencies = _individualKpi!['year_total_emergency_events'] as int;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width > 800) {
          // Desktop: 3 cards in a row: Citations | Emergencies | Next Guard
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDualStatCard(
                  'Citaciones',
                  monthCitationPct,
                  monthCitationCount,
                  monthTotalCitations,
                  yearCitationPct,
                  yearCitationCount,
                  yearTotalCitations,
                  Icons.notifications_active,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDualStatCard(
                  'Emergencias',
                  monthEmergencyPct,
                  monthEmergencyCount,
                  monthTotalEmergencies,
                  yearEmergencyPct,
                  yearEmergencyCount,
                  yearTotalEmergencies,
                  Icons.local_fire_department,
                  AppTheme.institutionalRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildNextShiftCard()),
            ],
          );
        } else {
          // Mobile: Stacked
          return Column(
            children: [
              _buildDualStatCard(
                'Citaciones',
                monthCitationPct,
                monthCitationCount,
                monthTotalCitations,
                yearCitationPct,
                yearCitationCount,
                yearTotalCitations,
                Icons.notifications_active,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildDualStatCard(
                'Emergencias',
                monthEmergencyPct,
                monthEmergencyCount,
                monthTotalEmergencies,
                yearEmergencyPct,
                yearEmergencyCount,
                yearTotalEmergencies,
                Icons.local_fire_department,
                AppTheme.institutionalRed,
              ),
            ],
          );
        }
      },
    );
  }


  Widget _buildDualStatCard(
    String title,
    double monthPct,
    int monthCount,
    int monthTotal,
    double yearPct,
    int yearCount,
    int yearTotal,
    IconData icon,
    Color color,
  ) {
    final monthName = _individualKpi!['month_name'] as String;
    final year = _individualKpi!['year'] as int;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // MES ACTUAL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName[0].toUpperCase() + monthName.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${monthPct.round()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$monthCount/$monthTotal',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // AÑO ACUMULADO
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acumulado $year',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${yearPct.round()}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$yearCount/$yearTotal',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNextShiftCard() {
    if (_nextShifts.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Próxima Guardia', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Sin asignar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              const Text('Verifica disponibilidad', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.efectivaColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield, color: AppTheme.efectivaColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text('Próximas Guardias Nocturnas', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_nextShifts.length, (index) {
              final shift = _nextShifts[index];
              final date = DateTime.parse(shift['shift_date']);
              final shiftDate = DateTime(date.year, date.month, date.day);
              
              final isToday = shiftDate.isAtSameMomentAs(today);
              final isTomorrow = shiftDate.isAtSameMomentAs(tomorrow);
              
              String dateText;
              Color dateColor = Colors.black87;
              
              if (isToday) {
                dateText = 'HOY';
                dateColor = AppTheme.institutionalRed;
              } else if (isTomorrow) {
                dateText = 'MAÑANA';
                dateColor = Colors.orange;
              } else {
                final formatted = DateFormat('EEE d MMM', 'es_ES').format(date);
                dateText = formatted[0].toUpperCase() + formatted.substring(1);
              }

              return Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bedtime, color: Color(0xFF1A237E), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: dateColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Según OD',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.efectivaColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (index < _nextShifts.length - 1)
                    const Divider(height: 12, thickness: 0.5),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (_monthlyStats.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histórico (6 Meses)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                Row(
                  children: [
                    _buildLegendDot(Colors.blue, 'Cit.'),
                    const SizedBox(width: 8),
                    _buildLegendDot(AppTheme.institutionalRed, 'Emer.'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  barGroups: _buildBarGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _monthlyStats.length) return const SizedBox();
                          final month = _monthlyStats[value.toInt()]['month_num'] as int;
                          const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(months[month], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_monthlyStats.length, (index) {
      final data = _monthlyStats[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data['citation_count'] as int? ?? 0).toDouble(),
            color: Colors.blue,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
          BarChartRodData(
            toY: (data['emergency_count'] as int? ?? 0).toDouble(),
            color: AppTheme.institutionalRed,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    });
  }

  double _getMaxY() {
    double max = 0;
    for (final data in _monthlyStats) {
      final citations = (data['citation_count'] as int? ?? 0).toDouble();
      final emergencies = (data['emergency_count'] as int? ?? 0).toDouble();
      if (citations > max) max = citations;
      if (emergencies > max) max = emergencies;
    }
    return (max * 1.2).ceilToDouble();
  }

  Widget _buildBottomSection() {
    if (MediaQuery.of(context).size.width > 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildRankingCard()),
          const SizedBox(width: 16),
          Expanded(child: _buildAlertsOrRestricted()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildRankingCard(),
          const SizedBox(height: 16),
          _buildAlertsOrRestricted(),
        ],
      );
    }
  }

  Widget _buildRankingCard() {
    final currentYear = DateTime.now().year;
    // Obtener el total de emergencias desde el primer registro del ranking (si existe)
    final totalEmergencies = _ranking.isNotEmpty 
        ? (_ranking.first['total_emergencies'] as int? ?? 0) 
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Top 10 Emergencias $currentYear ($totalEmergencies)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ranking.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No hay datos disponibles'),
              )
            else
              ..._ranking.take(10).map((user) {
                final index = _ranking.indexOf(user) + 1;
                final attended = user['emergencies_attended'] as int? ?? 0;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: index <= 3 ? Colors.amber.shade100 : Colors.grey.shade100,
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: index <= 3 ? Colors.amber.shade900 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  title: Text(user['full_name'] ?? 'N/A', style: const TextStyle(fontSize: 13)),
                  subtitle: Text('$attended asistencias', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  trailing: Text(
                    '${(user['attendance_pct'] as num).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyBlue),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsOrRestricted() {
    final canSeeAlerts = _currentUser != null &&
        (RolePermissions.isAdmin(_currentUser!.role) || RolePermissions.isOficial(_currentUser!.role));

    if (canSeeAlerts) {
      return _buildAlertsCard();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAlertsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Alertas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Sin alertas activas',
                    style: TextStyle(color: AppTheme.efectivaColor)),
              )
            else
              ..._alerts.take(5).map((alert) {
                final severity = alert['severity'] as String;
                final color = severity == 'critical' 
                    ? AppTheme.criticalColor 
                    : AppTheme.warningColor;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.circle, color: color, size: 12),
                  title: Text(alert['full_name'] ?? 'N/A', style: const TextStyle(fontSize: 13)),
                  trailing: Text(
                    '${(alert['attendance_pct'] as double).toStringAsFixed(0)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
  
  void _showActivityDetail(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(activityTypeFromString(activity['activity_type'] as String).emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity['title'] as String,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity['description'] != null) ...[
              Text(
                activity['description'] as String,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            _buildDetailRow(Icons.category, 'Tipo',
                activityTypeFromString(activity['activity_type'] as String).displayName),
            _buildDetailRow(Icons.calendar_today, 'Fecha',
                DateFormat('dd/MM/yyyy').format(DateTime.parse(activity['activity_date']))),
            if (activity['start_time'] != null)
              _buildDetailRow(Icons.access_time, 'Hora',
                  '${(activity['start_time'] as String).substring(0, 5)}${activity['end_time'] != null ? ' - ${(activity['end_time'] as String).substring(0, 5)}' : ''}'),
            if (activity['location'] != null)
              _buildDetailRow(
                  Icons.location_on, 'Lugar', activity['location'] as String),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
