import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';

/// Módulo 10: Configuración de Tipos de Acto (Efectiva vs Abono)
class ActTypesScreen extends StatefulWidget {
  const ActTypesScreen({super.key});

  @override
  State<ActTypesScreen> createState() => _ActTypesScreenState();
}

class _ActTypesScreenState extends State<ActTypesScreen> {
  final _supabase = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  List<Map<String, dynamic>> _actTypes = [];
  String _selectedCategory = 'efectiva';
  bool _isLoading = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _loadActTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadActTypes() async {
    setState(() => _isLoading = true);
    try {
      final actTypes = await _supabase.getAllActTypes();
      setState(() {
        _actTypes = actTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando tipos de acto: $e');
    }
  }

  Future<void> _saveActType() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_editingId != null) {
        // Editar
        await _supabase.updateActType(_editingId!, {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de acto actualizado'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      } else {
        // Crear
        await _supabase.createActType({
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'is_active': true,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de acto creado'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      }

      _clearForm();
      _loadActTypes();
    } catch (e) {
      _showError('Error guardando: $e');
    }
  }

  void _editActType(Map<String, dynamic> actType) {
    setState(() {
      _editingId = actType['id'];
      _nameController.text = actType['name'];
      _selectedCategory = actType['category'];
    });
  }

  Future<void> _deleteActType(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Está seguro de eliminar este tipo de acto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.deleteActType(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de acto eliminado')),
        );
        _loadActTypes();
      } catch (e) {
        _showError('Error eliminando: $e');
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    setState(() {
      _selectedCategory = 'efectiva';
      _editingId = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.criticalColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Tipos de Acto'),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulario
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _editingId != null ? 'Editar Tipo de Acto' : 'Nuevo Tipo de Acto',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                if (_editingId != null)
                                  TextButton(
                                    onPressed: _clearForm,
                                    child: const Text('Cancelar'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Nombre
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                hintText: 'ej: Incendio, Academia, Capacitación',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingrese un nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Categoría (CRÍTICO: Efectiva vs Abono)
                            Text(
                              'Categoría Contable',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RadioListTile<String>(
                                    value: 'efectiva',
                                    groupValue: _selectedCategory,
                                    onChanged: (value) {
                                      setState(() => _selectedCategory = value!);
                                    },
                                    title: Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.efectivaColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('LISTA EFECTIVA'),
                                      ],
                                    ),
                                    subtitle: const Text(
                                      'Cuenta para obligación legal de asistencia',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  RadioListTile<String>(
                                    value: 'abono',
                                    groupValue: _selectedCategory,
                                    onChanged: (value) {
                                      setState(() => _selectedCategory = value!);
                                    },
                                    title: Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.abonoColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('ABONO'),
                                      ],
                                    ),
                                    subtitle: const Text(
                                      'Cuenta como extra o compensación',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Botón guardar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saveActType,
                                icon: Icon(_editingId != null ? Icons.save : Icons.add),
                                label: Text(_editingId != null ? 'Actualizar' : 'Crear Tipo de Acto'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Lista de tipos
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipos de Acto Configurados',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          if (_actTypes.isEmpty)
                            const Center(child: Text('No hay tipos de acto'))
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Nombre')),
                                  DataColumn(label: Text('Categoría')),
                                  DataColumn(label: Text('Estado')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                rows: _actTypes.map((actType) {
                                  final category = actType['category'] as String;
                                  final isEfectiva = category == 'efectiva';
                                  final color = isEfectiva 
                                      ? AppTheme.efectivaColor 
                                      : AppTheme.abonoColor;
                                  
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(actType['name'])),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                category.toUpperCase(),
                                                style: TextStyle(
                                                  color: color,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Icon(
                                          actType['is_active'] ? Icons.check_circle : Icons.cancel,
                                          color: actType['is_active'] 
                                              ? AppTheme.efectivaColor 
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              onPressed: () => _editActType(actType),
                                              tooltip: 'Editar',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20),
                                              color: AppTheme.criticalColor,
                                              onPressed: () => _deleteActType(actType['id']),
                                              tooltip: 'Eliminar',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
