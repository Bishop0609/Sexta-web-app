import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/treasury_report_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/permissions/role_permissions.dart';
import '../../providers/user_provider.dart';
import '../../widgets/report_filters.dart';

/// Tab de Reportes para Tesorería
class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  final TreasuryReportService _reportService = TreasuryReportService();
  final UserService _userService = UserService();
  bool _isGenerating = false;
  
  // Filter state
  String? _selectedUserId;
  DateTime? _startDate;
  DateTime? _endDate;
  List<UserModel> _users = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _generateReport(Future<File?> Function() generator, String filename) async {
    setState(() => _isGenerating = true);

    try {
      final file = await generator();

      if (mounted) {
        setState(() => _isGenerating = false);

        if (file != null) {
          // Desktop/mobile: preview the file
          await _reportService.downloadOrPreviewPDF(file, filename);
          
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Reporte generado exitosamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Web: file was already downloaded, just show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Reporte descargado exitosamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser != null && RolePermissions.isAdmin(currentUser.role);

    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Generando reporte...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),
            Text(
              'Esto puede tomar unos segundos',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.institutionalRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.institutionalRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.assessment, size: 32, color: AppTheme.institutionalRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sistema de Reportes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.institutionalRed,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Genera reportes PDF para análisis y auditoría de tesorería',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Filtros
          if (!_isLoadingUsers)
            ReportFilters(
              selectedUserId: _selectedUserId,
              startDate: _startDate,
              endDate: _endDate,
              users: _users,
              onUserChanged: (userId) => setState(() => _selectedUserId = userId),
              onStartDateChanged: (date) => setState(() => _startDate = date),
              onEndDateChanged: (date) => setState(() => _endDate = date),
            ),

          const SizedBox(height: 30),

          // Reportes Mensuales
          _buildReportCategory(
            title: 'Reportes Mensuales',
            icon: Icons.calendar_month,
            color: Colors.blue,
            reports: [
              _ReportOption(
                title: 'Resumen Mensual',
                description: 'Recaudación y estado de pagos del mes actual',
                icon: Icons.summarize,
                onTap: () => _generateReport(
                  () => _reportService.generateMonthlyReport(
                    month: DateTime.now().month,
                    year: DateTime.now().year,
                    userId: _selectedUserId,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  'reporte_mensual_${DateTime.now().month}_${DateTime.now().year}.pdf',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Reportes de Usuarios
          _buildReportCategory(
            title: 'Reportes de Usuarios',
            icon: Icons.people,
            color: Colors.orange,
            reports: [
              _ReportOption(
                title: 'Morosidad General',
                description: 'Lista de usuarios con deudas pendientes',
                icon: Icons.warning_amber,
                onTap: () => _generateReport(
                  () => _reportService.generateDelinquencyReport(
                    userId: _selectedUserId,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  'reporte_morosidad_${DateTime.now().millisecondsSinceEpoch}.pdf',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Reportes Analíticos - SOLO PARA ADMIN
          if (isAdmin) ...[
            _buildReportCategory(
              title: 'Reportes Analíticos',
              icon: Icons.analytics,
              color: Colors.purple,
              reports: [
                _ReportOption(
                  title: 'Base de Datos Completa',
                  description: 'Estado completo de TODOS los usuarios con obligación de pago',
                  icon: Icons.storage,
                  important: true,
                  onTap: () => _generateReport(
                    () => _reportService.generateCompleteDatabaseReport(
                      userId: _selectedUserId,
                      startDate: _startDate,
                      endDate: _endDate,
                    ),
                    'reporte_completo_bd_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  ),
                ),
                _ReportOption(
                  title: 'Reporte de Inconsistencias',
                  description: 'Detecta problemas en los datos para regularizar',
                  icon: Icons.bug_report,
                  important: true,
                  onTap: () => _generateReport(
                    () => _reportService.generateInconsistenciesReport(),
                    'reporte_inconsistencias_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 30),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdmin ? 'Recomendación' : 'Información',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdmin
                            ? 'Ejecuta primero el "Reporte de Inconsistencias" para identificar problemas en los datos. Luego usa el "Reporte de Base de Datos Completa" para un análisis general.'
                            : 'Los reportes analíticos (Base de Datos Completa e Inconsistencias) están disponibles solo para administradores. Si necesitas acceso a estos reportes, contacta al administrador del sistema.',
                        style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCategory({
    required String title,
    required IconData icon,
    required Color color,
    required List<_ReportOption> reports,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Report Cards
        ...reports.map((report) => _buildReportCard(report, color)),
      ],
    );
  }

  Widget _buildReportCard(_ReportOption report, Color categoryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: InkWell(
        onTap: report.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(report.icon, color: categoryColor, size: 28),
              ),
              const SizedBox(width: 16),
              
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (report.important) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'IMPORTANTE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportOption {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool important;

  _ReportOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.important = false,
  });
}
