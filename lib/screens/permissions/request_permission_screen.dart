import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/email_service.dart';
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
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

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
    if (_startDate == null || _endDate == null) return 0;
    
    // Días inclusivos: incluye primer y último día
    final difference = _endDate!.difference(_startDate!).inDays;
    return difference + 1; // +1 para incluir ambos días
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
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione las fechas')),
      );
      return;
    }

    // Calcular días y mostrar advertencia si aplica
    final days = _calculatePermissionDays();
    if (days >= 15) {
      final shouldContinue = await _showApprovalWarningDialog(days);
      if (!shouldContinue) return; // Usuario canceló
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Obtener perfil del usuario
      final userProfile = await _supabase.getUserProfile(userId);
      if (userProfile == null) throw Exception('Perfil no encontrado');

      // Crear solicitud de permiso
      await _supabase.createPermission({
        'user_id': userId,
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': _endDate!.toIso8601String().split('T')[0],
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      final startDateFormatted = DateFormat('dd/MM/yyyy').format(_startDate!);
      final endDateFormatted = DateFormat('dd/MM/yyyy').format(_endDate!);
      final reason = _reasonController.text.trim();

      // Enviar email de confirmación al solicitante
      if (userProfile.email != null && userProfile.email!.isNotEmpty) {
        await _emailService.sendPermissionSubmittedConfirmation(
          userEmail: userProfile.email!,
          firefighterName: userProfile.fullName,
          startDate: startDateFormatted,
          endDate: endDateFormatted,
          reason: reason,
        );
      }

      // Enviar email de notificación a oficiales
      // TODO: Obtener emails de oficiales desde BD
      await _emailService.sendPermissionRequestNotification(
        officerEmail: ['gunthersoft.apps@gmail.com'], // Lista de emails temporales de prueba
        firefighterName: userProfile.fullName,
        startDate: startDateFormatted,
        endDate: endDateFormatted,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada exitosamente'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
        
        // Limpiar formulario
        _formKey.currentState!.reset();
        _reasonController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                      const SizedBox(height: 24),
                      
                      // Fecha inicio
                      Text(
                        'Fecha de Inicio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                                  color: _startDate != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Fecha fin
                      Text(
                        'Fecha de Término',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                                  color: _endDate != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
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
