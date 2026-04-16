import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/report_service.dart';
import 'package:sexta_app/utils/attendance_excel_generator.dart';
import 'package:sexta_app/utils/guard_roster_excel_generator.dart';
import 'package:sexta_app/widgets/app_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportService = ReportService();

  late int _selectedMonth;
  late int _selectedYear;
  bool _isLoading = false;
  bool _isLoadingGuard = false;

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  List<int> get _years {
    final now = DateTime.now();
    return List.generate(now.year - 2025 + 2, (i) => 2025 + i);
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await _reportService.getMonthlyAttendanceReport(
        _selectedYear,
        _selectedMonth,
      );
      final bytes = AttendanceExcelGenerator.generate(data);
      final mesStr = _meses[_selectedMonth - 1];
      AttendanceExcelGenerator.downloadExcel(
        bytes,
        'Asistencia_${mesStr}_$_selectedYear.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte generado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateGuardReport() async {
    setState(() => _isLoadingGuard = true);
    try {
      final data = await _reportService.getGuardRosterReport(
        _selectedYear,
        _selectedMonth,
      );
      final bytes = GuardRosterExcelGenerator.generate(data);
      final mesStr = _meses[_selectedMonth - 1];
      GuardRosterExcelGenerator.downloadExcel(
        bytes,
        'Rol_Guardia_${mesStr}_$_selectedYear.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte de guardia generado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte de guardia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGuard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: AppTheme.institutionalRed,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reporte Mensual de Asistencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Genera el reporte Excel con la asistencia a emergencias y citaciones del mes seleccionado.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Selector de mes
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mes', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButton<int>(
                          value: _selectedMonth,
                          items: List.generate(12, (i) {
                            return DropdownMenuItem(
                              value: i + 1,
                              child: Text(_meses[i]),
                            );
                          }),
                          onChanged: (v) => setState(() => _selectedMonth = v!),
                        ),
                      ],
                    ),
                    // Selector de año
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Año', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButton<int>(
                          value: _selectedYear,
                          items: _years.map((y) {
                            return DropdownMenuItem(value: y, child: Text(y.toString()));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedYear = v!),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _generateReport,
                        icon: const Icon(Icons.download),
                        label: const Text('Generar Reporte Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.institutionalRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calendario de Rol de Guardia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Genera el Excel con el rol de guardia nocturna y FDS del mes seleccionado.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Selector de mes
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mes', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButton<int>(
                            value: _selectedMonth,
                            items: List.generate(12, (i) {
                              return DropdownMenuItem(
                                value: i + 1,
                                child: Text(_meses[i]),
                              );
                            }),
                            onChanged: (v) => setState(() => _selectedMonth = v!),
                          ),
                        ],
                      ),
                      // Selector de año
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Año', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButton<int>(
                            value: _selectedYear,
                            items: _years.map((y) {
                              return DropdownMenuItem(value: y, child: Text(y.toString()));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedYear = v!),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _isLoadingGuard
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _generateGuardReport,
                          icon: const Icon(Icons.shield),
                          label: const Text('Generar Rol de Guardia'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.institutionalRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
