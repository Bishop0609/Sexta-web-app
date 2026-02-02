import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/epp_service.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/models/epp_assignment_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:intl/intl.dart';

class EPPManagementScreen extends ConsumerStatefulWidget {
  const EPPManagementScreen({super.key});

  @override
  ConsumerState<EPPManagementScreen> createState() => _EPPManagementScreenState();
}

class _EPPManagementScreenState extends ConsumerState<EPPManagementScreen> {
  final _eppService = EPPService();
  final _supabaseService = SupabaseService();
  final _authService = AuthService();

  bool _isLoading = true;
  List<EPPAssignmentModel> _assignments = [];
  Map<EPPType, int> _statistics = {};
  List<UserModel> _allUsers = [];
  UserModel? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final assignments = await _eppService.getAllAssignments();
      final stats = await _eppService.getEPPStatisticsByType();
      final users = await _supabaseService.getAllUsers();

      setState(() {
        _assignments = assignments;
        _statistics = stats;
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading EPP data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Gestión de EPP',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Chart
                  _buildStatisticsCard(),
                  const SizedBox(height: 24),
                  
                  // Assignment Form
                  _buildAssignmentForm(),
                  const SizedBox(height: 24),
                  
                  // Assignments List
                  _buildAssignmentsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_statistics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Estadísticas de EPP Asignados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const Text('No hay EPP asignados aún'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de EPP Asignados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxStatY(),
                  barGroups: _buildStatBarGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final types = _statistics.keys.toList();
                          if (value.toInt() >= types.length) {
                            return const Text('');
                          }
                          final type = types[value.toInt()];
                          // Abreviar nombres largos
                          String label = type.displayName;
                          if (label.length > 10) {
                            label = label.substring(0, 8) + '...';
                          }
                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildStatBarGroups() {
    final types = _statistics.keys.toList();
    return List.generate(types.length, (index) {
      final count = _statistics[types[index]]!;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: AppTheme.navyBlue,
            width: 20,
          ),
        ],
      );
    });
  }

  double _getMaxStatY() {
    if (_statistics.isEmpty) return 10;
    final max = _statistics.values.reduce((a, b) => a > b ? a : b);
    return (max * 1.2).ceilToDouble();
  }

  Widget _buildAssignmentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asignar Nuevo EPP',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            
            // User search
            Autocomplete<UserModel>(
              displayStringForOption: (user) => '${user.fullName} (${user.rank})',
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<UserModel>.empty();
                }
                return _allUsers.where((user) {
                  return user.fullName
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (user) {
                setState(() => _selectedUser = user);
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Buscar bombero',
                    hintText: 'Escribe el nombre del bombero',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            
            if (_selectedUser != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppTheme.navyBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedUser!.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _selectedUser!.rank,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedUser = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAssignmentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Asignar EPP a este bombero'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsList() {
    if (_assignments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'EPP Asignados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const Text('No hay asignaciones registradas'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EPP Asignados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _assignments.length,
              itemBuilder: (context, index) {
                final assignment = _assignments[index];
                return _buildAssignmentTile(assignment);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentTile(EPPAssignmentModel assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: assignment.isReturned 
              ? Colors.grey 
              : AppTheme.navyBlue,
          child: Icon(
            _getEPPIcon(assignment.eppType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '${assignment.eppType.displayName} - ${assignment.internalCode}',
          style: TextStyle(
            decoration: assignment.isReturned 
                ? TextDecoration.lineThrough 
                : null,
          ),
        ),
        subtitle: Text(
          'Estado: ${assignment.condition.displayName}\n'
          'Fecha: ${DateFormat('dd/MM/yyyy').format(assignment.receptionDate)}',
        ),
        trailing: assignment.isReturned
            ? const Chip(
                label: Text('Devuelto', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey,
              )
            : IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showAssignmentOptions(assignment),
              ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getEPPIcon(EPPType type) {
    switch (type) {
      case EPPType.casco:
        return Icons.safety_divider;
      case EPPType.uniformeEstructural:
      case EPPType.uniformeMultirrol:
      case EPPType.uniformeParada:
        return Icons.checkroom;
      case EPPType.guantesEstructurales:
      case EPPType.guantesRescate:
        return Icons.back_hand;
      case EPPType.botas:
        return Icons.skateboarding;
      case EPPType.linterna:
        return Icons.flashlight_on;
      default:
        return Icons.inventory_2;
    }
  }

  void _showAssignmentDialog() {
    if (_selectedUser == null) return;

    showDialog(
      context: context,
      builder: (context) => _AssignmentDialog(
        user: _selectedUser!,
        onAssigned: () {
          _loadData();
          setState(() => _selectedUser = null);
        },
      ),
    );
  }

  void _showAssignmentOptions(EPPAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opciones de EPP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(assignment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard_return),
              title: const Text('Registrar Devolución'),
              onTap: () {
                Navigator.pop(context);
                _showReturnDialog(assignment);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(EPPAssignmentModel assignment) {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de edición en desarrollo')),
    );
  }

  void _showReturnDialog(EPPAssignmentModel assignment) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Devolución'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('EPP: ${assignment.eppType.displayName}'),
            Text('Código: ${assignment.internalCode}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo de devolución',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debes indicar el motivo')),
                );
                return;
              }

              try {
                final userId = _authService.currentUserId!;
                await _eppService.returnEPP(
                  assignmentId: assignment.id,
                  returnDate: DateTime.now(),
                  returnReason: reasonController.text.trim(),
                  returnedBy: userId,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('EPP devuelto exitosamente')),
                  );
                  _loadData();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Registrar Devolución'),
          ),
        ],
      ),
    );
  }
}

// Dialog for new assignment
class _AssignmentDialog extends StatefulWidget {
  final UserModel user;
  final VoidCallback onAssigned;

  const _AssignmentDialog({
    required this.user,
    required this.onAssigned,
  });

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _eppService = EPPService();
  final _authService = AuthService();

  EPPType _selectedType = EPPType.casco;
  EPPCondition _selectedCondition = EPPCondition.nuevo;
  final _internalCodeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _observationsController = TextEditingController();
  DateTime _receptionDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Asignar EPP a ${widget.user.fullName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<EPPType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de EPP',
                  border: OutlineInputBorder(),
                ),
                items: EPPType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _internalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Código interno *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? true 
                    ? 'Campo requerido' 
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EPPCondition>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Estado *',
                  border: OutlineInputBorder(),
                ),
                items: EPPCondition.values.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCondition = value!),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Fecha de recepción'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_receptionDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _receptionDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _receptionDate = date);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observationsController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Asignar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = _authService.currentUserId!;
      await _eppService.assignEPP(
        userId: widget.user.id,
        eppType: _selectedType,
        internalCode: _internalCodeController.text.trim(),
        brand: _brandController.text.trim().isEmpty 
            ? null 
            : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty 
            ? null 
            : _modelController.text.trim(),
        color: _colorController.text.trim().isEmpty 
            ? null 
            : _colorController.text.trim(),
        condition: _selectedCondition,
        receptionDate: _receptionDate,
        observations: _observationsController.text.trim().isEmpty 
            ? null 
            : _observationsController.text.trim(),
        createdBy: userId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('EPP asignado exitosamente')),
        );
        widget.onAssigned();
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
  void dispose() {
    _internalCodeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
}
