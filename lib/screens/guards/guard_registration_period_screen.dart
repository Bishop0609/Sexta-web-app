import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/guard_registration_period_model.dart';
import 'package:sexta_app/providers/user_provider.dart';
import 'package:sexta_app/services/guard_registration_period_service.dart';
import 'package:sexta_app/services/guard_registration_period_service.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/services/email_service.dart';
import 'package:sexta_app/services/user_service.dart';
import 'package:sexta_app/models/user_model.dart';

/// Screen for managing guard registration periods (Admin/Oficial1 only)
class GuardRegistrationPeriodScreen extends ConsumerStatefulWidget {
  const GuardRegistrationPeriodScreen({super.key});

  @override
  ConsumerState<GuardRegistrationPeriodScreen> createState() =>
      _GuardRegistrationPeriodScreenState();
}

class _GuardRegistrationPeriodScreenState
    extends ConsumerState<GuardRegistrationPeriodScreen> {
  final _service = GuardRegistrationPeriodService();

  GuardRegistrationPeriod? _activePeriod;
  List<GuardRegistrationPeriod> _periods = [];
  bool _isLoading = false;
  Map<String, dynamic>? _nextMonthData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final active = await _service.getActivePeriod();
      final periods = await _service.getAllPeriods();

      // Calculate next month
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final monthData = _service.calculateMonthWeeks(
        nextMonth.year,
        nextMonth.month,
      );

      setState(() {
        _activePeriod = active;
        _periods = periods;
        _nextMonthData = monthData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openPeriod() async {
    if (_nextMonthData == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Inscripciones'),
        content: Text(
          '¿Abrir período de inscripción para ${_getMonthName(_nextMonthData!['periodStart'])}?\n\n'
          'Los bomberos podrán inscribirse desde ahora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.efectivaColor,
            ),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('Usuario no autenticado');

      await _service.openPeriod(
        periodStart: _nextMonthData!['periodStart'],
        periodEnd: _nextMonthData!['periodEnd'],
        userId: currentUser.id,
      );

      // Enviar correos de notificación (en segundo plano)
      try {
        final userService = UserService();
        final emailService = EmailService();
        
        // 1. Obtener usuarios
        final allUsers = await userService.getAllUsers();
        
        // 2. Filtrar: emails válidos y excluir Postulantes/Aspirantes
        final recipients = allUsers
            .where((u) => u.email != null && u.email!.isNotEmpty)
            .where((u) {
              final rank = u.rank.toLowerCase();
              return !rank.contains('postulante') && !rank.contains('aspirante');
            })
            .map((u) => u.email!)
            .toList();

        if (recipients.isNotEmpty) {
          // 3. Enviar correo
          await emailService.sendGuardRegistrationOpenedNotification(
            recipientEmails: recipients,
            periodStart: DateFormat('dd/MM/yyyy').format(_nextMonthData!['periodStart']),
            periodEnd: DateFormat('dd/MM/yyyy').format(_nextMonthData!['periodEnd']),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📧 Correo de aviso enviado a ${recipients.length} bomberos'),
                backgroundColor: AppTheme.efectivaColor,
              ),
            );
          }
        }
      } catch (e) {
        print('Error enviando correos de apertura: $e');
        // No bloqueamos el flujo si falla el correo
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Período abierto exitosamente'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _closePeriod() async {
    if (_activePeriod == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Inscripciones'),
        content: const Text(
          '¿Cerrar el período de inscripción actual?\n\n'
          'Los bomberos ya no podrán inscribirse.',
        ),
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
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.closePeriod(_activePeriod!.id);

      // Enviar correos de notificación de cierre
      try {
        final userService = UserService();
        final emailService = EmailService();
        
        // 1. Obtener usuarios activePeriod ya tiene la fecha
        final allUsers = await userService.getAllUsers();
        
        // 2. Filtrar
        final recipients = allUsers
            .where((u) => u.email != null && u.email!.isNotEmpty)
            .where((u) {
              final rank = u.rank.toLowerCase();
              return !rank.contains('postulante') && !rank.contains('aspirante');
            })
            .map((u) => u.email!)
            .toList();

        if (recipients.isNotEmpty) {
           // 3. Enviar correo
           await emailService.sendGuardRegistrationClosedNotification(
            recipientEmails: recipients,
            periodStart: DateFormat('dd/MM/yyyy').format(_activePeriod!.periodStart),
            periodEnd: DateFormat('dd/MM/yyyy').format(_activePeriod!.periodEnd),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📧 Correo de cierre enviado a ${recipients.length} bomberos'),
                backgroundColor: AppTheme.warningColor,
              ),
            );
          }
        }
      } catch (e) {
        print('Error enviando correos de cierre: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Período cerrado'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reopenPeriod(String periodId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reabrir Período'),
        content: const Text(
          '¿Reabrir este período de inscripción?\n\n'
          'Se cerrará cualquier período actualmente abierto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.efectivaColor,
            ),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.reopenPeriod(periodId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Período reabierto'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getMonthName(DateTime date) {
    return DateFormat('MMMM yyyy', 'es_ES').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inscripciones'),
        backgroundColor: AppTheme.navyBlue,
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next month card
                  _buildNextMonthCard(),
                  const SizedBox(height: 16),

                  // Active period status
                  _buildActiveStatusCard(),
                  const SizedBox(height: 24),

                  // History
                  Text(
                    'Historial de Períodos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryList(),
                ],
              ),
            ),
    );
  }

  Widget _buildNextMonthCard() {
    if (_nextMonthData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Cargando...'),
        ),
      );
    }

    final periodStart = _nextMonthData!['periodStart'] as DateTime;
    final periodEnd = _nextMonthData!['periodEnd'] as DateTime;
    final weeks = _nextMonthData!['weeks'] as List<Map<String, DateTime>>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Período de Inscripción - ${_getMonthName(periodStart)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_activePeriod != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.efectivaColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.efectivaColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ABIERTO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.efectivaColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Weeks
            ...List.generate(weeks.length, (index) {
              final week = weeks[index];
              final start = week['start']!;
              final end = week['end']!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.navyBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Semana ${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navyBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Lun ${DateFormat('dd', 'es_ES').format(start)} - Dom ${DateFormat('dd', 'es_ES').format(end)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rango total: ${DateFormat('dd/MM', 'es_ES').format(periodStart)} al ${DateFormat('dd/MM/yyyy', 'es_ES').format(periodEnd)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: _activePeriod == null
                  ? ElevatedButton.icon(
                      onPressed: _openPeriod,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Abrir Inscripciones'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.efectivaColor,
                        padding: const EdgeInsets.all(16),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _closePeriod,
                      icon: const Icon(Icons.lock),
                      label: const Text('Cerrar Inscripciones'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.criticalColor,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado Actual',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_activePeriod != null) ...[
              _buildInfoRow(
                Icons.date_range,
                'Período',
                _activePeriod!.periodLabel,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.lock_open,
                'Abierto',
                DateFormat('dd/MM/yyyy HH:mm', 'es_ES')
                    .format(_activePeriod!.openedAt),
              ),
            ] else
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Text(
                    'No hay período de inscripción activo',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.navyBlue),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_periods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No hay períodos registrados',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _periods.length,
      itemBuilder: (context, index) {
        final period = _periods[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        period.periodLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: period.isOpen
                            ? AppTheme.efectivaColor.withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        period.isOpen ? 'ABIERTO' : 'CERRADO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: period.isOpen
                              ? AppTheme.efectivaColor
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Abierto: ${DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(period.openedAt)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (period.closedAt != null)
                  Text(
                    'Cerrado: ${DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(period.closedAt!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                if (!period.isOpen) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _reopenPeriod(period.id),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reabrir'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.efectivaColor,
                        side: BorderSide(color: AppTheme.efectivaColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
