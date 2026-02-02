import 'package:flutter/material.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/email_service.dart';
import 'package:sexta_app/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';

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

  late TabController _tabController;
  List<Map<String, dynamic>> _pendingPermissions = [];
  List<Map<String, dynamic>> _historicalPermissions = [];
  List<Map<String, dynamic>> _filteredHistoricalPermissions = [];
  bool _isLoading = true;
  
  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all'; // all, approved, rejected
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
        final startDate = DateTime.parse(p['start_date']);
        final endDate = DateTime.parse(p['end_date']);
        
        // También considerar la fecha de revisión si existe
        DateTime? reviewedDate;
        if (p['reviewed_at'] != null) {
          try {
            reviewedDate = DateTime.parse(p['reviewed_at']);
          } catch (e) {
            // Ignorar si no se puede parsear
          }
        }
        
        final rangeStart = _dateRange!.start;
        final rangeEnd = _dateRange!.end.add(const Duration(days: 1)); // Incluir todo el último día
        
        // El permiso coincide si cualquiera de sus fechas está en el rango
        final startInRange = startDate.isAfter(rangeStart.subtract(const Duration(days: 1))) && startDate.isBefore(rangeEnd);
        final endInRange = endDate.isAfter(rangeStart.subtract(const Duration(days: 1))) && endDate.isBefore(rangeEnd);
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
    // Mostrar diálogo de configuración del reporte
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReportConfigDialog(
        initialDateRange: _dateRange,
      ),
    );

    if (result != null && mounted) {
      final dateRange = result['dateRange'] as DateTimeRange;
      final userId = result['userId'] as String?; // null = "Todos"
      final firefighterName = result['firefighterName'] as String?;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Obtener permisos aprobados entre las fechas
        final permissions = await _supabase.getApprovedPermissionsBetweenDates(
          dateRange.start,
          dateRange.end,
          userId: userId, // Filtrar por bombero si se seleccionó uno
        );

        // Cerrar indicador de carga
        if (mounted) Navigator.of(context).pop();

        // Generar PDF
        await _pdfService.generatePermissionsReport(
          permissions: permissions,
          startDate: dateRange.start,
          endDate: dateRange.end,
          firefighterName: firefighterName, // Para el título del PDF
        );
      } catch (e) {
        // Cerrar indicador de carga
        if (mounted) Navigator.of(context).pop();
        
        // Mostrar error
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
      );

      // Obtener datos del permiso y usuario para email
      final permission = _pendingPermissions
          .firstWhere((p) => p['id'] == permissionId);
      final userEmail = permission['user']['email'] as String?;
      final userName = permission['user']['full_name'] as String;
      final startDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(permission['start_date']));
      final endDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(permission['end_date']));
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'Pendientes (${_pendingPermissions.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Historial',
            ),
          ],
        ),
        actions: [
          if (_tabController.index == 1)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Generar Reporte PDF',
              onPressed: _showReportDialog,
            ),
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
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingPermissions.isEmpty) {
      return const Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPermissions.length,
      itemBuilder: (context, index) {
        final permission = _pendingPermissions[index];
        return _buildPermissionCard(permission, isPending: true);
      },
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

    return Column(
      children: [
        // Filtros
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
              const SizedBox(height: 12),
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
          child: _filteredHistoricalPermissions.isEmpty
              ? const Center(child: Text('No se encontraron permisos'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredHistoricalPermissions.length,
                  itemBuilder: (context, index) {
                    final permission = _filteredHistoricalPermissions[index];
                    return _buildPermissionCard(permission, isPending: false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPermissionCard(Map<String, dynamic> permission,
      {required bool isPending}) {
    final user = permission['user'] as Map<String, dynamic>;
    final startDate = DateTime.parse(permission['start_date']);
    final endDate = DateTime.parse(permission['end_date']);
    final status = permission['status'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPermissionDetail(permission),
        child: Padding(
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
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
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
  bool _isRejecting = false;

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
    final startDate = DateTime.parse(widget.permission['start_date']);
    final endDate = DateTime.parse(widget.permission['end_date']);
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

            // Fechas
            Text(
              'Período Solicitado',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Desde: ${DateFormat('dd/MM/yyyy').format(startDate)}',
              style: const TextStyle(fontSize: 15),
            ),
            Text(
              'Hasta: ${DateFormat('dd/MM/yyyy').format(endDate)}',
              style: const TextStyle(fontSize: 15),
            ),
            Text(
              'Duración: ${endDate.difference(startDate).inDays + 1} días',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
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
  String? _selectedUserId; // null = "Todos"
  String? _selectedUserName;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Reporte PDF'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
