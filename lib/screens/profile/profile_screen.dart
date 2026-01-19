import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:intl/intl.dart';

/// Profile screen showing user's personal information, statistics, and history
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = SupabaseService();
  final _authService = AuthService();
  final _attendanceService = AttendanceService();

  bool _isLoading = true;
  UserModel? _user;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _attendanceHistory = [];
  List<Map<String, dynamic>> _permissions = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load all profile data in parallel
      final results = await Future.wait([
        _supabase.getUserProfile(userId),
        _attendanceService.calculateIndividualStats(userId),
        _attendanceService.getUserAttendanceHistory(userId, 20),
        _supabase.getPermissionsByUser(userId),
      ]);

      setState(() {
        _user = results[0] as UserModel?;
        _stats = results[1] as Map<String, dynamic>;
        _attendanceHistory = results[2] as List<Map<String, dynamic>>;
        _permissions = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando perfil: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Mi Perfil'),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPersonalDataCard(),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildAttendanceHistoryCard(),
                  const SizedBox(height: 16),
                  _buildPermissionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildPersonalDataCard() {
    if (_user == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text(
                  'Datos Personales',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDataRow('Nombre Completo', _user!.fullName),
            _buildDataRow('RUT', _user!.rut),
            _buildDataRow('Número Victor', _user!.victorNumber),
            if (_user!.registroCompania != null)
              _buildDataRow('Registro Compañía', _user!.registroCompania!),
            _buildDataRow('Cargo', _user!.rank),
            if (_user!.email != null)
              _buildDataRow('Email', _user!.email!),
            _buildDataRow('Estado Civil', _user!.maritalStatus == MaritalStatus.married ? 'Casado/a' : 'Soltero/a'),
            _buildDataRow('Género', _user!.gender == Gender.male ? 'Masculino' : 'Femenino'),
            _buildDataRow('Rol', _getRoleName(_user!.role)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.officer:
        return 'Oficial';
      case UserRole.firefighter:
        return 'Bombero';
    }
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox();

    final efectivaPct = _stats!['efectiva_pct'] as double;
    final abonoPct = _stats!['abono_pct'] as double;
    final total = _stats!['total'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text(
                  'Mis Estadísticas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
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
                      _buildStatItem('Lista Efectiva', _stats!['efectiva_count'] as int, AppTheme.efectivaColor),
                      const SizedBox(height: 12),
                      _buildStatItem('Abonos', _stats!['abono_count'] as int, AppTheme.abonoColor),
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

  Widget _buildStatItem(String label, int count, Color color) {
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

  Widget _buildAttendanceHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text(
                  'Historial de Asistencias',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            if (_attendanceHistory.isEmpty)
              const Text('No hay registros de asistencia')
            else
              ..._attendanceHistory.take(20).map((record) {
                final date = DateTime.parse(record['event_date']);
                final actType = record['act_type_name'] ?? 'N/A';
                final status = record['status'] as String;
                
                IconData icon;
                Color color;
                String statusText;
                
                if (status == 'present') {
                  icon = Icons.check_circle;
                  color = AppTheme.efectivaColor;
                  statusText = 'Presente';
                } else if (status == 'licencia') {
                  icon = Icons.medical_services;
                  color = AppTheme.warningColor;
                  statusText = 'Licencia';
                } else {
                  icon = Icons.cancel;
                  color = Colors.grey;
                  statusText = 'Ausente';
                }

                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(actType),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                  trailing: Text(
                    statusText,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text(
                  'Mis Permisos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            if (_permissions.isEmpty)
              const Text('No hay permisos registrados')
            else
              ..._permissions.map((perm) {
                final startDate = DateTime.parse(perm['start_date']);
                final endDate = DateTime.parse(perm['end_date']);
                final status = perm['status'] as String;
                final reason = perm['reason'] as String;

                Color statusColor;
                String statusText;
                IconData icon;

                if (status == 'approved') {
                  statusColor = AppTheme.efectivaColor;
                  statusText = 'Aprobado';
                  icon = Icons.check_circle;
                } else if (status == 'rejected') {
                  statusColor = AppTheme.criticalColor;
                  statusText = 'Rechazado';
                  icon = Icons.cancel;
                } else {
                  statusColor = AppTheme.warningColor;
                  statusText = 'Pendiente';
                  icon = Icons.pending;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(icon, color: statusColor),
                    title: Text(
                      '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
}
