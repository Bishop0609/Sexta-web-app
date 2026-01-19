import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/models/activity_model.dart';
import 'package:sexta_app/models/user_model.dart';

class ManageActivitiesScreen extends StatefulWidget {
  const ManageActivitiesScreen({super.key});

  @override
  State<ManageActivitiesScreen> createState() => _ManageActivitiesScreenState();
}

class _ManageActivitiesScreenState extends State<ManageActivitiesScreen> {
  final _supabase = SupabaseService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _activities = [];
  List<UserModel> _allUsers = [];  // Para mostrar nombres de creadores/editores
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      // Cargar actividades y usuarios en paralelo
      final results = await Future.wait([
        _supabase.getUpcomingActivities(limit: 50),
        _supabase.getAllUsers(),
      ]);
      
      if (mounted) {
        setState(() {
          _activities = results[0] as List<Map<String, dynamic>>;
          _allUsers = results[1] as List<UserModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
      appBar: const BrandedAppBar(title: 'Gestionar Actividades'),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con botón crear
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note, size: 28, color: AppTheme.navyBlue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Próximas Actividades',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showActivityForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva Actividad'),
                      ),
                    ],
                  ),
                ),

                // Lista de actividades
                Expanded(
                  child: _activities.isEmpty
                      ? const Center(child: Text('No hay actividades programadas'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) {
                            final activity = _activities[index];
                            return _buildActivityCard(activity);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// Helper para obtener nombre de creador/editor
  Widget _buildCreatorEditorInfo(Map<String, dynamic> activity) {
    final createdBy = activity['created_by'] as String?;
    final modifiedBy = activity['modified_by'] as String?;
    
    // Buscar nombres de usuarios
    String? creatorName;
    String? editorName;
    
    if (createdBy != null) {
      try {
        final creator = _allUsers.firstWhere((u) => u.id == createdBy);
        creatorName = creator.fullName;
      } catch (_) {
        // Usuario no encontrado
      }
    }
    
    // Obtener nombre del editor si existe modified_by
    if (modifiedBy != null) {
      try {
        final editor = _allUsers.firstWhere((u) => u.id == modifiedBy);
        editorName = editor.fullName;
      } catch (_) {
        // Usuario no encontrado
      }
    }
    
    // No mostrar nada si no hay información
    if (creatorName == null && editorName == null) {
      return const SizedBox.shrink();
    }
    
    // Construir el texto según si fue editado o no
    String infoText;
    if (modifiedBy != null && editorName != null) {
      // Fue editado
      if (modifiedBy == createdBy) {
        // El creador editó su propia actividad
        infoText = 'Creado y editado por: $creatorName';
      } else {
        // Alguien más editó la actividad
        infoText = 'Creado por: $creatorName • Editado por: $editorName';
      }
    } else {
      // No ha sido editado
      infoText = 'Creado por: $creatorName';
    }
    
    return Text(
      infoText,
      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final type = activityTypeFromString(activity['activity_type'] as String);
    final date = DateTime.parse(activity['activity_date'] as String);
    final startTime = activity['start_time'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.navyBlue,
          child: Text(type.emoji, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          activity['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(type.displayName),
            Text(
              '${DateFormat('dd/MM/yyyy').format(date)}${startTime != null ? ' • ${startTime.substring(0, 5)}' : ''}',
            ),
            // Mostrar creador y editor
            const SizedBox(height: 4),
            _buildCreatorEditorInfo(activity),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showActivityForm(activity: activity);
            } else if (value == 'delete') {
              _confirmDelete(activity);
            }
          },
        ),
      ),
    );
  }

  void _showActivityForm({Map<String, dynamic>? activity}) {
    final isEdit = activity != null;
    
    showDialog(
      context: context,
      builder: (context) => _ActivityFormDialog(
        activity: activity,
        onSave: () {
          _loadActivities();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: Text('¿Estás seguro de eliminar "${activity['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.criticalColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _supabase.deleteActivity(activity['id']);
        _loadActivities();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Actividad eliminada'),
              backgroundColor: AppTheme.criticalColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

// Dialog para crear/editar actividad
class _ActivityFormDialog extends StatefulWidget {
  final Map<String, dynamic>? activity;
  final VoidCallback onSave;

  const _ActivityFormDialog({this.activity, required this.onSave});

  @override
  State<_ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<_ActivityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _supabase = SupabaseService();
  final _authService = AuthService();

  ActivityType _selectedType = ActivityType.academiaCompania;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      final activity = widget.activity!;
      _titleController.text = activity['title'] as String;
      _descriptionController.text = activity['description'] as String? ?? '';
      _locationController.text = activity['location'] as String? ?? '';
      _selectedType = activityTypeFromString(activity['activity_type'] as String);
      _selectedDate = DateTime.parse(activity['activity_date'] as String);
      
      if (activity['start_time'] != null) {
        final parts = (activity['start_time'] as String).split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (activity['end_time'] != null) {
        final parts = (activity['end_time'] as String).split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos requeridos')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'activity_type': activityTypeToString(_selectedType),
        'activity_date': _selectedDate!.toIso8601String().split('T')[0],
        'start_time': _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'end_time': _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'created_by': _authService.currentUserId!,
      };

      if (widget.activity == null) {
        data['created_by'] = _authService.currentUser!.id;
        await _supabase.createActivity(data);
      } else {
        final userId = _authService.currentUser!.id;
        await _supabase.updateActivity(widget.activity!['id'], data, userId);
      }

      if (mounted) {
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.activity == null ? 'Actividad creada' : 'Actividad actualizada'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.activity != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Actividad' : 'Nueva Actividad'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Tipo
                DropdownButtonFormField<ActivityType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Actividad *',
                    border: OutlineInputBorder(),
                  ),
                  items: ActivityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text('${type.emoji} ${type.displayName}'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 16),

                // Fecha
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Seleccionar fecha',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hora inicio y fin
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? const TimeOfDay(hour: 19, minute: 0),
                          );
                          if (time != null) setState(() => _startTime = time);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hora Inicio',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(_startTime?.format(context) ?? 'Opcional'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? const TimeOfDay(hour: 21, minute: 0),
                          );
                          if (time != null) setState(() => _endTime = time);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hora Fin',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(_endTime?.format(context) ?? 'Opcional'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Ubicación
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Cuartel',
                  ),
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    hintText: 'Detalles adicionales...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
              : Text(isEdit ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}
