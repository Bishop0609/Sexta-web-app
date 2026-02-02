import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/monthly_quota_model.dart';
import '../../models/treasury_payment_model.dart';
import '../../services/treasury_service.dart';
import '../../services/user_service.dart';
import '../../services/email_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';

/// Tab de registro de pagos de tesorería
class PaymentRegistrationTab extends ConsumerStatefulWidget {
  final TreasuryService treasuryService;

  const PaymentRegistrationTab({
    Key? key,
    required this.treasuryService,
  }) : super(key: key);

  @override
  ConsumerState<PaymentRegistrationTab> createState() => _PaymentRegistrationTabState();
}

class _PaymentRegistrationTabState extends ConsumerState<PaymentRegistrationTab> {
  final UserService _userService = UserService();
  final EmailService _emailService = EmailService();
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _statusFilter = 'all'; // all, paid, pending
  String _searchQuery = '';
  
  bool _isLoading = true;
  bool _isGenerating = false;
  List<UserModel> _allUsers = [];
  List<MonthlyQuota> _quotas = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar usuarios
      _allUsers = await _userService.getAllUsers();
      
      // Cargar cuotas del mes
      _quotas = await widget.treasuryService.getQuotasForMonth(
        month: _selectedMonth,
        year: _selectedYear,
      );

