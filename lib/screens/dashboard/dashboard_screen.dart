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
      
      // NEW: Load citation and emergency stats instead of efectiva/abono
      final kpi = await _attendanceService.calculateCitationAndEmergencyStats(userId);
      final monthly = await _attendanceService.calculateMonthlyAttendanceByType(userId);
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

    final citationPct = _individualKpi!['citation_pct'] as double;
    final emergencyPct = _individualKpi!['emergency_pct'] as double;
    final citationCount = _individualKpi!['citation_count'] as int;
    final emergencyCount = _individualKpi!['emergency_count'] as int;
    final totalCitations = _individualKpi!['total_citation_events'] as int;
    final totalEmergencies = _individualKpi!['total_emergency_events'] as int;
    final monthName = _individualKpi!['month_name'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi Desempeño - $monthName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            
            // Two pie charts side by side
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                
                if (isWide) {
                  // Desktop: side by side
                  return Row(
                    children: [
                      Expanded(child: _buildCitationChart(citationPct, citationCount, totalCitations)),
                      const SizedBox(width: 32),
                      Expanded(child: _buildEmergencyChart(emergencyPct, emergencyCount, totalEmergencies)),
                    ],
                  );
                } else {
                  // Mobile: stacked
                  return Column(
                    children: [
                      _buildCitationChart(citationPct, citationCount, totalCitations),
                      const SizedBox(height: 24),
                      _buildEmergencyChart(emergencyPct, emergencyCount, totalEmergencies),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationChart(double percentage, int attended, int total) {
    final absentPct = 100 - percentage;
    
    return Column(
      children: [
        const Text(
          'Asistencia a Citaciones',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: percentage,
                  color: Colors.blue,
                  title: '${percentage.toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  radius: 60,
                ),
                if (absentPct > 0)
                  PieChartSectionData(
                    value: absentPct,
                    color: Colors.grey[300]!,
                    title: '${absentPct.toStringAsFixed(1)}%',
                    titleStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    radius: 50,
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$attended de $total citaciones',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmergencyChart(double percentage, int attended, int total) {
    final absentPct = 100 - percentage;
    
    return Column(
      children: [
        const Text(
          'Asistencia a Emergencias',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: percentage,
                  color: Colors.red,
                  title: '${percentage.toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  radius: 60,
                ),
                if (absentPct > 0)
                  PieChartSectionData(
                    value: absentPct,
                    color: Colors.grey[300]!,
                    title: '${absentPct.toStringAsFixed(1)}%',
                    titleStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    radius: 50,
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$attended de $total emergencias',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
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
                'Mi Asistencia - Últimos 6 Meses',
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
              'Mi Asistencia - Últimos 6 Meses',
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
                _buildLegendItem('Citaciones', 0, Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Emergencias', 0, Colors.red),
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
            toY: (data['citation_count'] as int? ?? 0).toDouble(),
            color: Colors.blue,
            width: 16,
          ),
          BarChartRodData(
            toY: (data['emergency_count'] as int? ?? 0).toDouble(),
            color: Colors.red,
            width: 16,
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
