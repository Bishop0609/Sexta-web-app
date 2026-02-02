import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/email_service.dart';
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
  final _emailService = EmailService();

  ActivityType _selectedType = ActivityType.academiaCompania;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSaving = false;
  
  // Configuración de notificaciones
  bool _notifyNow = true;
  bool _notify24h = true;
  bool _notify48h = true;
  Set<String> _notifyGroups = {'all'};

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
      
      // Parse times
      if (activity['start_time'] != null) {
        final parts = (activity['start_time'] as String).split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (activity['end_time'] != null) {
        final parts = (activity['end_time'] as String).split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      
      // Parse notification settings
      _notifyNow = activity['notify_now'] as bool? ?? true;
      _notify24h = activity['notify_24h'] as bool? ?? true;
      _notify48h = activity['notify_48h'] as bool? ?? true;
      final groups = activity['notify_groups'] as List<dynamic>?;
      if (groups != null && groups.isNotEmpty) {
        _notifyGroups = groups.cast<String>().toSet();
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
        // Configuración de notificaciones
        'notify_now': _notifyNow,
        'notify_24h': _notify24h,
        'notify_48h': _notify48h,
        'notify_groups': _notifyGroups.toList(),
      };

      final isNewActivity = widget.activity == null;
      
      if (isNewActivity) {
        data['created_by'] = _authService.currentUser!.id;
        await _supabase.createActivity(data);
      } else {
        final userId = _authService.currentUser!.id;
        await _supabase.updateActivity(widget.activity!['id'], data, userId);
        
        // Si se cambió la fecha, limpiar recordatorios antiguos
        final oldDate = widget.activity!['activity_date'] as String;
        final newDate = data['activity_date'] as String;
        
        if (oldDate != newDate) {
          print('📅 Fecha cambiada: $oldDate -> $newDate');
          print('🗑️  Limpiando recordatorios antiguos...');
          
          try {
            await _supabase.client
                .from('sent_reminders')
                .delete()
                .eq('reference_id', widget.activity!['id']);
            
            print('✅ Recordatorios antiguos eliminados');
          } catch (e) {
            print('⚠️  Error limpiando recordatorios: $e');
            // No fallar si hay error limpiando recordatorios
          }
        }
      }

      // Enviar notificaciones por email a todos los usuarios
      _sendEmailNotifications(isNewActivity, data);

      if (mounted) {
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNewActivity ? 'Actividad creada' : 'Actividad actualizada'),
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

  /// Envía notificaciones por email a los usuarios seleccionados
  Future<void> _sendEmailNotifications(bool isNewActivity, Map<String, dynamic> data) async {
    try {
      // Solo enviar si "Enviar ahora" está marcado
      if (!_notifyNow) return;
      
      // Obtener todos los usuarios
      final response = await _supabase.client
          .from('users')
          .select()
          .order('full_name');
      
      final allUsers = (response as List).map((json) => UserModel.fromJson(json)).toList();
      
      // Filtrar usuarios según grupos seleccionados
      final filteredUsers = _filterUsersByGroups(allUsers, _notifyGroups);
      
      // Preparar datos para el email
      final activityTitle = data['title'] as String;
      final activityType = activityTypeFromString(data['activity_type'] as String).displayName;
      final activityDate = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      final activityTime = _startTime != null
          ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
          : null;
      final location = data['location'] as String?;
      final description = data['description'] as String?;
      
      // Enviar emails
      print('📧 Enviando emails a ${filteredUsers.length} usuarios...');
      int emailsSent = 0;
      int emailsFailed = 0;
      
      for (final user in filteredUsers) {
        if (user.email == null || user.email!.isEmpty) continue;
        
        try {
          if (isNewActivity) {
            final success = await _emailService.sendActivityCreatedNotification(
              userEmail: user.email!,
              userName: user.fullName,
              activityTitle: activityTitle,
              activityType: activityType,
              activityDate: activityDate,
              activityTime: activityTime,
              location: location,
              description: description,
            );
            if (success) {
              emailsSent++;
              print('✅ Email enviado a: ${user.fullName} (${user.email})');
            } else {
              emailsFailed++;
              print('❌ Error enviando email a: ${user.fullName} (${user.email})');
            }
          } else {
            final success = await _emailService.sendActivityModifiedNotification(
              userEmail: user.email!,
              userName: user.fullName,
              activityTitle: activityTitle,
              activityDate: activityDate,
              activityTime: activityTime,
            );
            if (success) {
              emailsSent++;
              print('✅ Email enviado a: ${user.fullName} (${user.email})');
            } else {
              emailsFailed++;
              print('❌ Error enviando email a: ${user.fullName} (${user.email})');
            }
          }
        } catch (e) {
          emailsFailed++;
          print('❌ Excepción enviando email a ${user.fullName}: $e');
        }
        
        // Delay de 500ms para respetar el rate limit de Resend (2 requests/segundo)
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      print('📊 Resumen: $emailsSent enviados, $emailsFailed fallidos');
    } catch (e) {
      // No fallar si hay error en emails, solo registrar
      print('Error enviando notificaciones: $e');
    }
  }
  
  /// Filtra usuarios según los grupos seleccionados
  List<UserModel> _filterUsersByGroups(List<UserModel> users, Set<String> groups) {
    // Si "Todos" está seleccionado, devolver todos los usuarios
    if (groups.contains('all')) {
      return users;
    }
    
    return users.where((user) {
      // Oficiales: usuarios con roles de oficial
      if (groups.contains('officers') && _isOfficer(user)) {
        return true;
      }
      
      // Consejeros de Disciplina: usuarios con cargo específico (definir más tarde)
      if (groups.contains('discipline_council') && _isDisciplineCouncilor(user)) {
        return true;
      }
      
      // Postulantes/Aspirantes: usuarios con rangos específicos
      if (groups.contains('applicants') && _isApplicant(user)) {
        return true;
      }
      
      // Bomberos Activos: usuarios con rol bombero
      if (groups.contains('active_firefighters') && _isActiveFirefighter(user)) {
        return true;
      }
      
      // Bomberos Honorarios: usuarios con rango Honorario
      if (groups.contains('honorary_firefighters') && _isHonoraryFirefighter(user)) {
        return true;
      }
      
      return false;
    }).toList();
  }
  
  /// Verifica si el usuario es oficial
  /// Usa el mismo criterio que el módulo de asistencia (basado en campo 'rank')
  /// IMPORTANTE: Solo OFICIALES DE COMPAÑÍA (excluye oficiales de cuerpo/generales)
  bool _isOfficer(UserModel user) {
    final rankLower = user.rank.toLowerCase();
    
    // Solo Oficiales de Compañía (NO incluye oficiales de cuerpo/generales)
    final companyOfficerPatterns = [
      'director',
      'secretari',      // Secretario/a, Pro-Secretario/a
      'tesorer',        // Tesorero/a, Pro-Tesorero/a
      'capitán',
      'teniente',
      'inspector m.',   // Inspector M. Mayor/Menor
    ];
    
    // Verificar patrones de Oficiales de Compañía
    for (final pattern in companyOfficerPatterns) {
      if (rankLower.contains(pattern)) {
        return true;
      }
    }
    
    // Caso especial: "Ayudante" SOLO si es de compañía
    // Excluir "Ayudante de Comandancia" (es oficial de cuerpo)
    if (rankLower.contains('ayudante') && !rankLower.contains('de comandancia')) {
      return true;
    }
    
    return false;
  }
  
  /// Verifica si el usuario es consejero de disciplina
  /// TODO: Definir criterio específico cuando el usuario lo indique
  bool _isDisciplineCouncilor(UserModel user) {
    // Por ahora retornar false, se definirá más tarde
    return false;
  }
  
  /// Verifica si el usuario es postulante o aspirante
  bool _isApplicant(UserModel user) {
    final applicantRanks = ['Postulante', 'Aspirante'];
    return applicantRanks.contains(user.rank);
  }
  
  /// Verifica si el usuario es bombero activo
  bool _isActiveFirefighter(UserModel user) {
    return user.role == UserRole.bombero;
  }
  
  /// Verifica si el usuario es bombero honorario
  bool _isHonoraryFirefighter(UserModel user) {
    return user.rank.toLowerCase().contains('honorario');
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
                const SizedBox(height: 24),

                // Sección de Notificaciones
                Divider(),
                const SizedBox(height: 8),
                Text(
                  'Configuración de Notificaciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // ¿Cuándo enviar?
                Text(
                  '¿Cuándo enviar notificaciones?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Enviar ahora'),
                  value: _notifyNow,
                  onChanged: (value) => setState(() => _notifyNow = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Recordatorio 24 horas antes'),
                  value: _notify24h,
                  onChanged: (value) => setState(() => _notify24h = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Recordatorio 48 horas antes'),
                  value: _notify48h,
                  onChanged: (value) => setState(() => _notify48h = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                
                const SizedBox(height: 16),
                
                // ¿A quién enviar?
                Text(
                  '¿A quién enviar?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Todos los bomberos'),
                  value: _notifyGroups.contains('all'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _notifyGroups = {'all'}; // Si selecciona "Todos", deselecciona otros
                      } else {
                        _notifyGroups.remove('all');
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Oficiales'),
                  value: _notifyGroups.contains('officers'),
                  enabled: !_notifyGroups.contains('all'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _notifyGroups.add('officers');
                      } else {
                        _notifyGroups.remove('officers');
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Consejeros de Disciplina'),
                  value: _notifyGroups.contains('discipline_council'),
                  enabled: !_notifyGroups.contains('all'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _notifyGroups.add('discipline_council');
                      } else {
                        _notifyGroups.remove('discipline_council');
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Postulantes/Aspirantes'),
                  value: _notifyGroups.contains('applicants'),
                  enabled: !_notifyGroups.contains('all'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _notifyGroups.add('applicants');
                      } else {
                        _notifyGroups.remove('applicants');
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Bomberos Activos'),
                  value: _notifyGroups.contains('active_firefighters'),
                  enabled: !_notifyGroups.contains('all'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _notifyGroups.add('active_firefighters');
                      } else {
                        _notifyGroups.remove('active_firefighters');
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Bomberos Honorarios'),
                  value: _notifyGroups.contains('honorary_firefighters'),
                  enabled: !_notifyGroups.contains('all'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _notifyGroups.add('honorary_firefighters');
                      } else {
                        _notifyGroups.remove('honorary_firefighters');
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
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
