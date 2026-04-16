import 'package:flutter/material.dart';

import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/epp_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/models/epp_assignment_model.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/widgets/treasury_status_card.dart';

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
  final _eppService = EPPService();

  bool _isLoading = true;
  UserModel? _user;
  List<Map<String, dynamic>> _attendanceHistory = [];
  List<Map<String, dynamic>> _permissions = [];
  List<EPPAssignmentModel> _eppAssignments = [];

  late int _selectedMonth;
  late int _selectedYear;

  // Genera las 3 opciones del dropdown: mes actual + 2 anteriores
  List<({int month, int year})> get _monthOptions {
    final now = DateTime.now();
    return List.generate(3, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return (month: d.month, year: d.year);
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
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
        _attendanceService.getUserAttendanceHistory(userId, 500),
        _supabase.getPermissionsByUser(userId),
        _eppService.getActiveEPPByUser(userId),
      ]);

      setState(() {
        _user = results[0] as UserModel?;
        _attendanceHistory = results[1] as List<Map<String, dynamic>>;
        _permissions = results[2] as List<Map<String, dynamic>>;
        _eppAssignments = results[3] as List<EPPAssignmentModel>;
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
                  // Widget de estado de tesorería
                  if (_user != null)
                    TreasuryStatusCard(user: _user!),
                  if (_user != null)
                    const SizedBox(height: 16),
                  _buildEPPCard(),
                  const SizedBox(height: 16),
                  _buildMonthFilter(),
                  const SizedBox(height: 8),
                  _buildCitationsHistoryCard(),
                  const SizedBox(height: 16),
                  _buildEmergenciesHistoryCard(),
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
            if (_user!.birthDate != null)
              _buildDataRow('Fecha de Nacimiento', DateFormat('dd/MM/yyyy').format(_user!.birthDate!)),
            if (_user!.enrollmentDate != null)
              _buildDataRow('Ingreso (Juramento)', DateFormat('dd/MM/yyyy').format(_user!.enrollmentDate!)),
            if (_user!.enrollmentDate != null)
              _buildDataRow('Años de Servicio', '${DateTime.now().difference(_user!.enrollmentDate!).inDays ~/ 365} años'),
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
      case UserRole.oficial1:
        return 'Oficial 1 - Capitán y Jefe';
      case UserRole.oficial2:
        return 'Oficial 2 - Gestión Actividades';
      case UserRole.oficial3:
        return 'Oficial 3 - Ayudante';
      case UserRole.oficial4:
        return 'Oficial 4 - Teniente a Cargo';
      case UserRole.oficial5:
        return 'Oficial 5 - Administración';
      case UserRole.oficial6:
        return 'Oficial 6 - Tesorero';
      case UserRole.bombero:
        return 'Bombero';
      // Deprecated roles (backward compatibility)
      case UserRole.officer:
        return 'Oficial (Migrar)';
      case UserRole.firefighter:
        return 'Bombero (Migrar)';
    }
  }

  Widget _buildEPPCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.safety_divider, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text(
                  'EPP a Cargo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            if (_eppAssignments.isEmpty)
              const Text('No tienes EPP asignado actualmente')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  columnSpacing: 16,
                  horizontalMargin: 0,
                  columns: const [
                    DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Marca/Modelo', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Fecha Recepción', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _eppAssignments.map((epp) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getEPPIcon(epp.eppType),
                                color: AppTheme.navyBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(epp.eppType.displayName),
                            ],
                          ),
                        ),
                        DataCell(Text(epp.internalCode)),
                        DataCell(Text('${epp.brand ?? ''} ${epp.model ?? ''}'.trim().isEmpty 
                            ? '-' 
                            : '${epp.brand ?? ''} ${epp.model ?? ''}'.trim())),
                        DataCell(Text(epp.condition.displayName)),
                        DataCell(Text(DateFormat('dd/MM/yyyy').format(epp.receptionDate))),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getEPPIcon(EPPType type) {
    switch (type) {
      case EPPType.casco:
        return Icons.safety_divider;
      case EPPType.uniformeEstructural:
      case EPPType.uniformeMultirrol:
      case EPPType.uniformeParada:
        return Icons.checkroom;
      case EPPType.guantesEstructurales:
      case EPPType.guantesRescate:
        return Icons.back_hand;
      case EPPType.botas:
        return Icons.skateboarding;
      case EPPType.linterna:
        return Icons.flashlight_on;
      default:
        return Icons.inventory_2;
    }
  }

  static const _monthNames = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  Widget _buildMonthFilter() {
    return Row(
      children: [
        const Icon(Icons.calendar_month, size: 18, color: AppTheme.navyBlue),
        const SizedBox(width: 8),
        const Text('Filtrar mes:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: '$_selectedYear-$_selectedMonth',
          isDense: true,
          items: _monthOptions.map((opt) {
            return DropdownMenuItem(
              value: '${opt.year}-${opt.month}',
              child: Text('${_monthNames[opt.month]} ${opt.year}'),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            final parts = val.split('-');
            setState(() {
              _selectedYear = int.parse(parts[0]);
              _selectedMonth = int.parse(parts[1]);
            });
          },
        ),
      ],
    );
  }


  static const _citationTypes = [
    'Academia de Compañía',
    'Academia de Cuerpo',
    'Reunión Ordinaria',
    'Reunión Extraordinaria',
    'Citación de Compañía',
    'Citación de Cuerpo',
    'Otra Actividad',
  ];

  Widget _buildAttendanceSection(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return const Text('Sin registros');

    final sorted = [...records]..sort((a, b) {
        final da = DateTime.tryParse(a['event_date']?.toString() ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['event_date']?.toString() ?? '') ?? DateTime(0);
        return db.compareTo(da); // descendente: más recientes arriba, más antiguas abajo
      });

    return Column(
      children: sorted.map((record) {
        final dateStr = record['event_date']?.toString();
        final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
        final actType = record['act_type_name']?.toString() ?? 'N/A';
        final subtype = record['subtype']?.toString();
        final isEmergency = actType == 'Emergencia';
        final titleText = (isEmergency && subtype != null && subtype.isNotEmpty)
            ? '$actType · $subtype'
            : actType;
        final status = record['status']?.toString() ?? 'absent';

        final IconData icon;
        final Color color;
        final String statusText;

        if (status == 'present') {
          icon = Icons.check_circle;
          color = AppTheme.efectivaColor;
          statusText = 'Presente';
        } else if (status == 'permiso') {
          icon = Icons.event_available;
          color = AppTheme.warningColor;
          statusText = 'Permiso';
        } else {
          icon = Icons.cancel;
          color = Colors.grey;
          statusText = 'Ausente';
        }

        return ListTile(
          dense: true,
          leading: Icon(icon, color: color),
          title: Text(titleText),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
          trailing: Text(
            statusText,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCitationsHistoryCard() {
    final citations = _attendanceHistory.where((r) {
      if (!_citationTypes.contains(r['act_type_name']?.toString())) return false;
      final d = DateTime.tryParse(r['event_date']?.toString() ?? '');
      return d != null && d.month == _selectedMonth && d.year == _selectedYear;
    }).toList();

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
                  'Historial de Asistencias a Citaciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildAttendanceSection(citations),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergenciesHistoryCard() {
    final emergencies = _attendanceHistory.where((r) {
      if (r['act_type_name']?.toString() != 'Emergencia') return false;
      final d = DateTime.tryParse(r['event_date']?.toString() ?? '');
      return d != null && d.month == _selectedMonth && d.year == _selectedYear;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: AppTheme.navyBlue),
                const SizedBox(width: 8),
                Text(
                  'Historial de Asistencias a Emergencias',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildAttendanceSection(emergencies),
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
                final startStr = perm['start_date']?.toString();
                final endStr = perm['end_date']?.toString();
                final startDate = startStr != null ? DateTime.tryParse(startStr) ?? DateTime.now() : DateTime.now();
                final endDate = endStr != null ? DateTime.tryParse(endStr) ?? DateTime.now() : DateTime.now();
                final status = perm['status']?.toString() ?? 'pending';
                final reason = perm['reason']?.toString() ?? 'Sin motivo especificado';

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
