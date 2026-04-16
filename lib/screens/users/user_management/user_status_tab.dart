import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/services/user_status_service.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:intl/intl.dart';

class UserStatusTab extends StatefulWidget {
  const UserStatusTab({super.key});

  @override
  State<UserStatusTab> createState() => _UserStatusTabState();
}

class _UserStatusTabState extends State<UserStatusTab> {
  final _service = UserStatusService();
  final _searchController = TextEditingController();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _filterStatus; // null = Todos

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
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .order('full_name');

      final users = (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();

      setState(() {
        _users = users;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando usuarios: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((u) {
        final matchSearch = query.isEmpty ||
            u.fullName.toLowerCase().contains(query) ||
            u.rut.toLowerCase().contains(query);
        final matchStatus = _filterStatus == null ||
            u.status.name == _filterStatus;
        return matchSearch && matchStatus;
      }).toList();
    });
  }

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

  void _showChangeStatusDialog(UserModel user) {
    String? selectedStatus;
    DateTime effectiveDate = DateTime.now();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final options = _statusOptions.where((s) => s != user.status.name).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Cambiar Estado — ${user.firstName}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado actual
                  Row(
                    children: [
                      const Text('Estado actual: '),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          user.getStatusDisplayName(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: _getStatusColor(user.status),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nuevo estado
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Nuevo estado *',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedStatus,
                    items: options.map((s) {
                      final model = UserModel.parseStatus(s);
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 5,
                              backgroundColor: _getStatusColor(model),
                            ),
                            const SizedBox(width: 8),
                            Text(model == UserStatus.activo
                                ? 'Activo'
                                : s[0].toUpperCase() + s.substring(1)),
                          ],
                        ),
                      );
                    }).toList(),
                    validator: (v) => v == null ? 'Selecciona un estado' : null,
                    onChanged: (v) => setDialogState(() => selectedStatus = v),
                  ),
                  const SizedBox(height: 16),

                  // Fecha efectiva
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: effectiveDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => effectiveDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha efectiva *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(effectiveDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Motivo
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'El motivo es obligatorio' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                Navigator.of(ctx).pop();

                final changedBy = AuthService().currentUser?.id ?? '';

                try {
                  if (selectedStatus == 'activo') {
                    await _service.reactivateUser(
                      userId: user.id,
                      effectiveDate: effectiveDate,
                      reason: reasonController.text.trim(),
                      changedBy: changedBy,
                    );
                  } else {
                    await _service.changeUserStatus(
                      userId: user.id,
                      newStatus: selectedStatus!,
                      effectiveDate: effectiveDate,
                      reason: reasonController.text.trim(),
                      changedBy: changedBy,
                    );
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Estado actualizado correctamente'),
                        backgroundColor: AppTheme.efectivaColor,
                      ),
                    );
                    await _loadUsers();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.criticalColor,
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de filtros
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o RUT...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String?>(
                value: _filterStatus,
                hint: const Text('Todos'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ..._statusOptions.map((s) => DropdownMenuItem<String?>(
                        value: s,
                        child: Text(
                          UserModel.parseStatus(s) == UserStatus.activo
                              ? 'Activo'
                              : s[0].toUpperCase() + s.substring(1),
                        ),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _filterStatus = v);
                  _applyFilters();
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
                tooltip: 'Actualizar',
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay resultados',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final statusColor = _getStatusColor(user.status);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.institutionalRed,
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${user.rut} · ${user.rank}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    user.getStatusDisplayName(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  backgroundColor: statusColor,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz),
                                  tooltip: 'Cambiar estado',
                                  onPressed: () => _showChangeStatusDialog(user),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