      // Cargar resumen
      _summary = await widget.treasuryService.getMonthSummary(
        month: _selectedMonth,
        year: _selectedYear,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQuotas() async {
    setState(() => _isGenerating = true);

    try {
      final result = await widget.treasuryService.generateMonthlyQuotas(
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuotas generadas: ${result.length} registros'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generando cuotas: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredUserQuotas() {
    final userQuotaMap = <String, MonthlyQuota>{};
    for (var quota in _quotas) {
      userQuotaMap[quota.userId] = quota;
    }

    final result = <Map<String, dynamic>>[];
    
    for (var user in _allUsers) {
      // Filtrar usuarios que no deben pagar
      if (user.paymentStartDate == null) continue;
      
      // Filtrar por búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.fullName.toLowerCase().contains(query) &&
            !user.rut.toLowerCase().contains(query)) {
          continue;
        }
      }

      final quota = userQuotaMap[user.id];
      
      // Filtrar por estado
      if (_statusFilter == 'paid' && (quota == null || quota.status != QuotaStatus.paid)) {
        continue;
      }
      if (_statusFilter == 'pending' && (quota != null && quota.status == QuotaStatus.paid)) {
        continue;
      }

      result.add({
        'user': user,
        'quota': quota,
      });
    }

    return result;
  }

  /// Envía notificaciones de cuotas generadas
  Future<void> _sendQuotaNotifications(List<MonthlyQuota> quotas) async {
    try {
      const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      final monthName = months[_selectedMonth - 1];
      
      for (final quota in quotas) {
        final user = _allUsers.firstWhere(
          (u) => u.id == quota.userId,
          orElse: () => throw Exception('Usuario no encontrado'),
        );
        
        if (user.email == null || user.email!.isEmpty) continue;
        
        _emailService.sendQuotaGeneratedNotification(
          userEmail: user.email!,
          userName: user.fullName,
          quotaAmount: quota.expectedAmount,
          month: monthName,
          year: _selectedYear,
        );
      }
    } catch (e) {
      print('Error enviando notificaciones de cuotas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Center(child: Text('Error: Usuario no autenticado'));
    }

    return Column(
      children: [
        // Controles superiores
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              // Selector de mes/año y botón generar
              Row(
                children: [
                  // Mes
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: List.generate(12, (index) {
                        final month = index + 1;
                        const months = [
                          'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
                        ];
                        return DropdownMenuItem(
                          value: month,
                          child: Text(months[index]),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMonth = value);
                          _loadData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Año
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - 1 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedYear = value);
                          _loadData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón generar cuotas
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateQuotas,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle),
                    label: const Text('Generar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Búsqueda
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre o RUT',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              // Filtros de estado como chips
              Row(
                children: [
                  const Text(
                    'Filtrar por estado:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _statusFilter == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => _statusFilter = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pendientes'),
                    selected: _statusFilter == 'pending',
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange.shade700,
                    onSelected: (selected) {
                      if (selected) setState(() => _statusFilter = 'pending');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pagados'),
                    selected: _statusFilter == 'paid',
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: Colors.green.shade700,
                    onSelected: (selected) {
                      if (selected) setState(() => _statusFilter = 'paid');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Resumen
        if (_summary.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total',
                  '${_summary['total_users'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Pagados',
                  '${_summary['paid_count'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Pendientes',
                  '${_summary['pending_count'] ?? 0}',
                  Icons.pending,
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Recaudado',
                  '\$${_summary['total_collected'] ?? 0}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ],
            ),
          ),

        // Lista de usuarios
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildUserList(currentUser),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildUserList(UserModel currentUser) {
    final filteredData = _getFilteredUserQuotas();

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                ? 'No se encontraron usuarios que coincidan con "$_searchQuery"'
                : _quotas.isEmpty
                  ? 'No hay cuotas generadas para este mes. Presione "Generar" arriba.'
                  : 'No hay usuarios con cuotas para mostrar',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // User count indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Mostrando ${filteredData.length} ${filteredData.length == 1 ? 'usuario' : 'usuarios'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // User list
        Expanded(
          child: ListView.separated(
            itemCount: filteredData.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = filteredData[index];
              final user = data['user'] as UserModel;
              final quota = data['quota'] as MonthlyQuota?;

        final hasPaid = quota != null && quota.status == QuotaStatus.paid;
        final statusColor = hasPaid ? Colors.green : Colors.orange;
        final statusIcon = hasPaid ? Icons.check_circle : Icons.pending;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(statusIcon, color: statusColor),
          ),
          title: Text(user.fullName),
          subtitle: Text(
            '${user.rank} | ${quota != null ? '\$${quota.expectedAmount}' : 'Sin cuota'}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quota != null) ...[
                Chip(
                  label: Text(
                    hasPaid ? 'Pagado' : 'Pendiente',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: statusColor.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
              ],
              if (quota != null && !hasPaid)
                ElevatedButton(
                  onPressed: () => _showRegisterPaymentDialog(user, quota, currentUser),
                  child: const Text('Registrar'),
                )
              else if (quota != null)
                TextButton(
                  onPressed: () => _showPaymentDetails(quota),
                  child: const Text('Ver'),
                ),
            ],
          ),
        );
      },
          ),
        ),
      ],
    );
  }

  Future<void> _showRegisterPaymentDialog(
    UserModel user,
    MonthlyQuota quota,
    UserModel currentUser,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _RegisterPaymentDialog(
        user: user,
        quota: quota,
        treasuryService: widget.treasuryService,
        registeredBy: currentUser.id,
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _showPaymentDetails(MonthlyQuota quota) async {
    final payments = await widget.treasuryService.getQuotaPayments(quota.id);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto esperado: \$${quota.expectedAmount}'),
            Text('Monto pagado: \$${quota.paidAmount}'),
            Text('Estado: ${quota.status.name}'),
            const SizedBox(height: 16),
            if (payments.isNotEmpty) ...[
              const Text('Pagos registrados:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...payments.map((p) => ListTile(
                title: Text('\$${p.amount}'),
                subtitle: Text('${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year}'),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para registrar un pago
class _RegisterPaymentDialog extends StatefulWidget {
  final UserModel user;
  final MonthlyQuota quota;
  final TreasuryService treasuryService;
  final String registeredBy;

  const _RegisterPaymentDialog({
    required this.user,
    required this.quota,
    required this.treasuryService,
    required this.registeredBy,
  });

  @override
  State<_RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends State<_RegisterPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  final _notesController = TextEditingController();
  final _emailService = EmailService();
  
  DateTime _paymentDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSaving = false;
  bool _markAsPaid = false; // Estado para el checkbox

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.quota.expectedAmount.toString();
    _amountController.addListener(_updateMarkAsPaidVisibility);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateMarkAsPaidVisibility);
    _amountController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateMarkAsPaidVisibility() {
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final success = await widget.treasuryService.registerPayment(
        quotaId: widget.quota.id,
        userId: widget.user.id,
        amount: int.parse(_amountController.text),
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        receiptNumber: _receiptController.text.isEmpty ? null : _receiptController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        registeredBy: widget.registeredBy,
        markAsPaid: _markAsPaid,
      );

      if (success && mounted) {
        // Enviar email de confirmación
        _sendPaymentConfirmationEmail();
        
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado exitosamente'),
            backgroundColor: Colors.green,
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

  /// Envía email de confirmación de pago
  Future<void> _sendPaymentConfirmationEmail() async {
    try {
      if (widget.user.email == null || widget.user.email!.isEmpty) return;
      
      const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      
      final quotaMonth = widget.quota.month;
      final quotaYear = widget.quota.year;
      final monthName = months[quotaMonth - 1];
      
      _emailService.sendPaymentConfirmationNotification(
        userEmail: widget.user.email!,
        userName: widget.user.fullName,
        paidAmount: int.parse(_amountController.text),
        paymentDate: DateFormat('dd/MM/yyyy').format(_paymentDate),
        month: monthName,
        year: quotaYear,
      );
    } catch (e) {
      print('Error enviando email de confirmación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si el monto ingresado es menor al esperado
    final currentAmount = int.tryParse(_amountController.text) ?? 0;
    final showAuthorizeCheckbox = currentAmount < widget.quota.expectedAmount;

    return AlertDialog(
      title: Text('Registrar Pago - ${widget.user.fullName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Monto
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (int.tryParse(value) == null) return 'Debe ser un número';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Fecha de pago
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _paymentDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de pago',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Checkbox para autorizar diferencia (SOLO si el monto es menor)
              if (showAuthorizeCheckbox)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'Autorizar diferencia',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Marcar cuota como totalmente SALDADA (pagada) aunque el monto sea menor.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _markAsPaid,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() => _markAsPaid = value ?? false);
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Método de pago
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PaymentMethod.cash, child: Text('Efectivo')),
                  DropdownMenuItem(value: PaymentMethod.transfer, child: Text('Transferencia')),
                  DropdownMenuItem(value: PaymentMethod.other, child: Text('Otro')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _paymentMethod = value);
                },
              ),
              const SizedBox(height: 16),
              
              // Número de comprobante
              TextFormField(
                controller: _receiptController,
                decoration: const InputDecoration(
                  labelText: 'N° Comprobante (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Notas
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
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
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
