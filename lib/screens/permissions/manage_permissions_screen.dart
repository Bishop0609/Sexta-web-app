import 'package:flutter/material.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/email_service.dart';
import 'package:sexta_app/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/storage_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ManagePermissionsScreen extends StatefulWidget {
  const ManagePermissionsScreen({super.key});

  @override
  State<ManagePermissionsScreen> createState() => _ManagePermissionsScreenState();
}

class _ManagePermissionsScreenState extends State<ManagePermissionsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService();
  final _authService = AuthService();
  final _emailService = EmailService();
  final _pdfService = PdfService();
  final _storageService = StorageService();

  late TabController _tabController;
  List<Map<String, dynamic>> _pendingPermissions = [];
  List<Map<String, dynamic>> _historicalPermissions = [];
  List<Map<String, dynamic>> _filteredHistoricalPermissions = [];
  bool _isLoading = true;
  
  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all'; // all, approved, rejected
  DateTimeRange? _dateRange;
  String _filtroAprobador = 'todos'; // 'todos', 'capitan', 'director'
  String _filtroAprobadorHistorial = 'todos'; // filtro separado para historial

  // Estado tab Reportes
  String _reportMode = 'fechas'; // 'fechas' o 'actividad'
  String _reportStatusFilter = 'all'; // all, approved, rejected
  String _reportAprobador = 'todos'; // todos, capitan, director
  DateTimeRange? _reportDateRange;
  String? _reportSelectedUserId;
  String? _reportSelectedUserName;
  List<UserModel> _reportUsers = [];
  List<Map<String, dynamic>> _reportActividades = [];
  String? _reportSelectedActividadId;
  String? _reportSelectedActividadName;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadPermissions();
    _loadUsersForReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsersForReport() async {
    try {
      final users = await _supabase.getAllUsers();
      setState(() => _reportUsers = users);
    } catch (e) {
      // silently ignore
    }
    try {
      final actividades = await _supabase.client
          .from('activities')
          .select('id, title, activity_date, activity_type')
          .order('activity_date', ascending: false)
          .limit(10);
      setState(() => _reportActividades = List<Map<String, dynamic>>.from(actividades as List));
    } catch (e) {
      // silently ignore
    }
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);

    try {
      final pending = await _supabase.getPermissionsByStatus('pending');
      final approved = await _supabase.getPermissionsByStatus('approved');
      final rejected = await _supabase.getPermissionsByStatus('rejected');

      setState(() {
        _pendingPermissions = pending;
        _historicalPermissions = [...approved, ...rejected]
          ..sort((a, b) => (b['reviewed_at'] as String? ?? '')
              .compareTo(a['reviewed_at'] as String? ?? ''));
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando permisos: $e')),
        );
      }
    }
  }
  
  void _applyFilters() {
    var filtered = _historicalPermissions;
    
    // Filtrar por búsqueda (nombre de bombero)
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        final userName = (p['user']['full_name'] as String).toLowerCase();
        return userName.contains(query);
      }).toList();
    }
    
    // Filtrar por estado
    if (_filterStatus != 'all') {
      filtered = filtered.where((p) => p['status'] == _filterStatus).toList();
    }
    
    // Filtrar por rango de fechas (busca en start_date, end_date y reviewed_at)
    if (_dateRange != null) {
      filtered = filtered.where((p) {
        final startDateStr = p['start_date'] as String?;
        final endDateStr = p['end_date'] as String?;

        DateTime? reviewedDate;
        if (p['reviewed_at'] != null) {
          try { reviewedDate = DateTime.parse(p['reviewed_at']); } catch (e) {}
        }

        final rangeStart = _dateRange!.start;
        final rangeEnd = _dateRange!.end.add(const Duration(days: 1));

        bool startInRange = false;
        bool endInRange = false;
        if (startDateStr != null) {
          final startDate = DateTime.parse(startDateStr);
          startInRange = startDate.isAfter(rangeStart.subtract(const Duration(days: 1))) && startDate.isBefore(rangeEnd);
        }
        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          endInRange = endDate.isAfter(rangeStart.subtract(const Duration(days: 1))) && endDate.isBefore(rangeEnd);
        }
        final reviewedInRange = reviewedDate != null &&
                                reviewedDate.isAfter(rangeStart.subtract(const Duration(days: 1))) &&
                                reviewedDate.isBefore(rangeEnd);

        return startInRange || endInRange || reviewedInRange;
      }).toList();
    }

    _filteredHistoricalPermissions = filtered;
  }

  void _showPermissionDetail(Map<String, dynamic> permission) {
    showDialog(
      context: context,
      builder: (context) => _PermissionDetailDialog(
        permission: permission,
        onApprove: () => _updatePermissionStatus(permission['id'], true, null),
        onReject: (reason) =>
            _updatePermissionStatus(permission['id'], false, reason),
      ),
    );
  }

  Future<void> _showReportDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReportConfigDialog(
        initialDateRange: _dateRange,
      ),
    );

    if (result != null && mounted) {
      final dateRange = result['dateRange'] as DateTimeRange;
      final userId = result['userId'] as String?;
      final firefighterName = result['firefighterName'] as String?;
      final statusFilter = result['statusFilter'] as String;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );

      try {
        List<Map<String, dynamic>> permissions = [];

        if (statusFilter == 'approved' || statusFilter == 'all') {
          final approved = await _supabase.getApprovedPermissionsBetweenDates(
            dateRange.start,
            dateRange.end,
            userId: userId,
          );
          permissions.addAll(approved);
        }

        if (statusFilter == 'rejected' || statusFilter == 'all') {
          final rejected = await _supabase.getPermissionsByStatusBetweenDates(
            'rejected',
            dateRange.start,
            dateRange.end,
            userId: userId,
          );
          permissions.addAll(rejected);
        }

        // Ordenar por fecha de inicio (null-safe: actividad va al final)
        permissions.sort((a, b) {
          final sa = a['start_date'] as String?;
          final sb = b['start_date'] as String?;
          if (sa == null && sb == null) return 0;
          if (sa == null) return 1;
          if (sb == null) return -1;
          return sa.compareTo(sb);
        });

        if (mounted) Navigator.of(context).pop();

        await _pdfService.generatePermissionsReport(
          permissions: permissions,
          startDate: dateRange.start,
          endDate: dateRange.end,
          firefighterName: firefighterName,
          statusFilter: statusFilter,
        );
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error generando reporte: $e'),
              backgroundColor: AppTheme.criticalColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _updatePermissionStatus(
    String permissionId,
    bool approved,
    String? rejectionReason,
  ) async {
    try {
      final userId = _authService.currentUserId!;
      await _supabase.updatePermissionStatus(
        permissionId,
        approved ? 'approved' : 'rejected',
        userId,
        reason: rejectionReason,
      );

      // Obtener datos del permiso y usuario para email
      final permission = _pendingPermissions
          .firstWhere((p) => p['id'] == permissionId);
      final userEmail = permission['user']['email'] as String?;
      final userName = permission['user']['full_name'] as String;
      final tipoPermiso = permission['tipo_permiso'] as String? ?? 'fecha';
      
      String startDate = '';
      String endDate = '';
      String? activityName;
      String? activityDate;
      
      if (tipoPermiso == 'actividad') {
        final activity = permission['activity'] as Map<String, dynamic>?;
        if (activity != null) {
          activityName = activity['title'] as String?;
          if (activity['activity_date'] != null) {
            activityDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(activity['activity_date']));
          }
        }
      } else {
        final startRaw = permission['start_date'] as String?;
        final endRaw = permission['end_date'] as String?;
        startDate = startRaw != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(startRaw))
            : '';
        endDate = endRaw != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(endRaw))
            : '';
      }
      
      final reason = permission['reason'] as String;

      if (userEmail != null) {
        await _emailService.sendPermissionDecisionNotification(
          firefighterEmail: userEmail,
          firefighterName: userName,
          approved: approved,
          startDate: startDate,
          endDate: endDate,
          reason: reason,
          rejectionReason: rejectionReason,
          activityName: activityName,
          activityDate: activityDate,
          aprobadorTipo: permission['aprobador_tipo'] as String? ?? 'capitan',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved
                ? 'Permiso aprobado exitosamente'
                : 'Permiso rechazado'),
            backgroundColor:
                approved ? AppTheme.efectivaColor : AppTheme.criticalColor,
          ),
        );
        _loadPermissions(); // Reload
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Permisos'),
        backgroundColor: AppTheme.institutionalRed,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'Pendientes (${_pendingPermissions.length})',
            ),
            const Tab(
              icon: Icon(Icons.history),
              text: 'Historial',
            ),
            const Tab(
              icon: Icon(Icons.picture_as_pdf),
              text: 'Reportes',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPermissions,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildHistoryTab(),
                _buildReportTab(),
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    final displayPermissions = _filtroAprobador == 'todos'
        ? _pendingPermissions
        : _pendingPermissions.where((p) {
            final aprobador = p['aprobador_tipo'] as String?;
            return aprobador == _filtroAprobador;
          }).toList();
          
    final countCapitan = _pendingPermissions.where((p) => p['aprobador_tipo'] == 'capitan').length;
    final countDirector = _pendingPermissions.where((p) => p['aprobador_tipo'] == 'director').length;
    
    return Column(
      children: [
        // Filtros por aprobador + leyenda
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text('🔵 Capitán  🟡 Director',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _filtroAprobador == 'todos',
                    onSelected: (_) => setState(() => _filtroAprobador = 'todos'),
                  ),
                  FilterChip(
                    label: Text('Capitán ($countCapitan)'),
                    avatar: CircleAvatar(
                        backgroundColor: Colors.blue[700], radius: 6),
                    selected: _filtroAprobador == 'capitan',
                    onSelected: (_) => setState(() => _filtroAprobador = 'capitan'),
                  ),
                  FilterChip(
                    label: Text('Director ($countDirector)'),
                    avatar: CircleAvatar(
                        backgroundColor: Colors.amber[700], radius: 6),
                    selected: _filtroAprobador == 'director',
                    onSelected: (_) => setState(() => _filtroAprobador = 'director'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: displayPermissions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: AppTheme.efectivaColor),
                      SizedBox(height: 16),
                      Text(
                        'No hay permisos pendientes',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayPermissions.length,
                  itemBuilder: (context, index) {
                    final permission = displayPermissions[index];
                    return _buildPermissionCard(permission, isPending: true);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_historicalPermissions.isEmpty) {
      return const Center(
        child: Text(
          'No hay historial de permisos',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final displayHistorial = _filtroAprobadorHistorial == 'todos'
        ? _filteredHistoricalPermissions
        : _filteredHistoricalPermissions.where((p) {
            final aprobador = p['aprobador_tipo'] as String?;
            return aprobador == _filtroAprobadorHistorial;
          }).toList();

    return Column(
      children: [
        // Filtros
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Búsqueda por nombre
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre de bombero...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _applyFilters());
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => setState(() => _applyFilters()),
              ),
              const SizedBox(height: 12),
              // Filtro por estado
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _filterStatus == 'all',
                    onSelected: (_) => setState(() {
                      _filterStatus = 'all';
                      _applyFilters();
                    }),
                  ),
                  FilterChip(
                    label: const Text('Aprobados'),
                    selected: _filterStatus == 'approved',
                    onSelected: (_) => setState(() {
                      _filterStatus = 'approved';
                      _applyFilters();
                    }),
                  ),
                  FilterChip(
                    label: const Text('Rechazados'),
                    selected: _filterStatus == 'rejected',
                    onSelected: (_) => setState(() {
                      _filterStatus = 'rejected';
                      _applyFilters();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Filtro por aprobador (idéntico al de Pendientes)
              const Center(
                child: Text('🔵 Capitán  🟡 Director',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _filtroAprobadorHistorial == 'todos',
                    onSelected: (_) => setState(() => _filtroAprobadorHistorial = 'todos'),
                  ),
                  FilterChip(
                    label: const Text('Capitán'),
                    avatar: CircleAvatar(
                        backgroundColor: Colors.blue[700], radius: 6),
                    selected: _filtroAprobadorHistorial == 'capitan',
                    onSelected: (_) => setState(() => _filtroAprobadorHistorial = 'capitan'),
                  ),
                  FilterChip(
                    label: const Text('Director'),
                    avatar: CircleAvatar(
                        backgroundColor: Colors.amber[700], radius: 6),
                    selected: _filtroAprobadorHistorial == 'director',
                    onSelected: (_) => setState(() => _filtroAprobadorHistorial = 'director'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Filtro por rango de fechas
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: _dateRange,
                        );
                        if (picked != null) {
                          setState(() {
                            _dateRange = picked;
                            _applyFilters();
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _dateRange == null
                            ? 'Filtrar por fechas'
                            : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
                      ),
                    ),
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Limpiar filtro de fechas',
                      onPressed: () => setState(() {
                        _dateRange = null;
                        _applyFilters();
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Lista filtrada
        Expanded(
          child: displayHistorial.isEmpty
              ? const Center(child: Text('No se encontraron permisos'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayHistorial.length,
                  itemBuilder: (context, index) {
                    final permission = displayHistorial[index];
                    return _buildPermissionCard(permission, isPending: false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportTab() {
    final bool canGenerate = _reportMode == 'fechas'
        ? _reportDateRange != null
        : _reportSelectedActividadId != null;

    String buttonLabel;
    if (_isGeneratingReport) {
      buttonLabel = 'Generando...';
    } else if (_reportMode == 'fechas' && _reportDateRange == null) {
      buttonLabel = 'Seleccione un rango de fechas';
    } else if (_reportMode == 'actividad' && _reportSelectedActividadId == null) {
      buttonLabel = 'Seleccione una actividad';
    } else {
      buttonLabel = 'Generar Reporte PDF';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selector de modo ──
          const Text('Modo de reporte', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppTheme.institutionalRed,
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(
                value: 'fechas',
                label: Text('Por rango de fechas'),
                icon: Icon(Icons.date_range),
              ),
              ButtonSegment(
                value: 'actividad',
                label: Text('Por actividad'),
                icon: Icon(Icons.event),
              ),
            ],
            selected: {_reportMode},
            onSelectionChanged: (val) => setState(() {
              _reportMode = val.first;
              if (_reportMode == 'fechas') {
                _reportSelectedActividadId = null;
                _reportSelectedActividadName = null;
              } else {
                _reportDateRange = null;
                _reportSelectedUserId = null;
                _reportSelectedUserName = null;
              }
            }),
          ),
          const SizedBox(height: 24),

          // ── Filtros condicionales por modo ──
          if (_reportMode == 'actividad') ...[
            const Text('Actividad', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _reportSelectedActividadId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Seleccionar actividad',
                prefixIcon: Icon(Icons.event),
              ),
              items: _reportActividades.map((act) {
                final title = act['title'] as String? ?? '';
                final dateRaw = act['activity_date'] as String?;
                String fechaLabel = '';
                if (dateRaw != null) {
                  try {
                    fechaLabel = DateFormat('dd/MMM', 'es').format(DateTime.parse(dateRaw));
                  } catch (_) {}
                }
                return DropdownMenuItem<String>(
                  value: act['id'] as String,
                  child: Text('$fechaLabel — $title', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) => setState(() {
                _reportSelectedActividadId = val;
                if (val == null) {
                  _reportSelectedActividadName = null;
                } else {
                  try {
                    _reportSelectedActividadName = _reportActividades
                        .firstWhere((a) => a['id'] == val)['title'] as String?;
                  } catch (_) {
                    _reportSelectedActividadName = null;
                  }
                }
              }),
            ),
            const SizedBox(height: 20),
          ],

          if (_reportMode == 'fechas') ...[
            const Text('Rango de fechas', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: _reportDateRange,
                      );
                      if (picked != null) setState(() => _reportDateRange = picked);
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _reportDateRange == null
                          ? 'Seleccionar rango'
                          : '${DateFormat('dd/MM/yyyy').format(_reportDateRange!.start)} — ${DateFormat('dd/MM/yyyy').format(_reportDateRange!.end)}',
                    ),
                  ),
                ),
                if (_reportDateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _reportDateRange = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            const Text('Filtrar por bombero (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _reportSelectedUserId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Todos los bomberos',
                prefixIcon: Icon(Icons.person_search),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('— Todos los bomberos —')),
                ..._reportUsers.map((u) => DropdownMenuItem<String>(
                      value: u.id,
                      child: Text(u.fullName),
                    )),
              ],
              onChanged: (val) => setState(() {
                _reportSelectedUserId = val;
                if (val == null) {
                  _reportSelectedUserName = null;
                } else {
                  try {
                    _reportSelectedUserName =
                        _reportUsers.firstWhere((u) => u.id == val).fullName;
                  } catch (_) {
                    _reportSelectedUserName = null;
                  }
                }
              }),
            ),
            const SizedBox(height: 20),
          ],

          // ── Tipo de permiso (ambos modos) ──
          const Text('Tipo de Permiso', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppTheme.institutionalRed,
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(value: 'all', label: Text('Ambos')),
              ButtonSegment(value: 'approved', label: Text('Aprobados')),
              ButtonSegment(value: 'rejected', label: Text('Rechazados')),
            ],
            selected: {_reportStatusFilter},
            onSelectionChanged: (val) => setState(() => _reportStatusFilter = val.first),
          ),
          const SizedBox(height: 20),

          // ── Filtro por aprobador (ambos modos) ──
          const Text('Filtrar por aprobador', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('🔵 Capitán  🟡 Director', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: _reportAprobador == 'todos',
                onSelected: (_) => setState(() => _reportAprobador = 'todos'),
              ),
              FilterChip(
                label: const Text('Capitán'),
                avatar: CircleAvatar(backgroundColor: Colors.blue[700], radius: 6),
                selected: _reportAprobador == 'capitan',
                onSelected: (_) => setState(() => _reportAprobador = 'capitan'),
              ),
              FilterChip(
                label: const Text('Director'),
                avatar: CircleAvatar(backgroundColor: Colors.amber[700], radius: 6),
                selected: _reportAprobador == 'director',
                onSelected: (_) => setState(() => _reportAprobador = 'director'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Botón generar ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !canGenerate || _isGeneratingReport ? null : _generateReportFromTab,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.institutionalRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isGeneratingReport
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReportFromTab() async {
    setState(() => _isGeneratingReport = true);
    try {
      List<Map<String, dynamic>> permissions = [];

      if (_reportMode == 'fechas') {
        if (_reportDateRange == null) return;

        if (_reportStatusFilter == 'approved' || _reportStatusFilter == 'all') {
          final approved = await _supabase.getApprovedPermissionsBetweenDates(
            _reportDateRange!.start,
            _reportDateRange!.end,
            userId: _reportSelectedUserId,
          );
          permissions.addAll(approved);
        }
        if (_reportStatusFilter == 'rejected' || _reportStatusFilter == 'all') {
          final rejected = await _supabase.getPermissionsByStatusBetweenDates(
            'rejected',
            _reportDateRange!.start,
            _reportDateRange!.end,
            userId: _reportSelectedUserId,
          );
          permissions.addAll(rejected);
        }
      } else {
        if (_reportSelectedActividadId == null) return;

        var query = _supabase.client
            .from('permissions')
            .select('*, user:users!permissions_user_id_fkey(*), activity:activities(*)')
            .eq('actividad_id', _reportSelectedActividadId!);

        if (_reportStatusFilter == 'approved') {
          query = query.eq('status', 'approved');
        } else if (_reportStatusFilter == 'rejected') {
          query = query.eq('status', 'rejected');
        } else {
          query = query.inFilter('status', ['approved', 'rejected']);
        }

        final result = await query.order('created_at', ascending: true);
        permissions = List<Map<String, dynamic>>.from(result as List);

        // También traer permisos por período que cubren la fecha de la actividad
        final actData = _reportActividades.firstWhere(
          (a) => a['id'] == _reportSelectedActividadId,
          orElse: () => <String, dynamic>{},
        );
        if (actData['activity_date'] != null) {
          final actDateStr = actData['activity_date'] as String;
          List<Map<String, dynamic>> datePermissions = [];

          if (_reportStatusFilter == 'approved' || _reportStatusFilter == 'all') {
            final approved = await _supabase.client
                .from('permissions')
                .select('*, user:users!permissions_user_id_fkey(*), activity:activities(*)')
                .eq('status', 'approved')
                .eq('tipo_permiso', 'fecha')
                .lte('start_date', actDateStr)
                .gte('end_date', actDateStr)
                .order('created_at', ascending: true);
            datePermissions.addAll(List<Map<String, dynamic>>.from(approved as List));
          }

          if (_reportStatusFilter == 'rejected' || _reportStatusFilter == 'all') {
            final rejected = await _supabase.client
                .from('permissions')
                .select('*, user:users!permissions_user_id_fkey(*), activity:activities(*)')
                .eq('status', 'rejected')
                .eq('tipo_permiso', 'fecha')
                .lte('start_date', actDateStr)
                .gte('end_date', actDateStr)
                .order('created_at', ascending: true);
            datePermissions.addAll(List<Map<String, dynamic>>.from(rejected as List));
          }

          for (var p in permissions) {
            p['_report_group'] = 'actividad';
          }
          for (var p in datePermissions) {
            p['_report_group'] = 'periodo';
          }

          final existingIds = permissions.map((p) => p['id']).toSet();
          for (var p in datePermissions) {
            if (!existingIds.contains(p['id'])) {
              permissions.add(p);
            }
          }
        }
      }

      // Filtrar por aprobador (aplica en ambos modos)
      if (_reportAprobador != 'todos') {
        permissions = permissions.where((p) {
          return p['aprobador_tipo'] == _reportAprobador;
        }).toList();
      }

      permissions.sort((a, b) {
        final sa = a['start_date'] as String?;
        final sb = b['start_date'] as String?;
        if (sa == null && sb == null) return 0;
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sa.compareTo(sb);
      });

      if (_reportMode == 'actividad') {
        final actData = _reportActividades.firstWhere(
          (a) => a['id'] == _reportSelectedActividadId,
          orElse: () => {},
        );
        final actDate = actData['activity_date'] != null
            ? DateTime.parse(actData['activity_date'])
            : DateTime.now();
        await _pdfService.generatePermissionsReport(
          permissions: permissions,
          startDate: actDate,
          endDate: actDate,
          firefighterName: null,
          statusFilter: _reportStatusFilter,
          activityName: _reportSelectedActividadName,
          groupByType: true,
        );
      } else {
        await _pdfService.generatePermissionsReport(
          permissions: permissions,
          startDate: _reportDateRange!.start,
          endDate: _reportDateRange!.end,
          firefighterName: _reportSelectedUserName,
          statusFilter: _reportStatusFilter,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando reporte: $e'),
            backgroundColor: AppTheme.criticalColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  Widget _buildPermissionCard(Map<String, dynamic> permission,
      {required bool isPending}) {
    final user = permission['user'] as Map<String, dynamic>;
    final status = permission['status'] as String;
    final tipoPermiso = permission['tipo_permiso'] as String? ?? 'fecha';
    final startDateStr = permission['start_date'] as String?;
    final endDateStr = permission['end_date'] as String?;
    final aprobadorTipo = permission['aprobador_tipo'] as String?;

    // Color del borde lateral según aprobador
    Color borderColor;
    if (aprobadorTipo == 'capitan') {
      borderColor = Colors.blue[700]!;
    } else if (aprobadorTipo == 'director') {
      borderColor = Colors.amber[700]!;
    } else {
      borderColor = Colors.grey.shade300;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPermissionDetail(permission),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: borderColor, width: 5.2),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.navyBlue,
                    child: Text(
                      user['full_name'].toString().substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user['rank'] ?? 'Sin rango',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPending) _buildStatusBadge(permission),
                ],
              ),
              const SizedBox(height: 12),
              // Tipo de permiso + período o actividad
              Row(
                children: [
                  Icon(
                    tipoPermiso == 'actividad' ? Icons.event : Icons.date_range,
                    size: 16,
                    color: tipoPermiso == 'actividad' ? Colors.orange[700] : Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      if (tipoPermiso == 'actividad') {
                        final activity = permission['activity'] as Map<String, dynamic>?;
                        if (activity != null) {
                           final actDate = DateTime.parse(activity['activity_date']);
                           return Expanded(
                             child: Text(
                               "\u{1F4C5} ${activity['title']} \u2014 ${DateFormat('dd/MM/yyyy').format(actDate)}",
                               style: const TextStyle(fontSize: 14),
                               overflow: TextOverflow.ellipsis,
                             ),
                           );
                        } else {
                           return const Text(
                             '\u{1F4C5} Actividad no encontrada',
                             style: TextStyle(fontSize: 14),
                           );
                        }
                      } else {
                        return Text(
                          startDateStr != null && endDateStr != null
                              ? '${DateFormat('dd/MM/yyyy').format(DateTime.parse(startDateStr))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(endDateStr))}'
                              : '\u{1F4C6} Permiso por Fechas',
                          style: const TextStyle(fontSize: 14),
                        );
                      }
                    },
                  ),
                ],
              ),
              if (tipoPermiso == 'actividad') ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    'Aprobador: ${aprobadorTipo == 'capitan' ? 'Capitán' : 'Director'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                permission['reason'],
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showPermissionDetail(permission),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver Detalle'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> permission) {
    final status = permission['status'] as String;
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        color = AppTheme.efectivaColor;
        label = 'Aprobado';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppTheme.criticalColor;
        label = 'Rechazado';
        icon = Icons.cancel;
        break;
      default:
        color = AppTheme.warningColor;
        label = 'Pendiente';
        icon = Icons.pending;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (permission['reviewed_by'] != null && status != 'pending') ...[
          const SizedBox(height: 2),
          FutureBuilder<String>(
            future: _getReviewerName(permission['reviewed_by']),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return Text(
                'por ${snapshot.data}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<String> _getReviewerName(String userId) async {
    try {
      final user = await _supabase.getUserProfile(userId);
      return user?.fullName ?? 'Desconocido';
    } catch (e) {
      return 'Desconocido';
    }
  }
}

// Dialog para mostrar detalle y aprobar/rechazar
class _PermissionDetailDialog extends StatefulWidget {
  final Map<String, dynamic> permission;
  final VoidCallback onApprove;
  final Function(String) onReject;

  const _PermissionDetailDialog({
    required this.permission,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_PermissionDetailDialog> createState() =>
      _PermissionDetailDialogState();
}

class _PermissionDetailDialogState extends State<_PermissionDetailDialog> {
  final _rejectionController = TextEditingController();
  final _storageService = StorageService();
  bool _isRejecting = false;
  bool _isLoadingAttachment = false;

  Future<void> _openAttachment(String path) async {
    setState(() => _isLoadingAttachment = true);
    try {
      final url = await _storageService.getAttachmentUrl(path);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se puede abrir el archivo';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error abriendo archivo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAttachment = false);
      }
    }
  }

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  void _handleApprove() {
    Navigator.of(context).pop();
    widget.onApprove();
  }

  void _handleReject() {
    if (_rejectionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar el motivo del rechazo'),
          backgroundColor: AppTheme.criticalColor,
        ),
      );
      return;
    }

    Navigator.of(context).pop();
    widget.onReject(_rejectionController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.permission['user'] as Map<String, dynamic>;
    final tipoPermiso = widget.permission['tipo_permiso'] as String? ?? 'fecha';
    final startDateStr = widget.permission['start_date'] as String?;
    final endDateStr = widget.permission['end_date'] as String?;
    final startDate = startDateStr != null ? DateTime.parse(startDateStr) : null;
    final endDate = endDateStr != null ? DateTime.parse(endDateStr) : null;
    final status = widget.permission['status'] as String;
    final isProcessed = status != 'pending';

    return AlertDialog(
      title: const Text('Detalle de Solicitud'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Usuario
            Text(
              'Bombero',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              user['full_name'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              user['rank'] ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 24),

            // Período o Actividad
            Text(
              tipoPermiso == 'actividad' ? 'Permiso por Actividad' : 'Período Solicitado',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            if (tipoPermiso == 'actividad') ...[
              Row(
                children: [
                  const Icon(Icons.event, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final activity = widget.permission['activity'] as Map<String, dynamic>?;
                        if (activity != null) {
                          final actDate = DateTime.parse(activity['activity_date']);
                          return Text(
                            "${activity['title']} — ${DateFormat('dd/MM/yyyy').format(actDate)}",
                            style: const TextStyle(fontSize: 14),
                          );
                        } else {
                          return const Text(
                            "Actividad no encontrada",
                            style: TextStyle(fontSize: 14),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Aprobador: ${widget.permission['aprobador_tipo'] == 'capitan' ? 'Capitán' : 'Director'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ] else ...[
              Text(
                'Desde: ${startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : '-'}',
                style: const TextStyle(fontSize: 15),
              ),
              Text(
                'Hasta: ${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : '-'}',
                style: const TextStyle(fontSize: 15),
              ),
              if (startDate != null && endDate != null)
                Text(
                  'Duración: ${endDate.difference(startDate).inDays + 1} días',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
            const Divider(height: 24),

            // Motivo
            Text(
              'Motivo',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.permission['reason'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Motivo de rechazo (solo permisos rechazados)
            if (status == 'rejected' &&
                widget.permission['rejection_reason'] != null) ...[
              const Divider(height: 24),
              Text(
                'Motivo del Rechazo',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.criticalColor,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.criticalColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.criticalColor.withOpacity(0.3)),
                ),
                child: Text(
                  widget.permission['rejection_reason'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Archivo Adjunto
            if (widget.permission['attachment_path'] != null) ...[
              const Divider(height: 24),
              Text(
                'Archivo Adjunto',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isLoadingAttachment 
                    ? null 
                    : () => _openAttachment(widget.permission['attachment_path']),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.institutionalRed),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.institutionalRed.withOpacity(0.05),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.permission['attachment_path'].toString().toLowerCase().endsWith('.pdf')
                            ? Icons.picture_as_pdf
                            : Icons.image,
                        color: AppTheme.institutionalRed,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ver archivo adjunto',
                          style: TextStyle(
                            color: AppTheme.institutionalRed,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      if (_isLoadingAttachment)
                        const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.open_in_new, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Campo de rechazo (solo si está rechazando)
            if (_isRejecting) ...[
              const Divider(height: 24),
              Text(
                'Motivo del Rechazo *',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.criticalColor,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rejectionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Explique por qué se rechaza esta solicitud...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.criticalColor.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Este mensaje será enviado al bombero por correo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (isProcessed) ...[
          // Permisos ya procesados: solo botón cerrar
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ] else if (!_isRejecting) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _isRejecting = true),
            icon: const Icon(Icons.cancel, color: AppTheme.criticalColor),
            label: const Text(
              'Rechazar',
              style: TextStyle(color: AppTheme.criticalColor),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _handleApprove,
            icon: const Icon(Icons.check_circle),
            label: const Text('Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.efectivaColor,
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: () => setState(() => _isRejecting = false),
            child: const Text('Volver'),
          ),
          ElevatedButton.icon(
            onPressed: _handleReject,
            icon: const Icon(Icons.send),
            label: const Text('Confirmar Rechazo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalColor,
            ),
          ),
        ],
      ],
    );
  }
}

// Diálogo de configuración del reporte PDF
class _ReportConfigDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const _ReportConfigDialog({this.initialDateRange});

  @override
  State<_ReportConfigDialog> createState() => _ReportConfigDialogState();
}

class _ReportConfigDialogState extends State<_ReportConfigDialog> {
  final _supabase = SupabaseService();
  DateTimeRange? _dateRange;
  String? _selectedUserId;
  String? _selectedUserName;
  String _statusFilter = 'approved'; // 'approved' | 'rejected' | 'all'
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initialDateRange;
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _supabase.getAllUsers();
      setState(() {
        _allUsers = users.map((u) => u.toJson()).toList();
        _filteredUsers = _allUsers;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _allUsers);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['full_name'] as String).toLowerCase();
        return name.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      helpText: 'Seleccionar rango de fechas',
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _generateReport() {
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un rango de fechas'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'dateRange': _dateRange,
      'userId': _selectedUserId,
      'firefighterName': _selectedUserName,
      'statusFilter': _statusFilter,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.picture_as_pdf),
          const SizedBox(width: 8),
          const Text('Reportes'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de tipo
              Text(
                'Tipo de Permisos',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'approved', label: Text('Aprobados')),
                  ButtonSegment(value: 'rejected', label: Text('Rechazados')),
                  ButtonSegment(value: 'all', label: Text('Ambos')),
                ],
                selected: {_statusFilter},
                onSelectionChanged: (val) =>
                    setState(() => _statusFilter = val.first),
              ),
              const SizedBox(height: 20),

              // Selector de fechas
              Text(
                'Rango de Fechas',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _dateRange == null
                      ? 'Seleccionar fechas'
                      : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 20),

              // Selector de bombero
              Text(
                'Bombero',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),

              // Opción "Todos"
              RadioListTile<String?>(
                title: const Text(
                  'Todos los bomberos',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: null,
                groupValue: _selectedUserId,
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = null;
                    _selectedUserName = null;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(),

              // Búsqueda de bombero específico
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar bombero...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterUsers('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                onChanged: _filterUsers,
              ),
              const SizedBox(height: 8),

              // Lista de bomberos
              if (_isLoadingUsers)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredUsers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No se encontraron bomberos',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final userId = user['id'] as String;
                      final userName = user['full_name'] as String;
                      final rank = user['rank'] as String?;

                      return RadioListTile<String>(
                        title: Text(userName),
                        subtitle: rank != null ? Text(rank) : null,
                        value: userId,
                        groupValue: _selectedUserId,
                        onChanged: (value) {
                          setState(() {
                            _selectedUserId = userId;
                            _selectedUserName = userName;
                          });
                        },
                        dense: true,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _generateReport,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Generar Reporte'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.navyBlue,
          ),
        ),
      ],
    );
  }
}
