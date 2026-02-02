import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CompanyDashboardScreen extends ConsumerStatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  ConsumerState<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends ConsumerState<CompanyDashboardScreen> {
  final _attendanceService = AttendanceService();
  final _supabaseService = SupabaseService();

  bool _isLoading = true;
  List<UserModel> _allUsers = [];
  UserModel? _selectedUser;
  
  // Company-wide stats
  Map<String, dynamic>? _companyStats;
  List<Map<String, dynamic>> _companyMonthlyStats = [];
  
  // Selected user stats (when filtered)
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>> _userMonthlyStats = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all users for filtering
      final users = await _supabaseService.getAllUsers();
      
      // Load company-wide statistics
      final companyStats = await _calculateCompanyStats();
      final companyMonthly = await _calculateCompanyMonthlyStats();

      setState(() {
        _allUsers = users;
        _companyStats = companyStats;
        _companyMonthlyStats = companyMonthly;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading company dashboard: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _calculateCompanyStats() async {
    // Calculate total citations and emergencies for current month across all users
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final supabaseClient = _supabaseService.client;

    // Get all events of current month
    final events = await supabaseClient
        .from('attendance_events')
        .select('''
          id,
          act_type:act_types!inner(name)
        ''')
        .gte('event_date', firstDayOfMonth.toIso8601String().split('T')[0])
        .lte('event_date', lastDayOfMonth.toIso8601String().split('T')[0]);

    int totalCitations = 0;
    int totalEmergencies = 0;

    for (final event in events as List) {
      final actTypeName = event['act_type']['name'] as String;
      
      if (actTypeName.toLowerCase().contains('citac') || 
          actTypeName.toLowerCase().contains('citación')) {
        totalCitations++;
      } else if (actTypeName.toLowerCase() == 'emergencia') {
        totalEmergencies++;
      }
    }

    return {
      'total_citations': totalCitations,
      'total_emergencies': totalEmergencies,
      'total_events': totalCitations + totalEmergencies,
      'month_name': DateFormat('MMMM', 'es_ES').format(now),
      'year': now.year,
    };
  }

  Future<List<Map<String, dynamic>>> _calculateCompanyMonthlyStats() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    final supabaseClient = _supabaseService.client;

    // Get all events from last 6 months
    final events = await supabaseClient
        .from('attendance_events')
        .select('''
          event_date,
          act_type:act_types!inner(name)
        ''')
        .gte('event_date', sixMonthsAgo.toIso8601String().split('T')[0]);

    // Group by month
    final Map<String, Map<String, int>> monthlyData = {};
    
    for (final event in events as List) {
      final eventDate = DateTime.parse(event['event_date'] as String);
      final monthKey = '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}';
      final actTypeName = event['act_type']['name'] as String;
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'citation': 0,
          'emergency': 0,
          'month_num': eventDate.month,
          'year': eventDate.year,
        };
      }
      
      if (actTypeName.toLowerCase().contains('citac') || 
          actTypeName.toLowerCase().contains('citación')) {
        monthlyData[monthKey]!['citation'] = (monthlyData[monthKey]!['citation'] ?? 0) + 1;
      } else if (actTypeName.toLowerCase() == 'emergencia') {
        monthlyData[monthKey]!['emergency'] = (monthlyData[monthKey]!['emergency'] ?? 0) + 1;
      }
    }

    // Convert to list and sort
    final result = monthlyData.entries.map((entry) {
      return {
        'month_key': entry.key,
        'month_num': entry.value['month_num'],
        'year': entry.value['year'],
        'citation_count': entry.value['citation'],
        'emergency_count': entry.value['emergency'],
      };
    }).toList();

    result.sort((a, b) {
      final dateA = DateTime(a['year'] as int, a['month_num'] as int);
      final dateB = DateTime(b['year'] as int, b['month_num'] as int);
      return dateA.compareTo(dateB);
    });

    // Fill missing months
    final completeResult = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthKey = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
      
      final existing = result.firstWhere(
        (r) => r['month_key'] == monthKey,
        orElse: () => {
          'month_key': monthKey,
          'month_num': targetDate.month,
          'year': targetDate.year,
          'citation_count': 0,
          'emergency_count': 0,
        },
      );
      
      completeResult.add(existing);
    }

    return completeResult;
  }

  Future<void> _loadUserStats(String userId) async {
    setState(() => _isLoading = true);
    
    try {
      final userStats = await _attendanceService.calculateCitationAndEmergencyStats(userId);
      final userMonthly = await _attendanceService.calculateMonthlyAttendanceByType(userId);

      setState(() {
        _userStats = userStats;
        _userMonthlyStats = userMonthly;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user stats: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando estadísticas del usuario: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Dashboard Compañía',
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
                  // User filter
                  _buildUserFilter(),
                  const SizedBox(height: 24),
                  
                  // Stats display
                  if (_selectedUser == null)
                    ..._buildCompanyStats()
                  else
                    ..._buildUserStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar por Bombero',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Autocomplete<UserModel>(
                    displayStringForOption: (user) => '${user.fullName} (${user.rank})',
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<UserModel>.empty();
                      }
                      return _allUsers.where((user) {
                        return user.fullName
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (user) async {
                      setState(() => _selectedUser = user);
                      await _loadUserStats(user.id);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Buscar bombero',
                          hintText: 'Escribe el nombre del bombero',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedUser != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedUser = null;
                        _userStats = null;
                        _userMonthlyStats = [];
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
                ],
              ],
            ),
            if (_selectedUser != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppTheme.navyBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedUser!.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _selectedUser!.rank,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCompanyStats() {
    if (_companyStats == null) return [];

    final totalCitations = _companyStats!['total_citations'] as int;
    final totalEmergencies = _companyStats!['total_emergencies'] as int;
    final totalEvents = _companyStats!['total_events'] as int;
    final monthName = _companyStats!['month_name'] as String;

    return [
      // Current month summary
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estadísticas de la Compañía - $monthName',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip('Citaciones', totalCitations, Colors.blue),
                  _buildStatChip('Emergencias', totalEmergencies, Colors.red),
                  _buildStatChip('Total', totalEvents, AppTheme.navyBlue),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      
      // Monthly chart
      _buildMonthlyChart(_companyMonthlyStats, 'Compañía - Últimos 6 Meses'),
    ];
  }

  List<Widget> _buildUserStats() {
    if (_userStats == null) return [];

    final citationPct = _userStats!['citation_pct'] as double;
    final emergencyPct = _userStats!['emergency_pct'] as double;
    final citationCount = _userStats!['citation_count'] as int;
    final emergencyCount = _userStats!['emergency_count'] as int;
    final totalCitations = _userStats!['total_citation_events'] as int;
    final totalEmergencies = _userStats!['total_emergency_events'] as int;
    final monthName = _userStats!['month_name'] as String;

    return [
      // Current month pie charts
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Desempeño de ${_selectedUser!.fullName} - $monthName',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  
                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: _buildCitationChart(citationPct, citationCount, totalCitations)),
                        const SizedBox(width: 32),
                        Expanded(child: _buildEmergencyChart(emergencyPct, emergencyCount, totalEmergencies)),
                      ],
                    );
                  } else {
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
      ),
      const SizedBox(height: 16),
      
      // Monthly chart
      _buildMonthlyChart(_userMonthlyStats, '${_selectedUser!.fullName} - Últimos 6 Meses'),
    ];
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  Widget _buildMonthlyChart(List<Map<String, dynamic>> stats, String title) {
    if (stats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(stats),
                  barGroups: _buildBarGroups(stats),
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
                          if (value.toInt() >= stats.length) {
                            return const Text('');
                          }
                          final month = stats[value.toInt()]['month_num'] as int;
                          const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                                         'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                          return Text(months[month], style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Citaciones', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Emergencias', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> stats) {
    return List.generate(stats.length, (index) {
      final data = stats[index];
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

  double _getMaxY(List<Map<String, dynamic>> stats) {
    if (stats.isEmpty) return 10;
    
    double max = 0;
    for (final data in stats) {
      final citations = (data['citation_count'] as int? ?? 0).toDouble();
      final emergencies = (data['emergency_count'] as int? ?? 0).toDouble();
      if (citations > max) max = citations;
      if (emergencies > max) max = emergencies;
    }
    
    // Si max es 0, retornar 10 para evitar gráfico vacío
    if (max == 0) return 10;
    
    // Agregar 20% de margen o mínimo 2 unidades
    final margin = max * 0.2;
    return (max + (margin < 2 ? 2 : margin)).ceilToDouble();
  }

  Widget _buildLegendItem(String label, Color color) {
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
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
