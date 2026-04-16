// import 'dart:io'; (Eliminado)
import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/email_service.dart';
import 'package:sexta_app/services/storage_service.dart';
import 'package:intl/intl.dart';

class RequestPermissionScreen extends StatefulWidget {
  const RequestPermissionScreen({super.key});

  @override
  State<RequestPermissionScreen> createState() => _RequestPermissionScreenState();
}

class _RequestPermissionScreenState extends State<RequestPermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _supabase = SupabaseService();
  final _authService = AuthService();
  final _emailService = EmailService();
  final _storageService = StorageService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  // Tipo de permiso
  String _tipoPermiso = 'fecha'; // 'fecha' o 'actividad'
  List<Map<String, dynamic>> _actividadesFuturas = [];
  Map<String, dynamic>? _selectedActividad;
  bool _isLoadingActividades = false;

  // Archivo adjunto
  AttachmentFile? _attachedFile;
  String? _attachedFileName;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? _startDate ?? DateTime.now()
        : _endDate ?? _startDate ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // Reset end date if it's before new start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  int _calculatePermissionDays() {
    if (_tipoPermiso == 'actividad') return 1;
    if (_startDate == null || _endDate == null) return 0;
    final difference = _endDate!.difference(_startDate!).inDays;
    return difference + 1;
  }

  Future<void> _loadActividadesFuturas() async {
    setState(() => _isLoadingActividades = true);
    try {
      final result = await _supabase.client.rpc('get_actividades_futuras_con_permisos');
      final allActividades = List<Map<String, dynamic>>.from(result as List);

      final asistenciasTomadas = await _supabase.client
          .from('attendance_events')
          .select('actividad_id')
          .not('actividad_id', 'is', null);

      final tomadasSet = (asistenciasTomadas as List)
          .map((e) => e['actividad_id'] as String)
          .toSet();

      setState(() {
        _actividadesFuturas = allActividades
            .where((a) => !tomadasSet.contains(a['id']))
            .toList();
        _isLoadingActividades = false;
      });
    } catch (e) {
      setState(() => _isLoadingActividades = false);
      _showError('Error cargando actividades: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _selectAttachment(String source) async {
    try {
      AttachmentFile? file;
      String fileName = '';

      switch (source) {
        case 'gallery':
          file = await _storageService.pickImageFromGallery();
          fileName = 'Imagen seleccionada';
          break;
        case 'camera':
          file = await _storageService.pickImageFromCamera();
          fileName = 'Foto capturada';
          break;
        case 'pdf':
          file = await _storageService.pickPdfFile();
          if (file != null) {
            fileName = file.fileName;
          }
          break;
      }

      if (file != null) {
        // Validar tamaño (ahora es sincrono o no necesita await porque ya está en memoria para AttachmentFile)
        final isValid = _storageService.validateFileSize(file);
        if (!isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo excede el límite de 2MB'),
                backgroundColor: AppTheme.criticalColor,
              ),
            );
          }
          return;
        }

        setState(() {
          _attachedFile = file;
          _attachedFileName = fileName;
        });
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
    });
  }

  Future<bool> _showApprovalWarningDialog(int days) async {
    String title;
    String message;
    Color color;
    IconData icon;

    if (days >= 30) {
      title = 'Permiso de Larga Duración';
      message = 'Este permiso es de $days días y debe ser aprobado por Reunión de Compañía.';
      color = AppTheme.criticalColor;
      icon = Icons.groups;
    } else if (days >= 15) {
      title = 'Permiso de Duración Media';
      message = 'Este permiso es de $days días y debe ser aprobado por la Junta de Oficiales.';
      color = AppTheme.warningColor;
      icon = Icons.supervised_user_circle;
    } else {
      return true; // No mostrar diálogo para permisos cortos
    }

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(icon, size: 48, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Su solicitud será revisada por la autoridad correspondiente.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Entendido, Solicitar'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _submitPermission() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('Usuario no autenticado');

    if (_tipoPermiso == 'fecha') {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor seleccione las fechas')),
        );
        return;
      }
      final days = _calculatePermissionDays();
      if (days >= 15) {
        final shouldContinue = await _showApprovalWarningDialog(days);
        if (!shouldContinue) return;
      }
    } else {
      if (_selectedActividad == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor seleccione una actividad')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final userProfile = await _supabase.getUserProfile(userId);
      if (userProfile == null) throw Exception('Perfil no encontrado');

      final reason = _reasonController.text.trim();
      final baseData = <String, dynamic>{
        'user_id': userId,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      if (_tipoPermiso == 'fecha') {
        baseData['start_date'] = _startDate!.toIso8601String().split('T')[0];
        baseData['end_date'] = _endDate!.toIso8601String().split('T')[0];
        baseData['tipo_permiso'] = 'fecha';
        baseData['aprobador_tipo'] = 'capitan';
      } else {
        baseData['tipo_permiso'] = 'actividad';
        baseData['actividad_id'] = _selectedActividad!['id'];
        baseData['aprobador_tipo'] = _selectedActividad!['aprobador'];
      }

      String? permissionId;
      if (_attachedFile != null) {
        final createdPermission = await _supabase.createPermission(baseData);
        permissionId = createdPermission['id'] as String;
        final attachmentPath = await _storageService.uploadPermissionAttachment(
          _attachedFile!,
          permissionId,
          userId,
        );
        await _supabase.updatePermission(permissionId, {'attachment_path': attachmentPath});
      } else {
        await _supabase.createPermission(baseData);
      }

      // Emails
      if (_tipoPermiso == 'fecha') {
        final startDateFormatted = DateFormat('dd/MM/yyyy').format(_startDate!);
        final endDateFormatted = DateFormat('dd/MM/yyyy').format(_endDate!);
        
        await _emailService.sendPermissionRequestNotification(
          officerEmail: ['capitan6@bomberosdecoquimbo.cl'],
          firefighterName: userProfile.fullName,
          startDate: startDateFormatted,
          endDate: endDateFormatted,
          reason: reason,
        );
      } else {
        final emailsActividad = _selectedActividad!['emails'] as List?;
        final oficialEmails = (emailsActividad != null && emailsActividad.isNotEmpty)
            ? List<String>.from(emailsActividad)
            : ['capitan6@bomberosdecoquimbo.cl'];
        final actividadFecha = _selectedActividad!['activity_date'] as String? ?? '';
        final actividadNombre = _selectedActividad!['title'] as String? ?? '';
        final aprobador = _selectedActividad!['aprobador'] as String? ?? 'capitan';
        
        await _emailService.sendPermissionRequestNotification(
          officerEmail: oficialEmails,
          firefighterName: userProfile.fullName,
          startDate: '', // No aplica
          endDate: '', // No aplica
          reason: reason,
          activityName: actividadNombre,
          activityDate: actividadFecha,
          aprobadorTipo: aprobador,
        );
      }

      // Email de confirmación al solicitante (Siempre)
      if (userProfile.email != null && userProfile.email!.isNotEmpty) {
        String startDateFormatted = '';
        String endDateFormatted = '';
        if (_tipoPermiso == 'fecha' && _startDate != null && _endDate != null) {
          startDateFormatted = DateFormat('dd/MM/yyyy').format(_startDate!);
          endDateFormatted = DateFormat('dd/MM/yyyy').format(_endDate!);
        }
        
        await _emailService.sendPermissionSubmittedConfirmation(
          userEmail: userProfile.email!,
          firefighterName: userProfile.fullName,
          startDate: startDateFormatted,
          endDate: endDateFormatted,
          reason: reason,
          activityName: _tipoPermiso == 'actividad' ? (_selectedActividad?['title'] as String?) : null,
          activityDate: _tipoPermiso == 'actividad' && _selectedActividad?['activity_date'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_selectedActividad!['activity_date']))
              : null,
          aprobadorTipo: _tipoPermiso == 'actividad' ? (_selectedActividad?['aprobador'] as String?) : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada exitosamente'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
        _formKey.currentState!.reset();
        _reasonController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
          _selectedActividad = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(
        title: 'Solicitar Permiso',
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva Solicitud de Permiso',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),

                      // SegmentedButton tipo permiso
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'fecha',
                            label: Text('Por Fechas'),
                            icon: Icon(Icons.date_range),
                          ),
                          ButtonSegment(
                            value: 'actividad',
                            label: Text('Por Actividad'),
                            icon: Icon(Icons.event),
                          ),
                        ],
                        selected: {_tipoPermiso},
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.institutionalRed;
                            }
                            return null;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return null;
                          }),
                        ),
                        onSelectionChanged: (val) {
                          setState(() {
                            _tipoPermiso = val.first;
                            if (_tipoPermiso == 'actividad' && _actividadesFuturas.isEmpty) {
                              _loadActividadesFuturas();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Sección fechas o actividad (condicional)
                      if (_tipoPermiso == 'fecha') ...[
                        // Fecha inicio
                        Text('Fecha de Inicio', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _startDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                      : 'Seleccionar fecha',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _startDate != null ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Fecha fin
                        Text('Fecha de Término', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _endDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                      : 'Seleccionar fecha',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _endDate != null ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        // Selector de actividad
                        Text('Actividad', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_isLoadingActividades)
                          const Center(child: CircularProgressIndicator())
                        else if (_actividadesFuturas.isEmpty)
                          Text('No hay actividades futuras disponibles.', style: TextStyle(color: Colors.grey[600]))
                        else
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedActividad,
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            hint: const Text('Seleccionar actividad'),
                            items: _actividadesFuturas.map((act) {
                              final actTypeName = act['act_type_name'] as String? ?? '';
                              String emoji = '📅';
                              if (actTypeName == 'Academia de Compañía' || actTypeName == 'Academia de Cuerpo') {
                                emoji = '📚';
                              } else if (actTypeName == 'Reunión Ordinaria' || actTypeName == 'Reunión Extraordinaria') {
                                emoji = '🤝';
                              } else if (actTypeName == 'Citación de Compañía' || actTypeName == 'Citación de Cuerpo') {
                                emoji = '📢';
                              }

                              final dateStr = act['activity_date'] as String?;
                              String fechaStr = '';
                              if (dateStr != null && dateStr.isNotEmpty) {
                                try {
                                  final dateObj = DateTime.parse(dateStr);
                                  fechaStr = DateFormat('dd/MMM', 'es_ES').format(dateObj);
                                } catch (_) {}
                              }
                              
                              final titulo = act['title'] as String? ?? '';
                              return DropdownMenuItem(
                                value: act,
                                child: Text('$emoji $fechaStr — $titulo', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedActividad = val),
                          ),
                        if (_selectedActividad != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.institutionalRed.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.institutionalRed.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Builder(builder: (context) {
                                      final dateStr = _selectedActividad!['activity_date'] as String?;
                                      String fechaStr = '-';
                                      if (dateStr != null && dateStr.isNotEmpty) {
                                         try {
                                           final dateObj = DateTime.parse(dateStr);
                                           fechaStr = DateFormat('dd/MM/yyyy').format(dateObj); // Mostrar completa aquí
                                         } catch (_) {}
                                      }
                                      return Text('Fecha: $fechaStr');
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Aprobador: ${_selectedActividad!['aprobador'] == 'capitan' ? 'Capitán' : 'Director'}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],

                      // Archivo Adjunto (Opcional)
                      Row(
                        children: [
                          Text(
                            'Archivo Adjunto',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Opcional',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (_attachedFile != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.institutionalRed),
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.institutionalRed.withOpacity(0.05),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _attachedFileName?.endsWith('.pdf') == true 
                                    ? Icons.picture_as_pdf 
                                    : Icons.image,
                                color: AppTheme.institutionalRed,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _attachedFileName ?? 'Archivo adjunto',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Tamaño: ${_storageService.getFileSizeString(_attachedFile!.size)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.criticalColor),
                                onPressed: _removeAttachment,
                                tooltip: 'Eliminar adjunto',
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectAttachment('gallery'),
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Galería'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectAttachment('camera'),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Cámara'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectAttachment('pdf'),
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                                label: const Text('PDF'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 8),
                      Text(
                        'Máximo 2MB. Formatos: JPG, PNG, PDF.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      
                      // Motivo
                      Text(
                        'Motivo del Permiso',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Describa el motivo de su solicitud...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingrese el motivo';
                          }
                          if (value.trim().length < 10) {
                            return 'El motivo debe tener al menos 10 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Información
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.abonoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.abonoColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Se enviará un email a los oficiales para su revisión. Recibirás una notificación cuando sea aprobada o rechazada.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.navyBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Botón enviar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitPermission,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enviar Solicitud'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
