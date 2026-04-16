import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/models/user_status_history_model.dart';
import 'package:sexta_app/services/user_status_service.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/services/user_report_service.dart';
import 'dart:io';

class UserReportsTab extends StatefulWidget {
  const UserReportsTab({super.key});

  @override
  State<UserReportsTab> createState() => _UserReportsTabState();
}

class _UserReportsTabState extends State<UserReportsTab> {
  final _service = UserStatusService();
  final _reportService = UserReportService();

  // Sección activa
  int _selectedSection = 0; // 0 = Resumen, 1 = Historial

  // Resumen
  Map<String, int> _statusSummary = {};
  List<Map<String, dynamic>> _rankSummary = [];
  bool _isLoadingResumen = false;

  // Historial
  List<UserStatusHistory> _history = [];
  bool _isLoadingHistory = false;
  String? _historyFilterStatus;
  DateTimeRange? _historyDateRange;

  static const _statusOptions = [
    'activo',
    'suspendido',
    'renunciado',
    'expulsado',
    'separado',
    'fallecido',
  ];

  @override
  void initState() {
    super.initState();
    _loadResumen();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadResumen() async {
    setState(() => _isLoadingResumen = true);
    try {
      final summary = await _service.getStatusSummary();

      final rankResponse = await Supabase.instance.client
          .from('users')
          .select('rank')
          .eq('status', 'activo');

      final rankCount = <String, int>{};
      for (final row in rankResponse as List) {
        final rank = row['rank'] as String? ?? 'Sin cargo';
        rankCount[rank] = (rankCount[rank] ?? 0) + 1;
      }

      final rankList = rankCount.entries
          .map((e) => {'rank': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      setState(() {
        _statusSummary = summary;
        _rankSummary = rankList;
        _isLoadingResumen = false;
      });
    } catch (e) {
      setState(() => _isLoadingResumen = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando resumen: $e')),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _service.getAllStatusHistory(
        filterStatus: _historyFilterStatus,
        fromDate: _historyDateRange?.start,
        toDate: _historyDateRange?.end,
      );
      setState(() {
        _history = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando historial: $e')),
        );
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.activo:
        return Colors.green;
      case UserStatus.suspendido:
        return Colors.orange;
      case UserStatus.renunciado:
        return Colors.grey;
      case UserStatus.expulsado:
        return Colors.red;
      case UserStatus.separado:
        return Colors.blueGrey;
      case UserStatus.fallecido:
        return Colors.black87;
    }
  }

  String _statusLabel(String name) =>
      name[0].toUpperCase() + name.substring(1);

  int get _totalUsers =>
      _statusSummary.values.fold(0, (a, b) => a + b);

  int get _activeUsers => _statusSummary['activo'] ?? 0;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Toggle Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Resumen'),
                  icon: Icon(Icons.bar_chart),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Historial de Cambios'),
                  icon: Icon(Icons.history),
                ),
              ],
              selected: {_selectedSection},
              onSelectionChanged: (sel) {
                final section = sel.first;
                setState(() => _selectedSection = section);
                if (section == 0 && _statusSummary.isEmpty) {
                  _loadResumen();
                } else if (section == 1 && _history.isEmpty) {
                  _loadHistory();
                }
              },
            ),
          ),

          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _selectedSection == 0
                ? _buildResumen()
                : _buildHistorial(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportSelector(),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Exportar PDF'),
        backgroundColor: AppTheme.institutionalRed,
      ),
    );
  }

  // ============================================================
  // SECCIÓN 1: RESUMEN
  // ============================================================

  Widget _buildResumen() {
    if (_isLoadingResumen) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadResumen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total general
            Card(
              color: AppTheme.institutionalRed,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _totalBadge('Total', _totalUsers, Colors.white),
                    Container(width: 1, height: 40, color: Colors.white38),
                    _totalBadge('Activos', _activeUsers, Colors.greenAccent),
                    Container(width: 1, height: 40, color: Colors.white38),
                    _totalBadge(
                      'Inactivos',
                      _totalUsers - _activeUsers,
                      Colors.orange.shade200,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Por estado
            Text(
              'Por Estado',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _statusOptions.map((s) {
                final status = UserModel.parseStatus(s);
                final count = _statusSummary[s] ?? 0;
                final color = _getStatusColor(status);
                return _statusCard(
                  label: _statusLabel(s),
                  count: count,
                  color: color,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Por cargo
            Text(
              'Por Cargo (usuarios activos)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_rankSummary.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin datos',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Card(
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Cargo')),
                    DataColumn(
                        label: Text('Cantidad'),
                        numeric: true),
                  ],
                  rows: _rankSummary
                      .map(
                        (r) => DataRow(cells: [
                          DataCell(Text(r['rank'] as String)),
                          DataCell(Text('${r['count']}')),
                        ]),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _totalBadge(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _statusCard({
    required String label,
    required int count,
    required Color color,
  }) {
    return SizedBox(
      width: 130,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(Icons.person, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECCIÓN 2: HISTORIAL
  // ============================================================

  Widget _buildHistorial() {
    return Column(
      children: [
        // Barra de filtros
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              // Filtro por estado
              DropdownButton<String?>(
                value: _historyFilterStatus,
                hint: const Text('Todos los estados'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ..._statusOptions.map(
                    (s) => DropdownMenuItem<String?>(
                      value: s,
                      child: Text(_statusLabel(s)),
                    ),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _historyFilterStatus = v);
                  _loadHistory();
                },
              ),
              const Spacer(),
              // Rango de fechas
              TextButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _historyDateRange == null
                      ? 'Rango de fechas'
                      : '${DateFormat('dd/MM').format(_historyDateRange!.start)} – ${DateFormat('dd/MM').format(_historyDateRange!.end)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (_historyDateRange != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Limpiar fechas',
                  onPressed: () {
                    setState(() => _historyDateRange = null);
                    _loadHistory();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
                onPressed: _loadHistory,
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
                  ? _buildEmptyHistory()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: _history.length,
                      itemBuilder: (context, index) =>
                          _historyCard(_history[index]),
                    ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _historyDateRange,
    );
    if (picked != null) {
      setState(() => _historyDateRange = picked);
      _loadHistory();
    }
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay cambios de estado registrados',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(UserStatusHistory h) {
    final df = DateFormat('dd/MM/yyyy');
    final prevStatus = h.previousStatus;
    final newStatus = h.newStatus;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.institutionalRed,
          child: Text(
            _initials(h.userName ?? '?'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          h.userName ?? h.userId,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            _miniChip(prevStatus),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
            ),
            _miniChip(newStatus),
            const SizedBox(width: 8),
            Text(
              df.format(h.effectiveDate),
              style:
                  const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              df.format(h.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (h.changedByName != null)
              Text(
                'por: ${h.changedByName}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Motivo: ${h.reason}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(UserStatus status) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _getStatusColor(status).withOpacity(0.6)),
      ),
      child: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(
          fontSize: 10,
          color: _getStatusColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _showReportSelector() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Seleccionar Reporte'),
        children: [
          SimpleDialogOption(
            onPressed: () { Navigator.pop(ctx); _generateReport('activos'); },
            child: const ListTile(
              leading: Icon(Icons.people, color: Colors.green),
              title: Text('Nómina de Bomberos Activos'),
              subtitle: Text('Listado completo ordenado por cargo'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(ctx); _generateReport('cargo'); },
            child: const ListTile(
              leading: Icon(Icons.category, color: Colors.blue),
              title: Text('Nómina por Cargo'),
              subtitle: Text('Agrupado por categoría con subtotales'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(ctx); _generateReport('inactivos'); },
            child: const ListTile(
              leading: Icon(Icons.person_off, color: Colors.grey),
              title: Text('Bomberos Inactivos'),
              subtitle: Text('Renunciados, expulsados, separados...'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(ctx); _generateReport('historial'); },
            child: const ListTile(
              leading: Icon(Icons.history, color: Colors.orange),
              title: Text('Historial de Cambios'),
              subtitle: Text('Registro de todos los cambios de estado'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(ctx); _generateReport('resumen'); },
            child: const ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.purple),
              title: Text('Resumen Estadístico'),
              subtitle: Text('Totales por estado y cargo'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String type) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      File? file;
      String filename;

      switch (type) {
        case 'activos':
          file = await _reportService.generateActiveRosterReport();
          filename = 'nomina_activos.pdf';
        case 'cargo':
          file = await _reportService.generateRosterByRankReport();
          filename = 'nomina_por_cargo.pdf';
        case 'inactivos':
          file = await _reportService.generateInactiveReport();
          filename = 'bomberos_inactivos.pdf';
        case 'historial':
          file = await _reportService.generateStatusHistoryReport(
            fromDate: _historyDateRange?.start,
            toDate: _historyDateRange?.end,
          );
          filename = 'historial_cambios.pdf';
        case 'resumen':
          file = await _reportService.generateSummaryReport();
          filename = 'resumen_estadistico.pdf';
        default:
          file = null;
          filename = 'reporte.pdf';
      }

      if (mounted) Navigator.pop(context); // cerrar loading

      if (file != null) {
        await _reportService.downloadOrPreviewPDF(file, filename);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error generando el reporte')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // cerrar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
