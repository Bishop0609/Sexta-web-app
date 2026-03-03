import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/models/guard_attendance_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/services/guard_attendance_service.dart';
import 'package:sexta_app/services/user_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';

class ManageGuardAttendanceScreen extends StatefulWidget {
  const ManageGuardAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<ManageGuardAttendanceScreen> createState() =>
      _ManageGuardAttendanceScreenState();
}

class _ManageGuardAttendanceScreenState
    extends State<ManageGuardAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _guardService = GuardAttendanceService();
  final _userService = UserService();

  bool _isLoadingFds = false;
  bool _isLoadingDiurna = false;
  bool _isLoadingNocturna = false;
  bool _isLoadingUsers = false;

  List<GuardAttendanceFds> _fdsRecords = [];
  List<GuardAttendanceDiurna> _diurnaRecords = [];
  List<GuardAttendanceNocturna> _nocturnaRecords = [];

  List<UserModel> _allUsers = [];
  Map<String, UserModel> _usersMap = {};

  // Filtros por tab
  DateTime? _fdsStart, _fdsEnd;
  DateTime? _diurnaStart, _diurnaEnd;
  DateTime? _nocturnaStart, _nocturnaEnd;

  // Cache de records nocturna cargados al expandir
  final Map<String, GuardAttendanceNocturna> _nocturnaDetails = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final users = await _userService.getAllUsers();
    setState(() {
      _allUsers = users;
      _usersMap = {for (var u in users) u.id: u};
      _isLoadingUsers = false;
    });
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadFds(), _loadDiurna(), _loadNocturna()]);
  }

  Future<void> _loadFds() async {
    setState(() => _isLoadingFds = true);
    try {
      final r = await _guardService.getFdsAttendanceHistory(limit: 200);
      setState(() => _fdsRecords = r);
    } catch (e) {
      _snack('Error FDS: $e', error: true);
    } finally {
      setState(() => _isLoadingFds = false);
    }
  }

  Future<void> _loadDiurna() async {
    setState(() => _isLoadingDiurna = true);
    try {
      final r = await _guardService.getDiurnaAttendanceHistory(limit: 200);
      setState(() => _diurnaRecords = r);
    } catch (e) {
      _snack('Error Diurna: $e', error: true);
    } finally {
      setState(() => _isLoadingDiurna = false);
    }
  }

  Future<void> _loadNocturna() async {
    setState(() => _isLoadingNocturna = true);
    try {
      final r = await _guardService.getNocturnaAttendanceHistory(limit: 200);
      setState(() => _nocturnaRecords = r);
    } catch (e) {
      _snack('Error Nocturna: $e', error: true);
    } finally {
      setState(() => _isLoadingNocturna = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _userName(String? id) =>
      id == null ? '—' : (_usersMap[id]?.fullName ?? id);

  List<T> _applyFilter<T>(
    List<T> list,
    DateTime? start,
    DateTime? end,
    DateTime Function(T) getDate,
  ) {
    return list.where((r) {
      final d = getDate(r);
      if (start != null && d.isBefore(start)) return false;
      if (end != null && d.isAfter(end.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  List<UserModel> get _selectableUsers {
    return _allUsers.where((u) {
      final r = u.rank.toLowerCase();
      return !r.contains('postulante') && !r.contains('aspirante');
    }).toList();
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Guardias'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.wb_sunny), text: 'FDS'),
            Tab(icon: Icon(Icons.light_mode), text: 'Diurna'),
            Tab(icon: Icon(Icons.nightlight_round), text: 'Nocturna'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Recargar',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFdsTab(),
          _buildDiurnaTab(),
          _buildNocturnaTab(),
        ],
      ),
    );
  }

  // ── filtro ─────────────────────────────────────────────────────────────────

  Widget _buildFilterBar({
    required DateTime? start,
    required DateTime? end,
    required void Function(DateTime?) onStartChanged,
    required void Function(DateTime?) onEndChanged,
  }) {
    final fmt = DateFormat('dd/MM/yy');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 14),
              label: Text(
                start == null ? 'Desde' : fmt.format(start),
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: start ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                onStartChanged(d);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 14),
              label: Text(
                end == null ? 'Hasta' : fmt.format(end),
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: end ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                onEndChanged(d);
              },
            ),
          ),
          if (start != null || end != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Limpiar filtros',
              onPressed: () {
                onStartChanged(null);
                onEndChanged(null);
              },
            ),
        ],
      ),
    );
  }

  // ── tabs ───────────────────────────────────────────────────────────────────

  Widget _buildFdsTab() {
    final filtered = _applyFilter(
        _fdsRecords, _fdsStart, _fdsEnd, (r) => r.guardDate);
    return Stack(
      children: [
        Column(
          children: [
            _buildFilterBar(
              start: _fdsStart,
              end: _fdsEnd,
              onStartChanged: (d) => setState(() => _fdsStart = d),
              onEndChanged: (d) => setState(() => _fdsEnd = d),
            ),
            Expanded(child: _buildFdsList(filtered)),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_fds',
            onPressed: _createFdsGuardia,
            icon: const Icon(Icons.add),
            label: const Text('Nueva FDS'),
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildDiurnaTab() {
    final filtered = _applyFilter(
        _diurnaRecords, _diurnaStart, _diurnaEnd, (r) => r.guardDate);
    return Stack(
      children: [
        Column(
          children: [
            _buildFilterBar(
              start: _diurnaStart,
              end: _diurnaEnd,
              onStartChanged: (d) => setState(() => _diurnaStart = d),
              onEndChanged: (d) => setState(() => _diurnaEnd = d),
            ),
            Expanded(child: _buildDiurnaList(filtered)),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_diurna',
            onPressed: _createDiurnaGuardia,
            icon: const Icon(Icons.add),
            label: const Text('Nueva Diurna'),
            backgroundColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildNocturnaTab() {
    final filtered = _applyFilter(
        _nocturnaRecords, _nocturnaStart, _nocturnaEnd, (r) => r.guardDate);
    return Stack(
      children: [
        Column(
          children: [
            _buildFilterBar(
              start: _nocturnaStart,
              end: _nocturnaEnd,
              onStartChanged: (d) => setState(() => _nocturnaStart = d),
              onEndChanged: (d) => setState(() => _nocturnaEnd = d),
            ),
            Expanded(child: _buildNocturnaList(filtered)),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_nocturna',
            onPressed: _createNocturnaGuardia,
            icon: const Icon(Icons.add),
            label: const Text('Nueva Nocturna'),
            backgroundColor: Colors.indigo,
          ),
        ),
      ],
    );
  }

  // ── listas ─────────────────────────────────────────────────────────────────

  Widget _buildFdsList(List<GuardAttendanceFds> records) {
    if (_isLoadingFds) return const Center(child: CircularProgressIndicator());
    if (records.isEmpty) return _empty('No hay registros FDS');
    return RefreshIndicator(
      onRefresh: _loadFds,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        itemCount: records.length,
        itemBuilder: (_, i) => _fdsCard(records[i]),
      ),
    );
  }

  Widget _buildDiurnaList(List<GuardAttendanceDiurna> records) {
    if (_isLoadingDiurna) {
      return const Center(child: CircularProgressIndicator());
    }
    if (records.isEmpty) return _empty('No hay registros Diurna');
    return RefreshIndicator(
      onRefresh: _loadDiurna,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        itemCount: records.length,
        itemBuilder: (_, i) => _diurnaCard(records[i]),
      ),
    );
  }

  Widget _buildNocturnaList(List<GuardAttendanceNocturna> records) {
    if (_isLoadingNocturna) {
      return const Center(child: CircularProgressIndicator());
    }
    if (records.isEmpty) return _empty('No hay registros Nocturna');
    return RefreshIndicator(
      onRefresh: _loadNocturna,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        itemCount: records.length,
        itemBuilder: (_, i) => _nocturnaCard(records[i]),
      ),
    );
  }

  Widget _empty(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

  // ── cards ──────────────────────────────────────────────────────────────────

  Widget _fdsCard(GuardAttendanceFds r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(r.shiftPeriod,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Text(DateFormat('EEEE dd/MM/yyyy', 'es_ES').format(r.guardDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${r.assignedCount} personas • '
            '${DateFormat('dd/MM HH:mm').format(r.createdAt)}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _positionRow('Maquinista 1', r.maquinista1Id),
                _positionRow('Maquinista 2', r.maquinista2Id),
                _positionRow('OBAC', r.obacId),
                ...List.generate(10, (i) {
                  final id =
                      i < r.bomberoIds.length ? r.bomberoIds[i] : null;
                  if (id == null) return const SizedBox.shrink();
                  return _positionRow('Bombero ${i + 1}', id);
                }),
                if (r.observations != null) ...[
                  const Divider(),
                  Text('Obs: ${r.observations}',
                      style: const TextStyle(
                          fontSize: 12, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 8),
                _actionRow(
                  onEdit: () => _editFds(r),
                  onDelete: () => _deleteFds(r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diurnaCard(GuardAttendanceDiurna r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text(r.shiftPeriod,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Text(DateFormat('EEEE dd/MM/yyyy', 'es_ES').format(r.guardDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${r.assignedCount} personas • '
            '${DateFormat('dd/MM HH:mm').format(r.createdAt)}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _positionRow('Maquinista 1', r.maquinista1Id),
                _positionRow('Maquinista 2', r.maquinista2Id),
                _positionRow('OBAC', r.obacId),
                ...List.generate(10, (i) {
                  final id =
                      i < r.bomberoIds.length ? r.bomberoIds[i] : null;
                  if (id == null) return const SizedBox.shrink();
                  return _positionRow('Bombero ${i + 1}', id);
                }),
                if (r.observations != null) ...[
                  const Divider(),
                  Text('Obs: ${r.observations}',
                      style: const TextStyle(
                          fontSize: 12, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 8),
                _actionRow(
                  onEdit: () => _editDiurna(r),
                  onDelete: () => _deleteDiurna(r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nocturnaCard(GuardAttendanceNocturna r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.nightlight_round, color: Colors.white, size: 18),
        ),
        title: Text(DateFormat('EEEE dd/MM/yyyy', 'es_ES').format(r.guardDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${r.assignedCount} personas • '
            '${DateFormat('dd/MM HH:mm').format(r.createdAt)}'),
        onExpansionChanged: (open) async {
          if (open && !_nocturnaDetails.containsKey(r.id)) {
            try {
              final detail =
                  await _guardService.getNocturnaAttendance(r.guardDate);
              if (detail != null) {
                setState(() => _nocturnaDetails[r.id] = detail);
              }
            } catch (_) {}
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _nocturnaPersonalWidget(r),
                if (r.observations != null) ...[
                  const Divider(),
                  Text('Obs: ${r.observations}',
                      style: const TextStyle(
                          fontSize: 12, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 8),
                _actionRow(
                  onEdit: () => _editNocturna(r),
                  onDelete: () => _deleteNocturna(r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nocturnaPersonalWidget(GuardAttendanceNocturna r) {
    final detail = _nocturnaDetails[r.id];
    final records = detail?.records ?? [];

    String statusIcon(String userId, String defaultPos) {
      if (records.isEmpty) return '';
      final rec = records.where((x) => x.userId == userId).firstOrNull;
      if (rec == null) return '';
      switch (rec.status) {
        case 'presente':
          return ' ✅';
        case 'ausente':
          return ' ❌';
        case 'permiso':
          return ' 🔵';
        case 'reemplazado':
          final repId = rec.replacedById;
          return ' 🔄 ${_userName(repId)}';
        default:
          return '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.maquinistaId != null)
          _positionRowExtra(
              'Maquinista', r.maquinistaId, statusIcon(r.maquinistaId!, 'maquinista')),
        if (r.obacId != null)
          _positionRowExtra('OBAC', r.obacId, statusIcon(r.obacId!, 'obac')),
        ...List.generate(8, (i) {
          final id = i < r.bomberoIds.length ? r.bomberoIds[i] : null;
          if (id == null) return const SizedBox.shrink();
          return _positionRowExtra(
              'Bombero ${i + 1}', id, statusIcon(id, 'bombero'));
        }),
      ],
    );
  }

  Widget _positionRow(String label, String? id) {
    if (id == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(_userName(id), style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _positionRowExtra(String label, String? id, String extra) {
    if (id == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text('${_userName(id)}$extra',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(
      {required VoidCallback onEdit, required VoidCallback onDelete}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
          label: const Text('Editar', style: TextStyle(color: Colors.blue)),
        ),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
          label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  // ── selección de usuario ───────────────────────────────────────────────────

  Future<String?> _pickUser(String title, {String? currentId}) async {
    String query = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = _selectableUsers
              .where((u) =>
                  u.fullName.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        hintText: 'Buscar...', prefixIcon: Icon(Icons.search)),
                    onChanged: (v) => setS(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return ListTile(
                            leading: const Icon(Icons.clear, color: Colors.red),
                            title: const Text('Dejar vacío',
                                style: TextStyle(color: Colors.red)),
                            onTap: () => Navigator.pop(ctx, ''),
                          );
                        }
                        final u = filtered[i - 1];
                        return ListTile(
                          title: Text(u.fullName,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(u.rank,
                              style: const TextStyle(fontSize: 11)),
                          selected: u.id == currentId,
                          onTap: () => Navigator.pop(ctx, u.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
            ],
          );
        },
      ),
    );
  }

  // ── CREAR GUARDIAS ─────────────────────────────────────────────────────────

  Future<void> _createFdsGuardia() async {
    DateTime? fecha;
    String periodo = 'M';
    String? maq1, maq2, obac;
    List<String?> bomberos = List.filled(10, null);
    final obsCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nueva Guardia FDS'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(fecha == null
                      ? 'Seleccionar fecha'
                      : DateFormat('dd/MM/yyyy').format(fecha!)),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    setS(() => fecha = d);
                  },
                ),
                // Período FDS: M, T, C
                const Text('Período:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  children: ['M', 'T', 'C'].map((p) {
                    return ChoiceChip(
                      label: Text(p == 'M'
                          ? 'Mañana'
                          : p == 'T'
                              ? 'Tarde'
                              : 'Completo'),
                      selected: periodo == p,
                      onSelected: (_) => setS(() => periodo = p),
                    );
                  }).toList(),
                ),
                const Divider(),
                // Personal
                _personalPickerTile('Maquinista 1', maq1, ctx, (id) => setS(() => maq1 = id == '' ? null : id)),
                _personalPickerTile('Maquinista 2', maq2, ctx, (id) => setS(() => maq2 = id == '' ? null : id)),
                _personalPickerTile('OBAC', obac, ctx, (id) => setS(() => obac = id == '' ? null : id)),
                ...List.generate(10, (i) => _personalPickerTile(
                  'Bombero ${i + 1}',
                  bomberos[i],
                  ctx,
                  (id) => setS(() => bomberos[i] = id == '' ? null : id),
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Observaciones', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: fecha == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || fecha == null) return;
    try {
      await _guardService.createFdsAttendance(
        guardDate: fecha!,
        shiftPeriod: periodo,
        maquinista1Id: maq1,
        maquinista2Id: maq2,
        obacId: obac,
        bomberoIds: bomberos,
        observations: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
      );
      _snack('✅ Guardia FDS creada');
      _loadFds();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
    obsCtrl.dispose();
  }

  Future<void> _createDiurnaGuardia() async {
    DateTime? fecha;
    String periodo = 'M';
    String? maq1, maq2, obac;
    List<String?> bomberos = List.filled(10, null);
    final obsCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nueva Guardia Diurna'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(fecha == null
                      ? 'Seleccionar fecha'
                      : DateFormat('dd/MM/yyyy').format(fecha!)),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    setS(() => fecha = d);
                  },
                ),
                const Text('Período:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  children: ['M', 'T'].map((p) {
                    return ChoiceChip(
                      label: Text(p == 'M' ? 'Mañana' : 'Tarde'),
                      selected: periodo == p,
                      onSelected: (_) => setS(() => periodo = p),
                    );
                  }).toList(),
                ),
                const Divider(),
                _personalPickerTile('Maquinista 1', maq1, ctx, (id) => setS(() => maq1 = id == '' ? null : id)),
                _personalPickerTile('Maquinista 2', maq2, ctx, (id) => setS(() => maq2 = id == '' ? null : id)),
                _personalPickerTile('OBAC', obac, ctx, (id) => setS(() => obac = id == '' ? null : id)),
                ...List.generate(10, (i) => _personalPickerTile(
                  'Bombero ${i + 1}',
                  bomberos[i],
                  ctx,
                  (id) => setS(() => bomberos[i] = id == '' ? null : id),
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Observaciones', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: fecha == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || fecha == null) return;
    try {
      await _guardService.createDiurnaAttendance(
        guardDate: fecha!,
        shiftPeriod: periodo,
        maquinista1Id: maq1,
        maquinista2Id: maq2,
        obacId: obac,
        bomberoIds: bomberos,
        observations: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
      );
      _snack('✅ Guardia Diurna creada');
      _loadDiurna();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
    obsCtrl.dispose();
  }

  Future<void> _createNocturnaGuardia() async {
    DateTime? fecha;
    String? maq, obac;
    List<String?> bomberos = List.filled(8, null);
    final obsCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nueva Guardia Nocturna'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(fecha == null
                      ? 'Seleccionar fecha'
                      : DateFormat('dd/MM/yyyy').format(fecha!)),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    setS(() => fecha = d);
                  },
                ),
                const Divider(),
                _personalPickerTile('Maquinista', maq, ctx, (id) => setS(() => maq = id == '' ? null : id)),
                _personalPickerTile('OBAC', obac, ctx, (id) => setS(() => obac = id == '' ? null : id)),
                ...List.generate(8, (i) => _personalPickerTile(
                  'Bombero ${i + 1}',
                  bomberos[i],
                  ctx,
                  (id) => setS(() => bomberos[i] = id == '' ? null : id),
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Observaciones', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: fecha == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || fecha == null) return;
    try {
      await _guardService.createNocturnaAttendance(
        guardDate: fecha!,
        maquinistaId: maq,
        obacId: obac,
        bomberoIds: bomberos,
        observations: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
      );
      _snack('✅ Guardia Nocturna creada');
      _loadNocturna();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
    obsCtrl.dispose();
  }

  Widget _personalPickerTile(
      String label, String? currentId, BuildContext ctx, Function(String) onPick) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      subtitle: Text(
        currentId == null ? '(vacío)' : _userName(currentId),
        style: TextStyle(
            fontSize: 12,
            color: currentId == null ? Colors.grey : Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () async {
        final result = await _pickUser(label, currentId: currentId);
        if (result != null) onPick(result);
      },
    );
  }

  // ── EDITAR COMPLETO ────────────────────────────────────────────────────────

  Future<void> _editFds(GuardAttendanceFds r) async {
    String? maq1 = r.maquinista1Id;
    String? maq2 = r.maquinista2Id;
    String? obac = r.obacId;
    List<String?> bomberos = List<String?>.from(r.bomberoIds);
    while (bomberos.length < 10) bomberos.add(null);
    final obsCtrl = TextEditingController(text: r.observations);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Editar FDS — ${DateFormat('dd/MM/yyyy').format(r.guardDate)} ${r.shiftPeriod}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _personalPickerTile('Maquinista 1', maq1, ctx, (id) => setS(() => maq1 = id == '' ? null : id)),
                _personalPickerTile('Maquinista 2', maq2, ctx, (id) => setS(() => maq2 = id == '' ? null : id)),
                _personalPickerTile('OBAC', obac, ctx, (id) => setS(() => obac = id == '' ? null : id)),
                ...List.generate(10, (i) => _personalPickerTile(
                  'Bombero ${i + 1}',
                  bomberos[i],
                  ctx,
                  (id) => setS(() => bomberos[i] = id == '' ? null : id),
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Observaciones', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    try {
      await _guardService.updateFdsAttendance(r.id, {
        'maquinista_1_id': maq1,
        'maquinista_2_id': maq2,
        'obac_id': obac,
        for (int i = 0; i < 10; i++) 'bombero_${i + 1}_id': bomberos[i],
        'observations': obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
      });
      _snack('✅ Registro actualizado');
      _loadFds();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
    obsCtrl.dispose();
  }

  Future<void> _editDiurna(GuardAttendanceDiurna r) async {
    String? maq1 = r.maquinista1Id;
    String? maq2 = r.maquinista2Id;
    String? obac = r.obacId;
    List<String?> bomberos = List<String?>.from(r.bomberoIds);
    while (bomberos.length < 10) bomberos.add(null);
    final obsCtrl = TextEditingController(text: r.observations);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Editar Diurna — ${DateFormat('dd/MM/yyyy').format(r.guardDate)} ${r.shiftPeriod}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _personalPickerTile('Maquinista 1', maq1, ctx, (id) => setS(() => maq1 = id == '' ? null : id)),
                _personalPickerTile('Maquinista 2', maq2, ctx, (id) => setS(() => maq2 = id == '' ? null : id)),
                _personalPickerTile('OBAC', obac, ctx, (id) => setS(() => obac = id == '' ? null : id)),
                ...List.generate(10, (i) => _personalPickerTile(
                  'Bombero ${i + 1}',
                  bomberos[i],
                  ctx,
                  (id) => setS(() => bomberos[i] = id == '' ? null : id),
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Observaciones', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    try {
      await _guardService.updateDiurnaAttendance(r.id, {
        'maquinista_1_id': maq1,
        'maquinista_2_id': maq2,
        'obac_id': obac,
        for (int i = 0; i < 10; i++) 'bombero_${i + 1}_id': bomberos[i],
        'observations': obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
      });
      _snack('✅ Registro actualizado');
      _loadDiurna();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
    obsCtrl.dispose();
  }

  Future<void> _editNocturna(GuardAttendanceNocturna r) async {
    String? maq = r.maquinistaId;
    String? obac = r.obacId;
    List<String?> bomberos = List<String?>.from(r.bomberoIds);
    while (bomberos.length < 8) bomberos.add(null);
    final obsCtrl = TextEditingController(text: r.observations);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Editar Nocturna — ${DateFormat('dd/MM/yyyy').format(r.guardDate)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _personalPickerTile('Maquinista', maq, ctx, (id) => setS(() => maq = id == '' ? null : id)),
                _personalPickerTile('OBAC', obac, ctx, (id) => setS(() => obac = id == '' ? null : id)),
                ...List.generate(8, (i) => _personalPickerTile(
                  'Bombero ${i + 1}',
                  bomberos[i],
                  ctx,
                  (id) => setS(() => bomberos[i] = id == '' ? null : id),
                )),
                const SizedBox(height: 8),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Observaciones', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    try {
      await _guardService.updateNocturnaAttendance(r.id, {
        'maquinista_id': maq,
        'obac_id': obac,
        for (int i = 0; i < 8; i++) 'bombero_${i + 1}_id': bomberos[i],
        'observations': obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
      });
      _snack('✅ Registro actualizado');
      _nocturnaDetails.remove(r.id);
      _loadNocturna();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
    obsCtrl.dispose();
  }

  // ── ELIMINAR CON DOBLE CONFIRMACIÓN ───────────────────────────────────────

  Future<bool> _confirmDelete(
      String fecha, String tipo, int cantidad) async {
    final confirmed1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          'Vas a eliminar:\n\n'
          '📅 Fecha: $fecha\n'
          '🏷️ Tipo: $tipo\n'
          '👥 Personal: $cantidad personas\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmed1 != true) return false;

    // Segunda confirmación: escribir ELIMINAR
    final ctrl = TextEditingController();
    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('⚠️ Confirmación final'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escribe ELIMINAR para confirmar:'),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (_) => setS(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: ctrl.text == 'ELIMINAR'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar definitivamente'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return confirmed2 == true;
  }

  Future<void> _deleteFds(GuardAttendanceFds r) async {
    final ok = await _confirmDelete(
        DateFormat('dd/MM/yyyy').format(r.guardDate),
        'FDS — ${r.shiftPeriod}',
        r.assignedCount);
    if (!ok) return;
    try {
      await _guardService.deleteFdsAttendance(r.id);
      _snack('✅ Registro eliminado');
      _loadFds();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Future<void> _deleteDiurna(GuardAttendanceDiurna r) async {
    final ok = await _confirmDelete(
        DateFormat('dd/MM/yyyy').format(r.guardDate),
        'Diurna — ${r.shiftPeriod}',
        r.assignedCount);
    if (!ok) return;
    try {
      await _guardService.deleteDiurnaAttendance(r.id);
      _snack('✅ Registro eliminado');
      _loadDiurna();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Future<void> _deleteNocturna(GuardAttendanceNocturna r) async {
    final ok = await _confirmDelete(
        DateFormat('dd/MM/yyyy').format(r.guardDate),
        'Nocturna',
        r.assignedCount);
    if (!ok) return;
    try {
      await _guardService.deleteNocturnaAttendance(r.id);
      _snack('✅ Registro eliminado');
      _nocturnaDetails.remove(r.id);
      _loadNocturna();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }
}
