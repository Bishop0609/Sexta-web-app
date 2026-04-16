import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/providers/night_guard_report_provider.dart';
import 'package:sexta_app/services/pdf/night_guard_pdf_service.dart';

class NightGuardReportScreen extends ConsumerStatefulWidget {
  const NightGuardReportScreen({super.key});

  @override
  ConsumerState<NightGuardReportScreen> createState() => _NightGuardReportScreenState();
}

class _NightGuardReportScreenState extends ConsumerState<NightGuardReportScreen> {
  late int _selectedMonth;
  late int _selectedYear;

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

  Future<void> _exportPdf(Map<String, dynamic> data) async {
    try {
      final pdfService = NightGuardPdfService();
      await pdfService.generateReport(data, _selectedYear, _selectedMonth);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(nightGuardReportProvider((year: _selectedYear, month: _selectedMonth)));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Guardia Nocturna', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.institutionalRed,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.table_chart), text: 'Detalle'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Rankings'),
            ],
          ),
          actions: [
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: AppTheme.institutionalRed,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: _selectedMonth,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: List.generate(12, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text(_meses[i]),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedMonth = v);
                    },
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedYear,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: _years.map((y) {
                      return DropdownMenuItem(value: y, child: Text(y.toString()));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedYear = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            reportAsync.when(
              data: (data) => IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exportar PDF',
                onPressed: () => _exportPdf(data),
              ),
              loading: () => const SizedBox(width: 48, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))),
              error: (_, __) => const SizedBox(width: 48),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error al cargar reporte:\n$err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          data: (data) {
            return TabBarView(
              children: [
                _DashboardTab(summary: data['summary'] as Map<String, dynamic>? ?? {}),
                _DetalleTab(byUser: List<Map<String, dynamic>>.from(data['by_user'] as List<dynamic>? ?? [])),
                _RankingsTab(rankings: data['rankings'] as Map<String, dynamic>? ?? {}),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _DashboardTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) {
      return const Center(child: Text('Sin datos para este período.'));
    }

    final complianceStr = summary['compliance_percentage']?.toString() ?? '0';
    final compliance = double.tryParse(complianceStr) ?? 0;
    
    Color compColor = Colors.red;
    if (compliance >= 80) compColor = Colors.green;
    else if (compliance >= 60) compColor = Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 3;
          if (constraints.maxWidth < 600) {
            crossAxisCount = 2;
          }
          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _MetricCard(
                title: 'Cumplimiento',
                value: '$complianceStr%',
                color: compColor,
              ),
              _MetricCard(
                title: 'Asignaciones',
                value: summary['total_assignments']?.toString() ?? '0',
                color: Colors.blueGrey,
              ),
              _MetricCard(
                title: 'Presentes',
                value: summary['total_presente']?.toString() ?? '0',
                color: Colors.green,
              ),
              _MetricCard(
                title: 'Ausencias',
                value: summary['total_ausente']?.toString() ?? '0',
                color: Colors.red,
              ),
              _MetricCard(
                title: 'Reemplazadas',
                value: summary['total_reemplazado_cubierto']?.toString() ?? '0',
                color: Colors.blue,
              ),
              _MetricCard(
                title: 'Sin registro',
                value: summary['total_sin_registro']?.toString() ?? '0',
                color: Colors.orange,
              ),
            ],
          );
        }
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleTab extends StatelessWidget {
  final List<Map<String, dynamic>> byUser;

  const _DetalleTab({required this.byUser});

  @override
  Widget build(BuildContext context) {
    if (byUser.isEmpty) {
      return const Center(child: Text('Sin datos para este período.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('Bombero', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Asig.', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Pres.', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Aus.', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Perm.', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Reemp.', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('S/R', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Cubrió', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('%', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: byUser.map((b) {
                  final asig = b['asignadas']?.toString() ?? '0';
                  final pres = b['presente']?.toString() ?? '0';
                  final aus = b['ausente']?.toString() ?? '0';
                  final perm = b['permiso']?.toString() ?? '0';
                  final reem = b['reemplazado_cubierto']?.toString() ?? '0';
                  final sr = b['sin_registro']?.toString() ?? '0';
                  final cubrio = b['cubriendo_otros']?.toString() ?? '0';
                  final pctStr = b['porcentaje_cumplimiento']?.toString() ?? '0';
                  final pct = double.tryParse(pctStr) ?? 0;

                  Color badgeColor = Colors.red;
                  if (pct >= 80) badgeColor = Colors.green;
                  else if (pct >= 60) badgeColor = Colors.orange;

                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(b['full_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(b['rank']?.toString() ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      DataCell(Text(asig)),
                      DataCell(Text(pres, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500))),
                      DataCell(Text(aus, style: TextStyle(color: aus == '0' ? Colors.black : Colors.red, fontWeight: aus == '0' ? FontWeight.normal : FontWeight.w500))),
                      DataCell(Text(perm)),
                      DataCell(Text(reem)),
                      DataCell(Text(sr, style: TextStyle(color: sr == '0' ? Colors.black : Colors.orange))),
                      DataCell(Text(cubrio, style: const TextStyle(color: Colors.blue))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeColor),
                          ),
                          child: Text('$pctStr%', style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey.shade50,
          child: const Text(
            'Asig.=Asignadas - Perm.=Permiso justificado - Reemp.=Reemplazado - S/R=Sin registro - Cubrió=Noches como reemplazante',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _RankingsTab extends StatelessWidget {
  final Map<String, dynamic> rankings;

  const _RankingsTab({required this.rankings});

  @override
  Widget build(BuildContext context) {
    final topCumplidores = List<Map<String, dynamic>>.from(rankings['top_cumplidores'] as List<dynamic>? ?? []);
    final topAusentes = List<Map<String, dynamic>>.from(rankings['top_ausentes'] as List<dynamic>? ?? []);
    final topCubridores = List<Map<String, dynamic>>.from(rankings['top_cubridores'] as List<dynamic>? ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRankingCard(
          title: 'Top Cumplidores',
          icon: Icons.emoji_events,
          iconColor: Colors.amber,
          data: topCumplidores,
          formatDetail: (item) => '${item['asignadas']} asignadas (${item['porcentaje']}%)',
        ),
        const SizedBox(height: 16),
        _buildRankingCard(
          title: 'Top Ausencias',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
          data: topAusentes,
          formatDetail: (item) => '${item['ausente']} faltas de ${item['asignadas']} asignadas',
        ),
        const SizedBox(height: 16),
        _buildRankingCard(
          title: 'Top Cubridores',
          icon: Icons.handshake,
          iconColor: Colors.blue,
          data: topCubridores,
          formatDetail: (item) => 'Cubrió ${item['cubriendo_otros']} veces',
        ),
      ],
    );
  }

  Widget _buildRankingCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> data,
    required String Function(Map<String, dynamic>) formatDetail,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            if (data.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Sin datos para este mes.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: iconColor.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(fontSize: 12, color: iconColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(item['full_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text(
                      formatDetail(item),
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
