import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/treasury_service.dart';
import '../../providers/user_provider.dart';
import '../../core/permissions/role_permissions.dart';

/// Tab de configuración de usuarios para Tesorería
/// Solo accesible por tesorero y admin
class TreasuryUserConfigTab extends ConsumerStatefulWidget {
  const TreasuryUserConfigTab({Key? key}) : super(key: key);

  @override
  ConsumerState<TreasuryUserConfigTab> createState() => _TreasuryUserConfigTabState();
}

class _TreasuryUserConfigTabState extends ConsumerState<TreasuryUserConfigTab> {
  final UserService _userService = UserService();
  final TreasuryService _treasuryService = TreasuryService();
  final _searchController = TextEditingController();
  
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;

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
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando usuarios: $e')),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final lowerQuery = query.toLowerCase();
          return user.fullName.toLowerCase().contains(lowerQuery) ||
                 user.rut.toLowerCase().contains(lowerQuery) ||
                 user.rank.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _showEditDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _TreasuryUserEditDialog(
        user: user,
        onSave: (updatedUser) async {
          await _userService.updateUser(updatedUser);
          _loadUsers();
        },
      ),
    );
  }

  void _showPromoteDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _PromoteToFirefighterDialog(
        user: user,
        onPromote: (promotionDate) async {
          await _promoteUser(user, promotionDate);
        },
      ),
    );
  }

  Future<void> _promoteUser(UserModel user, DateTime promotionDate) async {
    try {
      final result = await _treasuryService.promoteToFirefighter(
        user.id,
        promotionDate,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${user.fullName} promovido a Bombero. '
                '${result['quotas_updated']} cuotas actualizadas a \$${result['standard_quota']}'
              ),
              backgroundColor: AppTheme.efectivaColor,
            ),
          );
          _loadUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${result['error']}'),
              backgroundColor: AppTheme.criticalColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al promover: $e'),
            backgroundColor: AppTheme.criticalColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // Verificar permisos
    if (currentUser == null || 
        !RolePermissions.isAdmin(currentUser.role) && 
        !RolePermissions.canAccessTreasury(currentUser.role)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Acceso Restringido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Solo usuarios con rol Tesorero o Admin pueden acceder a esta sección.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, RUT o cargo...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterUsers,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        ),

        // Tabla de usuarios
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay usuarios registrados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('RUT')),
                            DataColumn(label: Text('Cargo')),
                            DataColumn(label: Text('Estudiante')),
                            DataColumn(label: Text('Inicio Cuotas')),
                            DataColumn(label: Text('Inicio Estudiante')),
                            DataColumn(label: Text('Fin Estudiante')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: _filteredUsers.map((user) {
                            final canPromote = user.rank == 'Aspirante' || user.rank == 'Postulante';
                            
                            return DataRow(cells: [
                              DataCell(Text(user.fullName)),
                              DataCell(Text(user.rut)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRankColor(user.rank).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.rank,
                                    style: TextStyle(
                                      color: _getRankColor(user.rank),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Icon(
                                  user.isStudent ? Icons.check_circle : Icons.cancel,
                                  color: user.isStudent ? AppTheme.efectivaColor : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              DataCell(
                                Text(
                                  user.paymentStartDate != null
                                      ? '${user.paymentStartDate!.month.toString().padLeft(2, '0')}/${user.paymentStartDate!.year}'
                                      : '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  user.studentStartDate != null
                                      ? '${user.studentStartDate!.month.toString().padLeft(2, '0')}/${user.studentStartDate!.year}'
                                      : '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  user.studentEndDate != null
                                      ? '${user.studentEndDate!.month.toString().padLeft(2, '0')}/${user.studentEndDate!.year}'
                                      : '-',
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (canPromote)
                                      IconButton(
                                        icon: const Icon(Icons.military_tech, size: 20),
                                        color: Colors.amber[700],
                                        onPressed: () => _showPromoteDialog(user),
                                        tooltip: 'Pasar a Bombero',
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEditDialog(user),
                                      tooltip: 'Editar Configuración',
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Color _getRankColor(String rank) {
    final rankLower = rank.toLowerCase();
    if (rankLower.contains('director') ||
        rankLower.contains('capitán') ||
        rankLower.contains('teniente')) {
      return AppTheme.navyBlue;
    } else if (rankLower.contains('honorario')) {
      return Colors.amber.shade700;
    } else if (rankLower.contains('postulante') || rankLower.contains('aspirante')) {
      return Colors.grey;
    }
    return AppTheme.efectivaColor;
  }
}

/// Dialog para editar configuración de tesorería de un usuario
class _TreasuryUserEditDialog extends StatefulWidget {
  final UserModel user;
  final Future<void> Function(UserModel) onSave;

  const _TreasuryUserEditDialog({
    required this.user,
    required this.onSave,
  });

  @override
  State<_TreasuryUserEditDialog> createState() => _TreasuryUserEditDialogState();
}

class _TreasuryUserEditDialogState extends State<_TreasuryUserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _isStudent;
  DateTime? _paymentStartDate;
  DateTime? _studentStartDate;
  DateTime? _studentEndDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isStudent = widget.user.isStudent;
    _paymentStartDate = widget.user.paymentStartDate;
    _studentStartDate = widget.user.studentStartDate;
    _studentEndDate = widget.user.studentEndDate;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Crear un mapa con los datos actualizados
      final userMap = widget.user.toJson();
      userMap['is_student'] = _isStudent;
      userMap['payment_start_date'] = _paymentStartDate?.toIso8601String();
      userMap['student_start_date'] = _studentStartDate?.toIso8601String();
      userMap['student_end_date'] = _studentEndDate?.toIso8601String();
      
      final updatedUser = UserModel.fromJson(userMap);

      await widget.onSave(updatedUser);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuración actualizada'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configuración de Tesorería - ${widget.user.fullName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estudiante
              SwitchListTile(
                title: const Text('Es Estudiante'),
                subtitle: const Text('Paga cuota reducida'),
                value: _isStudent,
                onChanged: (value) => setState(() => _isStudent = value),
              ),
              const SizedBox(height: 16),

              // Inicio de Cuotas
              ListTile(
                title: const Text('Inicio de Cuotas'),
                subtitle: Text(
                  _paymentStartDate != null
                      ? '${_paymentStartDate!.day}/${_paymentStartDate!.month}/${_paymentStartDate!.year}'
                      : 'No definido',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _paymentStartDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _paymentStartDate = date);
                  }
                },
              ),

              if (_isStudent) ...[
                const Divider(),
                // Inicio Estudiante
                ListTile(
                  title: const Text('Inicio Período Estudiante'),
                  subtitle: Text(
                    _studentStartDate != null
                        ? '${_studentStartDate!.day}/${_studentStartDate!.month}/${_studentStartDate!.year}'
                        : 'No definido',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _studentStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _studentStartDate = date);
                    }
                  },
                ),

                // Fin Estudiante
                ListTile(
                  title: const Text('Fin Período Estudiante'),
                  subtitle: Text(
                    _studentEndDate != null
                        ? '${_studentEndDate!.day}/${_studentEndDate!.month}/${_studentEndDate!.year}'
                        : 'No definido',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _studentEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _studentEndDate = date);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Dialog para promover a Bombero
class _PromoteToFirefighterDialog extends StatefulWidget {
  final UserModel user;
  final Future<void> Function(DateTime) onPromote;

  const _PromoteToFirefighterDialog({
    required this.user,
    required this.onPromote,
  });

  @override
  State<_PromoteToFirefighterDialog> createState() => _PromoteToFirefighterDialogState();
}

class _PromoteToFirefighterDialogState extends State<_PromoteToFirefighterDialog> {
  DateTime _promotionDate = DateTime.now();
  bool _isProcessing = false;

  Future<void> _promote() async {
    setState(() => _isProcessing = true);

    try {
      await widget.onPromote(_promotionDate);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.military_tech, color: Colors.amber[700]),
          const SizedBox(width: 8),
          const Text('Pasar a Bombero'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Deseas promover a ${widget.user.fullName} al cargo de Bombero?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fecha de Promoción:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(
              '${_promotionDate.day}/${_promotionDate.month}/${_promotionDate.year}',
              style: const TextStyle(fontSize: 18),
            ),
            trailing: const Icon(Icons.calendar_today),
            tileColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _promotionDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _promotionDate = date);
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[800]),
                    const SizedBox(width: 8),
                    const Text(
                      'Cambios que se aplicarán:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Cargo cambiará a "Bombero"\n'
                  '• Estado de estudiante se desactivará\n'
                  '• Cuotas futuras se recalcularán al monto estándar',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _promote,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Promover'),
        ),
      ],
    );
  }
}
