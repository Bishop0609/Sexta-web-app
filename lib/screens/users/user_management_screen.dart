import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/email_service.dart';
import 'dart:math';

/// Módulo 9: Gestión de Usuarios
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _supabase = SupabaseService();
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
      final users = await _supabase.getAllUsers();
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

  void _showCreateUserDialog() {
    final authService = AuthService();
    final emailService = EmailService();
    
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        onSave: (user) async {
          // Use fixed default password "Bombero2024!"
          const tempPassword = 'Bombero2024!';
          
          // Create user in database
          await _supabase.createUser(user);
          
          // Get the created user to obtain the generated ID
          final createdUser = await _supabase.getUserByRut(user.rut);
          
          if (createdUser != null) {
            // Create auth credentials with hashed password
            final passwordHash = authService.hashPassword(tempPassword);
            await _supabase.createAuthCredentials(createdUser.id, passwordHash);
            
            // Send welcome email (email is now required)
            await emailService.sendWelcomeEmail(
              userEmail: user.email!,
              fullName: user.fullName,
              rut: user.rut,
              tempPassword: tempPassword,
            );
            
            // Show temp password to admin (backup delivery)
            if (mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Usuario Creado'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Usuario creado exitosamente.'),
                      const SizedBox(height: 16),
                      const Text('Contraseña temporal:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          tempPassword,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '✉️ Email enviado a: ${user.email}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                   ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
              
              // Refresh user list after showing password dialog
              await _loadUsers();
            }
          }
        },
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        user: user,
        onSave: (updatedUser) async {
          await _supabase.updateUser(updatedUser);
          _loadUsers();
        },
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Está seguro que desea eliminar a ${user.fullName}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabase.deleteUser(user.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario eliminado exitosamente'),
                      backgroundColor: AppTheme.efectivaColor,
                    ),
                  );
                  _loadUsers();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Resetear Contraseña'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Está seguro que desea resetear la contraseña de:',
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 8),
            Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                      const SizedBox(width: 8),
                      const Text(
                        'Se generará una contraseña temporal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• La contraseña se mostrará solo una vez\n'
                    '• Deberás comunicársela al usuario\n'
                    '• El usuario deberá cambiarla en su primer login',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performPasswordReset(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
            child: const Text('RESETEAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _performPasswordReset(UserModel user) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authService = AuthService();
      final result = await authService.resetUserPassword(user.id);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result.success && result.temporaryPassword != null) {
          _showTemporaryPasswordDialog(user, result.temporaryPassword!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${result.error}'),
              backgroundColor: AppTheme.criticalColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error inesperado: $e'),
            backgroundColor: AppTheme.criticalColor,
          ),
        );
      }
    }
  }

  void _showTemporaryPasswordDialog(UserModel user, String tempPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Contraseña Reseteada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contraseña temporal generada para:'),
            const SizedBox(height: 8),
            Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'CONTRASEÑA TEMPORAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SelectableText(
                          tempPassword,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: tempPassword));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Contraseña copiada al portapapeles'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Copiar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, size: 20, color: Colors.red[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta contraseña solo se mostrará una vez. Comunícasela al usuario por el medio que prefieras (teléfono, email, WhatsApp, etc.)',
                      style: TextStyle(fontSize: 12, color: Colors.red[900]),
                    ),
                  ),
                ],
              ),
            ),
            if (user.email != null && user.email!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, size: 16, color: Colors.blue[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email del usuario: ${user.email}',
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Gestión de Usuarios',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Barra de búsqueda y botón crear
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
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Crear Usuario'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
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
                              DataColumn(label: Text('RUT')),
                              DataColumn(label: Text('Nombre')),
                              DataColumn(label: Text('Cargo')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Género')),
                              DataColumn(label: Text('Estado Civil')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: _filteredUsers.map((user) {
                              return DataRow(cells: [
                                DataCell(Text(user.rut)),
                                DataCell(Text(user.fullName)),
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
                                DataCell(Text(user.email ?? '-')),
                                DataCell(Text(user.gender == Gender.male ? 'Masculino' : 'Femenino')),
                                DataCell(Text(user.maritalStatus == MaritalStatus.single ? 'Soltero' : 'Casado')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _showEditUserDialog(user),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.lock_reset, size: 20),
                                        color: Colors.orange[700],
                                        onPressed: () => _showResetPasswordDialog(user),
                                        tooltip: 'Resetear Contraseña',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: AppTheme.criticalColor,
                                        ),
                                        onPressed: () => _showDeleteConfirmation(user),
                                        tooltip: 'Eliminar',
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
      ),
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
    } else if (rankLower.contains('postulante')) {
      return Colors.grey;
    }
    return AppTheme.efectivaColor;
  }
}

/// Dialog para crear/editar usuario
class _UserFormDialog extends StatefulWidget {
  final UserModel? user;
  final Future<void> Function(UserModel) onSave;

  const _UserFormDialog({
    this.user,
    required this.onSave,
  });

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _victorNumberController = TextEditingController(); // Nuevo
  final _registroCompaniaController = TextEditingController(); // Nuevo
  
  String _selectedRank = 'Bombero(a)'; // Cambiado a cargo que existe en nueva lista
  Gender _selectedGender = Gender.male;
  MaritalStatus _selectedMaritalStatus = MaritalStatus.single;
  UserRole _selectedRole = UserRole.firefighter; // Nuevo: rol del usuario
  bool _isSaving = false;

  // Cargos predefinidos por categoría
  final Map<String, List<String>> _cargoCategories = {
    'Oficiales de Compañía': [
      'Director',
      'Secretario',
      'Tesorero',
      'Capitán',
      'Teniente 1°',
      'Teniente 2°',
      'Teniente 3°',
      'Ayudante 1°',
      'Ayudante 2°',
      'Inspector M. Mayor',
      'Inspector M. Menor',
    ],
    'Oficiales de Cuerpo': [
      'Of. General',
      'Inspector de Comandancia',
      'Ayudante de Comandancia',
    ],
    'Miembros Honorarios': [
      'Miembro Honorario',
    ],
    'Voluntarios Activos': [
      'Bombero',
    ],
    'Aspirantes y Postulantes': [
      'Aspirante',
      'Postulante',
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _rutController.text = widget.user!.rut;
      _nameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email ?? '';
      _victorNumberController.text = widget.user!.victorNumber;
      _registroCompaniaController.text = widget.user!.registroCompania ?? '';
      _selectedGender = widget.user!.gender;
      _selectedMaritalStatus = widget.user!.maritalStatus;
      _selectedRank = widget.user!.rank;
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _rutController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _victorNumberController.dispose();
    _registroCompaniaController.dispose();
    super.dispose();
  }

  String? _validateRUT(String? value) {
    if (value == null || value.isEmpty) {
      return 'RUT es obligatorio';
    }
    
    // Si estamos editando, permitir el RUT tal como está
    if (widget.user != null) {
      return null;
    }
    
    // Solo validar para nuevos usuarios
    // Formato básico RUT chileno: 12345678-9
    final rutRegex = RegExp(r'^\d{7,8}-[\dkK]$');
    if (!rutRegex.hasMatch(value)) {
      return 'Formato inválido. Use: 12345678-9';
    }
    
    // Validar dígito verificador
    final parts = value.split('-');
    final rut = parts[0];
    final dv = parts[1].toUpperCase();
    
    if (_calculateDV(rut) != dv) {
      return 'Dígito verificador inválido';
    }
    
    return null;
  }

  String _calculateDV(String rut) {
    int sum = 0;
    int multiplier = 2;
    
    for (int i = rut.length - 1; i >= 0; i--) {
      sum += int.parse(rut[i]) * multiplier;
      multiplier = multiplier == 7 ? 2 : multiplier + 1;
    }
    
    final remainder = sum % 11;
    final dv = 11 - remainder;
    
    if (dv == 11) return '0';
    if (dv == 10) return 'K';
    return dv.toString();
  }

  /// Genera un número Victor aleatorio (formato: V-XXXX)
  String _generateVictorNumber() {
    final random = Random();
    final number = random.nextInt(9999) + 1;
    return 'V-${number.toString().padLeft(4, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Usar toJson para convertir correctamente los enums
      final userMap = {
        'rut': _rutController.text.trim(),
        'victor_number': _victorNumberController.text.trim(),
        'registro_compania': _registroCompaniaController.text.trim().isEmpty 
            ? null 
            : _registroCompaniaController.text.trim(),
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(), // Email is now required
        'rank': _selectedRank,
        'role': _selectedRole.name, // Usar el rol seleccionado
        'gender': _selectedGender == Gender.male ? 'M' : 'F',
        'marital_status': _selectedMaritalStatus == MaritalStatus.single ? 'single' : 'married',
      };

      // Agregar id solo si estamos editando, sino usar string vacío temporal
      if (widget.user != null) {
        userMap['id'] = widget.user!.id;
      } else {
        userMap['id'] = ''; // Temporal, se eliminará antes de insert
      }

      final user = UserModel.fromJson(userMap);
      
      // Close this dialog first (Fix #1: Modal stuck issue)
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Then call onSave which will show the password dialog
      await widget.onSave(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.user == null
                  ? 'Usuario creado exitosamente'
                  : 'Usuario actualizado exitosamente',
            ),
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
      title: Text(widget.user == null ? 'Crear Usuario' : 'Editar Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Helper para mostrar texto de enums
                // RUT
                TextFormField(
                  controller: _rutController,
                  decoration: const InputDecoration(
                    labelText: 'RUT *',
                    hintText: '12345678-9',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateRUT,
                  enabled: widget.user == null, // No editable si ya existe
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9kK-]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text.replaceAll('-', '');
                      if (text.length <= 1) {
                        return newValue;
                      }
                      
                      // Format as XXXXXXXX-X
                      final formatted = '${text.substring(0, text.length - 1)}-${text[text.length - 1]}';
                      
                      return TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'usuario@example.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email es obligatorio';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cargo
                DropdownButtonFormField<String>(
                  value: _selectedRank,
                  decoration: const InputDecoration(
                    labelText: 'Cargo *',
                    border: OutlineInputBorder(),
                  ),
                  items: _cargoCategories.entries.expand<DropdownMenuItem<String>>((category) {
                    return [
                      // Header de categoría
                      DropdownMenuItem<String>(
                        enabled: false,
                        value: null,
                        child: Text(
                          category.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      // Cargos de la categoría
                      ...category.value.map<DropdownMenuItem<String>>((rank) => DropdownMenuItem<String>(
                            value: rank,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(rank),
                            ),
                          )),
                    ];
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRank = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Rol del Usuario
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol en el Sistema *',
                    border: OutlineInputBorder(),
                    helperText: 'Define qué módulos puede acceder',
                  ),
                  items: const [
                    DropdownMenuItem<UserRole>(
                      value: UserRole.admin,
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Administrador (acceso completo)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<UserRole>(
                      value: UserRole.officer,
                      child: Row(
                        children: [
                          Icon(Icons.shield, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Oficial (gestión de permisos y asistencia)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<UserRole>(
                      value: UserRole.firefighter,
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Bombero (solo solicitudes)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Género
                DropdownButtonFormField<Gender>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Género *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: Gender.male, child: Text('Masculino')),
                    DropdownMenuItem(value: Gender.female, child: Text('Femenino')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGender = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Estado Civil
                DropdownButtonFormField<MaritalStatus>(
                  value: _selectedMaritalStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado Civil *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: MaritalStatus.single, child: Text('Soltero/a')),
                    DropdownMenuItem(value: MaritalStatus.married, child: Text('Casado/a')),
                  ],
                  onChanged: (value) {
                    if (value !=null) {
                      setState(() => _selectedMaritalStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // N° Registro General (victor_number)
                TextFormField(
                  controller: _victorNumberController,
                  decoration: const InputDecoration(
                    labelText: 'N° Registro General *',
                    hintText: 'Ej: V-1234',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'N° Registro General es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Registro de Compañía
                TextFormField(
                  controller: _registroCompaniaController,
                  decoration: const InputDecoration(
                    labelText: 'Registro de Compañía',
                    hintText: 'Número de registro en la compañía',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
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
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.user == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
