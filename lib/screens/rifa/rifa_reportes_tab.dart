import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/rifa_model.dart';
import 'package:sexta_app/services/rifa_service.dart';
import 'package:sexta_app/services/rifa_report_service.dart';

class RifaReportesTab extends StatefulWidget {
  const RifaReportesTab({super.key});

  @override
  State<RifaReportesTab> createState() => _RifaReportesTabState();
}

class _RifaReportesTabState extends State<RifaReportesTab> {
  final RifaService _rifaService = RifaService();
  final RifaReportService _rifaReportService = RifaReportService();
  
  bool _isGenerating = false;
  bool _isLoading = true;
  RifaModel? _rifaActiva;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rifa = await _rifaService.getRifaActiva();
      if (mounted) {
        setState(() {
          _rifaActiva = rifa;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando rifa activa para reportes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport(Future<File?> Function() generator, String filename) async {
    setState(() => _isGenerating = true);

    try {
      final file = await generator();

      if (mounted) {
        setState(() => _isGenerating = false);

        if (file != null) {
          // Móvil / Escritorio
          await _rifaReportService.downloadOrPreviewPDF(file, filename);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Reporte generado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Web
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Reporte descargado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.institutionalRed));
    }

    if (_rifaActiva == null) {
      return const Center(
        child: Text(
          'No hay rifa activa para generar reportes',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    final String rifaId = _rifaActiva!.id;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.institutionalRed,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.institutionalRed, AppTheme.institutionalRed.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 48, color: Colors.white),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sistema de Reportes - Rifa',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Genera reportes PDF para análisis y gestión de la rifa',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categoría 1: Reportes Generales
                _buildReportCategory(
                  title: 'Reportes Generales',
                  icon: Icons.assessment,
                  color: Colors.blue,
                  reports: [
                    _ReportOption(
                      title: 'Resumen General',
                      description: 'Estado general de la rifa con talonarios y recaudación',
                      icon: Icons.dashboard,
                      onTap: () => _generateReport(
                        () => _rifaReportService.generateResumenGeneral(rifaId),
                        'resumen_general_rifa.pdf'
                      ),
                    ),
                    _ReportOption(
                      title: 'Detalle por Bombero',
                      description: 'Talonarios y ventas desglosados por cada bombero',
                      icon: Icons.people,
                      onTap: () => _generateReport(
                        () => _rifaReportService.generateDetallePorBombero(rifaId),
                        'detalle_por_bombero.pdf'
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Categoría 2: Control y Seguimiento
                _buildReportCategory(
                  title: 'Control y Seguimiento',
                  icon: Icons.track_changes,
                  color: Colors.orange,
                  reports: [
                    _ReportOption(
                      title: 'Talonarios Pendientes',
                      description: 'Talonarios entregados que no han sido devueltos',
                      icon: Icons.warning_amber_rounded,
                      onTap: () => _generateReport(
                        () => _rifaReportService.generateTalonariosPendientes(rifaId),
                        'talonarios_pendientes.pdf'
                      ),
                      important: true,
                    ),
                    _ReportOption(
                      title: 'Bomberos Sin Talonarios',
                      description: 'Listado de bomberos que aún no han recibido talonarios asignados',
                      icon: Icons.person_off,
                      onTap: () => _generateReport(
                        () => _rifaReportService.generateBomberosSinTalonarios(rifaId),
                        'rifa_bomberos_sin_talonarios_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      ),
                    ),
                    _ReportOption(
                      title: 'Rendición de Dinero',
                      description: 'Estado de entregas de dinero por bombero',
                      icon: Icons.attach_money,
                      onTap: () => _generateReport(
                        () => _rifaReportService.generateRendicionDinero(rifaId),
                        'rendicion_dinero.pdf'
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Categoría 3: Análisis
                _buildReportCategory(
                  title: 'Análisis',
                  icon: Icons.analytics,
                  color: Colors.purple,
                  reports: [
                    _ReportOption(
                      title: 'Historial de Movimientos',
                      description: 'Registro completo de entregas y devoluciones',
                      icon: Icons.history,
                      onTap: () => _generateReport(
                        () => _rifaReportService.generateHistorialMovimientos(rifaId),
                        'historial_movimientos.pdf'
                      ),
                    ),
                    _ReportOption(
                      title: 'Ranking de Vendedores',
                      description: 'Clasificación de bomberos por números vendidos',
                      icon: Icons.emoji_events,
                      onTap: () => _generateReport(
                        () => _rifaReportService.generateRankingVendedores(rifaId),
                        'ranking_vendedores.pdf'
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80), // Padding extra abajo
              ],
            ),
          ),
        ),
        
        // Loading Overlay
        if (_isGenerating)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.institutionalRed),
                      SizedBox(height: 16),
                      Text(
                        'Generando documento PDF...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
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
