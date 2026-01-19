import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/models/activity_model.dart';
import 'package:intl/intl.dart';
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
        // No hay usuario logueado, mostrar datos vacíos
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Load user profile to get role
      final user = await _supabase.getUserProfile(userId);
      
      final kpi = await _attendanceService.calculateIndividualStats(userId);
      final monthly = await _attendanceService.calculateCompanyMonthlyStats();
      final ranking = await _attendanceService.getAttendanceRanking();
      final alerts = await _attendanceService.getLowAttendanceAlerts();
      final activities = await _supabase.getWeeklyActivities(_currentWeekStart);

      setState(() {
        _currentUser = user;
        _individualKpi = kpi;
        _monthlyStats = monthly;
        _ranking = ranking;
        _alerts = alerts;
        _weeklyActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e'); // Debug
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
                  // Calendario Semanal
                  WeeklyCalendar(
                    activities: _weeklyActivities,
                    onWeekChanged: (weekStart) async {
                      setState(() => _currentWeekStart = weekStart);
                      final activities = await _supabase.getWeeklyActivities(weekStart);
                      setState(() => _weeklyActivities = activities);
                    },
                    onActivityTap: (activity) => _showActivityDetail(activity),
                  ),
                  const SizedBox(height: 24),
                  
                  // KPI Individual
                  _buildIndividualKpiCard(),
                  const SizedBox(height: 24),
                  
                  // Gráfico 6 meses
                  _buildMonthlyChart(),
                  const SizedBox(height: 24),
                  
                  // Ranking y Alertas en grid
                  if (MediaQuery.of(context).size.width > 800)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRankingCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildAlertsOrRestricted()),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildRankingCard(),
                        const SizedBox(height: 16),
                        _buildAlertsOrRestricted(),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildIndividualKpiCard() {
    if (_individualKpi == null) return const SizedBox();

    final efectivaPct = _individualKpi!['efectiva_pct'] as double;
    final abonoPct = _individualKpi!['abono_pct'] as double;
    final total = _individualKpi!['total'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi Desempeño',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Pie chart
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: efectivaPct,
                          color: AppTheme.efectivaColor,
                          title: '${efectivaPct.toStringAsFixed(1)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: abonoPct,
                          color: AppTheme.abonoColor,
                          title: '${abonoPct.toStringAsFixed(1)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          radius: 60,
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        'Lista Efectiva',
                        _individualKpi!['efectiva_count'] as int,
                        AppTheme.efectivaColor,
                      ),
                      const SizedBox(height: 12),
                      _buildLegendItem(
                        'Abonos',
                        _individualKpi!['abono_count'] as int,
                        AppTheme.abonoColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Total de asistencias: $total',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    if (_monthlyStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Asistencia Compañía - Últimos 6 Meses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const Text('No hay datos disponibles'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asistencia Compañía - Últimos 6 Meses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  barGroups: _buildBarGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _monthlyStats.length) {
                            return const Text('');
                          }
                          final month = _monthlyStats[value.toInt()]['month_num'] as int;
                          const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                                         'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                          return Text(months[month], style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = rodIndex == 0 ? 'Efectiva' : 'Abono';
                        return BarTooltipItem(
                          '$type\n${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Efectiva', 0, AppTheme.efectivaColor),
                const SizedBox(width: 24),
                _buildLegendItem('Abono', 0, AppTheme.abonoColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_monthlyStats.length, (index) {
      final data = _monthlyStats[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data['efectiva_count'] as int).toDouble(),
            color: AppTheme.efectivaColor,
            width: 16,
          ),
          BarChartRodData(
            toY: (data['abono_count'] as int).toDouble(),
            color: AppTheme.abonoColor,
            width: 16,
          ),
        ],
      );
    });
  }

  double _getMaxY() {
    double max = 0;
    for (final data in _monthlyStats) {
      final efectiva = (data['efectiva_count'] as int).toDouble();
      final abono = (data['abono_count'] as int).toDouble();
      if (efectiva > max) max = efectiva;
      if (abono > max) max = abono;
    }
    return (max * 1.2).ceilToDouble();
  }

  Widget _buildRankingCard() {
    return Card(
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
                  'Top 10 Asistencia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ranking.isEmpty)
              const Text('No hay datos disponibles')
            else
              ..._ranking.take(10).map((user) {
                final index = _ranking.indexOf(user) + 1;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index <= 3 ? Colors.amber : AppTheme.navyBlue,
                    child: Text(
                      '$index',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(user['full_name'] ?? 'N/A'),
                  subtitle: Text(user['rank'] ?? 'N/A'),
                  trailing: Text(
                    '${(user['attendance_pct'] as double).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Alertas de Asistencia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_alerts.isEmpty)
              const Text('Sin alertas - ¡Excelente trabajo!',
                  style: TextStyle(color: AppTheme.efectivaColor))
            else
              ..._alerts.map((alert) {
                final severity = alert['severity'] as String;
                final color = severity == 'critical' 
                    ? AppTheme.criticalColor 
                    : AppTheme.warningColor;
                
                return ListTile(
                  leading: Icon(Icons.person, color: color),
                  title: Text(alert['full_name'] ?? 'N/A'),
                  subtitle: Text(alert['rank'] ?? 'N/A'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:Text(
                      '${(alert['attendance_pct'] as double).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  /// Conditionally show alerts based on user role
  Widget _buildAlertsOrRestricted() {
    // Check if user has permission to see alerts (officer or admin)
    final canSeeAlerts = _currentUser?.role == UserRole.officer || 
                         _currentUser?.role == UserRole.admin;
    
    if (canSeeAlerts) {
      return _buildAlertsCard();
    } else {
      return _buildRestrictedAlertsMessage();
    }
  }

  /// Message for users without permission to see company alerts
  Widget _buildRestrictedAlertsMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text(
                  'Alertas de Compañía',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta sección está disponible solo para oficiales y administradores.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes ver tu propio desempeño en la sección "Mi Desempeño" arriba.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetail(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
